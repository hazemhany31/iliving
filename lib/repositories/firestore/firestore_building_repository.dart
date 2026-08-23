import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/building.dart';
import '../interfaces/building_repository.dart';

class FirestoreBuildingRepository implements BuildingRepository {
  final FirebaseFirestore _firestore;

  FirestoreBuildingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _buildingsRef =>
      _firestore.collection('compounds');

  @override
  Future<Building?> getBuildingById(String id) async {
    final query = await _firestore.collectionGroup('buildings').where('id', isEqualTo: id).limit(1).get();
    if (query.docs.isEmpty) return null;
    return Building.fromJson(query.docs.first.data());
  }

  @override
  Stream<Building?> streamBuilding(String id) {
    return _firestore
        .collectionGroup('buildings')
        .where('id', isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? Building.fromJson(snap.docs.first.data()) : null);
  }

  @override
  Stream<List<Building>> streamBuildingsForCompound(String compoundId) {
    return _buildingsRef
        .doc(compoundId)
        .collection('buildings')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Building.fromJson(doc.data())).toList());
  }

  @override
  Future<List<Building>> getBuildingsForCompound(String compoundId) async {
    final snap = await _buildingsRef.doc(compoundId).collection('buildings').get();
    return snap.docs.map((doc) => Building.fromJson(doc.data())).toList();
  }

  @override
  Future<void> createBuilding(Building building) async {
    await _buildingsRef
        .doc(building.compoundId)
        .collection('buildings')
        .doc(building.id)
        .set(building.toJson());
  }

  @override
  Future<void> updateBuilding(Building building) async {
    await _buildingsRef
        .doc(building.compoundId)
        .collection('buildings')
        .doc(building.id)
        .update(building.toJson());
  }

  @override
  Future<void> deleteBuilding(String id) async {
    final query = await _firestore.collectionGroup('buildings').where('id', isEqualTo: id).limit(1).get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<void> batchCreateBuildings(List<Building> buildings) async {
    if (buildings.isEmpty) return;
    final batch = _firestore.batch();
    for (final b in buildings) {
      final ref = _buildingsRef.doc(b.compoundId).collection('buildings').doc(b.id);
      batch.set(ref, b.toJson());
    }
    await batch.commit();
  }
}
