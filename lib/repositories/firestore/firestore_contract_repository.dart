import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/contract.dart';
import '../interfaces/contract_repository.dart';

class FirestoreContractRepository implements ContractRepository {
  final FirebaseFirestore _firestore;

  FirestoreContractRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _contractsRef =>
      _firestore.collection('contracts');

  @override
  Future<Contract?> getContractById(String id) async {
    final doc = await _contractsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Contract.fromJson(doc.data()!);
  }

  @override
  Stream<Contract?> streamContract(String id) {
    return _contractsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Contract.fromJson(doc.data()!);
    });
  }

  @override
  Stream<List<Contract>> streamContractsForUser(String userId) {
    return _contractsRef
        .where('buyerUserId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Contract.fromJson(d.data())).toList());
  }

  @override
  Stream<List<Contract>> streamAllContracts() {
    return _contractsRef
        .snapshots()
        .map((snap) => snap.docs.map((d) => Contract.fromJson(d.data())).toList());
  }

  @override
  Future<List<Contract>> getContracts({
    String? buyerUserId,
    String? compoundId,
    String? clientCode,
    SignatureStatus? status,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _contractsRef;

    if (buyerUserId != null && buyerUserId.isNotEmpty) {
      q = q.where('buyerUserId', isEqualTo: buyerUserId);
    }
    if (compoundId != null && compoundId.isNotEmpty) {
      q = q.where('compoundId', isEqualTo: compoundId);
    }
    if (clientCode != null && clientCode.isNotEmpty) {
      q = q.where('clientCode', isEqualTo: clientCode);
    }
    if (status != null) {
      q = q.where('signatureStatus', isEqualTo: status.name);
    }

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _contractsRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    var list = snap.docs.map((d) => Contract.fromJson(d.data())).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final queryLower = searchQuery.trim().toLowerCase();
      list = list.where((c) {
        return c.contractNumber.toLowerCase().contains(queryLower) ||
            (c.clientCode != null && c.clientCode!.toLowerCase().contains(queryLower)) ||
            c.unitId.toLowerCase().contains(queryLower);
      }).toList();
    }

    return list;
  }

  @override
  Future<void> createContract(Contract contract) async {
    await _contractsRef.doc(contract.id).set(contract.toJson());
  }

  @override
  Future<void> updateContract(Contract contract) async {
    await _contractsRef.doc(contract.id).update(contract.toJson());
  }

  @override
  Future<void> deleteContract(String id) async {
    await _contractsRef.doc(id).delete();
  }

  @override
  Future<void> batchSaveContracts(List<Contract> contracts) async {
    if (contracts.isEmpty) return;
    final batch = _firestore.batch();
    for (final c in contracts) {
      batch.set(_contractsRef.doc(c.id), c.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
