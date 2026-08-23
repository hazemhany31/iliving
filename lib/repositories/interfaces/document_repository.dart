import '../../models/document.dart';

abstract class DocumentRepository {
  Future<DocumentItem?> getDocumentById(String documentId);
  Stream<DocumentItem?> streamDocument(String documentId);
  Stream<List<DocumentItem>> streamDocumentsForUser(String userId);
  Stream<List<DocumentItem>> streamDocumentsForUnit(String unitId);
  Stream<List<DocumentItem>> streamAllDocuments();
  Future<List<DocumentItem>> getDocuments({
    String? ownerUserId,
    String? unitId,
    String? category,
    int? limit,
    String? startAfterId,
  });
  Future<void> saveDocument(DocumentItem document);
  Future<void> updateDocument(DocumentItem document);
  Future<void> deleteDocument(String documentId);
  Future<void> batchSaveDocuments(List<DocumentItem> documents);
}
