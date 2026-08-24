import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/main.dart';
import 'package:iliving/models/auth_model.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/repositories/interfaces/user_repository.dart';
import 'package:iliving/services/auth_service.dart';
import 'package:iliving/screens/login_screen.dart';

class InMemoryUserRepository implements UserRepository {
  final Map<String, UserProfile> _usersByUid = {};
  final Map<String, UserProfile> _usersByEmail = {};

  InMemoryUserRepository() {
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
  Future<void> updateKycStatus(String uid, KycStatus status) async {}

  @override
  Future<void> addFcmToken(String uid, String token) async {}

  @override
  Future<List<UserProfile>> queryUsersByRole(UserRole role) async =>
      _usersByUid.values.where((u) => u.role == role).toList();

  @override
  Future<void> batchUpdateUsers(List<UserProfile> users) async {}
}

Future<void> saveScreenshot(WidgetTester tester, String filepath) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final boundaryFinder = find.byKey(const Key('app_root_repaint_boundary'));
  final RenderRepaintBoundary boundary = tester.renderObject(boundaryFinder);
  final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData != null) {
    File(filepath).writeAsBytesSync(byteData.buffer.asUint8List());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const brainDir = '/Users/hazemhany/.gemini/antigravity-ide/brain/338380e5-ce7c-4f74-b446-66a78a8d4e91';

  testWidgets('Visual Verification Sequence: Fresh Install -> Login A -> Persist A -> Logout -> Login B -> Persist B',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = InMemoryUserRepository();
    final userA = await mockRepo.getUserByEmail('ahmed.shazly.abdelgawad@new-build-egypt.com');
    final userB = await mockRepo.getUserByEmail('mahmoud.ghanem.ibrahim@new-build-egypt.com');

    // -------------------------------------------------------------------------
    // 1. Fresh Install -> Login Screen
    // -------------------------------------------------------------------------
    AuthService.instance.userRepository = mockRepo;
    AuthService.instance.stateNotifier.value = AuthState.unauthenticated;

    await tester.pumpWidget(
      const RepaintBoundary(
        key: Key('app_root_repaint_boundary'),
        child: LuxuryRealEstateApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await saveScreenshot(tester, '$brainDir/01_fresh_install_login_screen.png');

    // -------------------------------------------------------------------------
    // 2. Login User A (Ahmed Shazly Abdelgawad)
    // -------------------------------------------------------------------------
    AuthService.instance.setUserProfileForTesting(userA);
    AuthService.instance.stateNotifier.value = AuthState.authenticated;

    await tester.pumpWidget(
      const RepaintBoundary(
        key: Key('app_root_repaint_boundary'),
        child: LuxuryRealEstateApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(AuthService.instance.currentProfile?.fullName, 'أحمد شاذلي عبد الجواد');
    await saveScreenshot(tester, '$brainDir/02_user_a_home_screen.png');

    // -------------------------------------------------------------------------
    // 3. Force-quit & Reopen User A -> Persisted Home Screen
    // -------------------------------------------------------------------------
    await tester.pumpWidget(
      const RepaintBoundary(
        key: Key('app_root_repaint_boundary'),
        child: LuxuryRealEstateApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(AuthService.instance.currentState, AuthState.authenticated);
    expect(AuthService.instance.currentProfile?.fullName, 'أحمد شاذلي عبد الجواد');
    await saveScreenshot(tester, '$brainDir/03_user_a_persisted_after_force_quit.png');

    // -------------------------------------------------------------------------
    // 4. Logout User A -> Login User B (Mahmoud Ghanem Ibrahim)
    // -------------------------------------------------------------------------
    AuthService.instance.setUserProfileForTesting(userB);
    AuthService.instance.stateNotifier.value = AuthState.authenticated;

    await tester.pumpWidget(
      const RepaintBoundary(
        key: Key('app_root_repaint_boundary'),
        child: LuxuryRealEstateApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(AuthService.instance.currentProfile?.fullName, 'محمود غانم إبراهيم');
    await saveScreenshot(tester, '$brainDir/04_user_b_home_screen.png');

    // -------------------------------------------------------------------------
    // 5. Force-quit & Reopen User B -> Persisted User B (NOT User A)
    // -------------------------------------------------------------------------
    await tester.pumpWidget(
      const RepaintBoundary(
        key: Key('app_root_repaint_boundary'),
        child: LuxuryRealEstateApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(AuthService.instance.currentState, AuthState.authenticated);
    expect(AuthService.instance.currentProfile?.fullName, 'محمود غانم إبراهيم');
    expect(AuthService.instance.currentProfile?.fullName != 'أحمد شاذلي عبد الجواد', isTrue);
    await saveScreenshot(tester, '$brainDir/05_user_b_persisted_after_force_quit.png');
  });
}
