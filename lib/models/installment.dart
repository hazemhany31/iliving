import 'package:flutter/foundation.dart';

enum InstallmentType {
  downPayment,
  regularQuarterly,
  semiAnnual,
  annual,
  balloon,
  maintenanceFund,
  deliveryPayment,
}

enum InstallmentStatus {
  unpaid,
  gracePeriod,
  partiallyPaid,
  paid,
  overdue,
  waived,
  pendingApproval,
}

extension InstallmentStatusX on InstallmentStatus {
  String get nameString {
    if (this == InstallmentStatus.pendingApproval) return 'PENDING_APPROVAL';
    return name.toUpperCase();
  }

  static InstallmentStatus fromString(String? str) {
    switch (str?.toUpperCase()) {
      case 'PENDING_APPROVAL':
      case 'WAITING':
      case 'PENDING':
      case 'PENDINGAPPROVAL':
        return InstallmentStatus.pendingApproval;
      case 'GRACE_PERIOD':
        return InstallmentStatus.gracePeriod;
      case 'PARTIALLY_PAID':
        return InstallmentStatus.partiallyPaid;
      case 'PAID':
        return InstallmentStatus.paid;
      case 'OVERDUE':
        return InstallmentStatus.overdue;
      case 'WAIVED':
        return InstallmentStatus.waived;
      case 'UNPAID':
      default:
        return InstallmentStatus.unpaid;
    }
  }
}

@immutable
class Installment {
  final String id;
  final String contractId;
  final String unitId;
  final String buyerUserId;
  final int sequenceNumber;
  final InstallmentType installmentType;
  final DateTime dueDate;
  final DateTime gracePeriodEndDate;
  final double principalAmount;
  final double penaltyFeeAmount;
  final double paidAmount;
  final String currency;
  final InstallmentStatus status;
  final DateTime? paidAt;
  final String? paymentMethodLastUsed;
  final String? receiptNumber;
  final String? proofScreenshotUrl;
  final DateTime? submittedAt;
  final String? submissionNotes;

  const Installment({
    required this.id,
    required this.contractId,
    required this.unitId,
    required this.buyerUserId,
    required this.sequenceNumber,
    required this.installmentType,
    required this.dueDate,
    required this.gracePeriodEndDate,
    required this.principalAmount,
    this.penaltyFeeAmount = 0.0,
    this.paidAmount = 0.0,
    this.currency = 'EGP',
    this.status = InstallmentStatus.unpaid,
    this.paidAt,
    this.paymentMethodLastUsed,
    this.receiptNumber,
    this.proofScreenshotUrl,
    this.submittedAt,
    this.submissionNotes,
  });

  double get totalAmountDue => principalAmount + penaltyFeeAmount;
  double get amount => totalAmountDue;
  double get remainingAmount => (totalAmountDue - paidAmount).clamp(0.0, double.infinity);
  bool get isPaid => status == InstallmentStatus.paid;
  bool get isOverdue => status == InstallmentStatus.overdue;
  bool get inGracePeriod => status == InstallmentStatus.gracePeriod;
  bool get isPendingApproval => status == InstallmentStatus.pendingApproval;

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] as String? ?? '',
      contractId: json['contractId'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      buyerUserId: json['buyerUserId'] as String? ?? '',
      sequenceNumber: json['sequenceNumber'] as int? ?? 1,
      installmentType: InstallmentType.values.firstWhere(
        (e) => e.name == json['installmentType'],
        orElse: () => InstallmentType.regularQuarterly,
      ),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : DateTime.now(),
      gracePeriodEndDate: json['gracePeriodEndDate'] != null
          ? DateTime.parse(json['gracePeriodEndDate'] as String)
          : DateTime.now().add(const Duration(days: 14)),
      principalAmount: (json['principalAmount'] as num?)?.toDouble() ?? 0.0,
      penaltyFeeAmount: (json['penaltyFeeAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EGP',
      status: InstallmentStatusX.fromString(json['status'] as String?),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      paymentMethodLastUsed: json['paymentMethodLastUsed'] as String?,
      receiptNumber: json['receiptNumber'] as String?,
      proofScreenshotUrl: json['proofScreenshotUrl'] as String?,
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt'] as String) : null,
      submissionNotes: json['submissionNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractId': contractId,
      'unitId': unitId,
      'buyerUserId': buyerUserId,
      'sequenceNumber': sequenceNumber,
      'installmentType': installmentType.name,
      'dueDate': dueDate.toIso8601String(),
      'gracePeriodEndDate': gracePeriodEndDate.toIso8601String(),
      'principalAmount': principalAmount,
      'penaltyFeeAmount': penaltyFeeAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'currency': currency,
      'status': status.nameString,
      'paidAt': paidAt?.toIso8601String(),
      'paymentMethodLastUsed': paymentMethodLastUsed,
      'receiptNumber': receiptNumber,
      'proofScreenshotUrl': proofScreenshotUrl,
      'submittedAt': submittedAt?.toIso8601String(),
      'submissionNotes': submissionNotes,
    };
  }

  Installment copyWith({
    String? id,
    String? contractId,
    String? unitId,
    String? buyerUserId,
    int? sequenceNumber,
    InstallmentType? installmentType,
    DateTime? dueDate,
    DateTime? gracePeriodEndDate,
    double? principalAmount,
    double? penaltyFeeAmount,
    double? paidAmount,
    String? currency,
    InstallmentStatus? status,
    DateTime? paidAt,
    String? paymentMethodLastUsed,
    String? receiptNumber,
    String? proofScreenshotUrl,
    DateTime? submittedAt,
    String? submissionNotes,
  }) {
    return Installment(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      unitId: unitId ?? this.unitId,
      buyerUserId: buyerUserId ?? this.buyerUserId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      installmentType: installmentType ?? this.installmentType,
      dueDate: dueDate ?? this.dueDate,
      gracePeriodEndDate: gracePeriodEndDate ?? this.gracePeriodEndDate,
      principalAmount: principalAmount ?? this.principalAmount,
      penaltyFeeAmount: penaltyFeeAmount ?? this.penaltyFeeAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      paymentMethodLastUsed: paymentMethodLastUsed ?? this.paymentMethodLastUsed,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      proofScreenshotUrl: proofScreenshotUrl ?? this.proofScreenshotUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      submissionNotes: submissionNotes ?? this.submissionNotes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Installment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
