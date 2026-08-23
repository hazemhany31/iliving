import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/compound_model.dart';
import '../interfaces/compound_repository.dart';

class FirestoreCompoundRepository implements CompoundRepository {
  final FirebaseFirestore _firestore;

  FirestoreCompoundRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _compoundsRef =>
      _firestore.collection('compounds');

  @override
  Future<CompoundModel?> getCompoundById(String id) async {
    final doc = await _compoundsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return CompoundModel.fromJson(doc.data()!);
  }

  @override
  Stream<CompoundModel?> streamCompound(String id) {
    return _compoundsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CompoundModel.fromJson(doc.data()!);
    });
  }

  @override
  Stream<List<CompoundModel>> streamAllCompounds() {
    return _compoundsRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CompoundModel.fromJson(doc.data())).toList());
  }

  @override
  Future<List<CompoundModel>> getCompounds({
    String? projectId,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _compoundsRef;

    if (projectId != null && projectId.isNotEmpty) {
      q = q.where('projectId', isEqualTo: projectId);
    }

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _compoundsRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    var list = snap.docs.map((doc) => CompoundModel.fromJson(doc.data())).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final qLower = searchQuery.trim().toLowerCase();
      list = list.where((c) => c.title.toLowerCase().contains(qLower) || c.location.toLowerCase().contains(qLower)).toList();
    }

    return list;
  }

  @override
  Future<void> createCompound(CompoundModel compound) async {
    await _compoundsRef
        .doc(compound.id)
        .set(compound.toJson(), SetOptions(merge: true))
        .timeout(const Duration(seconds: 4), onTimeout: () {});
  }

  @override
  Future<void> updateCompound(CompoundModel compound) async {
    await _compoundsRef
        .doc(compound.id)
        .set(compound.toJson(), SetOptions(merge: true))
        .timeout(const Duration(seconds: 4), onTimeout: () {});
  }

  @override
  Future<void> deleteCompound(String id) async {
    await _compoundsRef
        .doc(id)
        .delete()
        .timeout(const Duration(seconds: 4), onTimeout: () {});
  }
}
