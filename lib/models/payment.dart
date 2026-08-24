import 'package:flutter/foundation.dart';
import '../utils/date_time_util.dart';

enum PaymentMethod {
  bankTransfer,
  instaPay,
  card,
  cash,
  cheque,
  other,
  creditCard,
  bankWire,
  applePay,
  stcPay,
}

extension PaymentMethodX on PaymentMethod {
  String get displayNameEn {
    switch (this) {
      case PaymentMethod.bankTransfer:
      case PaymentMethod.bankWire:
        return 'Bank Transfer';
      case PaymentMethod.instaPay:
        return 'InstaPay';
      case PaymentMethod.card:
      case PaymentMethod.creditCard:
        return 'Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.stcPay:
        return 'STC Pay';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String get displayNameAr {
    switch (this) {
      case PaymentMethod.bankTransfer:
      case PaymentMethod.bankWire:
        return 'تحويل بنكي';
      case PaymentMethod.instaPay:
        return 'انستا باي';
      case PaymentMethod.card:
      case PaymentMethod.creditCard:
        return 'بطاقة ائتمان';
      case PaymentMethod.cash:
        return 'نقداً';
      case PaymentMethod.cheque:
        return 'شيك';
      case PaymentMethod.applePay:
        return 'أبل باي';
      case PaymentMethod.stcPay:
        return 'اس تي سي باي';
      case PaymentMethod.other:
        return 'أخرى';
    }
  }
}

enum PaymentStatus {
  pending,
  success,
  failed,
  refunded,
}

@immutable
class Payment {
  final String id;
  final String transactionReference;
  final String contractId;
  final String installmentId;
  final String unitId;
  final String payerUserId;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final String currency;
  final double gatewayFee;
  final String? receiptPdfUrl;
  final String? notes;
  final String? verifiedByUserId;
  final PaymentStatus status;
  final DateTime createdAt;

  DateTime get paymentTimestamp => createdAt;

  const Payment({
    required this.id,
    required this.transactionReference,
    required this.contractId,
    required this.installmentId,
    required this.unitId,
    required this.payerUserId,
    required this.paymentMethod,
    required this.amountPaid,
    this.currency = 'EGP',
    this.gatewayFee = 0.0,
    this.receiptPdfUrl,
    this.notes,
    this.verifiedByUserId,
    this.status = PaymentStatus.success,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String? ?? '',
      transactionReference: json['transactionReference'] as String? ?? '',
      contractId: json['contractId'] as String? ?? '',
      installmentId: json['installmentId'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      payerUserId: json['payerUserId'] as String? ?? '',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EGP',
      gatewayFee: (json['gatewayFee'] as num?)?.toDouble() ?? 0.0,
      receiptPdfUrl: json['receiptPdfUrl'] as String?,
      notes: json['notes'] as String?,
      verifiedByUserId: json['verifiedByUserId'] as String?,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.success,
      ),
      createdAt: DateTimeUtil.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionReference': transactionReference,
      'contractId': contractId,
      'installmentId': installmentId,
      'unitId': unitId,
      'payerUserId': payerUserId,
      'paymentMethod': paymentMethod.name,
      'amountPaid': amountPaid,
      'currency': currency,
      'gatewayFee': gatewayFee,
      'receiptPdfUrl': receiptPdfUrl,
      'notes': notes,
      'verifiedByUserId': verifiedByUserId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? transactionReference,
    String? contractId,
    String? installmentId,
    String? unitId,
    String? payerUserId,
    PaymentMethod? paymentMethod,
    double? amountPaid,
    String? currency,
    double? gatewayFee,
    String? receiptPdfUrl,
    String? notes,
    String? verifiedByUserId,
    PaymentStatus? status,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      transactionReference: transactionReference ?? this.transactionReference,
      contractId: contractId ?? this.contractId,
      installmentId: installmentId ?? this.installmentId,
      unitId: unitId ?? this.unitId,
      payerUserId: payerUserId ?? this.payerUserId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountPaid: amountPaid ?? this.amountPaid,
      currency: currency ?? this.currency,
      gatewayFee: gatewayFee ?? this.gatewayFee,
      receiptPdfUrl: receiptPdfUrl ?? this.receiptPdfUrl,
      notes: notes ?? this.notes,
      verifiedByUserId: verifiedByUserId ?? this.verifiedByUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
