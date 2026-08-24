import 'package:flutter/foundation.dart';
import '../utils/date_time_util.dart';

@immutable
class AuditLog {
  final String id;
  final String actorUserId;
  final String actorRole;
  final String actionType;
  final String targetCollection;
  final String targetDocumentId;
  final Map<String, dynamic> payloadDelta;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.actorUserId,
    required this.actorRole,
    required this.actionType,
    required this.targetCollection,
    required this.targetDocumentId,
    this.payloadDelta = const {},
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String? ?? '',
      actorUserId: json['actorUserId'] as String? ?? '',
      actorRole: json['actorRole'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      targetCollection: json['targetCollection'] as String? ?? '',
      targetDocumentId: json['targetDocumentId'] as String? ?? '',
      payloadDelta: json['payloadDelta'] is Map
          ? Map<String, dynamic>.from(json['payloadDelta'] as Map)
          : {},
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      timestamp: DateTimeUtil.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actorUserId': actorUserId,
      'actorRole': actorRole,
      'actionType': actionType,
      'targetCollection': targetCollection,
      'targetDocumentId': targetDocumentId,
      'payloadDelta': payloadDelta,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  AuditLog copyWith({
    String? id,
    String? actorUserId,
    String? actorRole,
    String? actionType,
    String? targetCollection,
    String? targetDocumentId,
    Map<String, dynamic>? payloadDelta,
    String? ipAddress,
    String? userAgent,
    DateTime? timestamp,
  }) {
    return AuditLog(
      id: id ?? this.id,
      actorUserId: actorUserId ?? this.actorUserId,
      actorRole: actorRole ?? this.actorRole,
      actionType: actionType ?? this.actionType,
      targetCollection: targetCollection ?? this.targetCollection,
      targetDocumentId: targetDocumentId ?? this.targetDocumentId,
      payloadDelta: payloadDelta ?? this.payloadDelta,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLog && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
