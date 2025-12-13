import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/services/connectivity_service.dart';
import '../../dgii/dgii_validation_service.dart';
import '../data/invoice_database.dart';
import '../data/invoice_repository.dart';
import '../data/invoice_sync_service.dart';
import '../domain/invoice.dart';

final invoiceRepositoryProvider =
    FutureProvider<InvoiceRepository>((ref) async {
  final database = await InvoiceDatabase.open();
  return InvoiceRepository(database);
});

final invoiceControllerProvider =
    AsyncNotifierProvider<InvoiceController, List<Invoice>>(
  InvoiceController.new,
);

class InvoiceController extends AsyncNotifier<List<Invoice>> {
  InvoiceRepository? _repository;
  InvoiceSyncService? _syncService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;
  bool _isValidatingPending = false;

  Future<InvoiceRepository> _ensureRepository() async {
    final existing = _repository;
    if (existing != null) {
      return existing;
    }
    final resolved = await ref.watch(invoiceRepositoryProvider.future);
    _repository = resolved;
    _syncService ??= InvoiceSyncService(
      repository: resolved,
      firestore: FirebaseFirestore.instance,
      onLocalChange: () async {
        final userId = _currentUserId;
        state = AsyncData(await resolved.getAll(userId: userId));
      },
    );
    return resolved;
  }

  String? get _currentUserId {
    return ref
        .read(authStateChangesProvider)
        .maybeWhen(data: (user) => user?.uid, orElse: () => null);
  }

  @override
  Future<List<Invoice>> build() async {
    final repository = await _ensureRepository();
    final userId = _currentUserId;

    // Monitorear conectividad para validar invoices pendientes
    _setupConnectivityMonitoring(repository);

    // Verificar conectividad inicial y validar invoices pendientes si hay conexión
    final connectivityService = ref.read(connectivityServiceProvider);
    final hasInternet = await connectivityService.hasInternetConnection();
    if (hasInternet) {
      // Validar invoices pendientes después de un breve delay para no bloquear el build
      Future.delayed(const Duration(seconds: 2), () {
        _validatePendingInvoices(repository);
      });
    } else {
      _wasOffline = true;
    }

    ref.listen<AsyncValue<User?>>(
      authStateChangesProvider,
      (previous, next) async {
        await next.whenOrNull(
          data: (user) async {
            if (user != null) {
              await _syncService?.start(user);
            } else {
              await _syncService?.stop();
            }
            // Refrescar cuando cambia el usuario
            await refresh();
          },
        );
      },
      fireImmediately: true,
    );

    final currentUser = ref
        .read(authStateChangesProvider)
        .maybeWhen(data: (user) => user, orElse: () => null);
    if (currentUser != null) {
      await _syncService?.start(currentUser);
    }

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _syncService?.dispose();
    });

    return repository.getAll(userId: userId);
  }

  void _setupConnectivityMonitoring(InvoiceRepository repository) {
    final connectivityService = ref.read(connectivityServiceProvider);

    _connectivitySubscription = connectivityService.connectivityStream.listen(
      (results) async {
        final hasInternet = !results.contains(ConnectivityResult.none);

        if (!hasInternet) {
          _wasOffline = true;
          return;
        }

        // Si estaba offline y ahora hay conexión, validar invoices pendientes y sincronizar eliminaciones
        if (_wasOffline && hasInternet && !_isValidatingPending) {
          _wasOffline = false;
          await _validatePendingInvoices(repository);
          // Sincronizar eliminaciones pendientes cuando se detecta conexión
          await _syncService?.syncPendingDeletions();
        }
      },
    );
  }

  Future<void> _validatePendingInvoices(InvoiceRepository repository) async {
    if (_isValidatingPending) return;

    _isValidatingPending = true;

    try {
      if (kDebugMode) {
        debugPrint('[InvoiceController] Validando invoices pendientes...');
      }

      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        return;
      }

      final allInvoices = await repository.getAll(userId: userId);
      final dgiiService = ref.read(dgiiValidationServiceProvider);

      // Buscar invoices sin validación (sin validatedAt o sin validationStatus)
      final pendingInvoices = allInvoices.where((invoice) {
        return invoice.validatedAt == null &&
            invoice.rnc.isNotEmpty &&
            invoice.ecfNumber.isNotEmpty &&
            invoice.securityCode != null &&
            invoice.securityCode!.isNotEmpty;
      }).toList();

      if (pendingInvoices.isEmpty) {
        if (kDebugMode) {
          debugPrint(
              '[InvoiceController] No hay invoices pendientes de validación');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
            '[InvoiceController] Encontrados ${pendingInvoices.length} invoices pendientes de validación');
      }

      // Validar cada invoice pendiente
      for (final invoice in pendingInvoices) {
        try {
          final result = await dgiiService.validate(invoice);

          if (result.status == DgiiValidationStatus.missingData ||
              result.status == DgiiValidationStatus.error) {
            if (kDebugMode) {
              debugPrint(
                  '[InvoiceController] No se pudo validar invoice ${invoice.ecfNumber}: ${result.message}');
            }
            continue;
          }

          // Actualizar invoice con los resultados de la validación
          final updatedInvoice = invoice.copyWith(
            validationStatus: result.estado ?? result.message,
            validatedAt: DateTime.now(),
            status: result.estado ?? invoice.status,
            issuerName: (invoice.issuerName.isEmpty ||
                    invoice.issuerName == 'Proveedor desconocido')
                ? result.valueFor('Razón social emisor') ?? invoice.issuerName
                : invoice.issuerName,
            buyerName:
                result.valueFor('Razón social comprador') ?? invoice.buyerName,
            buyerRnc: result.valueFor('RNC Comprador') ?? invoice.buyerRnc,
            totalItbis: _parseDouble(result.valueFor('Total de ITBIS')) ??
                invoice.totalItbis,
            userId: userId, // Asegurar que tenga el userId
          );

          final saved = await repository.upsert(updatedInvoice);

          // Sincronizar con Firestore
          await _syncService?.pushLocalInvoice(saved);

          if (kDebugMode) {
            debugPrint(
                '[InvoiceController] Invoice ${invoice.ecfNumber} validado: ${result.estado ?? result.message}');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '[InvoiceController] Error al validar invoice ${invoice.ecfNumber}: $e');
          }
        }
      }

      // Refrescar la lista después de validar
      await refresh();

      if (kDebugMode) {
        debugPrint(
            '[InvoiceController] Validación de invoices pendientes completada');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[InvoiceController] Error al validar invoices pendientes: $e');
      }
    } finally {
      _isValidatingPending = false;
    }
  }

  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    final cleaned = normalized.contains(',')
        ? normalized.replaceAll('.', '').replaceAll(',', '.')
        : normalized;
    return double.tryParse(cleaned);
  }

  Future<void> refresh() async {
    final repository = await _ensureRepository();
    final userId = _currentUserId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.getAll(userId: userId));
  }

  Future<(Invoice, bool)> upsertInvoice(Invoice invoice) async {
    final repository = await _ensureRepository();
    final userId = _currentUserId;

    if (userId == null || userId.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    // Asegurar que el invoice tenga el userId del usuario actual
    final invoiceWithUserId = invoice.userId == null || invoice.userId!.isEmpty
        ? invoice.copyWith(userId: userId)
        : invoice;

    final existing =
        await repository.getByEcf(invoiceWithUserId.ecfNumber, userId: userId);
    final saved = await repository.upsert(invoiceWithUserId);
    await _syncService?.pushLocalInvoice(saved);
    await refresh();
    return (saved, existing == null);
  }

  Future<void> removeInvoice(int id) async {
    final repository = await _ensureRepository();

    Invoice? currentInvoice;
    if (state.hasValue) {
      for (final invoice in state.asData!.value) {
        if (invoice.id == id) {
          currentInvoice = invoice;
          break;
        }
      }
    }
    if (currentInvoice != null) {
      await _syncService?.deleteRemoteInvoice(currentInvoice);
    }

    final userId = _currentUserId;
    await repository.delete(id, userId: userId);
    await refresh();
  }

  Future<void> applyFilters({
    String? searchQuery,
    String? typeFilter,
    String? rncFilter,
    String? buyerRncFilter,
    bool includeBuyerRncIsNull = false,
    DateTime? issuedFrom,
    DateTime? issuedTo,
    SortOption sortOption = SortOption.createdAtDesc,
  }) async {
    final repository = await _ensureRepository();
    final userId = _currentUserId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.getAll(
          userId: userId,
          searchQuery: searchQuery,
          typeFilter: typeFilter,
          rncFilter: rncFilter,
          buyerRncFilter: buyerRncFilter,
          includeBuyerRncIsNull: includeBuyerRncIsNull,
          issuedFrom: issuedFrom,
          issuedTo: issuedTo,
          sortOption: sortOption,
        ));
  }
}
