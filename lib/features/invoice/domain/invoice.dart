import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

class Invoice {
  const Invoice({
    this.id,
    required this.rnc,
    required this.issuerName,
    required this.ecfNumber,
    required this.amount,
    required this.issuedAt,
    required this.type,
    this.status,
    this.buyerRnc,
    this.buyerName,
    this.totalItbis,
    this.signatureDate,
    this.securityCode,
    this.validationStatus,
    this.validatedAt,
    required this.rawData,
    required this.createdAt,
    this.remoteId,
    this.userId,
  });

  final int? id;
  final String rnc;
  final String issuerName;
  final String ecfNumber;
  final double amount;
  final DateTime issuedAt;
  final String type;
  final String? status;
  final String? buyerRnc;
  final String? buyerName;
  final double? totalItbis;
  final DateTime? signatureDate;
  final String? securityCode;
  final String? validationStatus;
  final DateTime? validatedAt;
  final String rawData;
  final DateTime createdAt;
  final String? remoteId;
  final String? userId;

  static const tableName = 'invoices';

  static const columns = [
    'id',
    'rnc',
    'issuer_name',
    'ecf_number',
    'amount',
    'issued_at',
    'type',
    'status',
    'buyer_rnc',
    'buyer_name',
    'total_itbis',
    'signature_date',
    'security_code',
    'validation_status',
    'validated_at',
    'raw_data',
    'created_at',
    'remote_id',
    'user_id',
  ];

  factory Invoice.fromMap(Map<String, Object?> map) {
    return Invoice(
      id: map['id'] as int?,
      rnc: map['rnc'] as String? ?? '',
      issuerName: map['issuer_name'] as String? ?? '',
      ecfNumber: map['ecf_number'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      issuedAt: DateTime.parse(map['issued_at'] as String),
      type: map['type'] as String? ?? '',
      status: map['status'] as String?,
      buyerRnc: map['buyer_rnc'] as String?,
      buyerName: map['buyer_name'] as String?,
      totalItbis: (map['total_itbis'] as num?)?.toDouble(),
      signatureDate: parseSignatureDate(map['signature_date']),
      securityCode: map['security_code'] as String?,
      validationStatus: map['validation_status'] as String?,
      validatedAt: map['validated_at'] != null
          ? DateTime.tryParse(map['validated_at'] as String)
          : null,
      rawData: map['raw_data'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      remoteId: map['remote_id'] as String?,
      userId: map['user_id'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'rnc': rnc,
      'issuer_name': issuerName,
      'ecf_number': ecfNumber,
      'amount': amount,
      'issued_at': issuedAt.toIso8601String(),
      'type': type,
      'status': status,
      'buyer_rnc': buyerRnc,
      'buyer_name': buyerName,
      'total_itbis': totalItbis,
      'signature_date': signatureDate?.toIso8601String(),
      'security_code': securityCode,
      'validation_status': validationStatus,
      'validated_at': validatedAt?.toIso8601String(),
      'raw_data': rawData,
      'created_at': createdAt.toIso8601String(),
      'remote_id': remoteId,
      'user_id': userId,
    }..removeWhere((_, value) => value == null);
  }

  static DateTime? parseSignatureDate(Object? value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      final date = value.trim();
      if (date.isEmpty) return null;

      final decoded = Uri.decodeComponent(date);

      for (final pattern in _signatureDatePatterns) {
        try {
          return DateFormat(pattern).parseStrict(decoded);
        } catch (_) {
          // Keep trying with the remaining patterns.
        }
      }

      // Fall back to ISO-8601 and other formats that DateTime.tryParse supports.
      final parsed = DateTime.tryParse(decoded);

      if (parsed == null) {
        developer.log(
          'Unable to parse signature date',
          name: 'Invoice',
          error: date,
        );
      }

      return parsed;
    }

    return null;
  }

  static const _signatureDatePatterns = [
    'dd-MM-yyyy HH:mm:ss',
    'dd-MM-yyyy H:mm:ss',
    'dd-MM-yyyy HH:mm',
    'dd-MM-yyyy H:mm',
    'dd-MM-yyyy',
  ];

  Invoice copyWith({
    int? id,
    String? rnc,
    String? issuerName,
    String? ecfNumber,
    double? amount,
    DateTime? issuedAt,
    String? type,
    String? status,
    String? buyerRnc,
    String? buyerName,
    double? totalItbis,
    DateTime? signatureDate,
    String? securityCode,
    String? validationStatus,
    DateTime? validatedAt,
    String? rawData,
    DateTime? createdAt,
    String? remoteId,
    String? userId,
  }) {
    return Invoice(
      id: id ?? this.id,
      rnc: rnc ?? this.rnc,
      issuerName: issuerName ?? this.issuerName,
      ecfNumber: ecfNumber ?? this.ecfNumber,
      amount: amount ?? this.amount,
      issuedAt: issuedAt ?? this.issuedAt,
      type: type ?? this.type,
      status: status ?? this.status,
      buyerRnc: buyerRnc ?? this.buyerRnc,
      buyerName: buyerName ?? this.buyerName,
      totalItbis: totalItbis ?? this.totalItbis,
      signatureDate: signatureDate ?? this.signatureDate,
      securityCode: securityCode ?? this.securityCode,
      validationStatus: validationStatus ?? this.validationStatus,
      validatedAt: validatedAt ?? this.validatedAt,
      rawData: rawData ?? this.rawData,
      createdAt: createdAt ?? this.createdAt,
      remoteId: remoteId ?? this.remoteId,
      userId: userId ?? this.userId,
    );
  }

  String get formattedAmount {
    final numberFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'RD\$',
    );
    return numberFormat.format(amount);
  }

  String get formattedDate {
    final dateFormat = DateFormat.yMMMMd('es_DO');
    return dateFormat.format(issuedAt);
  }

  String? get formattedSignatureDate {
    if (signatureDate == null) return null;
    return DateFormat.yMMMMd('es_DO').add_Hms().format(signatureDate!);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Invoice &&
            const ListEquality().equals(
              [
                id,
                rnc,
                issuerName,
                ecfNumber,
                amount,
                issuedAt,
                type,
                status,
                buyerRnc,
                buyerName,
                totalItbis,
                signatureDate,
                securityCode,
                validationStatus,
                validatedAt,
                rawData,
                createdAt,
              ],
              [
                other.id,
                other.rnc,
                other.issuerName,
                other.ecfNumber,
                other.amount,
                other.issuedAt,
                other.type,
                other.status,
                other.buyerRnc,
                other.buyerName,
                other.totalItbis,
                other.signatureDate,
                other.securityCode,
                other.validationStatus,
                other.validatedAt,
                other.rawData,
                other.createdAt,
              ],
            );
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        rnc,
        issuerName,
        ecfNumber,
        amount,
        issuedAt,
        type,
        status,
        buyerRnc,
        buyerName,
        totalItbis,
        signatureDate,
        securityCode,
        validationStatus,
        validatedAt,
        rawData,
        createdAt,
      ]);
}
