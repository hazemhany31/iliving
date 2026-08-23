import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/gate_pass.dart';
import '../interfaces/gate_repository.dart';

class FirestoreGateRepository implements GateRepository {
  final FirebaseFirestore _firestore;

  FirestoreGateRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _passesRef =>
      _firestore.collection('gate_passes');

  @override
  Future<GatePass?> getPassById(String passId) async {
    final doc = await _passesRef.doc(passId).get();
    if (!doc.exists || doc.data() == null) return null;
    return GatePass.fromJson(doc.data()!);
  }

  @override
  Stream<GatePass?> streamPass(String passId) {
    return _passesRef.doc(passId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return GatePass.fromJson(doc.data()!);
    });
  }

  @override
  Stream<List<GatePass>> streamPassesForUser(String userId) {
    return _passesRef
        .where('hostUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GatePass.fromJson(doc.data())).toList());
  }

  @override
  Stream<List<GatePass>> streamAllPasses() {
    return _passesRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => GatePass.fromJson(doc.data())).toList(),
        );
  }

  @override
  Future<List<GatePass>> getPasses({
    String? hostUserId,
    String? visitorName,
    PassStatus? status,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _passesRef;

    if (hostUserId != null && hostUserId.isNotEmpty) {
      q = q.where('hostUserId', isEqualTo: hostUserId);
    }
    if (status != null) {
      q = q.where('status', isEqualTo: status.name);
    }

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _passesRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    var list = snap.docs.map((doc) => GatePass.fromJson(doc.data())).toList();

    if (visitorName != null && visitorName.trim().isNotEmpty) {
      final vLower = visitorName.trim().toLowerCase();
      list = list.where((p) => p.visitorName.toLowerCase().contains(vLower)).toList();
    }

    return list;
  }

  @override
  Future<void> createPass(GatePass pass) async {
    await _passesRef.doc(pass.id).set(pass.toJson());
  }

  @override
  Future<void> updatePass(GatePass pass) async {
    await _passesRef.doc(pass.id).update(pass.toJson());
  }

  @override
  Future<void> revokePass(String passId) async {
    await _passesRef.doc(passId).update({'status': PassStatus.revoked.name});
  }

  @override
  Future<void> deletePass(String passId) async {
    await _passesRef.doc(passId).delete();
  }

  @override
  Future<void> logAccessEntry({
    required String passId,
    required String gateId,
    required String securityOfficerId,
    required bool granted,
  }) async {
    await _firestore.collection('access_logs').add({
      'passId': passId,
      'gateId': gateId,
      'securityOfficerId': securityOfficerId,
      'accessGranted': granted,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (granted) {
      await _passesRef.doc(passId).update({
        'currentUsageCount': FieldValue.increment(1),
      });
    }
  }
}
