import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/unit_model.dart';
import '../interfaces/unit_repository.dart';

class FirestoreUnitRepository implements UnitRepository {
  final FirebaseFirestore _firestore;

  FirestoreUnitRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _unitsRef =>
      _firestore.collection('units');

  @override
  Future<Unit?> getUnitById(String id) async {
    final doc = await _unitsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Unit.fromJson(doc.data()!);
  }

  @override
  Stream<Unit?> streamUnit(String id) {
    return _unitsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Unit.fromJson(doc.data()!);
    });
  }

  @override
  Stream<List<Unit>> streamUnitsForCompound(String compoundId) {
    return _unitsRef
        .where('compoundId', isEqualTo: compoundId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Unit.fromJson(doc.data())).toList());
  }

  @override
  Stream<List<Unit>> streamUnitsForUser(String userId) {
    return _unitsRef
        .where('currentOwnerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Unit.fromJson(doc.data())).toList());
  }

  @override
  Stream<List<Unit>> streamAllUnits() {
    return _unitsRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Unit.fromJson(doc.data())).toList(),
        );
  }

  @override
  Future<List<Unit>> getUnits({
    String? compoundId,
    String? buildingId,
    UnitStatus? status,
    String? orientation,
    String? block,
    bool? hasGarden,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _unitsRef;

    if (compoundId != null && compoundId.isNotEmpty) {
      q = q.where('compoundId', isEqualTo: compoundId);
    }
    if (buildingId != null && buildingId.isNotEmpty) {
      q = q.where('buildingId', isEqualTo: buildingId);
    }
    if (status != null) {
      q = q.where('status', isEqualTo: status.nameString);
    }
    if (orientation != null && orientation.isNotEmpty) {
      q = q.where('orientation', isEqualTo: orientation);
    }
    if (block != null && block.isNotEmpty) {
      q = q.where('block', isEqualTo: block);
    }

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _unitsRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    var list = snap.docs.map((doc) => Unit.fromJson(doc.data())).toList();

    if (hasGarden == true) {
      list = list.where((u) => u.gardenAreaSqM != null && u.gardenAreaSqM! > 0).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final queryLower = searchQuery.trim().toLowerCase();
      list = list.where((u) {
        return u.unitNumber.toLowerCase().contains(queryLower) ||
            u.compoundId.toLowerCase().contains(queryLower);
      }).toList();
    }

    return list;
  }

  @override
  Future<void> createUnit(Unit unit) async {
    await _unitsRef.doc(unit.id).set(unit.toJson());
  }

  @override
  Future<void> updateUnit(Unit unit) async {
    await _unitsRef.doc(unit.id).update(unit.toJson());
  }

  @override
  Future<void> deleteUnit(String id) async {
    await _unitsRef.doc(id).delete();
  }

  @override
  Future<void> updateUnitStatus(String unitId, UnitStatus status, {String? ownerId}) async {
    final Map<String, dynamic> updateData = {'status': status.nameString};
    if (ownerId != null) {
      updateData['currentOwnerId'] = ownerId;
    }
    await _unitsRef.doc(unitId).update(updateData);
  }

  @override
  Future<void> updateUnitPrice(
      String unitId, double newPricePerSqm, String reason, String changedByUserId) async {
    return _firestore.runTransaction((transaction) async {
      final docRef = _unitsRef.doc(unitId);
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Unit $unitId does not exist');
      }

      final currentData = snapshot.data()!;
      final oldPricePerSqm = (currentData['basePricePerSqm'] as num?)?.toDouble() ?? 0.0;
      final netArea = (currentData['netAreaSqm'] as num?)?.toDouble() ?? 100.0;
      final newTotalPrice = newPricePerSqm * netArea;

      transaction.update(docRef, {
        'basePricePerSqm': newPricePerSqm,
        'currentTotalPrice': newTotalPrice,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final priceTickRef = docRef.collection('price_ticks').doc();
      transaction.set(priceTickRef, {
        'id': priceTickRef.id,
        'unitId': unitId,
        'oldPricePerSqm': oldPricePerSqm,
        'newPricePerSqm': newPricePerSqm,
        'changedByUserId': changedByUserId,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  Future<void> batchCreateUnits(List<Unit> units) async {
    if (units.isEmpty) return;
    final batch = _firestore.batch();
    for (final u in units) {
      batch.set(_unitsRef.doc(u.id), u.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<void> batchUpdateUnits(List<Unit> units) async {
    if (units.isEmpty) return;
    final batch = _firestore.batch();
    for (final u in units) {
      batch.update(_unitsRef.doc(u.id), u.toJson());
    }
    await batch.commit();
  }
}
