import 'package:flutter/foundation.dart';
import '../utils/date_time_util.dart';

enum SignatureStatus {
  draft,
  pendingCustomer,
  pendingDeveloper,
  fullyExecuted,
  cancelled,
}

@immutable
class Contract {
  final String id;
  final String contractNumber;
  final String unitId;
  final String compoundId;
  final String buyerUserId;
  final String salesAgentUserId;
  final double agreedTotalPrice;
  final double downPaymentAmount;
  final double maintenanceDepositAmount;
  final double? handoverPaymentAmount;
  final String? clientCode;
  final int installmentDurationYears;
  final int totalInstallmentsCount;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime deliveryDateExpected;
  final String pdfContractUrl;
  final SignatureStatus signatureStatus;
  final DateTime? signedByCustomerAt;
  final DateTime? signedByDeveloperAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contract({
    required this.id,
    required this.contractNumber,
    required this.unitId,
    required this.compoundId,
    required this.buyerUserId,
    required this.salesAgentUserId,
    required this.agreedTotalPrice,
    required this.downPaymentAmount,
    this.maintenanceDepositAmount = 0.0,
    this.handoverPaymentAmount,
    this.clientCode,
    required this.installmentDurationYears,
    required this.totalInstallmentsCount,
    required this.startDate,
    required this.endDate,
    required this.deliveryDateExpected,
    this.pdfContractUrl = '',
    this.signatureStatus = SignatureStatus.draft,
    this.signedByCustomerAt,
    this.signedByDeveloperAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFullyExecuted => signatureStatus == SignatureStatus.fullyExecuted;
  double get totalPrice => agreedTotalPrice;

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] as String? ?? '',
      contractNumber: json['contractNumber'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      compoundId: json['compoundId'] as String? ?? '',
      buyerUserId: json['buyerUserId'] as String? ?? '',
      salesAgentUserId: json['salesAgentUserId'] as String? ?? '',
      agreedTotalPrice: (json['agreedTotalPrice'] as num?)?.toDouble() ?? 0.0,
      downPaymentAmount: (json['downPaymentAmount'] as num?)?.toDouble() ?? 0.0,
      maintenanceDepositAmount: (json['maintenanceDepositAmount'] as num?)?.toDouble() ?? 0.0,
      handoverPaymentAmount: (json['handoverPaymentAmount'] as num?)?.toDouble(),
      clientCode: json['clientCode'] as String?,
      installmentDurationYears: (json['installmentDurationYears'] as num?)?.toInt() ?? 1,
      totalInstallmentsCount: (json['totalInstallmentsCount'] as num?)?.toInt() ?? 4,
      startDate: DateTimeUtil.parse(json['startDate']),
      endDate: DateTimeUtil.parse(json['endDate']),
      deliveryDateExpected: DateTimeUtil.parse(json['deliveryDateExpected']),
      pdfContractUrl: json['pdfContractUrl'] as String? ?? '',
      signatureStatus: SignatureStatus.values.firstWhere(
        (e) => e.name == json['signatureStatus'],
        orElse: () => SignatureStatus.draft,
      ),
      signedByCustomerAt: DateTimeUtil.tryParse(json['signedByCustomerAt']),
      signedByDeveloperAt: DateTimeUtil.tryParse(json['signedByDeveloperAt']),
      createdAt: DateTimeUtil.parse(json['createdAt']),
      updatedAt: DateTimeUtil.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractNumber': contractNumber,
      'unitId': unitId,
      'compoundId': compoundId,
      'buyerUserId': buyerUserId,
      'salesAgentUserId': salesAgentUserId,
      'agreedTotalPrice': agreedTotalPrice,
      'downPaymentAmount': downPaymentAmount,
      'maintenanceDepositAmount': maintenanceDepositAmount,
      'handoverPaymentAmount': handoverPaymentAmount,
      'clientCode': clientCode,
      'installmentDurationYears': installmentDurationYears,
      'totalInstallmentsCount': totalInstallmentsCount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'deliveryDateExpected': deliveryDateExpected.toIso8601String(),
      'pdfContractUrl': pdfContractUrl,
      'signatureStatus': signatureStatus.name,
      'signedByCustomerAt': signedByCustomerAt?.toIso8601String(),
      'signedByDeveloperAt': signedByDeveloperAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Contract copyWith({
    String? id,
    String? contractNumber,
    String? unitId,
    String? compoundId,
    String? buyerUserId,
    String? salesAgentUserId,
    double? agreedTotalPrice,
    double? downPaymentAmount,
    double? maintenanceDepositAmount,
    double? handoverPaymentAmount,
    String? clientCode,
    int? installmentDurationYears,
    int? totalInstallmentsCount,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? deliveryDateExpected,
    String? pdfContractUrl,
    SignatureStatus? signatureStatus,
    DateTime? signedByCustomerAt,
    DateTime? signedByDeveloperAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contract(
      id: id ?? this.id,
      contractNumber: contractNumber ?? this.contractNumber,
      unitId: unitId ?? this.unitId,
      compoundId: compoundId ?? this.compoundId,
      buyerUserId: buyerUserId ?? this.buyerUserId,
      salesAgentUserId: salesAgentUserId ?? this.salesAgentUserId,
      agreedTotalPrice: agreedTotalPrice ?? this.agreedTotalPrice,
      downPaymentAmount: downPaymentAmount ?? this.downPaymentAmount,
      maintenanceDepositAmount: maintenanceDepositAmount ?? this.maintenanceDepositAmount,
      handoverPaymentAmount: handoverPaymentAmount ?? this.handoverPaymentAmount,
      clientCode: clientCode ?? this.clientCode,
      installmentDurationYears: installmentDurationYears ?? this.installmentDurationYears,
      totalInstallmentsCount: totalInstallmentsCount ?? this.totalInstallmentsCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deliveryDateExpected: deliveryDateExpected ?? this.deliveryDateExpected,
      pdfContractUrl: pdfContractUrl ?? this.pdfContractUrl,
      signatureStatus: signatureStatus ?? this.signatureStatus,
      signedByCustomerAt: signedByCustomerAt ?? this.signedByCustomerAt,
      signedByDeveloperAt: signedByDeveloperAt ?? this.signedByDeveloperAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contract && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
