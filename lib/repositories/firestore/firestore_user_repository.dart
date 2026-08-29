import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../interfaces/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  @override
  Future<UserProfile?> getUserById(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get().timeout(const Duration(milliseconds: 2500));
      final data = doc.data();
      if (doc.exists && data != null) {
        return UserProfile.fromJson(data);
      }
      final querySnap = await _usersRef
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get()
          .timeout(const Duration(milliseconds: 2500));
      if (querySnap.docs.isNotEmpty && querySnap.docs.first.data().isNotEmpty) {
        return UserProfile.fromJson(querySnap.docs.first.data());
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<UserProfile?> getUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;
    try {
      final querySnap = await _usersRef
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get()
          .timeout(const Duration(milliseconds: 2500));
      if (querySnap.docs.isNotEmpty && querySnap.docs.first.data().isNotEmpty) {
        return UserProfile.fromJson(querySnap.docs.first.data());
      }
    } catch (_) {}
    return null;
  }

  @override
  Stream<UserProfile?> streamUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return UserProfile.fromJson(data);
    });
  }

  @override
  Stream<List<UserProfile>> streamAllUsers() {
    return _usersRef.snapshots().map(
          (snap) => snap.docs.map((d) => UserProfile.fromJson(d.data())).toList(),
        );
  }

  @override
  Stream<List<UserProfile>> streamUsersByRole(UserRole role) {
    return _usersRef
        .where('role', isEqualTo: role.nameString)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserProfile.fromJson(d.data())).toList());
  }

  @override
  Future<List<UserProfile>> getUsers({
    UserRole? role,
    KycStatus? status,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _usersRef;

    if (role != null) {
      q = q.where('role', isEqualTo: role.nameString);
    }
    if (status != null) {
      q = q.where('kycStatus', isEqualTo: status.name);
    }

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _usersRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    var list = snap.docs.map((d) => UserProfile.fromJson(d.data())).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final queryLower = searchQuery.trim().toLowerCase();
      list = list.where((u) {
        return u.fullName.toLowerCase().contains(queryLower) ||
            u.email.toLowerCase().contains(queryLower) ||
            u.phoneNumber.contains(queryLower) ||
            (u.clientCode != null && u.clientCode!.toLowerCase().contains(queryLower));
      }).toList();
    }

    return list;
  }

  @override
  Future<void> createUser(UserProfile user) async {
    await _usersRef.doc(user.uid).set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    await _usersRef.doc(user.uid).update(user.toJson());
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).delete();
    } catch (_) {}
    try {
      final snap = await _usersRef.where('uid', isEqualTo: uid).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
  }

  @override
  Future<void> updateKycStatus(String uid, KycStatus status) async {
    await _usersRef.doc(uid).update({'kycStatus': status.name});
  }

  @override
  Future<void> addFcmToken(String uid, String token) async {
    await _usersRef.doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token])
    });
  }

  @override
  Future<List<UserProfile>> queryUsersByRole(UserRole role) async {
    final query = await _usersRef.where('role', isEqualTo: role.nameString).get();
    return query.docs.map((d) => UserProfile.fromJson(d.data())).toList();
  }

  @override
  Future<void> batchUpdateUsers(List<UserProfile> users) async {
    if (users.isEmpty) return;
    final batch = _firestore.batch();
    for (final u in users) {
      batch.set(_usersRef.doc(u.uid), u.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
