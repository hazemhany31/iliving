import 'dart:math';

enum GateAccessType { pedestrian, vehicle, delivery, contractor }

enum GateScanResult {
  granted,
  deniedExpired,
  deniedRevoked,
  deniedMaxScans,
  deniedNotValidYet,
}

class GateAccessCode {
  final String codeId;
  final String compoundId;
  final String unitId;
  final String issuedByClientId;
  final String guestName;
  final String guestPhone;
  final String? guestNationalId;
  final String? vehiclePlate;
  final GateAccessType accessType;
  final String validFromIso;
  final String validUntilIso;
  final int maxScans;
  final int scanCount;
  final bool isRevoked;
  final String? revokedAtIso;
  final String? revokedByClientId;
  final String createdAtIso;
  final String qrPayloadString;
  final String? notes;

  const GateAccessCode({
    required this.codeId,
    required this.compoundId,
    required this.unitId,
    required this.issuedByClientId,
    required this.guestName,
    required this.guestPhone,
    this.guestNationalId,
    this.vehiclePlate,
    required this.accessType,
    required this.validFromIso,
    required this.validUntilIso,
    required this.maxScans,
    required this.scanCount,
    required this.isRevoked,
    this.revokedAtIso,
    this.revokedByClientId,
    required this.createdAtIso,
    required this.qrPayloadString,
    this.notes,
  });

  bool get isExpired {
    final expiry = DateTime.tryParse(validUntilIso);
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  bool get hasScansRemaining => scanCount < maxScans;

  bool get isActive => !isRevoked && !isExpired && hasScansRemaining;

  String get accessTypeLabel {
    switch (accessType) {
      case GateAccessType.pedestrian:
        return 'Pedestrian';
      case GateAccessType.vehicle:
        return 'Vehicle';
      case GateAccessType.delivery:
        return 'Delivery';
      case GateAccessType.contractor:
        return 'Contractor';
    }
  }

  factory GateAccessCode.fromJson(Map<String, dynamic> json) {
    return GateAccessCode(
      codeId: json['codeId'] as String,
      compoundId: json['compoundId'] as String,
      unitId: json['unitId'] as String,
      issuedByClientId: json['issuedByClientId'] as String,
      guestName: json['guestName'] as String,
      guestPhone: json['guestPhone'] as String,
      guestNationalId: json['guestNationalId'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
      accessType: GateAccessType.values.firstWhere(
        (e) => e.name == json['accessType'],
        orElse: () => GateAccessType.pedestrian,
      ),
      validFromIso: json['validFromIso'] as String,
      validUntilIso: json['validUntilIso'] as String,
      maxScans: json['maxScans'] as int,
      scanCount: json['scanCount'] as int,
      isRevoked: json['isRevoked'] as bool,
      revokedAtIso: json['revokedAtIso'] as String?,
      revokedByClientId: json['revokedByClientId'] as String?,
      createdAtIso: json['createdAtIso'] as String,
      qrPayloadString: json['qrPayloadString'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codeId': codeId,
      'compoundId': compoundId,
      'unitId': unitId,
      'issuedByClientId': issuedByClientId,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'guestNationalId': guestNationalId,
      'vehiclePlate': vehiclePlate,
      'accessType': accessType.name,
      'validFromIso': validFromIso,
      'validUntilIso': validUntilIso,
      'maxScans': maxScans,
      'scanCount': scanCount,
      'isRevoked': isRevoked,
      'revokedAtIso': revokedAtIso,
      'revokedByClientId': revokedByClientId,
      'createdAtIso': createdAtIso,
      'qrPayloadString': qrPayloadString,
      'notes': notes,
    };
  }

  GateAccessCode copyWith({
    String? codeId,
    String? compoundId,
    String? unitId,
    String? issuedByClientId,
    String? guestName,
    String? guestPhone,
    String? guestNationalId,
    String? vehiclePlate,
    GateAccessType? accessType,
    String? validFromIso,
    String? validUntilIso,
    int? maxScans,
    int? scanCount,
    bool? isRevoked,
    String? revokedAtIso,
    String? revokedByClientId,
    String? createdAtIso,
    String? qrPayloadString,
    String? notes,
  }) {
    return GateAccessCode(
      codeId: codeId ?? this.codeId,
      compoundId: compoundId ?? this.compoundId,
      unitId: unitId ?? this.unitId,
      issuedByClientId: issuedByClientId ?? this.issuedByClientId,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      guestNationalId: guestNationalId ?? this.guestNationalId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      accessType: accessType ?? this.accessType,
      validFromIso: validFromIso ?? this.validFromIso,
      validUntilIso: validUntilIso ?? this.validUntilIso,
      maxScans: maxScans ?? this.maxScans,
      scanCount: scanCount ?? this.scanCount,
      isRevoked: isRevoked ?? this.isRevoked,
      revokedAtIso: revokedAtIso ?? this.revokedAtIso,
      revokedByClientId: revokedByClientId ?? this.revokedByClientId,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      qrPayloadString: qrPayloadString ?? this.qrPayloadString,
      notes: notes ?? this.notes,
    );
  }

  static String buildQrPayload({
    required String codeId,
    required String compoundId,
    required DateTime validUntil,
  }) {
    final epochMs = validUntil.millisecondsSinceEpoch;
    return 'IHOME-GATE:$codeId:$compoundId:$epochMs';
  }

  static GateAccessCode generate({
    required String compoundId,
    required String unitId,
    required String issuedByClientId,
    required String guestName,
    required String guestPhone,
    required GateAccessType accessType,
    required Duration validity,
    String? guestNationalId,
    String? vehiclePlate,
    int maxScans = 1,
    String? notes,
  }) {
    final rand = Random.secure();
    final codeId = List.generate(
      32,
      (_) => rand.nextInt(16).toRadixString(16),
    ).join();

    final now = DateTime.now().toUtc();
    final validUntil = now.add(validity);

    final qrPayload = buildQrPayload(
      codeId: codeId,
      compoundId: compoundId,
      validUntil: validUntil,
    );

    return GateAccessCode(
      codeId: codeId,
      compoundId: compoundId,
      unitId: unitId,
      issuedByClientId: issuedByClientId,
      guestName: guestName,
      guestPhone: guestPhone,
      guestNationalId: guestNationalId,
      vehiclePlate: vehiclePlate,
      accessType: accessType,
      validFromIso: now.toIso8601String(),
      validUntilIso: validUntil.toIso8601String(),
      maxScans: maxScans,
      scanCount: 0,
      isRevoked: false,
      createdAtIso: now.toIso8601String(),
      qrPayloadString: qrPayload,
      notes: notes,
    );
  }
}

class GateAccessLog {
  final String logId;
  final String codeId;
  final String compoundId;
  final String unitId;
  final String guestName;
  final String gateId;
  final String scanTimestampIso;
  final GateScanResult scanResult;
  final String? operatorId;
  final String? vehiclePlate;
  final String? cameraSnapshotUrl;

  const GateAccessLog({
    required this.logId,
    required this.codeId,
    required this.compoundId,
    required this.unitId,
    required this.guestName,
    required this.gateId,
    required this.scanTimestampIso,
    required this.scanResult,
    this.operatorId,
    this.vehiclePlate,
    this.cameraSnapshotUrl,
  });

  String get scanResultLabel {
    switch (scanResult) {
      case GateScanResult.granted:
        return 'Access Granted';
      case GateScanResult.deniedExpired:
        return 'Denied — Code Expired';
      case GateScanResult.deniedRevoked:
        return 'Denied — Code Revoked';
      case GateScanResult.deniedMaxScans:
        return 'Denied — Max Scans Reached';
      case GateScanResult.deniedNotValidYet:
        return 'Denied — Not Yet Valid';
    }
  }

  bool get wasGranted => scanResult == GateScanResult.granted;

  factory GateAccessLog.fromJson(Map<String, dynamic> json) {
    return GateAccessLog(
      logId: json['logId'] as String,
      codeId: json['codeId'] as String,
      compoundId: json['compoundId'] as String,
      unitId: json['unitId'] as String,
      guestName: json['guestName'] as String,
      gateId: json['gateId'] as String,
      scanTimestampIso: json['scanTimestampIso'] as String,
      scanResult: GateScanResult.values.firstWhere(
        (e) => e.name == json['scanResult'],
        orElse: () => GateScanResult.deniedExpired,
      ),
      operatorId: json['operatorId'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
      cameraSnapshotUrl: json['cameraSnapshotUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'codeId': codeId,
      'compoundId': compoundId,
      'unitId': unitId,
      'guestName': guestName,
      'gateId': gateId,
      'scanTimestampIso': scanTimestampIso,
      'scanResult': scanResult.name,
      'operatorId': operatorId,
      'vehiclePlate': vehiclePlate,
      'cameraSnapshotUrl': cameraSnapshotUrl,
    };
  }

  static GateAccessLog recordScan({
    required GateAccessCode code,
    required String gateId,
    required GateScanResult result,
    String? operatorId,
    String? vehiclePlate,
    String? cameraSnapshotUrl,
  }) {
    final rand = Random.secure();
    final logId = List.generate(
      24,
      (_) => rand.nextInt(16).toRadixString(16),
    ).join();

    return GateAccessLog(
      logId: logId,
      codeId: code.codeId,
      compoundId: code.compoundId,
      unitId: code.unitId,
      guestName: code.guestName,
      gateId: gateId,
      scanTimestampIso: DateTime.now().toUtc().toIso8601String(),
      scanResult: result,
      operatorId: operatorId,
      vehiclePlate: vehiclePlate ?? code.vehiclePlate,
      cameraSnapshotUrl: cameraSnapshotUrl,
    );
  }

  static GateScanResult evaluateScan(GateAccessCode code) {
    final now = DateTime.now().toUtc();

    if (code.isRevoked) return GateScanResult.deniedRevoked;

    final validFrom = DateTime.tryParse(code.validFromIso);
    if (validFrom != null && now.isBefore(validFrom)) {
      return GateScanResult.deniedNotValidYet;
    }

    final validUntil = DateTime.tryParse(code.validUntilIso);
    if (validUntil == null || now.isAfter(validUntil)) {
      return GateScanResult.deniedExpired;
    }

    if (code.scanCount >= code.maxScans) {
      return GateScanResult.deniedMaxScans;
    }

    return GateScanResult.granted;
  }
}
