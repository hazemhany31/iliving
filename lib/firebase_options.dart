// File generated for iLiving Real Estate Unified Platform.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, kReleaseMode, TargetPlatform;

/// Default [FirebaseOptions] for use with iLiving Firebase services across platforms.
///
/// These are REAL credentials pulled from the Firebase Console (project: nbig-app)
/// via `firebase apps:sdkconfig`.  The [assertRealCredentials] guard validates
/// that no placeholder keys slipped back in for release builds.
class DefaultFirebaseOptions {
  /// Call during app bootstrap to ensure we're not running with placeholder
  /// keys in a release binary.
  static void assertRealCredentials() {
    if (!kReleaseMode) return; // allow placeholders in debug/profile
    final key = currentPlatform.apiKey;
    if (key.contains('DemoKey') || key.contains('PLACEHOLDER')) {
      throw StateError(
        '\n╔══════════════════════════════════════════════════════════╗\n'
        '║  FATAL: Firebase is configured with PLACEHOLDER keys.  ║\n'
        '║  Replace firebase_options.dart with real credentials    ║\n'
        '║  from your Firebase Console before shipping.            ║\n'
        '╚══════════════════════════════════════════════════════════╝',
      );
    }
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        return web;
      default:
        return web;
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Real credentials — Firebase project: nbig-app (610302298484)
  //  Pulled via:  firebase apps:sdkconfig <PLATFORM> <APP_ID> --project nbig-app
  // ──────────────────────────────────────────────────────────────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAOYjOjxFznpV1st9cW2q7ADRlmSzQCmXk',
    appId: '1:610302298484:web:f77e47d11773ddadfd0421',
    messagingSenderId: '610302298484',
    projectId: 'nbig-app',
    authDomain: 'nbig-app.firebaseapp.com',
    storageBucket: 'nbig-app.firebasestorage.app',
    measurementId: 'G-WFKWZ9ENFC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4LrQKOWySgY31rwg6XEw4G_sijbbdHr4',
    appId: '1:610302298484:android:ab07fc61a51c9c24fd0421',
    messagingSenderId: '610302298484',
    projectId: 'nbig-app',
    storageBucket: 'nbig-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBCLDR9-Eyo-juuzZRdR9dxXI0UUe4Xykk',
    appId: '1:610302298484:ios:7324d41e59ed3565fd0421',
    messagingSenderId: '610302298484',
    projectId: 'nbig-app',
    storageBucket: 'nbig-app.firebasestorage.app',
    iosBundleId: 'com.hazemhany.iliving',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBCLDR9-Eyo-juuzZRdR9dxXI0UUe4Xykk',
    appId: '1:610302298484:ios:7324d41e59ed3565fd0421',
    messagingSenderId: '610302298484',
    projectId: 'nbig-app',
    storageBucket: 'nbig-app.firebasestorage.app',
    iosBundleId: 'com.hazemhany.iliving',
  );
}
