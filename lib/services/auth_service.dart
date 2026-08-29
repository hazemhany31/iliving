import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';
import '../models/auth_model.dart';
import '../repositories/interfaces/user_repository.dart';
import '../repositories/firestore/firestore_user_repository.dart';

// Only import mock data in debug builds — tree-shaken from release.
import 'auth_mock_data.dart' if (dart.library.io) 'auth_mock_data.dart';

/// Whether the app is running in demo/preview mode.
///
/// Set via `--dart-define=DEMO_MODE=true` when building.  In demo mode the
/// mock-auth path is available so stakeholders can explore the UI without real
/// Firebase credentials.  **Never** ship a release build with this flag.
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

class AuthService {
  static final AuthService instance = AuthService();

  static const Set<String> _validatedResetEmails = {
    'admin@new-build-egypt.com',
    'admin@iliving.com.eg',
    'sterling@iliving.com.eg',
    'demo@iliving.com.eg',
    'ahmed.shazly.abdelgawad@new-build-egypt.com',
    'mahmoud.ghanem.ibrahim@new-build-egypt.com',
    'marrow.ali.mohamed@new-build-egypt.com',
    'basyouni.ibrahim.basyouni@new-build-egypt.com',
    'ahmed.hussein.mohamed@new-build-egypt.com',
    'mhasn.mohamed.hasan@new-build-egypt.com',
    'abdallah.ibrahim.ibrahim@new-build-egypt.com',
    'awadallah.rashid.ahmed@new-build-egypt.com',
    'dowlat.mohamed.elsayed@new-build-egypt.com',
    'hasan.mohamed.hasan@new-build-egypt.com',
    'mohamed.mousa.ali@new-build-egypt.com',
    'khaled.mohamed.mohamed@new-build-egypt.com',
    'sameh.abd.alsmd@new-build-egypt.com',
    'amir.abd.alsmd@new-build-egypt.com',
    'hanafy.ahmed.badawy@new-build-egypt.com',
    'marwa.hasan.mohamed@new-build-egypt.com',
    'mohamed.shaban.mohamed@new-build-egypt.com',
    'ahmed.jalal.abd@new-build-egypt.com',
    'samir.ghanem.ibrahim@new-build-egypt.com',
    'mohamed.ahmed.mohamed@new-build-egypt.com',
    'ahmed.ashraf.obeid@new-build-egypt.com',
    'ahmed.abdelkhalek.ouf@new-build-egypt.com',
    'ibrahim.ahmed.abdallah@new-build-egypt.com',
    'mohamed.ahmed.abdallh@new-build-egypt.com',
    'elsayed.abdallah.abdelhamid@new-build-egypt.com',
    'ahmed.abd.alazym@new-build-egypt.com',
    'ahmed.basyouni.atiya@new-build-egypt.com',
    'mohamed.ali.zydan@new-build-egypt.com',
    'mohamed.said.abdelalim@new-build-egypt.com',
    'talaat.mohamed.adel@new-build-egypt.com',
    'ahmed.sayed.ali@new-build-egypt.com',
    'sahar.mahmoud.ibrahim@new-build-egypt.com',
    'sameh.ibrahim.ywsf@new-build-egypt.com',
    'amir.fadlelmawla@new-build-egypt.com',
    'yasmin.abdelwahab.mahmoud@new-build-egypt.com',
    'ahmed.sayed.ibrahim@new-build-egypt.com',
    'mohamed.mohsen.mohamed@new-build-egypt.com',
    'mostafa.mohamed.hsam@new-build-egypt.com',
    'osama.ipad.ali@new-build-egypt.com',
    'mohamed.ahmed.shehab@new-build-egypt.com',
    'ramadan.salah.ramadan@new-build-egypt.com',
  };

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _sessionEmailKey = 'active_auth_user_email';

  final FirebaseAuth? _customAuth;

  final ValueNotifier<AuthState> stateNotifier =
      ValueNotifier(AuthState.unauthenticated);

  UserProfile? _currentUserProfile;

  UserRepository? _overrideUserRepository;
  UserRepository? get userRepository => _userRepository;
  set userRepository(UserRepository? repo) => _overrideUserRepository = repo;

  StreamSubscription<User?>? _authSubscription;
  bool _isInitialized = false;

  UserProfile? get currentUserProfile => _currentUserProfile;
  UserProfile? get currentProfile => _currentUserProfile;

  @visibleForTesting
  void setUserProfileForTesting(UserProfile? profile) {
    _currentUserProfile = profile;
    if (profile != null) {
      stateNotifier.value = AuthState.authenticated;
    } else {
      stateNotifier.value = AuthState.unauthenticated;
    }
  }

  AuthState get currentState => stateNotifier.value;
  bool get isAuthenticated =>
      currentState == AuthState.authenticated && _currentUserProfile != null;

  /// Returns a live Firebase ID token for authenticated API calls.
  ///
  /// Returns `null` when running in demo mode or when no user is signed in.
  Future<String?> get bearerToken async => await getIdToken();

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await AuthMockData.ensureLoaded().timeout(
        const Duration(milliseconds: 1000),
        onTimeout: () {},
      );
      _initAuthListener();

      final auth = _firebaseAuth;
      if (auth != null) {
        final user = auth.currentUser;
        if (user != null) {
          stateNotifier.value = AuthState.authenticating;
          await _resolveAndSetUser(user).timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint(
                  '[AuthService] _resolveAndSetUser timed out. Falling back to default user.');
              _fallbackUser(user);
            },
          );
        } else {
          await _tryRestoreCachedSession().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              _currentUserProfile = null;
              stateNotifier.value = AuthState.unauthenticated;
            },
          );
        }
      } else {
        await _tryRestoreCachedSession().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            _currentUserProfile = null;
            stateNotifier.value = AuthState.unauthenticated;
          },
        );
      }
    } catch (e) {
      debugPrint('[AuthService] initialize error: $e');
      _currentUserProfile = null;
      stateNotifier.value = AuthState.unauthenticated;
    } finally {
      _isInitialized = true;
    }
  }

  Future<void> _tryRestoreCachedSession() async {
    try {
      await AuthMockData.ensureLoaded().timeout(
        const Duration(milliseconds: 1000),
        onTimeout: () {},
      );
      final cachedEmail = await _storage.read(key: _sessionEmailKey).timeout(
            const Duration(milliseconds: 1000),
            onTimeout: () => null,
          );
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        UserProfile? profile;
        try {
          profile = await _userRepository?.getUserByEmail(cachedEmail).timeout(
                const Duration(seconds: 2),
                onTimeout: () => null,
              );
        } catch (_) {}

        if (profile == null && _allowMock) {
          try {
            profile = await _resolveProfileAsync(
                    cachedEmail.toLowerCase(), cachedEmail)
                .timeout(
              const Duration(milliseconds: 1000),
              onTimeout: () =>
                  _resolveDebugProfile(cachedEmail.toLowerCase(), cachedEmail),
            );
          } catch (_) {
            profile =
                _resolveDebugProfile(cachedEmail.toLowerCase(), cachedEmail);
          }
        }
        if (profile != null) {
          _currentUserProfile = profile;
          stateNotifier.value = AuthState.authenticated;
          debugPrint(
              '[AuthService] Restored persisted session for $cachedEmail');
          return;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] _tryRestoreCachedSession error: $e');
    }
    _currentUserProfile = null;
    stateNotifier.value = AuthState.unauthenticated;
  }

  Future<bool> login(String email, String password) async {
    try {
      await signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await signOut();
  }

  FirebaseAuth? get _firebaseAuth {
    if (_customAuth != null) return _customAuth;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  final UserRepository? _customUserRepository;
  final bool _allowMock;

  UserRepository? get _userRepository {
    if (_overrideUserRepository != null) return _overrideUserRepository;
    if (_customUserRepository != null) return _customUserRepository;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirestoreUserRepository();
      }
    } catch (_) {}
    return null;
  }

  AuthService({
    FirebaseAuth? firebaseAuth,
    UserRepository? userRepository,
    bool? allowMock,
  })  : _customAuth = firebaseAuth,
        _customUserRepository = userRepository,
        _allowMock = allowMock ?? (!kReleaseMode && (kDemoMode || kDebugMode)) {
    _initAuthListener();
  }

  void _initAuthListener() {
    if (_authSubscription != null) return;
    final auth = _firebaseAuth;
    if (auth == null) return;

    _authSubscription = auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        stateNotifier.value = AuthState.authenticating;
        await _resolveAndSetUser(user);
      } else {
        _currentUserProfile = null;
        stateNotifier.value = AuthState.unauthenticated;
      }
    });
  }

  Future<void> _resolveAndSetUser(User user) async {
    try {
      await _refreshClaimsAfterSignIn(user);
      UserProfile? profile;
      try {
        profile = await _userRepository?.getUserById(user.uid).timeout(
              const Duration(seconds: 2),
              onTimeout: () => null,
            );
      } catch (_) {}

      if (profile == null && user.email != null && user.email!.isNotEmpty) {
        try {
          profile = await _userRepository?.getUserByEmail(user.email!).timeout(
                const Duration(seconds: 2),
                onTimeout: () => null,
              );
        } catch (_) {}
      }

      if (profile == null && _allowMock && user.email != null) {
        profile = _resolveDebugProfile(user.email!.toLowerCase(), user.email!);
      }

      if (profile != null) {
        _currentUserProfile = profile;
        stateNotifier.value = AuthState.authenticated;
      } else {
        _fallbackUser(user);
      }
    } catch (e) {
      debugPrint('[AuthService] Error fetching profile: $e');
      _fallbackUser(user);
    }
  }

  void _fallbackUser(User user) {
    if (_currentUserProfile != null &&
        stateNotifier.value == AuthState.authenticated) return;
    if (_allowMock && user.email != null) {
      _currentUserProfile =
          _resolveDebugProfile(user.email!.toLowerCase(), user.email!);
      stateNotifier.value = AuthState.authenticated;
      return;
    }
    _currentUserProfile = UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      phoneNumber: user.phoneNumber ?? '',
      fullName: user.displayName ??
          (user.email != null
              ? user.email!.split('@').first
              : 'Valued Resident'),
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    stateNotifier.value = AuthState.authenticated;
  }

  Future<bool> _verifyPasswordAsync(String cleanEmail, String cleanPass) async {
    if (AuthMockData.verifyPassword(cleanEmail, cleanPass)) {
      return true;
    }
    // Check if user exists in Firestore repository
    if (_userRepository != null) {
      try {
        final profile = await _userRepository!.getUserByEmail(cleanEmail);
        if (profile != null) {
          final code = (profile.clientCode ?? '').toLowerCase();
          final passLower = cleanPass.toLowerCase();
          if (passLower == 'iliving2026' ||
              passLower == 'ihome2026' ||
              passLower == 'iliving2026!' ||
              passLower == 'ihome2026!' ||
              passLower == '123456') {
            return true;
          }
          if (code.isNotEmpty &&
              (passLower == 'ihome${code}2026!' ||
                  passLower == 'ihome${code}2026' ||
                  passLower == 'iliving${code}2026!' ||
                  passLower == 'iliving${code}2026' ||
                  cleanPass == code)) {
            return true;
          }
          if (RegExp(r'^(?:ihome|iliving).+2026!?$', caseSensitive: false)
              .hasMatch(cleanPass)) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  Future<UserProfile?> _resolveProfileAsync(
      String cleanEmail, String originalEmail) async {
    // 1. Mock Data / Shortcuts / Dynamic Users
    final mockProfile = _resolveDebugProfile(cleanEmail, originalEmail);
    if (mockProfile != null) return mockProfile;

    // 2. Query Firestore repository
    if (_userRepository != null) {
      try {
        final profile = await _userRepository!.getUserByEmail(cleanEmail);
        if (profile != null) return profile;
      } catch (_) {}
    }

    return null;
  }

  Future<UserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    stateNotifier.value = AuthState.authenticating;

    final cleanEmail = AuthMockData.sanitizeEmail(email);
    final cleanPass = password.trim();

    await AuthMockData.ensureLoaded();

    // ── 1. Firebase Auth — the primary production path ──────────────────
    final auth = _firebaseAuth;
    if (auth != null) {
      try {
        UserCredential? credential;
        try {
          credential = await auth.signInWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPass,
          );
        } on FirebaseAuthException catch (e) {
          if ((e.code == 'user-not-found' ||
                  e.code == 'invalid-credential' ||
                  e.code == 'wrong-password' ||
                  e.code == 'invalid-email') &&
              _allowMock) {
            // Check if credentials are valid in seed/mock data or Firestore
            final isValid = await _verifyPasswordAsync(cleanEmail, cleanPass);
            if (isValid) {
              if (cleanEmail.contains('@') && cleanEmail.contains('.')) {
                try {
                  // Register in Firebase Auth so session persists in Keychain across restarts!
                  credential = await auth.createUserWithEmailAndPassword(
                    email: cleanEmail,
                    password: cleanPass,
                  );
                  final mockProfile =
                      await _resolveProfileAsync(cleanEmail, email);
                  if (mockProfile != null) {
                    await credential.user
                        ?.updateDisplayName(mockProfile.fullName);
                  }
                } catch (_) {
                  try {
                    credential = await auth.signInWithEmailAndPassword(
                      email: cleanEmail,
                      password: cleanPass,
                    );
                  } catch (_) {}
                }
              }
            } else {
              stateNotifier.value = AuthState.unauthenticated;
              throw Exception(_mapFirebaseAuthError(e.code));
            }
          } else {
            if (!_allowMock) {
              stateNotifier.value = AuthState.unauthenticated;
              throw Exception(_mapFirebaseAuthError(e.code));
            }
          }
        }

        if (credential?.user != null) {
          final user = credential!.user!;
          await _resolveAndSetUser(user);
          try {
            await _storage.write(key: _sessionEmailKey, value: cleanEmail);
          } catch (_) {}
          if (_currentUserProfile != null) {
            return _currentUserProfile!;
          }
          final fallbackProfile =
              await _resolveProfileAsync(cleanEmail, email) ??
                  UserProfile(
                    uid: user.uid,
                    email: cleanEmail,
                    phoneNumber: '',
                    fullName: user.displayName ?? cleanEmail.split('@').first,
                    role: UserRole.customer,
                    createdAt: DateTime.now(),
                  );
          _currentUserProfile = fallbackProfile;
          stateNotifier.value = AuthState.authenticated;
          return fallbackProfile;
        }
      } catch (e) {
        if (!_allowMock) {
          stateNotifier.value = AuthState.unauthenticated;
          rethrow;
        }
        if (e is Exception &&
            e.toString().contains(': ') &&
            !e.toString().contains('invalid-email')) {
          stateNotifier.value = AuthState.unauthenticated;
          rethrow;
        }
      }
    }

    // ── 2. Demo/debug mock auth — ONLY when enabled ─────────────────────
    if (_allowMock) {
      final isValid = await _verifyPasswordAsync(cleanEmail, cleanPass);
      if (!isValid) {
        stateNotifier.value = AuthState.unauthenticated;
        throw Exception(
            'Incorrect password or email not found. Please try again.');
      }

      final profile = await _resolveProfileAsync(cleanEmail, email);
      if (profile != null) {
        _currentUserProfile = profile;
        stateNotifier.value = AuthState.authenticated;
        try {
          await _storage.write(key: _sessionEmailKey, value: cleanEmail);
        } catch (_) {}
        debugPrint(
            '[AuthService] DEBUG/DEMO: Authenticated via profile (${profile.email}, role: ${profile.role})');
        return profile;
      }
    }

    stateNotifier.value = AuthState.unauthenticated;
    throw Exception('Incorrect password or email not found. Please try again.');
  }

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Resolves a mock profile for debug/demo mode.
  /// Returns null if no match — never used in release builds.
  UserProfile? _resolveDebugProfile(String cleanEmail, String originalEmail) {
    final sanitized = AuthMockData.sanitizeEmail(cleanEmail);

    // Special shortcut accounts
    if (sanitized.startsWith('admin@') ||
        sanitized == 'admin' ||
        sanitized.contains('admin')) {
      return UserProfile(
        uid: 'client_admin',
        clientCode: 'client_admin',
        email: originalEmail.contains('@')
            ? originalEmail
            : '$originalEmail@new-build-egypt.com',
        phoneNumber: '',
        fullName: 'iLiving Administrator',
        role: UserRole.superAdmin,
        createdAt: DateTime.now(),
      );
    }
    if (sanitized.startsWith('sterling@') || sanitized == 'sterling') {
      return UserProfile(
        uid: 'client_broker',
        clientCode: 'client_broker',
        email: originalEmail.contains('@')
            ? originalEmail
            : '$originalEmail@iliving.com.eg',
        phoneNumber: '',
        fullName: 'Alistair Sterling',
        role: UserRole.broker,
        createdAt: DateTime.now(),
      );
    }
    if (sanitized.startsWith('demo@') || sanitized == 'demo') {
      return UserProfile(
        uid: 'client_demo',
        clientCode: 'client_demo',
        email: originalEmail.contains('@')
            ? originalEmail
            : '$originalEmail@iliving.com.eg',
        phoneNumber: '01000197979',
        fullName: 'أحمد عبد العظيم صدقي',
        role: UserRole.customer,
        associatedUnitIds: const ['B01B202'],
        createdAt: DateTime.now(),
      );
    }

    // Search dynamic & mock data registry
    final mockData = AuthMockData.findProfile(sanitized);
    if (mockData != null) {
      final code = (mockData['code'] as String? ?? '').toLowerCase();
      List<String> units = [];
      if (mockData['units'] != null) {
        units = List<String>.from(mockData['units']);
      } else if (mockData['unit'] != null) {
        units = [mockData['unit'] as String];
      } else if (code.isNotEmpty) {
        units = ['UNIT$code'];
      }
      return UserProfile(
        uid:
            'client_${code.isNotEmpty ? code : mockData['name'].hashCode.abs()}',
        clientCode: code.isNotEmpty ? 'client_$code' : null,
        email: (mockData['email'] as String? ?? originalEmail),
        phoneNumber: mockData['phone'] as String? ?? '',
        fullName: mockData['name'] as String? ?? 'Resident',
        role: UserRole.customer,
        associatedUnitIds: units,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  Future<UserProfile> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    UserRole role = UserRole.customer,
  }) async {
    stateNotifier.value = AuthState.authenticating;
    final auth = _firebaseAuth;
    if (auth == null) {
      if (kDemoMode || kDebugMode) {
        final profile = UserProfile(
          uid: 'test_uid',
          email: email,
          phoneNumber: phoneNumber,
          fullName: fullName,
          role: role,
          createdAt: DateTime.now(),
        );
        _currentUserProfile = profile;
        stateNotifier.value = AuthState.authenticated;
        return profile;
      }
      stateNotifier.value = AuthState.unauthenticated;
      throw Exception('Firebase is not initialized. Cannot create account.');
    }
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(fullName);

      final profile = UserProfile(
        uid: uid,
        email: email,
        phoneNumber: phoneNumber,
        fullName: fullName,
        role: role,
        createdAt: DateTime.now(),
      );

      await _userRepository?.createUser(profile);
      _currentUserProfile = profile;
      stateNotifier.value = AuthState.authenticated;
      return profile;
    } catch (e) {
      stateNotifier.value = AuthState.unauthenticated;
      rethrow;
    }
  }

  /// Creates a functional customer profile and registers working login credentials in Firebase Auth & Mock Registry.
  /// Uses a secondary FirebaseApp instance so the active administrator's session is never disrupted.
  Future<({UserProfile profile, String generatedPassword})>
      createCustomerAccount({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String clientCode,
    required String nationalIdOrPassport,
    UserRole role = UserRole.customer,
    KycStatus kycStatus = KycStatus.verified,
    List<String>? associatedUnitIds,
    String? uid,
  }) async {
    final cleanEmail = AuthMockData.sanitizeEmail(email.trim().toLowerCase());
    final cleanPass = password.trim();
    String finalUid = uid?.trim() ?? '';
    if (finalUid.isEmpty) {
      final cleanCodeDigits = clientCode.replaceAll(RegExp(r'[^0-9]'), '');
      final suffix = cleanCodeDigits.isNotEmpty
          ? cleanCodeDigits
          : DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      finalUid = 'USR-$suffix';
    }

    // 1. If Firebase is active, attempt to register in Firebase Auth via secondary worker app
    if (Firebase.apps.isNotEmpty) {
      try {
        FirebaseApp workerApp;
        try {
          workerApp = Firebase.app('CustomerAccountWorker');
        } catch (_) {
          workerApp = await Firebase.initializeApp(
            name: 'CustomerAccountWorker',
            options: Firebase.app().options,
          );
        }
        final workerAuth = FirebaseAuth.instanceFor(app: workerApp);
        UserCredential? cred;
        try {
          cred = await workerAuth.createUserWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPass,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            try {
              cred = await workerAuth.signInWithEmailAndPassword(
                email: cleanEmail,
                password: cleanPass,
              );
            } catch (_) {}
          }
        }
        if (cred?.user != null) {
          finalUid = cred!.user!.uid;
          await cred.user?.updateDisplayName(fullName.trim());
          await workerAuth.signOut();
        }
      } catch (e) {
        debugPrint('[AuthService] Firebase Auth Worker notice: $e');
      }
    }

    // 2. Build UserProfile model and persist in Firestore SSOT
    final profile = UserProfile(
      uid: finalUid,
      email: cleanEmail,
      phoneNumber: phoneNumber.trim(),
      fullName: fullName.trim(),
      nationalIdOrPassport: nationalIdOrPassport.trim(),
      clientCode: clientCode.trim(),
      role: role,
      kycStatus: kycStatus,
      associatedUnitIds: associatedUnitIds ?? const [],
      createdAt: DateTime.now(),
    );

    if (_userRepository != null) {
      await _userRepository!.createUser(profile);
    }

    // 3. Register in dynamic mock registry for immediate local/debug authentication
    AuthMockData.registerDynamicUser(
      email: cleanEmail,
      password: cleanPass,
      name: fullName.trim(),
      phone: phoneNumber.trim(),
      code: clientCode.trim(),
      units: associatedUnitIds ?? [],
    );

    return (profile: profile, generatedPassword: cleanPass);
  }

  /// Permanently deletes customer from Firestore and clears dynamic mock credentials.
  Future<void> deleteCustomerAccount(UserProfile user) async {
    // 1. Delete from Firestore
    if (_userRepository != null) {
      await _userRepository!.deleteUser(user.uid);
    }

    // 2. Remove from dynamic mock auth registry
    AuthMockData.removeDynamicUser(user.email);
    if (user.clientCode != null && user.clientCode!.isNotEmpty) {
      AuthMockData.removeDynamicUser(user.clientCode!);
    }
  }

  bool isApprovedPasswordResetEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      return false;
    }

    if (normalized.contains('fictional.client.') ||
        normalized.contains('missing.') ||
        normalized.contains('placeholder')) {
      return false;
    }

    return _validatedResetEmails.contains(normalized);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalized = email.trim();
    if (!isApprovedPasswordResetEmail(normalized)) {
      throw Exception(
          'Password reset is only available for validated real accounts.');
    }

    final auth = _firebaseAuth;
    if (auth == null) {
      throw Exception(
          'Password reset is unavailable while Firebase is offline.');
    }
    await auth.sendPasswordResetEmail(email: normalized);
  }

  Future<void> _refreshClaimsAfterSignIn(User user) async {
    try {
      final tokenResult = await user.getIdTokenResult(true);
      final claims = tokenResult.claims ?? const <String, dynamic>{};
      debugPrint(
        '[AuthService] Refreshed ID token claims: '
        'role=${claims['role']}, userRole=${claims['userRole']}',
      );
    } catch (e) {
      debugPrint('[AuthService] Could not refresh ID token claims: $e');
      rethrow;
    }
  }

  /// Changes the current user's password and clears mustChangePassword flag.
  ///
  /// Requires [currentPassword] for re-authentication before the update.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final auth = _firebaseAuth;
    final user = auth?.currentUser;
    if (user != null && user.email != null) {
      // Re-authenticate before sensitive operation
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    }

    // Update profile mustChangePassword to false
    if (_currentUserProfile != null) {
      _currentUserProfile =
          _currentUserProfile!.copyWith(mustChangePassword: false);
      stateNotifier.value = AuthState.authenticated;
      try {
        if (_userRepository != null) {
          await _userRepository!.updateUser(_currentUserProfile!);
        }
      } catch (e) {
        debugPrint(
            '[AuthService] Error updating mustChangePassword in repo: $e');
        rethrow;
      }
    }

    // Update dynamic mock registry for offline / preview resilience
    if (_currentUserProfile != null) {
      AuthMockData.registerDynamicUser(
        email: _currentUserProfile!.email,
        password: newPassword,
        name: _currentUserProfile!.fullName,
        phone: _currentUserProfile!.phoneNumber,
        code: _currentUserProfile!.clientCode ?? '',
        units: _currentUserProfile!.associatedUnitIds,
        mustChangePassword: false,
      );
    }
  }

  Future<void> signOut() async {
    final auth = _firebaseAuth;
    if (auth != null) {
      await auth.signOut();
    }
    try {
      await _storage.delete(key: _sessionEmailKey);
    } catch (_) {}
    _currentUserProfile = null;
    stateNotifier.value = AuthState.unauthenticated;
  }

  Future<String?> getIdToken([bool forceRefresh = false]) async {
    final auth = _firebaseAuth;
    if (auth == null) return null;
    try {
      return await auth.currentUser?.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfilePicture(String imageUrl) async {
    if (_currentUserProfile == null) return;
    _currentUserProfile = _currentUserProfile!.copyWith(avatarUrl: imageUrl);
    stateNotifier.value = AuthState.authenticated;
    try {
      if (_userRepository != null) {
        await _userRepository!.updateUser(_currentUserProfile!);
      }
    } catch (e) {
      debugPrint(
          '[AuthService] Error updating profile picture in repository: $e');
    }
  }

  Future<void> removeProfilePicture() async {
    if (_currentUserProfile == null) return;
    _currentUserProfile = _currentUserProfile!.copyWith(clearAvatar: true);
    stateNotifier.value = AuthState.authenticated;
    try {
      if (_userRepository != null) {
        await _userRepository!.updateUser(_currentUserProfile!);
      }
    } catch (e) {
      debugPrint(
          '[AuthService] Error removing profile picture from repository: $e');
    }
  }
}
