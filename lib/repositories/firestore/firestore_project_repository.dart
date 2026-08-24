import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/project.dart';
import '../interfaces/project_repository.dart';

class FirestoreProjectRepository implements ProjectRepository {
  final FirebaseFirestore _firestore;

  FirestoreProjectRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      _firestore.collection('projects');

  @override
  Future<Project?> getProjectById(String id) async {
    final doc = await _projectsRef.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return Project.fromJson(data);
  }

  @override
  Stream<Project?> streamProject(String id) {
    return _projectsRef.doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return Project.fromJson(data);
    });
  }

  @override
  Stream<List<Project>> streamAllProjects() {
    return _projectsRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Project.fromJson(doc.data())).toList(),
        );
  }

  @override
  Future<List<Project>> getProjects({
    String? searchQuery,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _projectsRef;

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _projectsRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    var list = snap.docs.map((doc) => Project.fromJson(doc.data())).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final qLower = searchQuery.trim().toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(qLower) || p.code.toLowerCase().contains(qLower)).toList();
    }

    return list;
  }

  @override
  Future<void> createProject(Project project) async {
    await _projectsRef
        .doc(project.id)
        .set(project.toJson(), SetOptions(merge: true))
        .timeout(const Duration(seconds: 4), onTimeout: () {});
  }

  @override
  Future<void> updateProject(Project project) async {
    await _projectsRef
        .doc(project.id)
        .set(project.toJson(), SetOptions(merge: true))
        .timeout(const Duration(seconds: 4), onTimeout: () {});
  }

  @override
  Future<void> deleteProject(String id) async {
    await _projectsRef
        .doc(id)
        .delete()
        .timeout(const Duration(seconds: 4), onTimeout: () {});
  }
}
