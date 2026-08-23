import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/document.dart';
import '../../models/notification.dart';
import '../interfaces/document_repository.dart';
import 'firestore_notification_repository.dart';

class FirestoreDocumentRepository implements DocumentRepository {
  final FirebaseFirestore _firestore;

  FirestoreDocumentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _documentsRef =>
      _firestore.collection('documents');

  @override
  Future<DocumentItem?> getDocumentById(String documentId) async {
    final doc = await _documentsRef.doc(documentId).get();
    if (!doc.exists || doc.data() == null) return null;
    return DocumentItem.fromJson(doc.data()!);
  }

  @override
  Stream<DocumentItem?> streamDocument(String documentId) {
    return _documentsRef.doc(documentId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DocumentItem.fromJson(doc.data()!);
    });
  }

  @override
  Stream<List<DocumentItem>> streamDocumentsForUser(String userId) {
    return _documentsRef
        .where('ownerUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentItem.fromJson(doc.data()))
            .toList());
  }

  @override
  Stream<List<DocumentItem>> streamDocumentsForUnit(String unitId) {
    return _documentsRef
        .where('associatedUnitId', isEqualTo: unitId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentItem.fromJson(doc.data()))
            .toList());
  }

  @override
  Stream<List<DocumentItem>> streamAllDocuments() {
    return _documentsRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => DocumentItem.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<List<DocumentItem>> getDocuments({
    String? ownerUserId,
    String? unitId,
    String? category,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _documentsRef;

    if (ownerUserId != null && ownerUserId.isNotEmpty) {
      q = q.where('ownerUserId', isEqualTo: ownerUserId);
    }
    if (unitId != null && unitId.isNotEmpty) {
      q = q.where('associatedUnitId', isEqualTo: unitId);
    }
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _documentsRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    return snap.docs.map((doc) => DocumentItem.fromJson(doc.data())).toList();
  }

  @override
  Future<void> saveDocument(DocumentItem document) async {
    await _documentsRef.doc(document.id).set(document.toJson());
    try {
      final notif = AppNotification(
        id: 'NTF-DOC-${document.id}',
        targetUserId: document.ownerUserId ?? 'ALL',
        title: 'New Document: ${document.title}',
        titleAr: 'مستند جديد: ${document.title}',
        body: 'Official document for Unit ${document.associatedUnitId ?? ""}.',
        bodyAr: 'مستند رسمي متاح للوحدة ${document.associatedUnitId ?? ""}.',
        type: 'document_uploaded',
        unitId: document.associatedUnitId,
        pdfUrl: document.fileUrl,
        pdfTitle: document.title,
        priority: NotificationPriority.normal,
        createdAt: DateTime.now(),
      );
      await FirestoreNotificationRepository(firestore: _firestore).sendNotification(notif);
    } catch (_) {}
  }


  @override
  Future<void> updateDocument(DocumentItem document) async {
    await _documentsRef.doc(document.id).update(document.toJson());
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await _documentsRef.doc(documentId).delete();
  }

  @override
  Future<void> batchSaveDocuments(List<DocumentItem> documents) async {
    if (documents.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in documents) {
      batch.set(_documentsRef.doc(doc.id), doc.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
