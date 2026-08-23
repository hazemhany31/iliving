import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/services/auth_service.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/models/auth_model.dart';
import 'package:iliving/repositories/interfaces/user_repository.dart';

class InMemoryUserRepository implements UserRepository {
  final Map<String, UserProfile> _usersByUid = {};
  final Map<String, UserProfile> _usersByEmail = {};

  InMemoryUserRepository() {
    // Seed test users
    final userA = UserProfile(
      uid: 'client_87',
      clientCode: '87',
      email: 'ahmed.shazly.abdelgawad@new-build-egypt.com',
      fullName: 'أحمد شاذلي عبد الجواد',
      phoneNumber: '01127633326',
      role: UserRole.customer,
      associatedUnitIds: ['A301B208'],
      createdAt: DateTime.now(),
    );
    final userB = UserProfile(
      uid: 'client_89',
      clientCode: '89',
      email: 'mahmoud.ghanem.ibrahim@new-build-egypt.com',
      fullName: 'محمود غانم إبراهيم',
      phoneNumber: '032465795140',
      role: UserRole.customer,
      associatedUnitIds: ['B101B409'],
      createdAt: DateTime.now(),
    );
    _usersByUid[userA.uid] = userA;
    _usersByEmail[userA.email.toLowerCase()] = userA;
    _usersByUid[userB.uid] = userB;
    _usersByEmail[userB.email.toLowerCase()] = userB;
  }

  @override
  Future<UserProfile?> getUserById(String uid) async => _usersByUid[uid];

  @override
  Future<UserProfile?> getUserByEmail(String email) async =>
      _usersByEmail[email.trim().toLowerCase()];

  @override
  Future<void> createUser(UserProfile user) async {
    _usersByUid[user.uid] = user;
    _usersByEmail[user.email.toLowerCase()] = user;
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    _usersByUid[user.uid] = user;
    _usersByEmail[user.email.toLowerCase()] = user;
  }

  @override
  Future<void> deleteUser(String uid) async {
    final user = _usersByUid.remove(uid);
    if (user != null) _usersByEmail.remove(user.email.toLowerCase());
  }

  @override
  Stream<UserProfile?> streamUser(String uid) => Stream.value(_usersByUid[uid]);

  @override
  Stream<List<UserProfile>> streamAllUsers() =>
      Stream.value(_usersByUid.values.toList());

  @override
  Stream<List<UserProfile>> streamUsersByRole(UserRole role) =>
      Stream.value(_usersByUid.values.where((u) => u.role == role).toList());

  @override
  Future<List<UserProfile>> getUsers({
    UserRole? role,
    KycStatus? status,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  }) async =>
      _usersByUid.values.toList();

  @override
  Future<void> updateKycStatus(String uid, KycStatus status) async {
    final user = _usersByUid[uid];
    if (user != null) {
      final updated = user.copyWith(kycStatus: status);
      _usersByUid[uid] = updated;
      _usersByEmail[updated.email.toLowerCase()] = updated;
    }
  }

  @override
  Future<void> addFcmToken(String uid, String token) async {
    final user = _usersByUid[uid];
    if (user != null && !user.fcmTokens.contains(token)) {
      final updated = user.copyWith(fcmTokens: [...user.fcmTokens, token]);
      _usersByUid[uid] = updated;
      _usersByEmail[updated.email.toLowerCase()] = updated;
    }
  }

  @override
  Future<List<UserProfile>> queryUsersByRole(UserRole role) async =>
      _usersByUid.values.where((u) => u.role == role).toList();

  @override
  Future<void> batchUpdateUsers(List<UserProfile> users) async {
    for (final u in users) {
      _usersByUid[u.uid] = u;
      _usersByEmail[u.email.toLowerCase()] = u;
    }
  }
}

void main() {
  group('Auth Persistence & Session Management Tests', () {
    late InMemoryUserRepository userRepo;

    setUp(() {
      userRepo = InMemoryUserRepository();
    });

    test('1. Fresh install state: unauthenticated, null profile', () async {
      final auth = AuthService(
        userRepository: userRepo,
        allowMock: true,
      );
      await auth.initialize();

      expect(auth.currentState, AuthState.unauthenticated);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentProfile, isNull);
    });

    test('2. User A login loads User A real data (name, unit, code)', () async {
      final auth = AuthService(
        userRepository: userRepo,
        allowMock: true,
      );
      await auth.initialize();

      final profile = await auth.signInWithEmailAndPassword(
        email: 'ahmed.shazly.abdelgawad@new-build-egypt.com',
        password: 'iliving2026',
      );

      expect(auth.currentState, AuthState.authenticated);
      expect(auth.isAuthenticated, isTrue);
      expect(profile.fullName, 'أحمد شاذلي عبد الجواد');
      expect(profile.clientCode, anyOf('87', 'client_87'));
      expect(profile.associatedUnitIds, contains('A301B208'));
    });

    test('3. Account Switching: User A -> Logout -> User B login loads User B data', () async {
      final auth = AuthService(
        userRepository: userRepo,
        allowMock: true,
      );
      await auth.initialize();

      // Step A: Login User A
      await auth.signInWithEmailAndPassword(
        email: 'ahmed.shazly.abdelgawad@new-build-egypt.com',
        password: 'iliving2026',
      );
      expect(auth.currentProfile?.fullName, 'أحمد شاذلي عبد الجواد');
      expect(auth.currentProfile?.associatedUnitIds, contains('A301B208'));

      // Step B: Logout User A
      await auth.logout();
      expect(auth.currentState, AuthState.unauthenticated);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentProfile, isNull);

      // Step C: Login User B
      final profileB = await auth.signInWithEmailAndPassword(
        email: 'mahmoud.ghanem.ibrahim@new-build-egypt.com',
        password: 'iliving2026',
      );
      expect(auth.currentState, AuthState.authenticated);
      expect(auth.isAuthenticated, isTrue);
      expect(profileB.fullName, 'محمود غانم إبراهيم');
      expect(profileB.clientCode, anyOf('89', 'client_89'));
      expect(profileB.associatedUnitIds, contains('B101B409'));
      expect(profileB.associatedUnitIds, isNot(contains('A301B208')));
    });

    test('4. Token retrieval does not crash on unauthenticated state', () async {
      final auth = AuthService(
        userRepository: userRepo,
        allowMock: true,
      );
      final token = await auth.getIdToken(true);
      expect(token, isNull);
    });
  });
}
