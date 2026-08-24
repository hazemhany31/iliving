import 'package:flutter/foundation.dart';
import '../utils/date_time_util.dart';

@immutable
class PriceHistory {
  final String id;
  final String entityType; // "COMPOUND" | "BUILDING" | "UNIT"
  final String entityId;
  final double oldPrice;
  final double newPrice;
  final double changePercentage;
  final String changedByUserId;
  final String reason;
  final DateTime timestamp;

  const PriceHistory({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.oldPrice,
    required this.newPrice,
    required this.changePercentage,
    required this.changedByUserId,
    required this.reason,
    required this.timestamp,
  });

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      id: json['id'] as String? ?? '',
      entityType: json['entityType'] as String? ?? 'UNIT',
      entityId: json['entityId'] as String? ?? '',
      oldPrice: (json['oldPrice'] as num?)?.toDouble() ?? 0.0,
      newPrice: (json['newPrice'] as num?)?.toDouble() ?? 0.0,
      changePercentage: (json['changePercentage'] as num?)?.toDouble() ?? 0.0,
      changedByUserId: json['changedByUserId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      timestamp: DateTimeUtil.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'changePercentage': changePercentage,
      'changedByUserId': changedByUserId,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  PriceHistory copyWith({
    String? id,
    String? entityType,
    String? entityId,
    double? oldPrice,
    double? newPrice,
    double? changePercentage,
    String? changedByUserId,
    String? reason,
    DateTime? timestamp,
  }) {
    return PriceHistory(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      oldPrice: oldPrice ?? this.oldPrice,
      newPrice: newPrice ?? this.newPrice,
      changePercentage: changePercentage ?? this.changePercentage,
      changedByUserId: changedByUserId ?? this.changedByUserId,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceHistory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
