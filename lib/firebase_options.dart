// File generated for iLiving Real Estate Unified Platform.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, kReleaseMode, TargetPlatform;

/// Default [FirebaseOptions] for use with iLiving Firebase services across platforms.
///
/// These are REAL credentials pulled from dedicated Firebase project: `iliving-app` (252930638809)
/// via `firebase apps:sdkconfig`. The [assertRealCredentials] guard validates
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
  //  Real credentials — Dedicated Firebase project: iliving-app (252930638809)
  //  Pulled via:  firebase apps:sdkconfig <PLATFORM> <APP_ID> --project iliving-app
  // ──────────────────────────────────────────────────────────────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCwJ5HxZs1fg_r33pmkKhraoXTmEojkbjI',
    appId: '1:252930638809:web:b341900b5f8ad313160fc8',
    messagingSenderId: '252930638809',
    projectId: 'iliving-app',
    authDomain: 'iliving-app.firebaseapp.com',
    storageBucket: 'iliving-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHa_uy5WYhr9fXzz3pwc7ectOjrSZIPPY',
    appId: '1:252930638809:android:dd839b61fd0dcdc7160fc8',
    messagingSenderId: '252930638809',
    projectId: 'iliving-app',
    storageBucket: 'iliving-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAmezFfwIwBfEQyIPOLgw3iXFuyhtLhwNs',
    appId: '1:252930638809:ios:dfc44964c820ba44160fc8',
    messagingSenderId: '252930638809',
    projectId: 'iliving-app',
    storageBucket: 'iliving-app.firebasestorage.app',
    iosBundleId: 'com.hazemhany.iliving',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAmezFfwIwBfEQyIPOLgw3iXFuyhtLhwNs',
    appId: '1:252930638809:ios:dfc44964c820ba44160fc8',
    messagingSenderId: '252930638809',
    projectId: 'iliving-app',
    storageBucket: 'iliving-app.firebasestorage.app',
    iosBundleId: 'com.hazemhany.iliving',
  );
}
