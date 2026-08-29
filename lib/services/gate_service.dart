import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/gate_pass.dart';
import '../repositories/interfaces/gate_repository.dart';

class GatePassVerificationResult {
  final bool isValid;
  final String statusLabel;
  final String message;
  final GatePass? pass;

  const GatePassVerificationResult({
    required this.isValid,
    required this.statusLabel,
    required this.message,
    this.pass,
  });

  static GatePassVerificationResult valid(GatePass pass) =>
      GatePassVerificationResult(
        isValid: true,
        statusLabel: 'VALID',
        message: 'Pass verified and accepted at the gate.',
        pass: pass,
      );

  static GatePassVerificationResult invalid(
    String statusLabel,
    String message, {
    GatePass? pass,
  }) =>
      GatePassVerificationResult(
        isValid: false,
        statusLabel: statusLabel,
        message: message,
        pass: pass,
      );
}

class GateService {
  final GateRepository _gateRepository;

  GateRepository get gateRepository => _gateRepository;

  GateService({required GateRepository gateRepository})
      : _gateRepository = gateRepository;

  GatePass generatePass({
    required String compoundId,
    required String unitId,
    required String hostUserId,
    required String visitorName,
    required String visitorPhone,
    String? visitorPlateNumber,
    PassType passType = PassType.oneTime,
    required DateTime validFrom,
    required DateTime validUntil,
    int maxUsageCount = 1,
    required String serverSecretKey,
  }) {
    final passId = 'PASS-${DateTime.now().millisecondsSinceEpoch}';
    final totpSecret = _generateTotpSecret(hostUserId, passId);
    final qrPayloadSigned = buildSignedQrPayload(
      pass: GatePass(
        id: passId,
        compoundId: compoundId,
        unitId: unitId,
        hostUserId: hostUserId,
        visitorName: visitorName,
        visitorPhone: visitorPhone,
        visitorPlateNumber: visitorPlateNumber,
        passType: passType,
        validFrom: validFrom,
        validUntil: validUntil,
        maxUsageCount: maxUsageCount,
        totpSecret: totpSecret,
        qrPayloadSigned: '',
        createdAt: DateTime.now(),
      ),
      secretKey: serverSecretKey,
    );

    return GatePass(
      id: passId,
      compoundId: compoundId,
      unitId: unitId,
      hostUserId: hostUserId,
      visitorName: visitorName,
      visitorPhone: visitorPhone,
      visitorPlateNumber: visitorPlateNumber,
      passType: passType,
      validFrom: validFrom,
      validUntil: validUntil,
      maxUsageCount: maxUsageCount,
      totpSecret: totpSecret,
      qrPayloadSigned: qrPayloadSigned,
      createdAt: DateTime.now(),
    );
  }

  String buildSignedQrPayload({
    required GatePass pass,
    required String secretKey,
  }) {
    final payloadData = {
      'passId': pass.id,
      'compoundId': pass.compoundId,
      'unitId': pass.unitId,
      'hostUserId': pass.hostUserId,
      'visitorName': pass.visitorName,
      'visitorPhone': pass.visitorPhone,
      'visitorType': pass.passType.name,
      'validFrom': pass.validFrom.toUtc().toIso8601String(),
      'validUntil': pass.validUntil.toUtc().toIso8601String(),
      'maxUsageCount': pass.maxUsageCount,
      'currentUsageCount': pass.currentUsageCount,
      'status': pass.status.name,
    };

    final payloadJson = jsonEncode(payloadData);
    final base64Payload = base64Url.encode(utf8.encode(payloadJson));
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final signature = hmac.convert(utf8.encode(payloadJson)).toString();
    return 'ILIVING-GATE-PASS:$base64Payload:$signature';
  }

  bool verifyPassQrPayload(String payload, String secretKey) {
    try {
      final decoded = _decodeSignedPayload(payload, secretKey);
      if (decoded == null) return false;
      final validUntil =
          DateTime.tryParse(decoded['validUntil'] as String? ?? '');
      if (validUntil == null) return false;
      return DateTime.now().isBefore(validUntil);
    } catch (_) {
      return false;
    }
  }

  static GatePassVerificationResult evaluateGatePass(GatePass pass) {
    final now = DateTime.now();

    if (pass.status != PassStatus.active) {
      return GatePassVerificationResult.invalid(
          'INVALID', 'Pass is not active.',
          pass: pass);
    }
    if (now.isBefore(pass.validFrom)) {
      return GatePassVerificationResult.invalid(
          'NOT YET VALID', 'Pass is not yet valid.',
          pass: pass);
    }
    if (now.isAfter(pass.validUntil)) {
      return GatePassVerificationResult.invalid('EXPIRED', 'Pass has expired.',
          pass: pass);
    }
    if (pass.maxUsageCount != -1 &&
        pass.currentUsageCount >= pass.maxUsageCount) {
      return GatePassVerificationResult.invalid(
          'USED', 'Pass has reached its allowed usage count.',
          pass: pass);
    }

    return GatePassVerificationResult.valid(pass);
  }

  Future<GatePassVerificationResult> verifyAndLoadGatePass({
    required String payload,
    required String secretKey,
    required GateRepository gateRepository,
  }) async {
    try {
      final decoded = _decodeSignedPayload(payload, secretKey);
      if (decoded == null) {
        return GatePassVerificationResult.invalid(
            'INVALID', 'Cryptographic signature verification failed.');
      }

      final passId = decoded['passId'] as String?;
      if (passId == null || passId.trim().isEmpty) {
        return GatePassVerificationResult.invalid(
            'INVALID', 'QR payload is missing the pass ID.');
      }

      final pass = await gateRepository.getPassById(passId);
      if (pass == null) {
        return GatePassVerificationResult.invalid(
          'NOT FOUND',
          'Pass not found in Firestore.',
        );
      }

      final evaluation = evaluateGatePass(pass);
      if (evaluation.isValid) {
        return GatePassVerificationResult.valid(pass);
      }
      return GatePassVerificationResult.invalid(
        evaluation.statusLabel,
        evaluation.message,
        pass: pass,
      );
    } catch (_) {
      return GatePassVerificationResult.invalid(
          'INVALID', 'Unable to verify QR payload.');
    }
  }

  bool verifyOnlinePassPayload(String payload, String serverSecretKey) {
    return verifyPassQrPayload(payload, serverSecretKey);
  }

  Map<String, dynamic>? _decodeSignedPayload(String payload, String secretKey) {
    final parts = payload.split(':');
    if (parts.length != 3 || parts[0] != 'ILIVING-GATE-PASS') {
      return null;
    }

    final encodedData = parts[1];
    final signature = parts[2];
    final decodedJson =
        utf8.decode(base64Url.decode(base64Url.normalize(encodedData)));
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final expectedSignature = hmac.convert(utf8.encode(decodedJson)).toString();

    if (signature != expectedSignature) {
      return null;
    }

    final decoded = jsonDecode(decodedJson);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return decoded;
  }

  String _generateTotpSecret(String uid, String passId) {
    final bytes =
        utf8.encode('$uid:$passId:${DateTime.now().microsecondsSinceEpoch}');
    return sha256.convert(bytes).toString().substring(0, 16);
  }
}
