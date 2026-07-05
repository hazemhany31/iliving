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
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    final String unitNum = json['unitNumber'] as String;
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
    final double areaSqM = 120.0 + (val % 131);

    return UnitModel(
      unitNumber: unitNum,
      configuration: json['configuration'] as String,
      areaSqFt: (json['areaSqFt'] as num).toDouble(),
      priceEGP: (json['priceEGP'] as num).toDouble(),
      isVacant: json['isVacant'] as bool,
      assetClass: json['assetClass'] as String,
      furnishingStatus: json['furnishingStatus'] as String,
      pricePerSqFt: (json['pricePerSqFt'] as num).toDouble(),
      parkingSpaces: json['parkingSpaces'] as int,
      constructionPhase: json['constructionPhase'] as String,
      parentCompoundId: json['parentCompoundId'] as String,
      paymentMilestones: (json['paymentMilestones'] as List<dynamic>?)
              ?.map((e) => PaymentMilestone.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      floorTier: floorTierStr,
      areaSquareMeters: areaSqM,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'paymentMilestones': paymentMilestones.map((e) => e.toJson()).toList(),
      'floorTier': floorTier,
      'areaSquareMeters': areaSquareMeters,
    };
  }
}
