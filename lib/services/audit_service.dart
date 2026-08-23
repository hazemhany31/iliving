import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';

class AuditService {
  final FirebaseFirestore _firestore;

  AuditService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> logAction({
    required String actorUserId,
    required String actorRole,
    required String actionType,
    required String targetCollection,
    required String targetDocumentId,
    Map<String, dynamic> payloadDelta = const {},
  }) async {
    final audit = AuditLog(
      id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
      actorUserId: actorUserId,
      actorRole: actorRole,
      actionType: actionType,
      targetCollection: targetCollection,
      targetDocumentId: targetDocumentId,
      payloadDelta: payloadDelta,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('audit_logs').doc(audit.id).set(audit.toJson());
  }
}
