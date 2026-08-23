import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/gate_pass.dart';
import '../repositories/interfaces/gate_repository.dart';

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
    final qrPayloadSigned = _signQrPayload(
      passId: passId,
      unitId: unitId,
      validUntil: validUntil,
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

  bool verifyOnlinePassPayload(String payload, String serverSecretKey) {
    try {
      final parts = payload.split('.');
      if (parts.length != 2) return false;

      final dataJson = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
      final signature = parts[1];

      final hmac = Hmac(sha256, utf8.encode(serverSecretKey));
      final expectedSignature = hmac.convert(utf8.encode(dataJson)).toString();

      if (signature != expectedSignature) return false;

      final Map<String, dynamic> data = jsonDecode(dataJson);
      final validUntil = DateTime.parse(data['validUntil'] as String);
      return DateTime.now().isBefore(validUntil);
    } catch (_) {
      return false;
    }
  }

  String _generateTotpSecret(String uid, String passId) {
    final bytes = utf8.encode('$uid:$passId:${DateTime.now().microsecondsSinceEpoch}');
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  String _signQrPayload({
    required String passId,
    required String unitId,
    required DateTime validUntil,
    required String secretKey,
  }) {
    final dataJson = jsonEncode({
      'passId': passId,
      'unitId': unitId,
      'validUntil': validUntil.toIso8601String(),
    });
    final base64Data = base64Url.encode(utf8.encode(dataJson));
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final signature = hmac.convert(utf8.encode(dataJson)).toString();
    return '$base64Data.$signature';
  }
}
