typedef Unit = UnitModel;

enum UnitStatus {
  available,
  reserved,
  contracted,
  delivered,
  hold;

  String get nameString => name.toUpperCase();
}

class PaymentMilestone {
  final String title;
  final double percentageDue;
  final bool isPaid;

  const PaymentMilestone({
    required this.title,
    required this.percentageDue,
    required this.isPaid,
  });

  factory PaymentMilestone.fromJson(Map<String, dynamic> json) {
    return PaymentMilestone(
      title: json['title'] as String,
      percentageDue: (json['percentageDue'] as num).toDouble(),
      isPaid: json['isPaid'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'percentageDue': percentageDue,
      'isPaid': isPaid,
    };
  }
}

class UnitModel {
  final String unitNumber;
  final String configuration;
  final double areaSqFt;
  final double priceEGP;
  final bool isVacant;
  final String assetClass;
  final String furnishingStatus;
  final double pricePerSqFt;
  final int parkingSpaces;
  final String constructionPhase;
  final String parentCompoundId;
  final List<PaymentMilestone> paymentMilestones;
  final String floorTier;
  final double areaSquareMeters;
  final double? gardenArea;
  final String? orientation;
  final String? block;
  final UnitStatus status;
  final String? currentOwnerId;
  final String? buildingId;

  String get id => unitNumber;
  String get compoundId => parentCompoundId;
  double? get gardenAreaSqM => gardenArea;

  const UnitModel({
    required this.unitNumber,
    required this.configuration,
    required this.areaSqFt,
    required this.priceEGP,
    required this.isVacant,
    required this.assetClass,
    required this.furnishingStatus,
    required this.pricePerSqFt,
    required this.parkingSpaces,
    required this.constructionPhase,
    required this.parentCompoundId,
    this.paymentMilestones = const [],
    this.floorTier = 'Ground Floor',
    this.areaSquareMeters = 150.0,
    this.gardenArea,
    this.orientation,
    this.block,
    this.status = UnitStatus.available,
    this.currentOwnerId,
    this.buildingId,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    final String unitNum = json['unitNumber'] as String? ?? json['id'] as String? ?? '';
    final match = RegExp(r'\d').firstMatch(unitNum);
    String floorTierStr = 'Ground Floor';
    if (match != null) {
      final digit = unitNum.substring(match.start, match.start + 1);
      switch (digit) {
        case '0':
          floorTierStr = 'Ground Floor';
          break;
        case '1':
          floorTierStr = 'First Floor';
          break;
        case '2':
          floorTierStr = 'Second Floor';
          break;
        case '3':
          floorTierStr = 'Third Floor';
          break;
        case '4':
          floorTierStr = 'Fourth Floor';
          break;
        default:
          floorTierStr = '$digit Floor';
          break;
      }
    }
    final cleanDigits = unitNum.replaceAll(RegExp(r'[^0-9]'), '');
    final int val = int.tryParse(cleanDigits) ?? 150;
    final double areaSqM = (json['areaSquareMeters'] as num?)?.toDouble() ?? (120.0 + (val % 131));

    return UnitModel(
      unitNumber: unitNum,
      configuration: json['configuration'] as String? ?? '',
      areaSqFt: (json['areaSqFt'] as num?)?.toDouble() ?? 0.0,
      priceEGP: (json['priceEGP'] as num?)?.toDouble() ?? 0.0,
      isVacant: json['isVacant'] as bool? ?? true,
      assetClass: json['assetClass'] as String? ?? '',
      furnishingStatus: json['furnishingStatus'] as String? ?? '',
      pricePerSqFt: (json['pricePerSqFt'] as num?)?.toDouble() ?? 0.0,
      parkingSpaces: json['parkingSpaces'] as int? ?? 0,
      constructionPhase: json['constructionPhase'] as String? ?? '',
      parentCompoundId: json['parentCompoundId'] as String? ?? json['compoundId'] as String? ?? '',
      paymentMilestones: (json['paymentMilestones'] as List<dynamic>?)
              ?.map((e) => PaymentMilestone.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      floorTier: floorTierStr,
      areaSquareMeters: areaSqM,
      gardenArea: (json['gardenArea'] as num?)?.toDouble(),
      orientation: json['orientation'] as String?,
      block: json['block'] as String?,
      status: UnitStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] as String? ?? '').toUpperCase(),
        orElse: () => UnitStatus.available,
      ),
      currentOwnerId: json['currentOwnerId'] as String?,
      buildingId: json['buildingId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitNumber': unitNumber,
      'configuration': configuration,
      'areaSqFt': areaSqFt,
      'priceEGP': priceEGP,
      'isVacant': isVacant,
      'assetClass': assetClass,
      'furnishingStatus': furnishingStatus,
      'pricePerSqFt': pricePerSqFt,
      'parkingSpaces': parkingSpaces,
      'constructionPhase': constructionPhase,
      'parentCompoundId': parentCompoundId,
      'compoundId': compoundId,
      'paymentMilestones': paymentMilestones.map((e) => e.toJson()).toList(),
      'floorTier': floorTier,
      'areaSquareMeters': areaSquareMeters,
      'gardenArea': gardenArea,
      'orientation': orientation,
      'block': block,
      'status': status.nameString,
      'currentOwnerId': currentOwnerId,
      'buildingId': buildingId,
    };
  }

  UnitModel copyWith({
    String? unitNumber,
    String? configuration,
    double? areaSqFt,
    double? priceEGP,
    bool? isVacant,
    String? assetClass,
    String? furnishingStatus,
    double? pricePerSqFt,
    int? parkingSpaces,
    String? constructionPhase,
    String? parentCompoundId,
    List<PaymentMilestone>? paymentMilestones,
    String? floorTier,
    double? areaSquareMeters,
    double? gardenArea,
    String? orientation,
    String? block,
    UnitStatus? status,
    String? currentOwnerId,
    String? buildingId,
  }) {
    return UnitModel(
      unitNumber: unitNumber ?? this.unitNumber,
      configuration: configuration ?? this.configuration,
      areaSqFt: areaSqFt ?? this.areaSqFt,
      priceEGP: priceEGP ?? this.priceEGP,
      isVacant: isVacant ?? this.isVacant,
      assetClass: assetClass ?? this.assetClass,
      furnishingStatus: furnishingStatus ?? this.furnishingStatus,
      pricePerSqFt: pricePerSqFt ?? this.pricePerSqFt,
      parkingSpaces: parkingSpaces ?? this.parkingSpaces,
      constructionPhase: constructionPhase ?? this.constructionPhase,
      parentCompoundId: parentCompoundId ?? this.parentCompoundId,
      paymentMilestones: paymentMilestones ?? this.paymentMilestones,
      floorTier: floorTier ?? this.floorTier,
      areaSquareMeters: areaSquareMeters ?? this.areaSquareMeters,
      gardenArea: gardenArea ?? this.gardenArea,
      orientation: orientation ?? this.orientation,
      block: block ?? this.block,
      status: status ?? this.status,
      currentOwnerId: currentOwnerId ?? this.currentOwnerId,
      buildingId: buildingId ?? this.buildingId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnitModel && runtimeType == other.runtimeType && (id == other.id || unitNumber == other.unitNumber);

  @override
  int get hashCode => unitNumber.hashCode;
}
