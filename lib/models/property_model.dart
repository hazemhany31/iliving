import '../utils/date_time_util.dart';

class Development {
  final String id;
  final String title;
  final String imageUrl;
  final String location;
  final double areaSqFt;
  final double basePriceEGP;
  final String primaryView;
  final double completionPercentage;
  final String category;
  final String description;

  const Development({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.location,
    required this.areaSqFt,
    required this.basePriceEGP,
    required this.primaryView,
    required this.completionPercentage,
    required this.category,
    required this.description,
  });

  factory Development.fromJson(Map<String, dynamic> json) {
    return Development(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      location: json['location'] as String? ?? '',
      areaSqFt: (json['areaSqFt'] as num?)?.toDouble() ?? 0.0,
      basePriceEGP: (json['basePriceEGP'] as num?)?.toDouble() ?? 0.0,
      primaryView: json['primaryView'] as String? ?? '',
      completionPercentage: (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'location': location,
      'areaSqFt': areaSqFt,
      'basePriceEGP': basePriceEGP,
      'primaryView': primaryView,
      'completionPercentage': completionPercentage,
      'category': category,
      'description': description,
    };
  }
}

class PropertyUnit {
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

  const PropertyUnit({
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
  });

  factory PropertyUnit.fromJson(Map<String, dynamic> json) {
    return PropertyUnit(
      unitNumber: json['unitNumber'] as String? ?? '',
      configuration: json['configuration'] as String? ?? '',
      areaSqFt: (json['areaSqFt'] as num?)?.toDouble() ?? 0.0,
      priceEGP: (json['priceEGP'] as num?)?.toDouble() ?? 0.0,
      isVacant: json['isVacant'] as bool? ?? true,
      assetClass: json['assetClass'] as String? ?? '',
      furnishingStatus: json['furnishingStatus'] as String? ?? '',
      pricePerSqFt: (json['pricePerSqFt'] as num?)?.toDouble() ?? 0.0,
      parkingSpaces: (json['parkingSpaces'] as num?)?.toInt() ?? 0,
      constructionPhase: json['constructionPhase'] as String? ?? '',
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
    };
  }
}

enum LeadStatus {
  newLead,
  contacted,
  meetingScheduled,
  proposalSent,
  closed
}

class Lead {
  final String id;
  final String clientName;
  final String email;
  final String phone;
  final LeadStatus status;
  final DateTime registeredAt;

  const Lead({
    required this.id,
    required this.clientName,
    required this.email,
    required this.phone,
    required this.status,
    required this.registeredAt,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: LeadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeadStatus.newLead,
      ),
      registeredAt: DateTimeUtil.parse(json['registeredAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'email': email,
      'phone': phone,
      'status': status.name,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }
}

enum BookingStatus {
  spaExecuted,
  pendingApproval,
  rejected
}

class BookingTransaction {
  final String transactionId;
  final String buyerName;
  final String unitId;
  final bool isDownPaymentPaid;
  final BookingStatus status;
  final double contractedPriceEGP;
  final DateTime timestamp;
  final String relationshipManager;
  final String buyerRegistryInfo;
  final String invoiceUrl;

  const BookingTransaction({
    required this.transactionId,
    required this.buyerName,
    required this.unitId,
    required this.isDownPaymentPaid,
    required this.status,
    required this.contractedPriceEGP,
    required this.timestamp,
    required this.relationshipManager,
    required this.buyerRegistryInfo,
    required this.invoiceUrl,
  });

  factory BookingTransaction.fromJson(Map<String, dynamic> json) {
    return BookingTransaction(
      transactionId: json['transactionId'] as String? ?? '',
      buyerName: json['buyerName'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      isDownPaymentPaid: json['isDownPaymentPaid'] as bool? ?? false,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pendingApproval,
      ),
      contractedPriceEGP: (json['contractedPriceEGP'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTimeUtil.parse(json['timestamp']),
      relationshipManager: json['relationshipManager'] as String? ?? '',
      buyerRegistryInfo: json['buyerRegistryInfo'] as String? ?? '',
      invoiceUrl: json['invoiceUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'buyerName': buyerName,
      'unitId': unitId,
      'isDownPaymentPaid': isDownPaymentPaid,
      'status': status.name,
      'contractedPriceEGP': contractedPriceEGP,
      'timestamp': timestamp.toIso8601String(),
      'relationshipManager': relationshipManager,
      'buyerRegistryInfo': buyerRegistryInfo,
      'invoiceUrl': invoiceUrl,
    };
  }
}
