import '../models/document.dart';
import '../repositories/interfaces/document_repository.dart';

class DocumentService {
  final DocumentRepository _documentRepository;

  DocumentService({required DocumentRepository documentRepository})
      : _documentRepository = documentRepository;

  Future<DocumentItem> archiveContractDocument({
    required String contractId,
    required String ownerUserId,
    required String unitId,
    required String fileUrl,
  }) async {
    final doc = DocumentItem(
      id: 'DOC-CTR-$contractId',
      title: 'Sales Agreement Contract - $contractId',
      description: 'Official tri-party sales agreement contract PDF.',
      category: DocumentCategory.contract,
      fileUrl: fileUrl,
      fileExtension: 'pdf',
      ownerUserId: ownerUserId,
      associatedUnitId: unitId,
      createdAt: DateTime.now(),
    );

    await _documentRepository.saveDocument(doc);
    return doc;
  }
}
