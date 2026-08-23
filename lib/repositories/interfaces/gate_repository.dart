import '../../models/gate_pass.dart';

abstract class GateRepository {
  Future<GatePass?> getPassById(String passId);
  Stream<GatePass?> streamPass(String passId);
  Stream<List<GatePass>> streamPassesForUser(String userId);
  Stream<List<GatePass>> streamAllPasses();
  Future<List<GatePass>> getPasses({
    String? hostUserId,
    String? visitorName,
    PassStatus? status,
    int? limit,
    String? startAfterId,
  });
  Future<void> createPass(GatePass pass);
  Future<void> updatePass(GatePass pass);
  Future<void> revokePass(String passId);
  Future<void> deletePass(String passId);
  Future<void> logAccessEntry({
    required String passId,
    required String gateId,
    required String securityOfficerId,
    required bool granted,
  });
}
