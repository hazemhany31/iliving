import 'package:flutter/foundation.dart';
import '../utils/date_time_util.dart';

enum MaintenanceCategory {
  plumbing,
  electrical,
  hvac,
  carpentry,
  cleaning,
  securityHardware,
}

enum MaintenanceUrgency {
  low,
  medium,
  high,
  emergency,
}

enum MaintenanceStatus {
  submitted,
  assigned,
  inProgress,
  pendingParts,
  completed,
  cancelled,
}

@immutable
class MaintenanceRequest {
  final String id;
  final String ticketNumber;
  final String compoundId;
  final String unitId;
  final String residentUserId;
  final String? assignedTechnicianUserId;
  final MaintenanceCategory category;
  final MaintenanceUrgency urgency;
  final String title;
  final String description;
  final List<String> attachments;
  final DateTime? preferredScheduleSlot;
  final MaintenanceStatus status;
  final double? rating;
  final String? residentFeedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceRequest({
    required this.id,
    required this.ticketNumber,
    required this.compoundId,
    required this.unitId,
    required this.residentUserId,
    this.assignedTechnicianUserId,
    required this.category,
    this.urgency = MaintenanceUrgency.medium,
    required this.title,
    required this.description,
    this.attachments = const [],
    this.preferredScheduleSlot,
    this.status = MaintenanceStatus.submitted,
    this.rating,
    this.residentFeedback,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == MaintenanceStatus.completed;

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'] as String? ?? '',
      ticketNumber: json['ticketNumber'] as String? ?? '',
      compoundId: json['compoundId'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      residentUserId: json['residentUserId'] as String? ?? '',
      assignedTechnicianUserId: json['assignedTechnicianUserId'] as String?,
      category: MaintenanceCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => MaintenanceCategory.plumbing,
      ),
      urgency: MaintenanceUrgency.values.firstWhere(
        (e) => e.name == json['urgency'],
        orElse: () => MaintenanceUrgency.medium,
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      preferredScheduleSlot: DateTimeUtil.tryParse(json['preferredScheduleSlot']),
      status: MaintenanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MaintenanceStatus.submitted,
      ),
      rating: (json['rating'] as num?)?.toDouble(),
      residentFeedback: json['residentFeedback'] as String?,
      createdAt: DateTimeUtil.parse(json['createdAt']),
      updatedAt: DateTimeUtil.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'compoundId': compoundId,
      'unitId': unitId,
      'residentUserId': residentUserId,
      'assignedTechnicianUserId': assignedTechnicianUserId,
      'category': category.name,
      'urgency': urgency.name,
      'title': title,
      'description': description,
      'attachments': attachments,
      'preferredScheduleSlot': preferredScheduleSlot?.toIso8601String(),
      'status': status.name,
      'rating': rating,
      'residentFeedback': residentFeedback,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MaintenanceRequest copyWith({
    String? id,
    String? ticketNumber,
    String? compoundId,
    String? unitId,
    String? residentUserId,
    String? assignedTechnicianUserId,
    MaintenanceCategory? category,
    MaintenanceUrgency? urgency,
    String? title,
    String? description,
    List<String>? attachments,
    DateTime? preferredScheduleSlot,
    MaintenanceStatus? status,
    double? rating,
    String? residentFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceRequest(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      compoundId: compoundId ?? this.compoundId,
      unitId: unitId ?? this.unitId,
      residentUserId: residentUserId ?? this.residentUserId,
      assignedTechnicianUserId: assignedTechnicianUserId ?? this.assignedTechnicianUserId,
      category: category ?? this.category,
      urgency: urgency ?? this.urgency,
      title: title ?? this.title,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      preferredScheduleSlot: preferredScheduleSlot ?? this.preferredScheduleSlot,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      residentFeedback: residentFeedback ?? this.residentFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceRequest && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
