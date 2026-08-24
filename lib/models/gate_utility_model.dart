import 'dart:math';
import '../core/config/app_secrets.dart';

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
      codeId: json['codeId'] as String? ?? '',
      compoundId: json['compoundId'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      issuedByClientId: json['issuedByClientId'] as String? ?? '',
      guestName: json['guestName'] as String? ?? '',
      guestPhone: json['guestPhone'] as String? ?? '',
      guestNationalId: json['guestNationalId'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
      accessType: GateAccessType.values.firstWhere(
        (e) => e.name == json['accessType'],
        orElse: () => GateAccessType.pedestrian,
      ),
      validFromIso: json['validFromIso'] as String? ?? DateTime.now().toIso8601String(),
      validUntilIso: json['validUntilIso'] as String? ?? DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      maxScans: (json['maxScans'] as num?)?.toInt() ?? 1,
      scanCount: (json['scanCount'] as num?)?.toInt() ?? 0,
      isRevoked: json['isRevoked'] as bool? ?? false,
      revokedAtIso: json['revokedAtIso'] as String?,
      revokedByClientId: json['revokedByClientId'] as String?,
      createdAtIso: json['createdAtIso'] as String? ?? DateTime.now().toIso8601String(),
      qrPayloadString: json['qrPayloadString'] as String? ?? '',
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
    final message = 'ILIVING-GATE:$codeId:$compoundId:$epochMs';
    final signature = hmacSha256(message, AppSecrets.instance.gateSigningKey);
    return '$message:$signature';
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

  static String hmacSha256(String message, String key) {
    final List<int> msgBytes = _utf8Encode(message);
    final List<int> keyBytes = _utf8Encode(key);
    final List<int> k = List<int>.filled(64, 0);
    if (keyBytes.length > 64) {
      final hashedKey = _sha256(keyBytes);
      for (int i = 0; i < hashedKey.length; i++) {
        k[i] = hashedKey[i];
      }
    } else {
      for (int i = 0; i < keyBytes.length; i++) {
        k[i] = keyBytes[i];
      }
    }
    final List<int> ipad = List<int>.filled(64, 0);
    final List<int> opad = List<int>.filled(64, 0);
    for (int i = 0; i < 64; i++) {
      ipad[i] = k[i] ^ 0x36;
      opad[i] = k[i] ^ 0x5c;
    }
    final List<int> innerHash = _sha256([...ipad, ...msgBytes]);
    final List<int> outerHash = _sha256([...opad, ...innerHash]);
    return outerHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static List<int> _utf8Encode(String str) {
    final List<int> bytes = [];
    for (int i = 0; i < str.length; i++) {
      final code = str.codeUnitAt(i);
      if (code < 0x80) {
        bytes.add(code);
      } else if (code < 0x800) {
        bytes.add(0xc0 | (code >> 6));
        bytes.add(0x80 | (code & 0x3f));
      } else {
        bytes.add(0xe0 | (code >> 12));
        bytes.add(0x80 | ((code >> 6) & 0x3f));
        bytes.add(0x80 | (code & 0x3f));
      }
    }
    return bytes;
  }

  static List<int> _sha256(List<int> bytes) {
    final List<int> h = [
      0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
      0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ];
    final List<int> k = [
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ];
    final List<int> padded = List<int>.from(bytes);
    padded.add(0x80);
    while ((padded.length + 8) % 64 != 0) {
      padded.add(0x00);
    }
    final int lenBits = bytes.length * 8;
    for (int i = 7; i >= 0; i--) {
      padded.add((lenBits >> (i * 8)) & 0xff);
    }
    for (int chunkStart = 0; chunkStart < padded.length; chunkStart += 64) {
      final List<int> w = List<int>.filled(64, 0);
      for (int i = 0; i < 16; i++) {
        w[i] = (padded[chunkStart + i * 4] << 24) |
               (padded[chunkStart + i * 4 + 1] << 16) |
               (padded[chunkStart + i * 4 + 2] << 8) |
               (padded[chunkStart + i * 4 + 3]);
      }
      for (int i = 16; i < 64; i++) {
        final int s0 = _rightRotate(w[i - 15], 7) ^ _rightRotate(w[i - 15], 18) ^ (w[i - 15] >> 3);
        final int s1 = _rightRotate(w[i - 2], 17) ^ _rightRotate(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
      }
      int a = h[0];
      int b = h[1];
      int c = h[2];
      int d = h[3];
      int e = h[4];
      int f = h[5];
      int g = h[6];
      int hVal = h[7];
      for (int i = 0; i < 64; i++) {
        final int s1 = _rightRotate(e, 6) ^ _rightRotate(e, 11) ^ _rightRotate(e, 25);
        final int ch = (e & f) ^ (~e & g);
        final int temp1 = (hVal + s1 + ch + k[i] + w[i]) & 0xffffffff;
        final int s0 = _rightRotate(a, 2) ^ _rightRotate(a, 13) ^ _rightRotate(a, 22);
        final int maj = (a & b) ^ (a & c) ^ (b & c);
        final int temp2 = (s0 + maj) & 0xffffffff;
        hVal = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xffffffff;
      }
      h[0] = (h[0] + a) & 0xffffffff;
      h[1] = (h[1] + b) & 0xffffffff;
      h[2] = (h[2] + c) & 0xffffffff;
      h[3] = (h[3] + d) & 0xffffffff;
      h[4] = (h[4] + e) & 0xffffffff;
      h[5] = (h[5] + f) & 0xffffffff;
      h[6] = (h[6] + g) & 0xffffffff;
      h[7] = (h[7] + hVal) & 0xffffffff;
    }
    final List<int> resultBytes = [];
    for (int i = 0; i < 8; i++) {
      resultBytes.add((h[i] >> 24) & 0xff);
      resultBytes.add((h[i] >> 16) & 0xff);
      resultBytes.add((h[i] >> 8) & 0xff);
      resultBytes.add(h[i] & 0xff);
    }
    return resultBytes;
  }

  static int _rightRotate(int val, int amt) {
    return ((val >> amt) | (val << (32 - amt))) & 0xffffffff;
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
      logId: json['logId'] as String? ?? '',
      codeId: json['codeId'] as String? ?? '',
      compoundId: json['compoundId'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      guestName: json['guestName'] as String? ?? '',
      gateId: json['gateId'] as String? ?? '',
      scanTimestampIso: json['scanTimestampIso'] as String? ?? DateTime.now().toIso8601String(),
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
