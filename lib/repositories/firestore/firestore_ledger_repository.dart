import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/unit_ledger_model.dart';
import '../../models/installment.dart';
import '../interfaces/ledger_repository.dart';

class FirestoreLedgerRepository implements LedgerRepository {
  final FirebaseFirestore _firestore;

  FirestoreLedgerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ledgersRef =>
      _firestore.collection('ledgers');

  @override
  Future<UnitLedger?> getLedgerByUnitId(String unitId) async {
    final query = await _ledgersRef.where('unitId', isEqualTo: unitId).limit(1).get();
    if (query.docs.isEmpty) return null;
    return UnitLedger.fromJson(query.docs.first.data());
  }

  @override
  Stream<UnitLedger?> streamLedgerForUnit(String unitId) {
    return _ledgersRef
        .where('unitId', isEqualTo: unitId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return UnitLedger.fromJson(snapshot.docs.first.data());
    });
  }

  @override
  Stream<List<UnitLedger>> streamAllLedgers() {
    return _ledgersRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => UnitLedger.fromJson(doc.data())).toList(),
        );
  }

  @override
  Stream<List<Installment>> streamInstallmentsForUser(String userId) {
    return _firestore
        .collectionGroup('installments')
        .where('buyerUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Installment.fromJson(doc.data())).toList());
  }

  Installment _parseInstallmentDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    final docId = doc.id;
    final parentContractId = doc.reference.parent.parent?.id ?? '';

    if (!data.containsKey('id') || (data['id'] as String? ?? '').isEmpty) {
      data['id'] = docId;
    }
    if (!data.containsKey('contractId') || (data['contractId'] as String? ?? '').isEmpty) {
      data['contractId'] = parentContractId;
    }
    return Installment.fromJson(data);
  }

  /// Streams all installments belonging to a single contract, ordered by
  /// [sequenceNumber] ascending. Used by the payment history panel.
  Stream<List<Installment>> streamInstallmentsForContract(String contractId) {
    return _firestore
        .collection('contracts')
        .doc(contractId)
        .collection('installments')
        .orderBy('sequenceNumber')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _parseInstallmentDoc(doc)).toList());
  }

  /// Fetches all installments for a single contract once (non-streaming).
  Future<List<Installment>> getInstallmentsForContract(String contractId) async {
    final snap = await _firestore
        .collection('contracts')
        .doc(contractId)
        .collection('installments')
        .orderBy('sequenceNumber')
        .get();
    return snap.docs.map((doc) => _parseInstallmentDoc(doc)).toList();
  }

  @override
  Stream<List<Installment>> streamAllInstallments() {
    return _firestore
        .collectionGroup('installments')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _parseInstallmentDoc(doc)).toList());
  }

  /// A bandwidth-capped variant for admin list screens. Limits to [limit]
  /// records to prevent downloading the full installments collection group.
  Stream<List<Installment>> streamAllInstallmentsLimited({int limit = 500}) {
    return _firestore
        .collectionGroup('installments')
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _parseInstallmentDoc(doc)).toList());
  }

  @override
  Future<List<Installment>> getAllInstallments() async {
    final snap = await _firestore.collectionGroup('installments').get();
    return snap.docs.map((doc) => _parseInstallmentDoc(doc)).toList();
  }

  @override
  Future<List<UnitLedger>> getLedgers({
    String? compoundId,
    String? clientId,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _ledgersRef;

    if (compoundId != null && compoundId.isNotEmpty) {
      q = q.where('compoundId', isEqualTo: compoundId);
    }
    if (clientId != null && clientId.isNotEmpty) {
      q = q.where('clientId', isEqualTo: clientId);
    }

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _ledgersRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    return snap.docs.map((doc) => UnitLedger.fromJson(doc.data())).toList();
  }

  @override
  Future<void> saveLedger(UnitLedger ledger) async {
    await _ledgersRef.doc(ledger.unitId).set(ledger.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> createInstallment(Installment installment) async {
    final contractId = installment.contractId.isNotEmpty
        ? installment.contractId
        : (installment.unitId.isNotEmpty ? 'CNT-${installment.unitId}' : 'CNT-DEFAULT');
    final instId = installment.id.isNotEmpty
        ? installment.id
        : 'INS-$contractId-${installment.sequenceNumber}';

    final toSave = installment.copyWith(
      id: instId,
      contractId: contractId,
    );

    final ref = _firestore
        .collection('contracts')
        .doc(contractId)
        .collection('installments')
        .doc(instId);
    await ref.set(toSave.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateInstallment(Installment installment) async {
    final contractId = installment.contractId.isNotEmpty
        ? installment.contractId
        : (installment.unitId.isNotEmpty ? 'CNT-${installment.unitId}' : 'CNT-DEFAULT');
    final instId = installment.id.isNotEmpty
        ? installment.id
        : 'INS-$contractId-${installment.sequenceNumber}';

    final toSave = installment.copyWith(
      id: instId,
      contractId: contractId,
    );

    await _firestore
        .collection('contracts')
        .doc(contractId)
        .collection('installments')
        .doc(instId)
        .set(toSave.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteInstallment(String contractId, String installmentId) async {
    await _firestore
        .collection('contracts')
        .doc(contractId)
        .collection('installments')
        .doc(installmentId)
        .delete();
  }

  @override
  Future<void> deleteLedger(String unitId) async {
    await _ledgersRef.doc(unitId).delete();
  }


  @override
  Future<void> batchUpdateInstallments(List<Installment> installments) async {
    if (installments.isEmpty) return;
    final batch = _firestore.batch();
    for (final inst in installments) {
      final ref = _firestore
          .collection('contracts')
          .doc(inst.contractId)
          .collection('installments')
          .doc(inst.id);
      batch.update(ref, inst.toJson());
    }
    await batch.commit();
  }
}
