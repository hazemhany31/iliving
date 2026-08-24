import 'package:flutter/foundation.dart';
import '../utils/date_time_util.dart';

enum PassType {
  oneTime,
  multiEntry,
  durationBased,
  permanent,
}

enum PassStatus {
  active,
  expired,
  revoked,
  used,
}

@immutable
class GatePass {
  final String id;
  final String compoundId;
  final String unitId;
  final String hostUserId;
  final String visitorName;
  final String visitorPhone;
  final String? visitorPlateNumber;
  final PassType passType;
  final DateTime validFrom;
  final DateTime validUntil;
  final int maxUsageCount;
  final int currentUsageCount;
  final String totpSecret;
  final String qrPayloadSigned;
  final PassStatus status;
  final DateTime createdAt;

  const GatePass({
    required this.id,
    required this.compoundId,
    required this.unitId,
    required this.hostUserId,
    required this.visitorName,
    required this.visitorPhone,
    this.visitorPlateNumber,
    this.passType = PassType.oneTime,
    required this.validFrom,
    required this.validUntil,
    this.maxUsageCount = 1,
    this.currentUsageCount = 0,
    required this.totpSecret,
    required this.qrPayloadSigned,
    this.status = PassStatus.active,
    required this.createdAt,
  });

  bool get isValid {
    final now = DateTime.now();
    return status == PassStatus.active &&
        now.isAfter(validFrom) &&
        now.isBefore(validUntil) &&
        (maxUsageCount == -1 || currentUsageCount < maxUsageCount);
  }

  factory GatePass.fromJson(Map<String, dynamic> json) {
    return GatePass(
      id: json['id'] as String? ?? '',
      compoundId: json['compoundId'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      hostUserId: json['hostUserId'] as String? ?? '',
      visitorName: json['visitorName'] as String? ?? '',
      visitorPhone: json['visitorPhone'] as String? ?? '',
      visitorPlateNumber: json['visitorPlateNumber'] as String?,
      passType: PassType.values.firstWhere(
        (e) => e.name == json['passType'],
        orElse: () => PassType.oneTime,
      ),
      validFrom: DateTimeUtil.parse(json['validFrom']),
      validUntil: DateTimeUtil.parse(
        json['validUntil'],
        fallback: DateTime.now().add(const Duration(hours: 24)),
      ),
      maxUsageCount: (json['maxUsageCount'] as num?)?.toInt() ?? 1,
      currentUsageCount: (json['currentUsageCount'] as num?)?.toInt() ?? 0,
      totpSecret: json['totpSecret'] as String? ?? '',
      qrPayloadSigned: json['qrPayloadSigned'] as String? ?? '',
      status: PassStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PassStatus.active,
      ),
      createdAt: DateTimeUtil.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'compoundId': compoundId,
      'unitId': unitId,
      'hostUserId': hostUserId,
      'visitorName': visitorName,
      'visitorPhone': visitorPhone,
      'visitorPlateNumber': visitorPlateNumber,
      'passType': passType.name,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'maxUsageCount': maxUsageCount,
      'currentUsageCount': currentUsageCount,
      'totpSecret': totpSecret,
      'qrPayloadSigned': qrPayloadSigned,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  GatePass copyWith({
    String? id,
    String? compoundId,
    String? unitId,
    String? hostUserId,
    String? visitorName,
    String? visitorPhone,
    String? visitorPlateNumber,
    PassType? passType,
    DateTime? validFrom,
    DateTime? validUntil,
    int? maxUsageCount,
    int? currentUsageCount,
    String? totpSecret,
    String? qrPayloadSigned,
    PassStatus? status,
    DateTime? createdAt,
  }) {
    return GatePass(
      id: id ?? this.id,
      compoundId: compoundId ?? this.compoundId,
      unitId: unitId ?? this.unitId,
      hostUserId: hostUserId ?? this.hostUserId,
      visitorName: visitorName ?? this.visitorName,
      visitorPhone: visitorPhone ?? this.visitorPhone,
      visitorPlateNumber: visitorPlateNumber ?? this.visitorPlateNumber,
      passType: passType ?? this.passType,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      maxUsageCount: maxUsageCount ?? this.maxUsageCount,
      currentUsageCount: currentUsageCount ?? this.currentUsageCount,
      totpSecret: totpSecret ?? this.totpSecret,
      qrPayloadSigned: qrPayloadSigned ?? this.qrPayloadSigned,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GatePass && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
