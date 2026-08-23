import 'package:flutter/foundation.dart';

enum NotificationPriority {
  normal,
  high,
  critical,
  emergency,
}

@immutable
class AppNotification {
  final String id;
  final String targetUserId;
  final String title;
  final String titleAr;
  final String body;
  final String bodyAr;
  final NotificationPriority priority;
  final String? deepLinkRoute;
  final bool isRead;
  final DateTime createdAt;
  final String? type;
  final String? installmentId;
  final String? unitId;
  final String? contractId;
  final double? installmentAmount;
  final DateTime? dueDate;
  final String? installmentName;
  final String? installmentNameAr;
  final String? unitInfo;
  final String? unitInfoAr;
  final String? pdfUrl;
  final String? pdfTitle;

  const AppNotification({
    required this.id,
    required this.targetUserId,
    required this.title,
    this.titleAr = '',
    required this.body,
    this.bodyAr = '',
    this.priority = NotificationPriority.normal,
    this.deepLinkRoute,
    this.isRead = false,
    required this.createdAt,
    this.type,
    this.installmentId,
    this.unitId,
    this.contractId,
    this.installmentAmount,
    this.dueDate,
    this.installmentName,
    this.installmentNameAr,
    this.unitInfo,
    this.unitInfoAr,
    this.pdfUrl,
    this.pdfTitle,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      targetUserId: json['targetUserId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      body: json['body'] as String? ?? '',
      bodyAr: json['bodyAr'] as String? ?? '',
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      deepLinkRoute: json['deepLinkRoute'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      type: json['type'] as String?,
      installmentId: json['installmentId'] as String?,
      unitId: json['unitId'] as String?,
      contractId: json['contractId'] as String?,
      installmentAmount: (json['installmentAmount'] as num?)?.toDouble(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      installmentName: json['installmentName'] as String?,
      installmentNameAr: json['installmentNameAr'] as String?,
      unitInfo: json['unitInfo'] as String?,
      unitInfoAr: json['unitInfoAr'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      pdfTitle: json['pdfTitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetUserId': targetUserId,
      'title': title,
      'titleAr': titleAr,
      'body': body,
      'bodyAr': bodyAr,
      'priority': priority.name,
      'deepLinkRoute': deepLinkRoute,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
      'installmentId': installmentId,
      'unitId': unitId,
      'contractId': contractId,
      'installmentAmount': installmentAmount,
      'dueDate': dueDate?.toIso8601String(),
      'installmentName': installmentName,
      'installmentNameAr': installmentNameAr,
      'unitInfo': unitInfo,
      'unitInfoAr': unitInfoAr,
      'pdfUrl': pdfUrl,
      'pdfTitle': pdfTitle,
    };
  }

  AppNotification copyWith({
    String? id,
    String? targetUserId,
    String? title,
    String? titleAr,
    String? body,
    String? bodyAr,
    NotificationPriority? priority,
    String? deepLinkRoute,
    bool? isRead,
    DateTime? createdAt,
    String? type,
    String? installmentId,
    String? unitId,
    String? contractId,
    double? installmentAmount,
    DateTime? dueDate,
    String? installmentName,
    String? installmentNameAr,
    String? unitInfo,
    String? unitInfoAr,
    String? pdfUrl,
    String? pdfTitle,
  }) {
    return AppNotification(
      id: id ?? this.id,
      targetUserId: targetUserId ?? this.targetUserId,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      body: body ?? this.body,
      bodyAr: bodyAr ?? this.bodyAr,
      priority: priority ?? this.priority,
      deepLinkRoute: deepLinkRoute ?? this.deepLinkRoute,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      installmentId: installmentId ?? this.installmentId,
      unitId: unitId ?? this.unitId,
      contractId: contractId ?? this.contractId,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      dueDate: dueDate ?? this.dueDate,
      installmentName: installmentName ?? this.installmentName,
      installmentNameAr: installmentNameAr ?? this.installmentNameAr,
      unitInfo: unitInfo ?? this.unitInfo,
      unitInfoAr: unitInfoAr ?? this.unitInfoAr,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfTitle: pdfTitle ?? this.pdfTitle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
