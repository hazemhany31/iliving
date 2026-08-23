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
  AuthState get currentState => stateNotifier.value;
  bool get isAuthenticated => currentState == AuthState.authenticated && _currentUserProfile != null;

  /// Returns a live Firebase ID token for authenticated API calls.
  ///
  /// Returns `null` when running in demo mode or when no user is signed in.
  Future<String?> get bearerToken async => await getIdToken();

  Future<void> initialize() async {
    if (_isInitialized) return;
    _initAuthListener();

    final auth = _firebaseAuth;
    if (auth != null) {
      final user = auth.currentUser;
      if (user != null) {
        stateNotifier.value = AuthState.authenticating;
        await _resolveAndSetUser(user);
      } else {
        await _tryRestoreCachedSession();
      }
    } else {
      await _tryRestoreCachedSession();
    }
    _isInitialized = true;
  }

  Future<void> _tryRestoreCachedSession() async {
    try {
      final cachedEmail = await _storage.read(key: _sessionEmailKey);
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        UserProfile? profile = await _userRepository?.getUserByEmail(cachedEmail);
        if (profile == null && _allowMock) {
          profile = _resolveDebugProfile(cachedEmail.toLowerCase(), cachedEmail);
        }
        if (profile != null) {
          _currentUserProfile = profile;
          stateNotifier.value = AuthState.authenticated;
          debugPrint('[AuthService] Restored persisted session for $cachedEmail');
          return;
        }
      }
    } catch (_) {}
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
      UserProfile? profile = await _userRepository?.getUserById(user.uid);
      if (profile == null && user.email != null && user.email!.isNotEmpty) {
        profile = await _userRepository?.getUserByEmail(user.email!);
      }
      if (profile == null && _allowMock && user.email != null) {
        profile = _resolveDebugProfile(user.email!.toLowerCase(), user.email!);
      }

      if (profile != null) {
        _currentUserProfile = profile;
        stateNotifier.value = AuthState.authenticated;
      } else {
        // Profile pending creation or fallback
        final idTokenResult = await user.getIdTokenResult();
        final roleStr = idTokenResult.claims?['role'] as String?;
        _currentUserProfile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          phoneNumber: user.phoneNumber ?? '',
          fullName: user.displayName ?? (user.email != null ? user.email!.split('@').first : 'Valued Resident'),
          role: UserRoleX.fromString(roleStr),
          createdAt: DateTime.now(),
        );
        stateNotifier.value = AuthState.authenticated;
      }
    } catch (e) {
      debugPrint('[AuthService] Error fetching profile: $e');
      stateNotifier.value = AuthState.error;
    }
  }

  Future<UserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    stateNotifier.value = AuthState.authenticating;

    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

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
          if ((e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') && _allowMock) {
            // Check if credentials are valid in seed/mock data
            if (AuthMockData.verifyPassword(cleanEmail, cleanPass)) {
              try {
                // Register in Firebase Auth so session persists in Keychain across restarts!
                credential = await auth.createUserWithEmailAndPassword(
                  email: cleanEmail,
                  password: cleanPass,
                );
                final mockProfile = _resolveDebugProfile(cleanEmail, email);
                if (mockProfile != null) {
                  await credential.user?.updateDisplayName(mockProfile.fullName);
                }
              } catch (_) {
                // If create failed (e.g. email-already-in-use with different password), try sign-in again
                credential = await auth.signInWithEmailAndPassword(
                  email: cleanEmail,
                  password: cleanPass,
                );
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
          final fallbackProfile = UserProfile(
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
      }
    }

    // ── 2. Demo/debug mock auth — ONLY when enabled ─────────────────────
    if (_allowMock) {
      if (!AuthMockData.verifyPassword(cleanEmail, cleanPass)) {
        stateNotifier.value = AuthState.unauthenticated;
        throw Exception('Invalid credentials');
      }

      final mockProfile = _resolveDebugProfile(cleanEmail, email);
      if (mockProfile != null) {
        _currentUserProfile = mockProfile;
        stateNotifier.value = AuthState.authenticated;
        try {
          await _storage.write(key: _sessionEmailKey, value: cleanEmail);
        } catch (_) {}
        debugPrint('[AuthService] DEBUG/DEMO: Authenticated via mock profile (${mockProfile.email})');
        return mockProfile;
      }
    }

    stateNotifier.value = AuthState.unauthenticated;
    throw Exception('Invalid credentials');
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
    if (sanitized.startsWith('admin@') || sanitized == 'admin' || sanitized.contains('admin')) {
      return UserProfile(
        uid: 'client_admin',
        clientCode: 'client_admin',
        email: originalEmail.contains('@') ? originalEmail : '$originalEmail@new-build-egypt.com',
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
        email: originalEmail.contains('@') ? originalEmail : '$originalEmail@iliving.com.eg',
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
        email: originalEmail.contains('@') ? originalEmail : '$originalEmail@ihome.com.eg',
        phoneNumber: '01000197979',
        fullName: 'أحمد عبد العظيم صدقي',
        role: UserRole.customer,
        associatedUnitIds: const ['B01B202'],
        createdAt: DateTime.now(),
      );
    }

    // Search mock data registry
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
        uid: 'client_$code',
        clientCode: 'client_$code',
        email: originalEmail.contains('@')
            ? originalEmail
            : (mockData['email'] as String? ?? '$originalEmail@new-build-egypt.com'),
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

  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _firebaseAuth;
    if (auth != null) {
      await auth.sendPasswordResetEmail(email: email);
    }
  }

  /// Changes the current user's password.
  ///
  /// Requires [currentPassword] for re-authentication before the update.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final auth = _firebaseAuth;
    final user = auth?.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user. Please sign in first.');
    }

    // Re-authenticate before sensitive operation
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
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
      debugPrint('[AuthService] Error updating profile picture in repository: $e');
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
      debugPrint('[AuthService] Error removing profile picture from repository: $e');
    }
  }
}
