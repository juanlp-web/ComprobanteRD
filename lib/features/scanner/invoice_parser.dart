import 'package:intl/intl.dart';

import '../invoice/domain/invoice.dart';

class InvoiceParser {
  static Invoice parse(String rawValue) {
    final data = _extractFields(rawValue);

    final rnc = _firstNonEmpty(
      data,
      const ['rnc', 'rncemisor', 'id', 'ced', 'cedula'],
    );
    final issuerName = _firstNonEmpty(
      data,
      const [
        'nombre',
        'razonsocial',
        'razonsocialemisor',
        'nombreemisor',
        'prov',
        'proveedor',
        'issuer',
      ],
      fallback: 'Proveedor desconocido',
    );
    final ecfNumber = _firstNonEmpty(
      data,
      const ['ecf', 'encf', 'ncf', 'numero', 'numfactura'],
    );
    final amountString = _firstNonEmpty(
      data,
      const ['monto', 'total', 'importe', 'amount', 'montototal'],
    );
    final issuedAtString = _firstNonEmpty(
      data,
      const ['fechaemision', 'fecha', 'fechafactura', 'issued', 'date'],
    );
    final type = _firstNonEmpty(
      data,
      const ['tipo', 'type', 'documento'],
      fallback: 'Sin clasificar',
    );
    final status = _firstNonEmpty(
      data,
      const ['estado', 'status', 'validacion'],
    );
    final buyerRnc = _firstNonEmpty(
      data,
      const ['rncreceptor', 'rnccomprador', 'comprador', 'rnccliente'],
    );
    final buyerName = _firstNonEmpty(
      data,
      const ['nombrecomprador', 'razonsocialcomprador', 'cliente', 'buyer'],
    );
    final itbisString = _firstNonEmpty(
      data,
      const ['itbis', 'impuesto', 'tax', 'totalitbis'],
    );
    final signatureDateString = _firstNonEmpty(
      data,
      const ['fechafirma', 'firmado', 'fechaautorizacion'],
    );
    final securityCode = _firstNonEmpty(
      data,
      const ['codigoseguridad', 'seguridad', 'codigo'],
    );

    if (rnc == null || ecfNumber == null || amountString == null) {
      throw const FormatException(
        'No se pudo interpretar el comprobante. Verifica el QR o intenta nuevamente.',
      );
    }

    final amount = _parseAmount(amountString);
    final issuedAt = _parseDate(issuedAtString) ?? DateTime.now();
    final signatureDate = _parseDate(signatureDateString);

    return Invoice(
      rnc: rnc,
      issuerName: issuerName ?? 'Proveedor desconocido',
      ecfNumber: ecfNumber,
      amount: amount,
      issuedAt: issuedAt,
      type: type ?? 'Sin clasificar',
      status: status,
      buyerRnc: buyerRnc,
      buyerName: buyerName,
      totalItbis: itbisString != null ? _parseAmount(itbisString) : null,
      signatureDate: signatureDate,
      securityCode: securityCode,
      rawData: rawValue,
      createdAt: DateTime.now(),
    );
  }

  static String? extractRawValue(String rawValue, List<String> keys) {
    final data = _extractFields(rawValue);
    final normalizedKeys = keys.map(_normalizeKey).toList();
    return _firstNonEmpty(data, normalizedKeys);
  }

  static Map<String, String> _extractFields(String raw) {
    final normalized = raw.trim();
    final fields = <String, String>{};

    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.hasQuery) {
      // Los queryParameters ya están decodificados automáticamente por Dart
      // Estos tienen prioridad porque están correctamente decodificados
      for (final entry in uri.queryParameters.entries) {
        final normalizedKey = _normalizeKey(entry.key);
        // Solo agregar si no existe, para no sobrescribir valores del URI
        if (!fields.containsKey(normalizedKey)) {
          fields[normalizedKey] = entry.value;
        }
      }

      if (uri.fragment.isNotEmpty) {
        final fragmentFields = _parseKeyValuePairs(uri.fragment);
        // Agregar campos del fragment solo si no existen ya
        for (final entry in fragmentFields.entries) {
          if (!fields.containsKey(entry.key)) {
            fields[entry.key] = entry.value;
          }
        }
      }
    }

    // Solo parsear el string raw si no se pudo parsear como URI o no tiene query
    // para evitar sobrescribir valores ya decodificados del URI
    if (uri == null || !uri.hasQuery || uri.queryParameters.isEmpty) {
      final rawFields = _parseKeyValuePairs(normalized);
      // Agregar campos del string raw solo si no existen ya
      for (final entry in rawFields.entries) {
        if (!fields.containsKey(entry.key)) {
          fields[entry.key] = entry.value;
        }
      }
    }

    return fields;
  }

  static Map<String, String> _parseKeyValuePairs(String text) {
    final pairs = <String, String>{};
    final separators = ['&', '|', ';', ','];

    for (final separator in separators) {
      if (text.contains(separator)) {
        final parts = text.split(separator);
        for (final part in parts) {
          final kv = part.split('=');
          if (kv.length == 2) {
            final key = _normalizeKey(kv[0]);
            // Decodificar el valor del URL encoding
            final value = Uri.decodeComponent(kv[1].trim());
            if (key.isNotEmpty && value.isNotEmpty) {
              pairs[key] = value;
            }
          }
        }
      }
    }

    return pairs;
  }

  static String _normalizeKey(String key) {
    return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String? _firstNonEmpty(
    Map<String, String> data,
    List<String> keys, {
    String? fallback,
  }) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key]!.isNotEmpty) {
        return data[key];
      }
    }
    return fallback;
  }

  static double _parseAmount(String raw) {
    // En el QR: coma (,) es separador de miles, punto (.) es separador decimal
    final normalized = raw.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    
    // Si contiene coma, asumir que es separador de miles y eliminarla
    // El punto ya es el separador decimal, no necesita cambio
    final cleaned = normalized.replaceAll(',', '');
    
    return double.tryParse(cleaned) ?? 0.0;
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final formats = [
      DateFormat('dd-MM-yyyy'),
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('dd/MM/yyyy HH:mm:ss'),
      DateFormat('dd-MM-yyyy HH:mm:ss'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('yyyyMMdd'),
      DateFormat('MM/dd/yyyy'),
    ];

    for (final format in formats) {
      try {
        return format.parse(raw);
      } catch (_) {
        continue;
      }
    }

    final timestamp = int.tryParse(raw);
    if (timestamp != null) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}
