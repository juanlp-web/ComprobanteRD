import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/invoice.dart';
import 'invoice_repository.dart';

typedef InvoicesChangedCallback = Future<void> Function();

class InvoiceSyncService {
  InvoiceSyncService({
    required InvoiceRepository repository,
    required FirebaseFirestore firestore,
    this.onLocalChange,
  })  : _repository = repository,
        _firestore = firestore;

  final InvoiceRepository _repository;
  final FirebaseFirestore _firestore;
  final InvoicesChangedCallback? onLocalChange;
  final Connectivity _connectivity = Connectivity();

  CollectionReference<Map<String, dynamic>>? _remoteCollection;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _currentUserId;
  bool _isApplyingRemoteChange = false;

  Future<bool> _hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity().timeout(
          const Duration(seconds: 2),
          onTimeout: () => [ConnectivityResult.none]);
      return !results.contains(ConnectivityResult.none);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InvoiceSync] Error al verificar conectividad: $e');
      }
      return false;
    }
  }

  Future<void> start(User user) async {
    if (_currentUserId == user.uid) {
      return;
    }
    await stop();
    _currentUserId = user.uid;
    _remoteCollection =
        _firestore.collection('users').doc(user.uid).collection('invoices');

    // Verificar conectividad antes de iniciar el stream
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      if (kDebugMode) {
        debugPrint(
            '[InvoiceSync] Sin conexión, no se iniciará sincronización con Firestore');
      }
      return;
    }

    try {
      _subscription = _remoteCollection!
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen(
        _applyRemoteSnapshot,
        onError: (error) {
          // Manejar errores de red silenciosamente
          final errorString = error.toString().toLowerCase();
          if (errorString.contains('network') ||
              errorString.contains('connection') ||
              errorString.contains('hostname') ||
              errorString.contains('unavailable') ||
              errorString.contains('unable to resolve')) {
            if (kDebugMode) {
              debugPrint('[InvoiceSync] Error de red (ignorado): $error');
            }
            // Detener el stream si no hay conexión
            stop();
          } else {
            if (kDebugMode) {
              debugPrint('[InvoiceSync] Error en stream: $error');
            }
          }
        },
      );

      await _syncPendingLocalInvoices();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InvoiceSync] Error al iniciar sincronización: $e');
      }
      // Si falla, detener el servicio
      await stop();
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _remoteCollection = null;
    _currentUserId = null;
  }

  Future<Invoice> pushLocalInvoice(Invoice invoice) async {
    final collection = _remoteCollection;
    if (collection == null || invoice.id == null) {
      return invoice;
    }

    // Verificar conectividad antes de intentar subir
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      if (kDebugMode) {
        debugPrint(
            '[InvoiceSync] Sin conexión, no se subirá invoice a Firestore');
      }
      return invoice;
    }

    try {
      final data = _toRemoteMap(invoice);

      if (invoice.remoteId != null) {
        await collection
            .doc(invoice.remoteId)
            .set(data, SetOptions(merge: true));
        return invoice;
      }

      final docRef = collection.doc();
      await docRef.set(data);
      await _repository.attachRemoteId(
        invoice.id!,
        docRef.id,
        userId: invoice.userId ?? _currentUserId,
      );
      return invoice.copyWith(remoteId: docRef.id);
    } catch (e) {
      // Manejar errores de red silenciosamente
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('hostname') ||
          errorString.contains('unavailable') ||
          errorString.contains('unable to resolve')) {
        if (kDebugMode) {
          debugPrint(
              '[InvoiceSync] Error de red al subir invoice (ignorado): $e');
        }
      } else {
        if (kDebugMode) {
          debugPrint('[InvoiceSync] Error al subir invoice: $e');
        }
      }
      return invoice;
    }
  }

  Future<void> deleteRemoteInvoice(Invoice invoice) async {
    final collection = _remoteCollection;
    if (collection == null) {
      return;
    }
    final remoteId = invoice.remoteId;
    if (remoteId == null) {
      return;
    }

    // Verificar conectividad antes de intentar eliminar
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      // Guardar eliminación pendiente para sincronizar cuando haya conexión
      if (_currentUserId != null) {
        await _repository.addPendingDeletion(
          remoteId,
          userId: _currentUserId,
        );
        if (kDebugMode) {
          debugPrint(
              '[InvoiceSync] Sin conexión, eliminación guardada como pendiente: $remoteId');
        }
      }
      return;
    }

    try {
      await collection.doc(remoteId).delete();
      // Si se eliminó exitosamente, remover de pendientes si existe
      if (_currentUserId != null) {
        await _repository.removePendingDeletion(
          remoteId,
          userId: _currentUserId,
        );
      }
    } catch (e) {
      // Manejar errores de red silenciosamente
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('hostname') ||
          errorString.contains('unavailable') ||
          errorString.contains('unable to resolve')) {
        // Guardar eliminación pendiente si hay error de red
        if (_currentUserId != null) {
          await _repository.addPendingDeletion(
            remoteId,
            userId: _currentUserId,
          );
        }
        if (kDebugMode) {
          debugPrint(
              '[InvoiceSync] Error de red al eliminar invoice, guardado como pendiente: $e');
        }
      } else {
        if (kDebugMode) {
          debugPrint('[InvoiceSync] Error al eliminar invoice: $e');
        }
      }
    }
  }

  /// Sincroniza manualmente las eliminaciones pendientes
  Future<void> syncPendingDeletions() async {
    await _syncPendingLocalInvoices();
  }

  Future<void> _syncPendingLocalInvoices() async {
    final collection = _remoteCollection;
    if (collection == null || _currentUserId == null) {
      return;
    }

    // Verificar conectividad antes de sincronizar
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      if (kDebugMode) {
        debugPrint(
            '[InvoiceSync] Sin conexión, no se sincronizarán invoices pendientes');
      }
      return;
    }

    try {
      // Sincronizar invoices pendientes (sin remote_id)
      final invoices = await _repository.getAll(userId: _currentUserId);
      for (final invoice in invoices) {
        if (invoice.remoteId == null) {
          await pushLocalInvoice(invoice);
        }
      }

      // Sincronizar eliminaciones pendientes
      final pendingDeletions =
          await _repository.getPendingDeletions(userId: _currentUserId);
      for (final remoteId in pendingDeletions) {
        try {
          await collection.doc(remoteId).delete();
          // Remover de pendientes si se eliminó exitosamente
          await _repository.removePendingDeletion(
            remoteId,
            userId: _currentUserId,
          );
          if (kDebugMode) {
            debugPrint(
                '[InvoiceSync] Eliminación pendiente sincronizada: $remoteId');
          }
        } catch (e) {
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('network') ||
              errorString.contains('connection') ||
              errorString.contains('hostname') ||
              errorString.contains('unavailable') ||
              errorString.contains('unable to resolve')) {
            // Si es error de red, mantener como pendiente
            if (kDebugMode) {
              debugPrint(
                  '[InvoiceSync] Error de red al sincronizar eliminación pendiente (se mantendrá pendiente): $e');
            }
          } else if (errorString.contains('not-found') ||
              errorString.contains('not found')) {
            // Si el documento ya no existe, remover de pendientes
            await _repository.removePendingDeletion(
              remoteId,
              userId: _currentUserId,
            );
            if (kDebugMode) {
              debugPrint(
                  '[InvoiceSync] Documento ya no existe en Firestore, removido de pendientes: $remoteId');
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                  '[InvoiceSync] Error al sincronizar eliminación pendiente: $e');
            }
          }
        }
      }
    } catch (e) {
      // Manejar errores silenciosamente
      if (kDebugMode) {
        debugPrint(
            '[InvoiceSync] Error al sincronizar invoices pendientes: $e');
      }
    }
  }

  Future<void> dispose() async {
    await stop();
  }

  Future<void> _applyRemoteSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (_isApplyingRemoteChange) return;
    _isApplyingRemoteChange = true;
    try {
      for (final change in snapshot.docChanges) {
        final doc = change.doc;
        final remoteInvoice = _invoiceFromDoc(doc);
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            await _upsertRemote(remoteInvoice);
            break;
          case DocumentChangeType.removed:
            await _repository.deleteByRemoteId(
              doc.id,
              userId: _currentUserId,
            );
            break;
        }
      }
      await onLocalChange?.call();
    } catch (e) {
      // Manejar errores silenciosamente
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('hostname') ||
          errorString.contains('unavailable') ||
          errorString.contains('unable to resolve')) {
        if (kDebugMode) {
          debugPrint(
              '[InvoiceSync] Error de red al aplicar snapshot (ignorado): $e');
        }
      } else {
        if (kDebugMode) {
          debugPrint('[InvoiceSync] Error al aplicar snapshot: $e');
        }
      }
    } finally {
      _isApplyingRemoteChange = false;
    }
  }

  Future<void> _upsertRemote(Invoice remoteInvoice) async {
    if (_currentUserId == null) {
      return;
    }

    // Asegurar que el invoice tenga el userId del usuario actual
    final invoiceWithUserId =
        remoteInvoice.userId == null || remoteInvoice.userId!.isEmpty
            ? remoteInvoice.copyWith(userId: _currentUserId)
            : remoteInvoice;

    final existingByRemote = await _repository.getByRemoteId(
      invoiceWithUserId.remoteId!,
      userId: _currentUserId,
    );
    if (existingByRemote != null) {
      await _repository.upsert(
        invoiceWithUserId.copyWith(id: existingByRemote.id),
      );
      return;
    }

    final existingByEcf = await _repository.getByEcf(
      invoiceWithUserId.ecfNumber,
      userId: _currentUserId,
    );
    if (existingByEcf != null) {
      await _repository.upsert(
        invoiceWithUserId.copyWith(id: existingByEcf.id),
      );
      return;
    }

    await _repository.insert(invoiceWithUserId);
  }

  Invoice _invoiceFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? _parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Invoice(
      id: null,
      remoteId: doc.id,
      rnc: data['rnc'] as String? ?? '',
      issuerName: data['issuerName'] as String? ?? '',
      ecfNumber: data['ecfNumber'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      issuedAt: _parseTimestamp(data['issuedAt']) ?? DateTime.now(),
      type: data['type'] as String? ?? '',
      status: data['status'] as String?,
      buyerRnc: data['buyerRnc'] as String?,
      buyerName: data['buyerName'] as String?,
      totalItbis: (data['totalItbis'] as num?)?.toDouble(),
      signatureDate: _parseTimestamp(data['signatureDate']),
      securityCode: data['securityCode'] as String?,
      validationStatus: data['validationStatus'] as String?,
      validatedAt: _parseTimestamp(data['validatedAt']),
      rawData: data['rawData'] as String? ?? '',
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      userId: _currentUserId, // Asignar userId del usuario actual
    );
  }

  Map<String, dynamic> _toRemoteMap(Invoice invoice) {
    return {
      'rnc': invoice.rnc,
      'issuerName': invoice.issuerName,
      'ecfNumber': invoice.ecfNumber,
      'amount': invoice.amount,
      'issuedAt': Timestamp.fromDate(invoice.issuedAt),
      'type': invoice.type,
      'status': invoice.status,
      'buyerRnc': invoice.buyerRnc,
      'buyerName': invoice.buyerName,
      'totalItbis': invoice.totalItbis,
      'signatureDate': invoice.signatureDate != null
          ? Timestamp.fromDate(invoice.signatureDate!)
          : null,
      'securityCode': invoice.securityCode,
      'validationStatus': invoice.validationStatus,
      'validatedAt': invoice.validatedAt != null
          ? Timestamp.fromDate(invoice.validatedAt!)
          : null,
      'rawData': invoice.rawData,
      'createdAt': Timestamp.fromDate(invoice.createdAt),
    }..removeWhere((key, value) => value == null);
  }
}
