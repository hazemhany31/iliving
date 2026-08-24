import 'package:flutter/foundation.dart';
import '../utils/date_time_util.dart';

@immutable
class MaintenanceComment {
  final String id;
  final String ticketId;
  final String authorUserId;
  final String authorName;
  final String authorRole;
  final String commentText;
  final List<String> attachments;
  final DateTime createdAt;

  const MaintenanceComment({
    required this.id,
    required this.ticketId,
    required this.authorUserId,
    required this.authorName,
    required this.authorRole,
    required this.commentText,
    this.attachments = const [],
    required this.createdAt,
  });

  factory MaintenanceComment.fromJson(Map<String, dynamic> json) {
    return MaintenanceComment(
      id: json['id'] as String? ?? '',
      ticketId: json['ticketId'] as String? ?? '',
      authorUserId: json['authorUserId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorRole: json['authorRole'] as String? ?? '',
      commentText: json['commentText'] as String? ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTimeUtil.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'authorUserId': authorUserId,
      'authorName': authorName,
      'authorRole': authorRole,
      'commentText': commentText,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MaintenanceComment copyWith({
    String? id,
    String? ticketId,
    String? authorUserId,
    String? authorName,
    String? authorRole,
    String? commentText,
    List<String>? attachments,
    DateTime? createdAt,
  }) {
    return MaintenanceComment(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      authorUserId: authorUserId ?? this.authorUserId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      commentText: commentText ?? this.commentText,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceComment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
