import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/services/auth_service.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/models/auth_model.dart';
import 'package:iliving/repositories/interfaces/user_repository.dart';

class MockUserRepository implements UserRepository {
  final Map<String, UserProfile> _db = {};

  @override
  Future<UserProfile?> getUserById(String uid) async => _db[uid];

  @override
  Future<UserProfile?> getUserByEmail(String email) async {
    try {
      return _db.values.firstWhere(
        (u) => u.email.trim().toLowerCase() == email.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createUser(UserProfile user) async => _db[user.uid] = user;

  @override
  Future<void> updateUser(UserProfile user) async => _db[user.uid] = user;

  @override
  Future<void> deleteUser(String uid) async => _db.remove(uid);

  @override
  Stream<UserProfile?> streamUser(String uid) => Stream.value(_db[uid]);

  @override
  Stream<List<UserProfile>> streamAllUsers() => Stream.value(_db.values.toList());

  @override
  Stream<List<UserProfile>> streamUsersByRole(UserRole role) =>
      Stream.value(_db.values.where((u) => u.role == role).toList());

  @override
  Future<List<UserProfile>> getUsers({
    UserRole? role,
    KycStatus? status,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  }) async => _db.values.toList();

  @override
  Future<void> updateKycStatus(String uid, KycStatus status) async {
    final user = _db[uid];
    if (user != null) {
      _db[uid] = user.copyWith(kycStatus: status);
    }
  }

  @override
  Future<void> addFcmToken(String uid, String token) async {
    final user = _db[uid];
    if (user != null && !user.fcmTokens.contains(token)) {
      _db[uid] = user.copyWith(fcmTokens: [...user.fcmTokens, token]);
    }
  }

  @override
  Future<List<UserProfile>> queryUsersByRole(UserRole role) async =>
      _db.values.where((u) => u.role == role).toList();

  @override
  Future<void> batchUpdateUsers(List<UserProfile> users) async {
    for (final u in users) {
      _db[u.uid] = u;
    }
  }
}

void main() {
  group('Release Mode & Security Auth Guard Proof Tests', () {
    test('1. Mock auth bypass is strictly BLOCKED in release mode (allowMock: false)', () async {
      // In release mode, allowMock is false by default.
      final releaseAuthService = AuthService(
        userRepository: MockUserRepository(),
        allowMock: false,
      );

      // Attempting to login with admin@ or demo@ in release mode WITHOUT real Firebase throws:
      expect(
        () => releaseAuthService.signInWithEmailAndPassword(
          email: 'admin@iliving.com.eg',
          password: 'anyPassword',
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => releaseAuthService.signInWithEmailAndPassword(
          email: 'sterling@iliving.com.eg',
          password: 'anyPassword',
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => releaseAuthService.signInWithEmailAndPassword(
          email: 'demo@iliving.com.eg',
          password: 'anyPassword',
        ),
        throwsA(isA<Exception>()),
      );

      expect(releaseAuthService.currentState, AuthState.unauthenticated);
      expect(releaseAuthService.isAuthenticated, isFalse);
    });

    test('2. Wrong password is strictly rejected even in demo mode', () async {
      final demoAuthService = AuthService(
        userRepository: MockUserRepository(),
        allowMock: true,
      );

      expect(
        () => demoAuthService.signInWithEmailAndPassword(
          email: 'ahmed.shazly.abdelgawad@new-build-egypt.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<Exception>()),
      );

      expect(demoAuthService.currentState, AuthState.unauthenticated);
      expect(demoAuthService.isAuthenticated, isFalse);
    });

    test('3. Non-existent user is strictly rejected', () async {
      final demoAuthService = AuthService(
        userRepository: MockUserRepository(),
        allowMock: true,
      );

      expect(
        () => demoAuthService.signInWithEmailAndPassword(
          email: 'nonexistent_user@nowhere.com',
          password: 'somePassword',
        ),
        throwsA(isA<Exception>()),
      );

      expect(demoAuthService.currentState, AuthState.unauthenticated);
    });

    test('4. Bearer token retrieves live token asynchronously', () async {
      final auth = AuthService(userRepository: MockUserRepository(), allowMock: false);
      final token = await auth.bearerToken;
      // In production, bearerToken is null when no live session exists (NOT a fake string)
      expect(token, isNull);
    });
  });
}
