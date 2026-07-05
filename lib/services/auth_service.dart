import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/auth_model.dart';
import 'auth_interface.dart';
import 'auth_mock_data.dart';

/// Concrete implementation of the client authentication service implementing [IAuthService].
class AuthService implements IAuthService {
  AuthService._internal();

  /// Singleton access point.
  static final AuthService instance = AuthService._internal();

  @override
  final ValueNotifier<AuthState> stateNotifier =
      ValueNotifier(AuthState.unauthenticated);

  @override
  AuthState get currentState => stateNotifier.value;

  ClientProfile? _cachedProfile;

  @override
  ClientProfile? get currentProfile => _cachedProfile;

  String? _cachedToken;

  /// Returns the current raw token.
  String? get bearerToken => _cachedToken;

  void _emit(AuthState state) {
    stateNotifier.value = state;
    debugPrint("[AuthService] Emitted state change: $state");
  }

  @override
  Future<void> initialize() async {
    _emit(AuthState.authenticating);
    if (_cachedProfile != null) {
      _emit(AuthState.authenticated);
      return;
    }
    final completer = Completer<void>();
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          try {
            _cachedToken = await user.getIdToken();
            final mapped = _resolveProfileFromFirebaseUser(user);
            _cachedProfile = mapped ?? ClientProfile(
              clientId: user.uid,
              displayName: user.displayName ?? _resolveDisplayName(user.email ?? ''),
              email: user.email ?? '',
              ownedUnitIds: const ['B01B202'],
              assignedLedgerId: 'ledger_${user.uid}',
            );
            _emit(AuthState.authenticated);
          } catch (e) {
            debugPrint("[AuthService] Error in auth changes listener mapping: $e");
            _emit(AuthState.unauthenticated);
          }
        } else {
          if (_cachedProfile == null) {
            _cachedToken = null;
            _emit(AuthState.unauthenticated);
          } else {
            _emit(AuthState.authenticated);
          }
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      }, onError: (err) {
        debugPrint("[AuthService] Listener error in state changes: $err");
        if (!completer.isCompleted) {
          _emit(AuthState.unauthenticated);
          completer.complete();
        }
      });
    } catch (e) {
      debugPrint("[AuthService] Firebase auth not initialized or failed on start: $e");
      _emit(AuthState.unauthenticated);
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    try {
      await completer.future.timeout(const Duration(milliseconds: 500));
    } catch (_) {
      // Graceful timeout fallback
      if (currentState == AuthState.authenticating) {
        _emit(AuthState.unauthenticated);
      }
    }
  }

  /// Verification checks.
  Future<bool> isAuthenticated() async {
    if (_cachedProfile != null) return true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      _cachedToken = await user.getIdToken();
      return true;
    } catch (e) {
      debugPrint("[AuthService] Error checking isAuthenticated: $e");
      return false;
    }
  }

  /// Token access wrapper.
  Future<String?> getValidToken() async {
    if (_cachedProfile != null) return _cachedToken;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      _cachedToken = await user.getIdToken(true);
      return _cachedToken;
    } catch (e) {
      debugPrint("[AuthService] Error retrieving valid token: $e");
      return null;
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    _emit(AuthState.authenticating);
    final input = email.trim().toLowerCase();
    final cleanInput = input.replaceAll(RegExp(r'[^0-9]'), '');

    // 1. Look up in consolidated mock registry database
    final matched = AuthMockData.findProfile(cleanInput);
    if (matched != null) {
      final code = matched['code'] as String;
      if (password == AuthMockData.defaultMasterPassword || password == code || password == 'IHome${code}2026!') {
        _cachedToken = 'ihome_token_$code';
        final List<String> resolvedUnits = matched.containsKey('units')
            ? (matched['units'] as List).cast<String>()
            : [matched['unit'] as String];
        
        _cachedProfile = ClientProfile(
          clientId: 'client_$code',
          displayName: matched['name'] as String,
          email: 'client$code@new-build-egypt.com',
          ownedUnitIds: resolvedUnits,
          assignedLedgerId: 'ledger_$code',
        );
        _emit(AuthState.authenticated);
        return true;
      }
    }

    // 2. Demo credentials fallback
    if (input == 'demo@ihome.com.eg' && password == AuthMockData.defaultMasterPassword) {
      _cachedToken = 'ihome_token_demo';
      _cachedProfile = const ClientProfile(
        clientId: 'client_demo',
        displayName: 'أحمد عبد العظيم صدقي',
        email: 'demo@ihome.com.eg',
        ownedUnitIds: ['B01B202'],
        assignedLedgerId: 'ledger_147',
      );
      _emit(AuthState.authenticated);
      return true;
    }

    // 3. Fallback to Firebase email/password authentication
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        _cachedToken = await user.getIdToken();
        _cachedProfile = ClientProfile(
          clientId: user.uid,
          displayName: user.displayName ?? _resolveDisplayName(user.email ?? ''),
          email: user.email ?? '',
          ownedUnitIds: const ['SH/12/1204', 'ZL/08/801'],
          assignedLedgerId: 'ledger_${user.uid}',
        );
        _emit(AuthState.authenticated);
        return true;
      }
      _emit(AuthState.unauthenticated);
      return false;
    } catch (e) {
      debugPrint("[AuthService] Firebase Authentication flow exception: $e");
      _emit(AuthState.unauthenticated);
      return false;
    }
  }

  String _resolveDisplayName(String email) {
    if (email.contains('sterling')) return 'Alistair Sterling';
    if (email.contains('admin')) return 'iHome Administrator';
    return 'iHome Client';
  }

  ClientProfile? _resolveProfileFromFirebaseUser(User user) {
    final email = user.email?.trim().toLowerCase() ?? '';
    final phone = user.phoneNumber?.trim() ?? '';
    final displayName = user.displayName ?? '';

    for (final u in AuthMockData.mockUsers) {
      final cleanPhone = (u['phone'] as String).replaceAll(RegExp(r'[^0-9]'), '');
      final cleanEmail = '$cleanPhone@new-build-egypt.com';
      if (email.contains(cleanPhone) || 
          phone.contains(cleanPhone) || 
          displayName.contains(u['name'] as String) || 
          email == cleanEmail) {
        final List<String> resolvedUnits = u.containsKey('units')
            ? (u['units'] as List).cast<String>()
            : [u['unit'] as String];
        return ClientProfile(
          clientId: 'client_${u['code']}',
          displayName: u['name'] as String,
          email: 'client${u['code']}@new-build-egypt.com',
          ownedUnitIds: resolvedUnits,
          assignedLedgerId: 'ledger_${u['code']}',
        );
      }
    }
    return null;
  }

  @override
  Future<ClientProfile> loadClientProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return ClientProfile.fallback;
      final mapped = _resolveProfileFromFirebaseUser(user);
      _cachedProfile = mapped ?? ClientProfile(
        clientId: user.uid,
        displayName: user.displayName ?? _resolveDisplayName(user.email ?? ''),
        email: user.email ?? '',
        ownedUnitIds: const ['B01B202'],
        assignedLedgerId: 'ledger_${user.uid}',
      );
      return _cachedProfile!;
    } catch (e) {
      debugPrint("[AuthService] Profile retrieval failed, returning fallback: $e");
      return ClientProfile.fallback;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("[AuthService] Firebase signOut error: $e");
    }
    _cachedToken = null;
    _cachedProfile = null;
    _emit(AuthState.unauthenticated);
  }
}
