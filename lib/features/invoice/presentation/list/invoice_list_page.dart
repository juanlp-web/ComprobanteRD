import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/intl.dart';

import '../../../scanner/invoice_parser.dart';
import '../../../ads/widgets/banner_ad_widget.dart';
import '../../controllers/invoice_controller.dart';
import '../../data/invoice_repository.dart';
import '../../domain/invoice.dart';
import 'package:mi_comprobante_rd/features/settings/services/export_service.dart';
import '../detail/invoice_detail_page.dart';

class InvoiceListPage extends ConsumerStatefulWidget {
  const InvoiceListPage({
    super.key,
    required this.onRequestScan,
  });

  final VoidCallback onRequestScan;

  @override
  ConsumerState<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends ConsumerState<InvoiceListPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  SortOption _sortOption = SortOption.createdAtDesc;
  DateTime? _issuedFrom;
  DateTime? _issuedTo;
  bool _isSearchExpanded = false;
  bool _currentMonth = true;
  bool _preferencesLoaded = false;
  bool _filtersApplied = false;
  bool _hasTriggeredInitialRefresh = false;
  static const _allBuyersKey = '__all__';
  static const _unknownBuyerKey = '__unknown__';
  String _selectedBuyerKey = _allBuyersKey;
  List<_BuyerGroup> _buyerGroupsCache = const [];
  static const String _currentMonthKey = 'current_month_filter';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadCurrentMonthPreference();
  }

  Future<void> _loadCurrentMonthPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getBool(_currentMonthKey);
      if (kDebugMode) {
        debugPrint(
          '[InvoiceListPage] Cargando preferencia: savedValue=$savedValue',
        );
      }
      if (savedValue != null) {
        if (mounted) {
          final now = DateTime.now();
          setState(() {
            _currentMonth = savedValue;
            if (_currentMonth) {
              _issuedFrom = DateTime(now.year, now.month, 1);
              _issuedTo = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
            } else {
              _issuedFrom = null;
              _issuedTo = null;
            }
            _preferencesLoaded = true;
            _filtersApplied = false;
          });
          if (kDebugMode) {
            debugPrint(
              '[InvoiceListPage] Preferencia cargada: currentMonth=$_currentMonth, '
              'issuedFrom=$_issuedFrom, issuedTo=$_issuedTo',
            );
          }
        }
      } else {
        // Si no hay valor guardado, usar el valor por defecto
        if (mounted) {
          final now = DateTime.now();
          setState(() {
            _currentMonth = true;
            _issuedFrom = DateTime(now.year, now.month, 1);
            _issuedTo = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
            _preferencesLoaded = true;
            _filtersApplied = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InvoiceListPage] Error al cargar preferencia: $e');
      }
      // Si hay error, usar valores por defecto
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _currentMonth = true;
          _issuedFrom = DateTime(now.year, now.month, 1);
          _issuedTo = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
          _preferencesLoaded = true;
          _filtersApplied = false;
        });
      }
    }
  }

  Future<void> _saveCurrentMonthPreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_currentMonthKey, value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al guardar preferencia de mes en curso: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _applyFilters();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
    if (_isSearchExpanded) {
      Future.microtask(() => _searchFocusNode.requestFocus());
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aplicar filtros cuando las preferencias se hayan cargado y aún no se hayan aplicado
    if (_preferencesLoaded && !_filtersApplied) {
      // Usar un pequeño delay para asegurar que el ref esté disponible
      Future.microtask(() async {
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            await _applyFilters();
            if (mounted) {
              setState(() {
                _filtersApplied = true;
                _preferencesLoaded = false;
              });
            }
          }
        }
      });
    }

    // Activar refresh automáticamente al entrar (después de aplicar filtros)
    if (!_hasTriggeredInitialRefresh && _filtersApplied) {
      Future.microtask(() async {
        if (mounted) {
          // Esperar un momento para que el widget esté completamente construido
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            await _refresh();
            if (mounted) {
              setState(() {
                _hasTriggeredInitialRefresh = true;
              });
            }
          }
        }
      });
    }

    final invoicesAsync = ref.watch(invoiceControllerProvider);
    final invoices = invoicesAsync.valueOrNull;
    final buyerGrouping = invoices != null ? _groupInvoices(invoices) : null;
    final filteredInvoices =
        buyerGrouping?.filteredInvoices ?? const <Invoice>[];
    final buyerGroups = buyerGrouping?.groups ?? const <_BuyerGroup>[];
    final availableBuyerGroups = buyerGroups.length > 1
        ? buyerGroups
        : (_buyerGroupsCache.isNotEmpty ? _buyerGroupsCache : buyerGroups);
    final showBuyerFolders = buyerGrouping?.showFolders ?? false;
    final showBuyerSelector =
        showBuyerFolders || availableBuyerGroups.length > 1;
    final selectedBuyerKey = buyerGrouping?.selectedKey ?? _allBuyersKey;
    final totalInvoiceCount = _buyerGroupsCache.isNotEmpty
        ? _buyerGroupsCache.fold<int>(
            0,
            (previousValue, element) => previousValue + element.count,
          )
        : invoices?.length ?? 0;
    final selectedGroup = selectedBuyerKey == _allBuyersKey
        ? _BuyerGroup(
            key: _allBuyersKey,
            displayName: 'Todos',
            count: totalInvoiceCount,
          )
        : availableBuyerGroups.firstWhereOrNull(
            (group) => group.key == selectedBuyerKey,
          );
    final selectedTitle = selectedGroup?.displayName ?? 'Todos';
    final selectedCount = selectedGroup?.count ?? filteredInvoices.length;
    final selectedSubtitle = selectedBuyerKey == _allBuyersKey
        ? '$totalInvoiceCount comprobantes'
        : '$selectedCount comprobantes'
            '${selectedGroup?.rnc != null ? ' · RNC ${selectedGroup!.rnc}' : ''}';
    final selectedIcon =
        selectedBuyerKey == _allBuyersKey ? Icons.folder_open : Icons.folder;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.start,
              children: [
                IconButton(
                  onPressed: _toggleSearch,
                  icon: Icon(
                    _isSearchExpanded ? Icons.close : Icons.search,
                  ),
                  tooltip: _isSearchExpanded ? 'Cerrar búsqueda' : 'Buscar',
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _currentMonth,
                      onChanged: (value) {
                        setState(() {
                          _currentMonth = value;
                          if (value) {
                            final now = DateTime.now();
                            _issuedFrom = DateTime(now.year, now.month, 1);
                            _issuedTo = DateTime(
                                now.year, now.month + 1, 0, 23, 59, 59, 999);
                          } else {
                            _issuedFrom = null;
                            _issuedTo = null;
                          }
                        });
                        _saveCurrentMonthPreference(value);
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Mes en curso',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
                _SortMenu(
                  selected: _sortOption,
                  onChanged: (option) {
                    setState(() => _sortOption = option);
                    _applyFilters();
                  },
                ),
                IconButton(
                  onPressed: _openFilterSheet,
                  icon: Icon(
                    Icons.filter_alt_outlined,
                    color: _hasAdvancedFilters
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: _hasAdvancedFilters ? 'Filtros activos' : 'Filtros',
                ),
                _ExportButton(invoicesAsync: invoicesAsync),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _isSearchExpanded
                  ? Padding(
                      key: const ValueKey('search_field'),
                      padding: const EdgeInsets.only(top: 12),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar por proveedor, RNC o número e-CF',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Limpiar búsqueda',
                                ),
                        ),
                        onChanged: (_) => _applyFilters(),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (showBuyerSelector) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Compradores',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openBuyerSelector(
                        availableBuyerGroups, totalInvoiceCount),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(selectedIcon, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  selectedSubtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.unfold_more),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _SummaryCard(invoices: filteredInvoices),
            const SizedBox(height: 12),
            Expanded(
              child: invoicesAsync.when(
                data: (invoices) {
                  final grouping = _groupInvoices(invoices);
                  final invoicesToShow = grouping.filteredInvoices;

                  if (invoicesToShow.isEmpty) {
                    return _EmptyState(onScanPressed: widget.onRequestScan);
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final invoice = invoicesToShow[index];
                        return _InvoiceListTile(invoice: invoice);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: invoicesToShow.length,
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_rounded, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No pudimos cargar tus comprobantes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Future<void> _applyFilters() async {
    String? buyerRncFilter;
    var includeBuyerRncIsNull = false;

    if (_selectedBuyerKey == _unknownBuyerKey) {
      includeBuyerRncIsNull = true;
    } else if (_selectedBuyerKey != _allBuyersKey) {
      buyerRncFilter = _selectedBuyerKey;
    }

    if (kDebugMode) {
      debugPrint(
        '[InvoiceListPage] Aplicando filtros: currentMonth=$_currentMonth, '
        'issuedFrom=$_issuedFrom, issuedTo=$_issuedTo',
      );
    }

    await ref.read(invoiceControllerProvider.notifier).applyFilters(
          searchQuery: _searchController.text,
          buyerRncFilter: buyerRncFilter,
          includeBuyerRncIsNull: includeBuyerRncIsNull,
          sortOption: _sortOption,
          issuedFrom: _issuedFrom,
          issuedTo: _issuedTo,
        );
  }

  bool get _hasAdvancedFilters => _issuedFrom != null || _issuedTo != null;

  String _buildFilterLabel() {
    final formatter = DateFormat('dd/MM/yyyy');
    if (_issuedFrom != null && _issuedTo != null) {
      final sameMonth = _issuedFrom!.year == _issuedTo!.year &&
          _issuedFrom!.month == _issuedTo!.month;
      if (sameMonth &&
          _issuedFrom!.day == 1 &&
          _issuedTo!.day ==
              DateTime(_issuedTo!.year, _issuedTo!.month + 1, 0).day) {
        final monthName = DateFormat.MMMM('es').format(_issuedFrom!);
        return 'Filtrado por mes: ${monthName.capitalize()} ${_issuedFrom!.year}';
      }
      return 'Filtrado del ${formatter.format(_issuedFrom!)} al ${formatter.format(_issuedTo!)}';
    }
    return 'Filtros personalizados activos';
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        initialFrom: _issuedFrom,
        initialTo: _issuedTo,
      ),
    );

    if (result == null) return;

    setState(() {
      _issuedFrom = result.from;
      _issuedTo = result.to;

      // Actualizar el toggle de "mes en curso" basado en las fechas seleccionadas
      if (result.from != null && result.to != null) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        _currentMonth = result.from!.year == monthStart.year &&
            result.from!.month == monthStart.month &&
            result.from!.day == monthStart.day &&
            result.to!.year == monthEnd.year &&
            result.to!.month == monthEnd.month &&
            result.to!.day == monthEnd.day &&
            result.to!.hour == monthEnd.hour &&
            result.to!.minute == monthEnd.minute;
      } else {
        _currentMonth = false;
      }
    });
    _saveCurrentMonthPreference(_currentMonth);
    _applyFilters();
  }

  Future<void> _openBuyerSelector(
    List<_BuyerGroup> buyerGroups,
    int totalInvoiceCount,
  ) async {
    final searchController = TextEditingController();
    String query = '';

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final options = [
                _BuyerGroup(
                  key: _allBuyersKey,
                  displayName: 'Todos',
                  count: totalInvoiceCount,
                ),
                ...buyerGroups,
              ];
              final lowerQuery = query.toLowerCase();
              final filtered = options.where((group) {
                if (lowerQuery.isEmpty) return true;
                final searchable =
                    '${group.displayName} ${group.rnc ?? ''}'.toLowerCase();
                return searchable.contains(lowerQuery);
              }).toList();

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar comprador o RNC',
                        ),
                        onChanged: (value) {
                          setModalState(() => query = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No se encontraron compradores',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final group = filtered[index];
                                  final isSelected =
                                      group.key == _selectedBuyerKey;
                                  final subtitle = group.key == _allBuyersKey
                                      ? '$totalInvoiceCount comprobantes'
                                      : '${group.count} comprobantes'
                                          '${group.rnc != null ? ' · RNC ${group.rnc}' : ''}';
                                  final icon = group.key == _allBuyersKey
                                      ? Icons.folder_open
                                      : Icons.folder;

                                  return ListTile(
                                    tileColor: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.08)
                                        : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    leading: Icon(icon),
                                    title: Text(
                                      group.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    subtitle: Text(subtitle),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          )
                                        : null,
                                    onTap: () =>
                                        Navigator.of(context).pop(group.key),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _selectedBuyerKey = result);
      await _applyFilters();
    }
  }

  _BuyerGroupingResult _groupInvoices(List<Invoice> invoices) {
    final groups = _buildBuyerGroups(invoices);
    final showFolders = groups.length > 1;

    _scheduleBuyerCacheUpdate(groups);

    var effectiveKey = _selectedBuyerKey;
    if (!showFolders) {
      if (_selectedBuyerKey != _allBuyersKey &&
          groups.any((group) => group.key == _selectedBuyerKey)) {
        effectiveKey = _selectedBuyerKey;
      } else {
        effectiveKey = _allBuyersKey;
        if (_selectedBuyerKey != _allBuyersKey) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedBuyerKey = _allBuyersKey);
          });
        }
      }
    } else if (effectiveKey != _allBuyersKey &&
        !groups.any((group) => group.key == effectiveKey)) {
      effectiveKey = _allBuyersKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedBuyerKey = _allBuyersKey);
      });
    }

    final filtered = showFolders && effectiveKey != _allBuyersKey
        ? invoices
            .where((invoice) => _buyerKeyFor(invoice) == effectiveKey)
            .toList()
        : invoices;

    return _BuyerGroupingResult(
      groups: groups,
      filteredInvoices: filtered,
      showFolders: showFolders,
      selectedKey: effectiveKey,
    );
  }

  void _scheduleBuyerCacheUpdate(List<_BuyerGroup> groups) {
    if (!mounted) return;
    final normalizedGroups = groups.toList(growable: false);
    if (normalizedGroups.isEmpty) {
      return;
    }
    List<_BuyerGroup> targetGroups;

    if (normalizedGroups.length > 1 ||
        _selectedBuyerKey == _allBuyersKey ||
        _buyerGroupsCache.isEmpty) {
      targetGroups = normalizedGroups;
    } else {
      final updated = _buyerGroupsCache
          .map(
            (group) => group.key == normalizedGroups.first.key
                ? normalizedGroups.first
                : group,
          )
          .toList();
      if (!updated.any((group) => group.key == normalizedGroups.first.key)) {
        updated.add(normalizedGroups.first);
      }
      targetGroups = updated;
    }

    if (listEquals(_buyerGroupsCache, targetGroups)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (listEquals(_buyerGroupsCache, targetGroups)) {
        return;
      }
      setState(() => _buyerGroupsCache = targetGroups);
    });
  }

  List<_BuyerGroup> _buildBuyerGroups(List<Invoice> invoices) {
    final grouped = invoices.groupListsBy(_buyerKeyFor);
    final groups = grouped.entries.map((entry) {
      final key = entry.key;
      final buyerInvoices = entry.value;
      final buyerName =
          buyerInvoices.map((invoice) => invoice.buyerName?.trim()).firstWhere(
                (name) => name != null && name.isNotEmpty,
                orElse: () => null,
              );
      final resolvedName =
          buyerName ?? (key == _unknownBuyerKey ? 'Sin RNC comprador' : key);
      final rnc = key == _unknownBuyerKey ? null : key;
      return _BuyerGroup(
        key: key,
        rnc: rnc,
        displayName: resolvedName,
        count: buyerInvoices.length,
      );
    }).toList();

    groups.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
    );

    return groups;
  }

  String _buyerKeyFor(Invoice invoice) {
    final rnc = invoice.buyerRnc?.trim();
    if (rnc == null || rnc.isEmpty) {
      return _unknownBuyerKey;
    }
    return rnc;
  }
}

class _InvoiceListTile extends StatelessWidget {
  const _InvoiceListTile({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final dateLabel = InvoiceParser.extractRawValue(
          invoice.rawData,
          const ['FechaEmision', 'fechaemision', 'fecha'],
        ) ??
        invoice.formattedDate;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InvoiceDetailPage(invoice: invoice),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.issuerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.confirmation_number_outlined,
                      label: invoice.ecfNumber,
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: dateLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    invoice.formattedAmount,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (invoice.totalItbis != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'ITBIS ${NumberFormat.currency(locale: 'en_US', symbol: 'RD\$').format(invoice.totalItbis)}',
                        style: textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _Tag(
                        label: invoice.type,
                        background: theme.colorScheme.primary.withOpacity(0.08),
                        color: theme.colorScheme.primary,
                      ),
                      if (invoice.validationStatus != null)
                        _Tag.validation(label: invoice.validationStatus!),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onScanPressed});

  final VoidCallback onScanPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay comprobantes en este período',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Escanea un e-CF o cambia el filtro de fecha para ver comprobantes de otros meses.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onScanPressed,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Escanear ahora'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.invoices});

  final List<Invoice> invoices;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const SizedBox.shrink();
    }
    final count = invoices.length;
    final totalAmount = invoices.fold<double>(
      0,
      (previousValue, element) => previousValue + element.amount,
    );
    final totalItbis = invoices.fold<double>(
      0,
      (previousValue, element) => previousValue + (element.totalItbis ?? 0),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryColumn(
            label: 'Cantidad',
            value: count.toString(),
          ),
          _SummaryColumn(
            label: 'Total facturas',
            value: NumberFormat.currency(
              locale: 'en_US',
              symbol: 'RD\$',
            ).format(totalAmount),
          ),
          _SummaryColumn(
            label: 'Total ITBIS',
            value: NumberFormat.currency(
              locale: 'en_US',
              symbol: 'RD\$',
            ).format(totalItbis),
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BuyerGroup {
  const _BuyerGroup({
    required this.key,
    required this.displayName,
    required this.count,
    this.rnc,
  });

  final String key;
  final String? rnc;
  final String displayName;
  final int count;

  bool get isUnknown => key == _InvoiceListPageState._unknownBuyerKey;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is _BuyerGroup &&
        other.key == key &&
        other.rnc == rnc &&
        other.displayName == displayName &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hash(key, rnc, displayName, count);
}

class _BuyerGroupingResult {
  const _BuyerGroupingResult({
    required this.groups,
    required this.filteredInvoices,
    required this.showFolders,
    required this.selectedKey,
  });

  final List<_BuyerGroup> groups;
  final List<Invoice> filteredInvoices;
  final bool showFolders;
  final String selectedKey;
}

enum _ExportOption { pdf, excel, csv }

class _ExportButton extends ConsumerWidget {
  const _ExportButton({required this.invoicesAsync});

  final AsyncValue<List<Invoice>> invoicesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = invoicesAsync.value ?? const <Invoice>[];
    final isBusy = invoicesAsync.isLoading;
    final isDisabled = isBusy || invoices.isEmpty;
    final iconColor = isDisabled
        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.38)
        : Theme.of(context).colorScheme.primary;

    return PopupMenuButton<_ExportOption>(
      enabled: !isDisabled,
      tooltip: 'Exportar comprobantes',
      icon: Icon(Icons.download_outlined, color: iconColor),
      onSelected: (option) async {
        final messenger = ScaffoldMessenger.of(context);
        final exportService = ref.read(exportServiceProvider);
        try {
          switch (option) {
            case _ExportOption.pdf:
              await exportService.exportAsPdf(
                context,
                invoices: invoices,
              );
              break;
            case _ExportOption.excel:
              await exportService.exportAsExcel(
                context,
                invoices: invoices,
              );
              break;
            case _ExportOption.csv:
              await exportService.exportAsCsv(
                context,
                invoices: invoices,
              );
              break;
          }
        } catch (error) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error al exportar: $error'),
            ),
          );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _ExportOption.pdf,
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text('Exportar a PDF'),
          ),
        ),
        PopupMenuItem(
          value: _ExportOption.excel,
          child: ListTile(
            leading: Icon(Icons.grid_on_outlined),
            title: Text('Exportar a Excel'),
          ),
        ),
        PopupMenuItem(
          value: _ExportOption.csv,
          child: ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Exportar a CSV'),
          ),
        ),
      ],
    );
  }
}

class _FilterResult {
  const _FilterResult({this.from, this.to});

  final DateTime? from;
  final DateTime? to;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialFrom,
    required this.initialTo,
  });

  final DateTime? initialFrom;
  final DateTime? initialTo;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _currentMonth;
  int? _selectedYear;
  int? _selectedMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  void _initialise() {
    _rangeStart = widget.initialFrom;
    _rangeEnd = widget.initialTo;

    if (_isCurrentMonth(_rangeStart, _rangeEnd)) {
      _currentMonth = true;
      _selectedYear = null;
      _selectedMonth = null;
      return;
    }

    _currentMonth = false;

    if (_isFullMonth(_rangeStart, _rangeEnd)) {
      _selectedYear = _rangeStart?.year;
      _selectedMonth = _rangeStart?.month;
      _rangeStart = null;
      _rangeEnd = null;
      return;
    }

    if (_isFullYear(_rangeStart, _rangeEnd)) {
      _selectedYear = _rangeStart?.year;
      _selectedMonth = null;
      _rangeStart = null;
      _rangeEnd = null;
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List<int>.generate(7, (index) => now.year - index);
    final monthItems = List<DropdownMenuItem<int?>>.generate(
      12,
      (index) => DropdownMenuItem<int?>(
        value: index + 1,
        child: Text(
          DateFormat.MMMM('es')
              .format(DateTime(now.year, index + 1))
              .capitalize(),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Filtros avanzados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(const _FilterResult());
                    },
                    child: const Text('Limpiar filtros'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                title: const Text('Mes en curso'),
                value: _currentMonth,
                onChanged: (value) {
                  setState(() {
                    _currentMonth = value;
                    if (value) {
                      _selectedYear = null;
                      _selectedMonth = null;
                      _rangeStart = null;
                      _rangeEnd = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedYear,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todos los años'),
                        ),
                        ...years.map(
                          (year) => DropdownMenuItem<int?>(
                            value: year,
                            child: Text(year.toString()),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _currentMonth = false;
                          _selectedYear = value;
                          if (value == null) {
                            _selectedMonth = null;
                          }
                          _rangeStart = null;
                          _rangeEnd = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedMonth,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todos los meses'),
                        ),
                        ...monthItems,
                      ],
                      onChanged: _selectedYear == null
                          ? null
                          : (value) {
                              setState(() {
                                _currentMonth = false;
                                _selectedMonth = value;
                                _rangeStart = null;
                                _rangeEnd = null;
                              });
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  _rangeStart != null && _rangeEnd != null
                      ? 'Rango: ${DateFormat('dd/MM/yyyy').format(_rangeStart!)} - ${DateFormat('dd/MM/yyyy').format(_rangeEnd!)}'
                      : 'Seleccionar rango personalizado',
                ),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    initialDateRange: _rangeStart != null && _rangeEnd != null
                        ? DateTimeRange(start: _rangeStart!, end: _rangeEnd!)
                        : null,
                    firstDate: DateTime(now.year - 10),
                    lastDate: DateTime(now.year + 1, 12, 31),
                    helpText: 'Selecciona el rango de fechas',
                  );
                  if (range != null) {
                    setState(() {
                      _currentMonth = false;
                      _selectedYear = null;
                      _selectedMonth = null;
                      _rangeStart = range.start;
                      _rangeEnd = range.end;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final result = _buildResult();
                        Navigator.of(context).pop(result);
                      },
                      child: const Text('Aplicar filtros'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _FilterResult _buildResult() {
    final now = DateTime.now();

    if (_currentMonth) {
      final from = _startOfMonth(now);
      final to = _endOfMonth(now);
      return _FilterResult(from: from, to: to);
    }

    if (_selectedYear != null) {
      if (_selectedMonth != null) {
        final from = DateTime(_selectedYear!, _selectedMonth!, 1);
        final to = _endOfMonth(from);
        return _FilterResult(
          from: _startOfDay(from),
          to: _endOfDay(to),
        );
      }
      final from = DateTime(_selectedYear!, 1, 1);
      final to = DateTime(_selectedYear!, 12, 31);
      return _FilterResult(
        from: _startOfDay(from),
        to: _endOfDay(to),
      );
    }

    if (_rangeStart != null && _rangeEnd != null) {
      return _FilterResult(
        from: _startOfDay(_rangeStart!),
        to: _endOfDay(_rangeEnd!),
      );
    }

    return const _FilterResult();
  }

  bool _isCurrentMonth(DateTime? from, DateTime? to) {
    if (from == null || to == null) return false;
    final now = DateTime.now();
    final start = _startOfMonth(now);
    final end = _endOfMonth(now);
    return from == _startOfDay(start) && to == _endOfDay(end);
  }

  bool _isFullYear(DateTime? from, DateTime? to) {
    if (from == null || to == null) return false;
    return from.month == 1 &&
        from.day == 1 &&
        to.month == 12 &&
        to.day == 31 &&
        from.year == to.year;
  }

  bool _isFullMonth(DateTime? from, DateTime? to) {
    if (from == null || to == null) return false;
    final endOfMonth = DateTime(from.year, from.month + 1, 0);
    return from.day == 1 &&
        to.day == endOfMonth.day &&
        from.month == to.month &&
        from.year == to.year;
  }

  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    required this.color,
  });

  final String label;
  final Color background;
  final Color color;

  factory _Tag.validation({required String label}) {
    final normalized = label.toLowerCase();
    if (normalized.contains('acept')) {
      return _Tag(
        label: label,
        background: Colors.green.withOpacity(0.12),
        color: Colors.green.shade700,
      );
    }
    if (normalized.contains('rechaz')) {
      return _Tag(
        label: label,
        background: Colors.red.withOpacity(0.12),
        color: Colors.red.shade700,
      );
    }
    return _Tag(
      label: label,
      background: Colors.blueGrey.withOpacity(0.12),
      color: Colors.blueGrey.shade700,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

extension _StringCasing on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({
    required this.selected,
    required this.onChanged,
  });

  final SortOption selected;
  final ValueChanged<SortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort),
      initialValue: selected,
      onSelected: onChanged,
      itemBuilder: (context) => [
        _buildItem(context, SortOption.createdAtDesc, 'Recientes'),
        _buildItem(context, SortOption.createdAtAsc, 'Más antiguos'),
        _buildItem(context, SortOption.issueDateDesc, 'Fecha de emisión (↓)'),
        _buildItem(context, SortOption.issueDateAsc, 'Fecha de emisión (↑)'),
        _buildItem(context, SortOption.amountDesc, 'Monto (↓)'),
        _buildItem(context, SortOption.amountAsc, 'Monto (↑)'),
      ],
    );
  }

  PopupMenuEntry<SortOption> _buildItem(
    BuildContext context,
    SortOption value,
    String label,
  ) {
    final theme = Theme.of(context);
    final isSelected = value == selected;
    return CheckedPopupMenuItem<SortOption>(
      value: value,
      checked: isSelected,
      child: Text(
        label,
        style: isSelected
            ? theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )
            : theme.textTheme.bodyMedium,
      ),
    );
  }
}
