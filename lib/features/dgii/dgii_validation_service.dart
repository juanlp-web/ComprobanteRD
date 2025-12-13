import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../invoice/domain/invoice.dart';

final dgiiValidationServiceProvider = Provider<DgiiValidationService>((ref) {
  return DgiiValidationService();
});

class DgiiValidationService {
  static const _host = 'ecf.dgii.gov.do';
  static const _path = '/ecf/ConsultaTimbre';

  Future<DgiiValidationResult> validate(Invoice invoice) async {
    final requiredFieldsMissing = <String>[];

    if (invoice.rnc.isEmpty) requiredFieldsMissing.add('RNC del emisor');
    if (invoice.ecfNumber.isEmpty) requiredFieldsMissing.add('Número e-CF');
    if (invoice.securityCode == null || invoice.securityCode!.isEmpty) {
      requiredFieldsMissing.add('Código de seguridad');
    }

    if (requiredFieldsMissing.isNotEmpty) {
      return DgiiValidationResult(
        status: DgiiValidationStatus.missingData,
        message:
            'Faltan datos necesarios para consultar en la DGII: ${requiredFieldsMissing.join(', ')}.',
        fields: const {},
      );
    }

    final rawFechaEmision = _extractFromRaw(invoice.rawData, 'FechaEmision') ??
        _extractFromRaw(invoice.rawData, 'fechaemision');
    final rawFechaFirma = _extractFromRaw(invoice.rawData, 'FechaFirma') ??
        _extractFromRaw(invoice.rawData, 'fechafirma');
    final rawMontoTotal = _extractFromRaw(invoice.rawData, 'MontoTotal') ??
        _extractFromRaw(invoice.rawData, 'montototal');
    final rawCodigoSeguridad =
        _extractFromRaw(invoice.rawData, 'CodigoSeguridad') ??
            _extractFromRaw(invoice.rawData, 'codigoseguridad');
    final rawRncComprador = _extractFromRaw(invoice.rawData, 'RncComprador') ??
        _extractFromRaw(invoice.rawData, 'rnccomprador');

    final dateFormat = DateFormat('dd-MM-yyyy');
    final params = <String, String>{
      'RncEmisor': invoice.rnc,
      if ((invoice.buyerRnc != null && invoice.buyerRnc!.isNotEmpty) ||
          (rawRncComprador != null && rawRncComprador.isNotEmpty))
        'RncComprador': rawRncComprador ?? invoice.buyerRnc!,
      'eNCF': invoice.ecfNumber,
      'FechaEmision': rawFechaEmision?.isNotEmpty == true
          ? rawFechaEmision!
          : dateFormat.format(invoice.issuedAt),
      'MontoTotal': rawMontoTotal?.isNotEmpty == true
          ? rawMontoTotal!
          : invoice.amount.toStringAsFixed(2),
      if (rawFechaFirma?.isNotEmpty == true)
        'FechaFirma': rawFechaFirma!
      else if (invoice.signatureDate != null)
        'FechaFirma': DateFormat('dd-MM-yyyy HH:mm:ss').format(
          invoice.signatureDate!,
        ),
      'CodigoSeguridad': rawCodigoSeguridad?.isNotEmpty == true
          ? rawCodigoSeguridad!
          : invoice.securityCode!,
    }..removeWhere((_, value) => value.isEmpty);

    final uri = Uri.https(_host, _path, params);
    final response = await http.get(
      uri,
      headers: {
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.9',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    );

    if (kDebugMode) {
      debugPrint('[DGII] GET $uri -> ${response.statusCode}');
      debugPrint('[DGII] Params: $params');
      debugPrint('[DGII] Body preview: ${_previewBody(response.body)}');
    }

    if (response.statusCode != 200) {
      return DgiiValidationResult(
        status: DgiiValidationStatus.error,
        message:
            'La DGII respondió con un estado inesperado (${response.statusCode}). Intenta nuevamente más tarde.',
        fields: const {},
      );
    }

    final result = _parseHtml(response.body);
    if (result == null) {
      return const DgiiValidationResult(
        status: DgiiValidationStatus.notFound,
        message:
            'No se encontraron datos para este comprobante en la consulta de la DGII.',
        fields: {},
      );
    }

    return result;
  }

  String _previewBody(String body) {
    if (body.isEmpty) return '<empty>';
    const maxLength = 500;
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength)}...';
  }

  String? _extractFromRaw(String raw, String key) {
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri != null) {
      final value = uri.queryParameters[key];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    final regex = RegExp('$key=([^&]+)', caseSensitive: false);
    final match = regex.firstMatch(raw);
    if (match != null && match.groupCount >= 1) {
      return Uri.decodeComponent(match.group(1)!);
    }
    return null;
  }

  DgiiValidationResult? _parseHtml(String html) {
    final document = html_parser.parse(html);
    final table = document.querySelector('table');
    if (table == null) {
      return null;
    }

    final rows = table.querySelectorAll('tr');
    final fields = <String, String>{};

    for (final row in rows) {
      final cells = row.querySelectorAll('td,th');
      if (cells.length < 2) continue;
      final key = cells.first.text.trim();
      final value = cells.sublist(1).map((cell) => cell.text.trim()).join(' ');
      if (key.isEmpty) continue;
      fields[key] = value;
    }

    if (fields.isEmpty) return null;

    final estado = fields.entries
        .firstWhere(
          (entry) => entry.key.toLowerCase().contains('estado'),
          orElse: () => const MapEntry('', ''),
        )
        .value;

    final status = _mapEstadoToStatus(estado);
    final message = estado.isEmpty
        ? 'Consulta realizada. Revisa los detalles obtenidos.'
        : 'Estado DGII: $estado';

    return DgiiValidationResult(
      status: status,
      message: message,
      fields: fields,
    );
  }

  DgiiValidationStatus _mapEstadoToStatus(String estado) {
    final normalized = estado.toLowerCase();
    if (normalized.contains('acept')) {
      return DgiiValidationStatus.accepted;
    }
    if (normalized.contains('rechaz') ||
        normalized.contains('anulad') ||
        normalized.contains('inválido')) {
      return DgiiValidationStatus.rejected;
    }
    if (normalized.isEmpty) {
      return DgiiValidationStatus.unknown;
    }
    return DgiiValidationStatus.unknown;
  }
}

class DgiiValidationResult {
  const DgiiValidationResult({
    required this.status,
    required this.message,
    required this.fields,
  });

  final DgiiValidationStatus status;
  final String message;
  final Map<String, String> fields;

  String? valueFor(String keyName) {
    return fields.entries
        .firstWhere(
          (entry) => entry.key.toLowerCase().contains(keyName.toLowerCase()),
          orElse: () => const MapEntry('', ''),
        )
        .value;
  }

  String? get estado =>
      valueFor('estado')?.isEmpty ?? true ? null : valueFor('estado');
}

enum DgiiValidationStatus {
  accepted,
  rejected,
  notFound,
  missingData,
  error,
  unknown,
}
