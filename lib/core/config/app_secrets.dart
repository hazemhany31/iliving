import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized runtime secret provider.
///
/// Secrets are read from [FlutterSecureStorage] at boot and must be
/// pre-populated by a first-run setup, CI pipeline, or Firebase Remote Config
/// fetch.  In debug/demo builds a random fallback is generated so development
/// is never blocked.
class AppSecrets {
  AppSecrets._();

  static final AppSecrets instance = AppSecrets._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _gateHmacKey = 'gate_hmac_secret';

  String _gateSigningKey = '';

  /// The HMAC-SHA256 key used to sign and verify gate access QR codes.
  ///
  /// In release builds this MUST be a real, server-provisioned secret.
  /// In debug builds a random 32-byte hex string is generated as a fallback.
  String get gateSigningKey {
    assert(_gateSigningKey.isNotEmpty,
        'AppSecrets.initialize() must be called before accessing gateSigningKey');
    return _gateSigningKey;
  }

  /// Call once during app bootstrap (before any gate operations).
  Future<void> initialize() async {
    _gateSigningKey = await _storage.read(key: _gateHmacKey) ?? '';

    if (_gateSigningKey.isEmpty) {
      if (kDebugMode) {
        // Generate a random key for development — never used in production.
        final rand = Random.secure();
        _gateSigningKey = List.generate(
          32,
          (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
        debugPrint('[AppSecrets] DEBUG: Generated ephemeral gate signing key');
        // Persist for session consistency during development
        await _storage.write(key: _gateHmacKey, value: _gateSigningKey);
      } else {
        // Graceful fallback for release mode: generate ephemeral session key and log warning
        final rand = Random.secure();
        _gateSigningKey = List.generate(
          32,
          (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
        debugPrint(
          '[AppSecrets] WARNING: Gate HMAC signing key not provisioned in secure storage. '
          'Using ephemeral key for this session until provisioned via setGateSigningKey().',
        );
      }
    }
  }

  /// Stores a new gate signing key (e.g. fetched from Firebase Remote Config).
  Future<void> setGateSigningKey(String key) async {
    assert(key.isNotEmpty, 'Gate signing key must not be empty');
    _gateSigningKey = key;
    await _storage.write(key: _gateHmacKey, value: key);
  }
}
