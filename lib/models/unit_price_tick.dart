import '../utils/date_time_util.dart';

enum PriceSyncStatus { live, stale, error }

class UnitPriceTick {
  final String unitNumber;
  final String compoundId;
  final double priceEGP;
  final double pricePerSqFt;
  final String installmentLayout;
  final String assetDetail;
  final DateTime updatedAt;
  final PriceSyncStatus status;

  const UnitPriceTick({
    required this.unitNumber,
    required this.compoundId,
    required this.priceEGP,
    required this.pricePerSqFt,
    required this.installmentLayout,
    required this.assetDetail,
    required this.updatedAt,
    this.status = PriceSyncStatus.live,
  });

  factory UnitPriceTick.fromJson(Map<String, dynamic> json) {
    return UnitPriceTick(
      unitNumber: json['unit_number'] as String? ?? json['unitNumber'] as String? ?? '',
      compoundId: json['compound_id'] as String? ?? json['compoundId'] as String? ?? '',
      priceEGP: (json['price_egp'] as num?)?.toDouble() ?? (json['priceEGP'] as num?)?.toDouble() ?? 0.0,
      pricePerSqFt: (json['price_per_sqft'] as num?)?.toDouble() ?? (json['pricePerSqFt'] as num?)?.toDouble() ?? 0.0,
      installmentLayout: json['installment_layout'] as String? ?? json['installmentLayout'] as String? ?? '',
      assetDetail: json['asset_detail'] as String? ?? json['assetDetail'] as String? ?? '',
      updatedAt: DateTimeUtil.parse(json['updated_at'] ?? json['updatedAt']),
      status: PriceSyncStatus.live,
    );
  }

  UnitPriceTick copyWith({
    String? unitNumber,
    String? compoundId,
    double? priceEGP,
    double? pricePerSqFt,
    String? installmentLayout,
    String? assetDetail,
    DateTime? updatedAt,
    PriceSyncStatus? status,
  }) {
    return UnitPriceTick(
      unitNumber: unitNumber ?? this.unitNumber,
      compoundId: compoundId ?? this.compoundId,
      priceEGP: priceEGP ?? this.priceEGP,
      pricePerSqFt: pricePerSqFt ?? this.pricePerSqFt,
      installmentLayout: installmentLayout ?? this.installmentLayout,
      assetDetail: assetDetail ?? this.assetDetail,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unitNumber': unitNumber,
      'compoundId': compoundId,
      'priceEGP': priceEGP,
      'pricePerSqFt': pricePerSqFt,
      'installmentLayout': installmentLayout,
      'assetDetail': assetDetail,
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnitPriceTick &&
        other.unitNumber == unitNumber &&
        other.priceEGP == priceEGP &&
        other.installmentLayout == installmentLayout &&
        other.assetDetail == assetDetail;
  }

  @override
  int get hashCode => Object.hash(unitNumber, priceEGP, installmentLayout, assetDetail);
}
