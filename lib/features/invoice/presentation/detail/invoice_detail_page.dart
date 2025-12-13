import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../dgii/dgii_validation_service.dart';
import 'package:mi_comprobante_rd/features/webviews/dgii_webview_page.dart';
import '../../controllers/invoice_controller.dart';
import '../../domain/invoice.dart';
import '../../../scanner/invoice_parser.dart';

class InvoiceDetailPage extends ConsumerStatefulWidget {
  const InvoiceDetailPage({required this.invoice, super.key});

  final Invoice invoice;

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  late Invoice _invoice;
  bool _isValidating = false;
  DgiiValidationResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signatureDateText = _signatureDateText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del comprobante'),
        actions: [
          IconButton(
            onPressed: () => _deleteInvoice(context),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar comprobante',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _invoice.issuerName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text(_invoice.type)),
                Text(
                  _invoice.formattedAmount,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isValidating ? null : _validateWithDgii,
                    icon: _isValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: Text(
                      _isValidating ? 'Validando...' : 'Validar con la DGII',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openDgiiWeb,
                  icon: const Icon(Icons.remove_red_eye_outlined),
                  label: const Text('Ver en DGII'),
                ),
              ],
            ),
            if (_invoice.validationStatus != null ||
                _invoice.validatedAt != null) ...[
              const SizedBox(height: 16),
              _ValidationBanner(invoice: _invoice),
            ],
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DataSection(
                      title: 'Información fiscal',
                      items: [
                        _DataItem('RNC emisor', _invoice.rnc),
                        _DataItem('Número e-CF', _invoice.ecfNumber),
                        _DataItem(
                          'Fecha de emisión',
                          InvoiceParser.extractRawValue(
                                _invoice.rawData,
                                const [
                                  'FechaEmision',
                                  'fechaemision',
                                  'fecha',
                                ],
                              ) ??
                              _invoice.formattedDate,
                        ),
                        if (_invoice.totalItbis != null)
                          _DataItem(
                            'ITBIS',
                            NumberFormat.currency(
                              locale: 'en_US',
                              symbol: 'RD\$',
                            ).format(_invoice.totalItbis),
                          ),
                        if (_invoice.status != null)
                          _DataItem('Estado (QR)', _invoice.status ?? ''),
                      ],
                    ),
                    if (_invoice.buyerName != null ||
                        _invoice.buyerRnc != null) ...[
                      const SizedBox(height: 24),
                      _DataSection(
                        title: 'Comprador',
                        items: [
                          if (_invoice.buyerName != null)
                            _DataItem('Razón social', _invoice.buyerName!),
                          if (_invoice.buyerRnc != null)
                            _DataItem('RNC comprador', _invoice.buyerRnc!),
                        ],
                      ),
                    ],
                    if (_invoice.validationStatus != null ||
                        _invoice.validatedAt != null ||
                        (_lastResult?.fields.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 24),
                      _DataSection(
                        title: 'Resultado DGII',
                        items: [
                          if (_invoice.validationStatus != null)
                            _DataItem(
                                'Estado DGII', _invoice.validationStatus!),
                          if (_invoice.validatedAt != null)
                            _DataItem(
                              'Validado el',
                              DateFormat.yMMMMd('es_DO')
                                  .add_Hms()
                                  .format(_invoice.validatedAt!),
                            ),
                          if (_lastResult != null &&
                              _lastResult!.fields.isNotEmpty)
                            ..._lastResult!.fields.entries.map(
                              (entry) => _DataItem(entry.key, entry.value),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    _DataSection(
                      title: 'Registro',
                      items: [
                        _DataItem(
                          'Fecha de registro',
                          MaterialLocalizations.of(context).formatFullDate(
                            _invoice.createdAt,
                          ),
                        ),
                        if (signatureDateText.isNotEmpty)
                          _DataItem('Fecha de firma', signatureDateText),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _DataSection(
                      title: 'Datos originales',
                      items: [
                        _DataItem('Cadena QR', _invoice.rawData),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _signatureDateText {
    final raw = InvoiceParser.extractRawValue(
      _invoice.rawData,
      const [
        'FechaFirma',
        'fechaFirma',
        'fechafirma',
        'fecha_firma',
        'DocumentSignatureDate',
      ],
    );

    final signatureDate = _invoice.signatureDate;
    if (signatureDate != null && signatureDate.year >= 2000) {
      return _invoice.formattedSignatureDate ?? '';
    }

    if (raw == null || raw.trim().isEmpty) return '';

    final reparsed = Invoice.parseSignatureDate(raw);
    if (reparsed != null && reparsed.year >= 2000) {
      return DateFormat.yMMMMd('es_DO').add_Hms().format(reparsed);
    }

    return raw;
  }

  Future<void> _validateWithDgii() async {
    setState(() {
      _isValidating = true;
    });
    try {
      final service = ref.read(dgiiValidationServiceProvider);
      final result = await service.validate(_invoice);
      if (!mounted) return;

      setState(() {
        _lastResult = result;
      });

      if (result.status == DgiiValidationStatus.missingData ||
          result.status == DgiiValidationStatus.error) {
        _showSnackBar(result.message);
        return;
      }

      if (result.status == DgiiValidationStatus.notFound) {
        if (!mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _ValidationResultSheet(result: result),
          ),
        );
        return;
      }

      final updatedInvoice = _invoice.copyWith(
        validationStatus: result.estado ?? result.message,
        validatedAt: DateTime.now(),
        status: result.estado ?? _invoice.status,
        buyerRnc: result.valueFor('RNC Comprador') ?? _invoice.buyerRnc,
        buyerName:
            result.valueFor('Razón social comprador') ?? _invoice.buyerName,
        totalItbis: _parseDouble(
              result.valueFor('Total de ITBIS'),
            ) ??
            _invoice.totalItbis,
      );

      await ref
          .read(invoiceControllerProvider.notifier)
          .upsertInvoice(updatedInvoice);

      if (!mounted) return;

      setState(() {
        _invoice = updatedInvoice;
      });

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _ValidationResultSheet(result: result),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('No fue posible validar este comprobante: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  void _openDgiiWeb() {
    final raw = _invoice.rawData.trim();
    Uri? uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible abrir el enlace original de la DGII desde este comprobante.',
          ),
        ),
      );
      return;
    }

    if (uri.query.isNotEmpty && uri.queryParameters.isEmpty) {
      final params = <String, String>{};
      for (final pair in uri.query.split('&')) {
        final separatorIndex = pair.indexOf('=');
        if (separatorIndex == -1) continue;
        final key = Uri.decodeQueryComponent(pair.substring(0, separatorIndex));
        final value =
            Uri.decodeQueryComponent(pair.substring(separatorIndex + 1));
        params[key] = value;
      }
      uri = uri.replace(queryParameters: params);
    } else if (uri.queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: uri.queryParameters);
    }

    if (!uri.hasScheme) {
      uri = uri.replace(scheme: 'https');
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DgiiWebViewPage(initialUri: uri!),
      ),
    );
  }

  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    final cleaned = normalized.contains(',')
        ? normalized.replaceAll('.', '').replaceAll(',', '.')
        : normalized;
    return double.tryParse(cleaned);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteInvoice(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comprobante'),
        content: const Text(
          '¿Seguro que deseas eliminar este comprobante? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(invoiceControllerProvider.notifier).removeInvoice(
            _invoice.id!,
          );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = invoice.validationStatus ?? 'Sin validar';
    final normalized = status.toLowerCase();
    final isAccepted =
        normalized.contains('acept') || normalized.contains('válid');
    final isRejected =
        normalized.contains('rechaz') || normalized.contains('anulad');

    final color = isAccepted
        ? theme.colorScheme.primaryContainer
        : isRejected
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerLow;

    final textColor = isAccepted
        ? theme.colorScheme.onPrimaryContainer
        : isRejected
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.onSurface;

    final subtitle = invoice.validatedAt != null
        ? 'Última validación: ${DateFormat.yMd('es_DO').add_Hms().format(invoice.validatedAt!)}'
        : 'Aún no se ha validado en línea';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}

class _ValidationResultSheet extends StatelessWidget {
  const _ValidationResultSheet({required this.result});

  final DgiiValidationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultado de la DGII',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.message),
                    const SizedBox(height: 16),
                    ...result.fields.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.key,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Text(entry.value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection({required this.title, required this.items});

  final String title;
  final List<_DataItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _DataRow(item: item),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.item});

  final _DataItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            item.label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(item.value),
        ),
      ],
    );
  }
}

class _DataItem {
  const _DataItem(this.label, this.value);

  final String label;
  final String value;
}
