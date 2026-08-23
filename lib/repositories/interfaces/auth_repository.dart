import '../../models/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;

  Future<UserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<Map<String, dynamic>> fetchCustomClaims();
}
