import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/core/config/app_secrets.dart';
import 'package:iliving/models/gate_pass.dart';
import 'package:iliving/repositories/interfaces/gate_repository.dart';
import 'package:iliving/services/gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    storageChannel,
    (call) async {
      if (call.method == 'write') {
        return null;
      }
      if (call.method == 'read') {
        return null;
      }
      if (call.method == 'delete') {
        return null;
      }
      if (call.method == 'deleteAll') {
        return null;
      }
      return null;
    },
  );

  setUp(() async {
    await AppSecrets.instance.setGateSigningKey('test_gate_signing_secret_123');
  });

  test('signed gate pass payload remains valid when unexpired and unused', () {
    final service = GateService(gateRepository: _TestGateRepository());
    final pass = service.generatePass(
      compoundId: 'compound_01',
      unitId: 'A-101',
      hostUserId: 'host_01',
      visitorName: 'Jane Doe',
      visitorPhone: '+966500000000',
      passType: PassType.durationBased,
      validFrom: DateTime.now().subtract(const Duration(minutes: 5)),
      validUntil: DateTime.now().add(const Duration(hours: 2)),
      maxUsageCount: 1,
      serverSecretKey: AppSecrets.instance.gateSigningKey,
    );

    expect(pass.qrPayloadSigned, isNotEmpty);
    expect(pass.qrPayloadSigned.startsWith('ILIVING-GATE-PASS:'), isTrue);
    expect(
        service.verifyPassQrPayload(
            pass.qrPayloadSigned, AppSecrets.instance.gateSigningKey),
        isTrue);

    final evaluation = GateService.evaluateGatePass(pass);
    expect(evaluation.isValid, isTrue);
    expect(evaluation.statusLabel, 'VALID');
  });

  test('expired or fully used gate passes are invalid', () {
    final expiredPass = GatePass(
      id: 'PASS-EXPIRED',
      compoundId: 'compound_01',
      unitId: 'A-101',
      hostUserId: 'host_01',
      visitorName: 'Jane Doe',
      visitorPhone: '+966500000000',
      passType: PassType.durationBased,
      validFrom: DateTime.now().subtract(const Duration(hours: 3)),
      validUntil: DateTime.now().subtract(const Duration(minutes: 5)),
      maxUsageCount: 1,
      currentUsageCount: 0,
      totpSecret: 'abc123',
      qrPayloadSigned: 'ILIVING-GATE-PASS:test:expired',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    );

    final usedPass = expiredPass.copyWith(
      validUntil: DateTime.now().add(const Duration(hours: 2)),
      currentUsageCount: 1,
      qrPayloadSigned: 'ILIVING-GATE-PASS:test:used',
    );

    expect(GateService.evaluateGatePass(expiredPass).isValid, isFalse);
    expect(GateService.evaluateGatePass(expiredPass).statusLabel,
        contains('EXPIRED'));
    expect(GateService.evaluateGatePass(usedPass).isValid, isFalse);
    expect(
        GateService.evaluateGatePass(usedPass).statusLabel, contains('USED'));
  });
}

class _TestGateRepository implements GateRepository {
  @override
  Future<void> createPass(GatePass pass) async {}

  @override
  Future<GatePass?> getPassById(String passId) async => null;

  @override
  Future<void> logAccessEntry({
    required String passId,
    required String gateId,
    required String securityOfficerId,
    required bool granted,
  }) async {}

  @override
  Future<void> revokePass(String passId) async {}

  @override
  Future<void> updatePass(GatePass pass) async {}

  @override
  Stream<List<GatePass>> streamAllPasses() => const Stream.empty();

  @override
  Stream<GatePass?> streamPass(String passId) => const Stream.empty();

  @override
  Stream<List<GatePass>> streamPassesForUser(String userId) =>
      const Stream.empty();

  @override
  Future<List<GatePass>> getPasses({
    String? hostUserId,
    String? visitorName,
    PassStatus? status,
    int? limit,
    String? startAfterId,
  }) async =>
      const <GatePass>[];

  @override
  Future<void> deletePass(String passId) async {}
}
