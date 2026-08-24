enum InvoiceType {
  downPayment,
  installment,
  maintenanceFee,
  electricity,
  water,
  gas,
}

class InvoiceModel {
  final String id;
  final InvoiceType type;
  final String title;
  final double amountEGP;
  final bool isPaid;
  final String dueDate;
  final String? paidTimestamp;
  final String compoundId;
  final String unitId;
  final String? receiptUrl;

  const InvoiceModel({
    required this.id,
    required this.type,
    required this.title,
    required this.amountEGP,
    required this.isPaid,
    required this.dueDate,
    this.paidTimestamp,
    required this.compoundId,
    required this.unitId,
    this.receiptUrl,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String? ?? '',
      type: InvoiceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InvoiceType.installment,
      ),
      title: json['title'] as String? ?? '',
      amountEGP: (json['amountEGP'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['isPaid'] as bool? ?? false,
      dueDate: json['dueDate'] as String? ?? '',
      paidTimestamp: json['paidTimestamp'] as String?,
      compoundId: json['compoundId'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      receiptUrl: json['receiptUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'amountEGP': amountEGP,
      'isPaid': isPaid,
      'dueDate': dueDate,
      'paidTimestamp': paidTimestamp,
      'compoundId': compoundId,
      'unitId': unitId,
      'receiptUrl': receiptUrl,
    };
  }

  String get typeLabel {
    switch (type) {
      case InvoiceType.downPayment:
        return 'Down Payment';
      case InvoiceType.installment:
        return 'Installment';
      case InvoiceType.maintenanceFee:
        return 'Maintenance Fee';
      case InvoiceType.electricity:
        return 'Electricity';
      case InvoiceType.water:
        return 'Water';
      case InvoiceType.gas:
        return 'Gas';
    }
  }
}
