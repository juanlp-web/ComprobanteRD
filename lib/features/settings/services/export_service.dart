import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../ads/interstitial_ad_manager.dart';
import '../../invoice/controllers/invoice_controller.dart';
import '../../invoice/domain/invoice.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref);
});

class ExportService {
  ExportService(this._ref) {
    _ensureAdPreloaded();
  }

  final Ref _ref;

  Future<void> _ensureAdPreloaded() async {
    try {
      await InterstitialAdManager.instance.preload();
    } catch (_) {
      // ignore preload errors
    }
  }

  Future<void> _showVideoAd() async {
    try {
      final shown = await InterstitialAdManager.instance.show();
      if (!shown) {
        await _ensureAdPreloaded();
      }
    } catch (_) {
      await _ensureAdPreloaded();
    }
  }

  Future<void> exportAsCsv(
    BuildContext context, {
    List<Invoice>? invoices,
  }) async {
    final data = _resolveInvoices(invoices);
    if (data.isEmpty) {
      _showEmptyMessage(context);
      return;
    }

    await _showVideoAd();

    final csvContent = _generateCsv(data);
    final file = await _writeStringFile(
      'comprobantes_${_timestamp()}.csv',
      csvContent,
    );
    await _presentExportOptions(context, file);
  }

  Future<void> exportAsPdf(
    BuildContext context, {
    List<Invoice>? invoices,
  }) async {
    final data = _resolveInvoices(invoices);
    if (data.isEmpty) {
      _showEmptyMessage(context);
      return;
    }

    await _showVideoAd();

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Comprobantes (${data.length})',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'RNC comprador',
              'Comprador',
              'RNC',
              'Proveedor',
              'e-CF',
              'Fecha',
              'AñoMes',
              'Código seguridad',
              'Estado',
              'Subtotal',
              'ITBIS',
              'Total',
            ],
            data: data.map((invoice) {
              final subtotal = invoice.amount - (invoice.totalItbis ?? 0);
              final anoMes = DateFormat('yyyyMM').format(invoice.issuedAt);
              return [
                invoice.buyerRnc ?? '',
                invoice.buyerName ?? '',
                invoice.rnc,
                invoice.issuerName,
                invoice.ecfNumber,
                DateFormat('dd-MM-yyyy').format(invoice.issuedAt),
                anoMes,
                invoice.securityCode ?? '',
                invoice.validationStatus ?? invoice.status ?? '',
                NumberFormat.currency(locale: 'en_US', symbol: 'RD\$')
                    .format(subtotal),
                NumberFormat.currency(locale: 'en_US', symbol: 'RD\$').format(
                  invoice.totalItbis ?? 0,
                ),
                NumberFormat.currency(locale: 'en_US', symbol: 'RD\$')
                    .format(invoice.amount),
              ];
            }).toList(),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: pw.BoxDecoration(
              color: pdf.PdfColors.grey300,
            ),
          ),
        ],
      ),
    );

    final bytes = await document.save();
    final file = await _writeBytesFile(
      'comprobantes_${_timestamp()}.pdf',
      bytes,
    );

    await _presentExportOptions(context, file);
  }

  Future<void> exportAsExcel(
    BuildContext context, {
    List<Invoice>? invoices,
  }) async {
    final data = _resolveInvoices(invoices);
    if (data.isEmpty) {
      _showEmptyMessage(context);
      return;
    }

    await _showVideoAd();

    final excel = Excel.createExcel();
    final sheet = excel['Comprobantes'];
    sheet.appendRow([
      TextCellValue('RNC comprador'),
      TextCellValue('Comprador'),
      TextCellValue('RNC'),
      TextCellValue('Proveedor'),
      TextCellValue('Número e-CF'),
      TextCellValue('Fecha emisión'),
      TextCellValue('AñoMes'),
      TextCellValue('Código seguridad'),
      TextCellValue('Estado'),
      TextCellValue('Subtotal'),
      TextCellValue('ITBIS'),
      TextCellValue('Monto'),
    ]);

    for (final invoice in data) {
      final subtotal = invoice.amount - (invoice.totalItbis ?? 0);
      final anoMes = DateFormat('yyyyMM').format(invoice.issuedAt);
      sheet.appendRow([
        TextCellValue(invoice.buyerRnc ?? ''),
        TextCellValue(invoice.buyerName ?? ''),
        TextCellValue(invoice.rnc),
        TextCellValue(invoice.issuerName),
        TextCellValue(invoice.ecfNumber),
        TextCellValue(DateFormat('dd-MM-yyyy').format(invoice.issuedAt)),
        TextCellValue(anoMes),
        TextCellValue(invoice.securityCode ?? ''),
        TextCellValue(invoice.validationStatus ?? invoice.status ?? ''),
        DoubleCellValue(subtotal),
        DoubleCellValue(invoice.totalItbis ?? 0),
        DoubleCellValue(invoice.amount),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al generar el Excel.'),
        ),
      );
      return;
    }

    final file = await _writeBytesFile(
      'comprobantes_${_timestamp()}.xlsx',
      bytes,
    );

    await _presentExportOptions(context, file);
  }

  List<Invoice> _resolveInvoices(List<Invoice>? invoices) {
    return invoices ?? _ref.read(invoiceControllerProvider).value ?? [];
  }

  void _showEmptyMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'No tienes comprobantes para exportar con los filtros actuales.'),
      ),
    );
  }

  String _generateCsv(List<Invoice> invoices) {
    final buffer = StringBuffer()
      ..writeln(
        [
          'RNC comprador',
          'Comprador',
          'RNC',
          'Proveedor',
          'Número e-CF',
          'Fecha emisión',
          'AñoMes',
          'Código seguridad',
          'Estado',
          'Subtotal',
          'ITBIS',
          'Monto',
          'Tipo',
          'Fecha registro',
        ].join(';'),
      );

    for (final invoice in invoices) {
      final subtotal = invoice.amount - (invoice.totalItbis ?? 0);
      final anoMes = DateFormat('yyyyMM').format(invoice.issuedAt);
      final fields = [
        invoice.buyerRnc ?? '',
        invoice.buyerName ?? '',
        invoice.rnc,
        invoice.issuerName,
        invoice.ecfNumber,
        DateFormat('dd-MM-yyyy').format(invoice.issuedAt),
        anoMes,
        invoice.securityCode ?? '',
        invoice.validationStatus ?? invoice.status ?? '',
        NumberFormat('###,##0.00', 'en_US').format(subtotal),
        NumberFormat('###,##0.00', 'en_US').format(invoice.totalItbis ?? 0),
        NumberFormat('###,##0.00', 'en_US').format(invoice.amount),
        invoice.type,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(invoice.createdAt),
      ].map(_escapeField).join(';');

      buffer.writeln(fields);
    }

    return buffer.toString();
  }

  String _escapeField(String field) {
    final needsQuotes = field.contains(';') || field.contains('\n');
    if (!needsQuotes) return field;
    return '"${field.replaceAll('"', '""')}"';
  }

  Future<File> _writeStringFile(String filename, String content) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    return file.writeAsString(content);
  }

  Future<File> _writeBytesFile(String filename, List<int> bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    return file.writeAsBytes(bytes, flush: true);
  }

  String _timestamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  Future<void> _presentExportOptions(BuildContext context, File file) async {
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Archivo generado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.open_in_new_outlined),
              title: const Text('Abrir'),
              onTap: () async {
                await OpenFilex.open(file.path);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Compartir'),
              onTap: () async {
                await Share.shareXFiles([XFile(file.path)]);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
