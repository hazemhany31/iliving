enum TicketTrade { plumbing, electrical, drainage }

enum TicketStatus { requested, inProgress, resolved }

enum TicketPriority { low, medium, high, critical }

class TicketStatusEntry {
  final String status;
  final String changedByName;
  final String changedByRole;
  final String timestampIso;
  final String? note;

  const TicketStatusEntry({
    required this.status,
    required this.changedByName,
    required this.changedByRole,
    required this.timestampIso,
    this.note,
  });

  factory TicketStatusEntry.fromJson(Map<String, dynamic> json) {
    return TicketStatusEntry(
      status: json['status'] as String,
      changedByName: json['changedByName'] as String,
      changedByRole: json['changedByRole'] as String,
      timestampIso: json['timestampIso'] as String,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'changedByName': changedByName,
      'changedByRole': changedByRole,
      'timestampIso': timestampIso,
      'note': note,
    };
  }
}

class OperationTicketModel {
  final String id;
  final TicketTrade trade;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final String compoundId;
  final String unitId;
  final String clientId;
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final String reportedByName;
  final String contactPhone;
  final String createdAtIso;
  final String updatedAtIso;
  final String? resolvedAtIso;
  final String? scheduledVisitIso;
  final List<TicketStatusEntry> statusLog;
  final List<String> photoUrls;
  final String? resolutionNotes;
  final String? internalReference;

  const OperationTicketModel({
    required this.id,
    required this.trade,
    required this.description,
    required this.status,
    this.priority = TicketPriority.medium,
    required this.compoundId,
    required this.unitId,
    required this.clientId,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    required this.reportedByName,
    required this.contactPhone,
    required this.createdAtIso,
    required this.updatedAtIso,
    this.resolvedAtIso,
    this.scheduledVisitIso,
    this.statusLog = const [],
    this.photoUrls = const [],
    this.resolutionNotes,
    this.internalReference,
  });

  String get tradeLabel {
    switch (trade) {
      case TicketTrade.plumbing:
        return 'Plumbing';
      case TicketTrade.electrical:
        return 'Electrical';
      case TicketTrade.drainage:
        return 'Drainage';
    }
  }

  String get statusLabel {
    switch (status) {
      case TicketStatus.requested:
        return 'Requested';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.critical:
        return 'Critical';
    }
  }

  factory OperationTicketModel.fromJson(Map<String, dynamic> json) {
    return OperationTicketModel(
      id: json['id'] as String,
      trade: TicketTrade.values.firstWhere(
        (e) => e.name == json['trade'],
        orElse: () => TicketTrade.plumbing,
      ),
      description: json['description'] as String,
      status: TicketStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TicketStatus.requested,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.name == (json['priority'] as String? ?? 'medium').toLowerCase(),
        orElse: () => TicketPriority.medium,
      ),
      compoundId: json['compoundId'] as String,
      unitId: json['unitId'] as String,
      clientId: json['clientId'] as String? ?? '',
      assignedTechnicianId: json['assignedTechnicianId'] as String?,
      assignedTechnicianName: json['assignedTechnicianName'] as String?,
      reportedByName: json['reportedByName'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      createdAtIso: json['createdAtIso'] as String? ??
          DateTime.now().toIso8601String(),
      updatedAtIso: json['updatedAtIso'] as String? ??
          DateTime.now().toIso8601String(),
      resolvedAtIso: json['resolvedAtIso'] as String?,
      scheduledVisitIso: json['scheduledVisitIso'] as String?,
      statusLog: (json['statusLog'] as List<dynamic>?)
              ?.map((e) =>
                  TicketStatusEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      resolutionNotes: json['resolutionNotes'] as String?,
      internalReference: json['internalReference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trade': trade.name,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'compoundId': compoundId,
      'unitId': unitId,
      'clientId': clientId,
      'assignedTechnicianId': assignedTechnicianId,
      'assignedTechnicianName': assignedTechnicianName,
      'reportedByName': reportedByName,
      'contactPhone': contactPhone,
      'createdAtIso': createdAtIso,
      'updatedAtIso': updatedAtIso,
      'resolvedAtIso': resolvedAtIso,
      'scheduledVisitIso': scheduledVisitIso,
      'statusLog': statusLog.map((e) => e.toJson()).toList(),
      'photoUrls': photoUrls,
      'resolutionNotes': resolutionNotes,
      'internalReference': internalReference,
    };
  }

  OperationTicketModel copyWith({
    String? id,
    TicketTrade? trade,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    String? compoundId,
    String? unitId,
    String? clientId,
    String? assignedTechnicianId,
    String? assignedTechnicianName,
    String? reportedByName,
    String? contactPhone,
    String? createdAtIso,
    String? updatedAtIso,
    String? resolvedAtIso,
    String? scheduledVisitIso,
    List<TicketStatusEntry>? statusLog,
    List<String>? photoUrls,
    String? resolutionNotes,
    String? internalReference,
  }) {
    return OperationTicketModel(
      id: id ?? this.id,
      trade: trade ?? this.trade,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      compoundId: compoundId ?? this.compoundId,
      unitId: unitId ?? this.unitId,
      clientId: clientId ?? this.clientId,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      assignedTechnicianName:
          assignedTechnicianName ?? this.assignedTechnicianName,
      reportedByName: reportedByName ?? this.reportedByName,
      contactPhone: contactPhone ?? this.contactPhone,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      resolvedAtIso: resolvedAtIso ?? this.resolvedAtIso,
      scheduledVisitIso: scheduledVisitIso ?? this.scheduledVisitIso,
      statusLog: statusLog ?? this.statusLog,
      photoUrls: photoUrls ?? this.photoUrls,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      internalReference: internalReference ?? this.internalReference,
    );
  }

  OperationTicketModel withStatusTransition({
    required TicketStatus newStatus,
    required String changedByName,
    required String changedByRole,
    String? note,
  }) {
    final now = DateTime.now().toIso8601String();
    final entry = TicketStatusEntry(
      status: newStatus.name,
      changedByName: changedByName,
      changedByRole: changedByRole,
      timestampIso: now,
      note: note,
    );
    return copyWith(
      status: newStatus,
      updatedAtIso: now,
      resolvedAtIso:
          newStatus == TicketStatus.resolved ? now : resolvedAtIso,
      statusLog: [...statusLog, entry],
    );
  }
}
