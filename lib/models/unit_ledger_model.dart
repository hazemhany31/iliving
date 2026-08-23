class DownPaymentRecord {
  final bool isPaid;
  final String status;
  final double percentageDue;
  final double amountEGP;
  final String? paidTimestamp;
  final String? receiptUrl;
  final String? transactionRef;

  const DownPaymentRecord({
    required this.isPaid,
    required this.status,
    required this.percentageDue,
    required this.amountEGP,
    this.paidTimestamp,
    this.receiptUrl,
    this.transactionRef,
  });

  factory DownPaymentRecord.fromJson(Map<String, dynamic> json) {
    return DownPaymentRecord(
      isPaid: json['isPaid'] as bool,
      status: json['status'] as String,
      percentageDue: (json['percentageDue'] as num).toDouble(),
      amountEGP: (json['amountEGP'] as num).toDouble(),
      paidTimestamp: json['paidTimestamp'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      transactionRef: json['transactionRef'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPaid': isPaid,
      'status': status,
      'percentageDue': percentageDue,
      'amountEGP': amountEGP,
      'paidTimestamp': paidTimestamp,
      'receiptUrl': receiptUrl,
      'transactionRef': transactionRef,
    };
  }

  DownPaymentRecord copyWith({
    bool? isPaid,
    String? status,
    double? percentageDue,
    double? amountEGP,
    String? paidTimestamp,
    String? receiptUrl,
    String? transactionRef,
  }) {
    return DownPaymentRecord(
      isPaid: isPaid ?? this.isPaid,
      status: status ?? this.status,
      percentageDue: percentageDue ?? this.percentageDue,
      amountEGP: amountEGP ?? this.amountEGP,
      paidTimestamp: paidTimestamp ?? this.paidTimestamp,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      transactionRef: transactionRef ?? this.transactionRef,
    );
  }
}

class InstallmentRecord {
  final String id;
  final String title;
  final bool isPaid;
  final double amountEGP;
  final String dueDateIso;
  final String dueDateLabel;
  final String? paidTimestamp;
  final String? receiptUrl;
  final String? milestoneTag;

  const InstallmentRecord({
    required this.id,
    required this.title,
    required this.isPaid,
    required this.amountEGP,
    required this.dueDateIso,
    required this.dueDateLabel,
    this.paidTimestamp,
    this.receiptUrl,
    this.milestoneTag,
  });

  factory InstallmentRecord.fromJson(Map<String, dynamic> json) {
    return InstallmentRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      isPaid: json['isPaid'] as bool,
      amountEGP: (json['amountEGP'] as num).toDouble(),
      dueDateIso: json['dueDateIso'] as String,
      dueDateLabel: json['dueDateLabel'] as String,
      paidTimestamp: json['paidTimestamp'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      milestoneTag: json['milestoneTag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isPaid': isPaid,
      'amountEGP': amountEGP,
      'dueDateIso': dueDateIso,
      'dueDateLabel': dueDateLabel,
      'paidTimestamp': paidTimestamp,
      'receiptUrl': receiptUrl,
      'milestoneTag': milestoneTag,
    };
  }

  InstallmentRecord copyWith({
    String? id,
    String? title,
    bool? isPaid,
    double? amountEGP,
    String? dueDateIso,
    String? dueDateLabel,
    String? paidTimestamp,
    String? receiptUrl,
    String? milestoneTag,
  }) {
    return InstallmentRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      isPaid: isPaid ?? this.isPaid,
      amountEGP: amountEGP ?? this.amountEGP,
      dueDateIso: dueDateIso ?? this.dueDateIso,
      dueDateLabel: dueDateLabel ?? this.dueDateLabel,
      paidTimestamp: paidTimestamp ?? this.paidTimestamp,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      milestoneTag: milestoneTag ?? this.milestoneTag,
    );
  }
}

class MaintenanceFundRecord {
  final bool isPaid;
  final String status;
  final double balanceEGP;
  final double annualFeeEGP;
  final String? lastPaidTimestamp;
  final String? nextDueDateIso;
  final String? escrowAccountRef;

  const MaintenanceFundRecord({
    required this.isPaid,
    required this.status,
    required this.balanceEGP,
    required this.annualFeeEGP,
    this.lastPaidTimestamp,
    this.nextDueDateIso,
    this.escrowAccountRef,
  });

  factory MaintenanceFundRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceFundRecord(
      isPaid: json['isPaid'] as bool,
      status: json['status'] as String,
      balanceEGP: (json['balanceEGP'] as num).toDouble(),
      annualFeeEGP: (json['annualFeeEGP'] as num).toDouble(),
      lastPaidTimestamp: json['lastPaidTimestamp'] as String?,
      nextDueDateIso: json['nextDueDateIso'] as String?,
      escrowAccountRef: json['escrowAccountRef'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPaid': isPaid,
      'status': status,
      'balanceEGP': balanceEGP,
      'annualFeeEGP': annualFeeEGP,
      'lastPaidTimestamp': lastPaidTimestamp,
      'nextDueDateIso': nextDueDateIso,
      'escrowAccountRef': escrowAccountRef,
    };
  }

  MaintenanceFundRecord copyWith({
    bool? isPaid,
    String? status,
    double? balanceEGP,
    double? annualFeeEGP,
    String? lastPaidTimestamp,
    String? nextDueDateIso,
    String? escrowAccountRef,
  }) {
    return MaintenanceFundRecord(
      isPaid: isPaid ?? this.isPaid,
      status: status ?? this.status,
      balanceEGP: balanceEGP ?? this.balanceEGP,
      annualFeeEGP: annualFeeEGP ?? this.annualFeeEGP,
      lastPaidTimestamp: lastPaidTimestamp ?? this.lastPaidTimestamp,
      nextDueDateIso: nextDueDateIso ?? this.nextDueDateIso,
      escrowAccountRef: escrowAccountRef ?? this.escrowAccountRef,
    );
  }
}


class UnitLedger {
  final String compoundId;
  final String clientId;
  final String unitId;
  final String unitType;
  final DownPaymentRecord downPayment;
  final List<InstallmentRecord> installments;
  final MaintenanceFundRecord maintenance;
  final String floorTier;
  final double areaSquareMeters;

  String get id => unitId;

  const UnitLedger({
    required this.compoundId,
    required this.clientId,
    required this.unitId,
    required this.unitType,
    required this.downPayment,
    required this.installments,
    required this.maintenance,
    this.floorTier = 'Ground Floor',
    this.areaSquareMeters = 150.0,
  });

  factory UnitLedger.fromJson(Map<String, dynamic> json) {
    final String unitId = json['unitId'] as String;
    final match = RegExp(r'\d').firstMatch(unitId);
    String floorTierStr = 'Ground Floor';
    if (match != null) {
      final digit = unitId.substring(match.start, match.start + 1);
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
    final cleanDigits = unitId.replaceAll(RegExp(r'[^0-9]'), '');
    final int val = int.tryParse(cleanDigits) ?? 150;
    final double areaSqM = 120.0 + (val % 131);

    return UnitLedger(
      compoundId: json['compoundId'] as String,
      clientId: json['clientId'] as String,
      unitId: unitId,
      unitType: json['unitType'] as String,
      downPayment: json['downPayment'] != null
          ? DownPaymentRecord.fromJson(json['downPayment'] as Map<String, dynamic>)
          : const DownPaymentRecord(
              isPaid: false,
              status: 'Unpaid',
              percentageDue: 10.0,
              amountEGP: 0.0,
            ),
      installments: (json['installments'] as List<dynamic>?)
              ?.map((e) =>
                  InstallmentRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      maintenance: json['maintenance'] != null
          ? MaintenanceFundRecord.fromJson(json['maintenance'] as Map<String, dynamic>)
          : const MaintenanceFundRecord(
              isPaid: false,
              status: 'Active',
              balanceEGP: 0.0,
              annualFeeEGP: 0.0,
            ),
      floorTier: floorTierStr,
      areaSquareMeters: areaSqM,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compoundId': compoundId,
      'clientId': clientId,
      'unitId': unitId,
      'unitType': unitType,
      'downPayment': downPayment.toJson(),
      'installments': installments.map((e) => e.toJson()).toList(),
      'maintenance': maintenance.toJson(),
      'floorTier': floorTier,
      'areaSquareMeters': areaSquareMeters,
    };
  }

  double get totalPaidEGP {
    double total = 0.0;
    if (downPayment.isPaid) total += downPayment.amountEGP;
    for (final inst in installments) {
      if (inst.isPaid) total += inst.amountEGP;
    }
    if (maintenance.isPaid) total += maintenance.balanceEGP;
    return total;
  }

  double get totalOutstandingEGP {
    double total = 0.0;
    if (!downPayment.isPaid) total += downPayment.amountEGP;
    for (final inst in installments) {
      if (!inst.isPaid) total += inst.amountEGP;
    }
    if (!maintenance.isPaid) total += maintenance.balanceEGP;
    return total;
  }

  List<InstallmentRecord> get upcomingInstallments =>
      installments.where((i) => !i.isPaid).toList();

  List<InstallmentRecord> get paidInstallments =>
      installments.where((i) => i.isPaid).toList();

  UnitLedger copyWith({
    String? compoundId,
    String? clientId,
    String? unitId,
    String? unitType,
    DownPaymentRecord? downPayment,
    List<InstallmentRecord>? installments,
    MaintenanceFundRecord? maintenance,
    String? floorTier,
    double? areaSquareMeters,
  }) {
    return UnitLedger(
      compoundId: compoundId ?? this.compoundId,
      clientId: clientId ?? this.clientId,
      unitId: unitId ?? this.unitId,
      unitType: unitType ?? this.unitType,
      downPayment: downPayment ?? this.downPayment,
      installments: installments ?? this.installments,
      maintenance: maintenance ?? this.maintenance,
      floorTier: floorTier ?? this.floorTier,
      areaSquareMeters: areaSquareMeters ?? this.areaSquareMeters,
    );
  }
}
