// File generated for iLiving Real Estate Unified Platform.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, kReleaseMode, TargetPlatform;

/// Default [FirebaseOptions] for use with iLiving Firebase services across platforms.
///
/// **IMPORTANT:** The API keys below are PLACEHOLDER values for development.
/// Replace them with real credentials from the Firebase Console before any
/// release or staging build.  The [assertRealCredentials] guard will throw
/// at startup if placeholders are detected in a release build.
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

  // ┌──────────────────────────────────────────────────────────────────────┐
  // │  TODO: Replace ALL keys below with real Firebase project values.    │
  // │  Get them from: Firebase Console → Project Settings → Your Apps.    │
  // └──────────────────────────────────────────────────────────────────────┘

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForILivingWebPortal1234567',
    appId: '1:123456789012:web:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'iliving-app',
    authDomain: 'iliving-app.firebaseapp.com',
    storageBucket: 'iliving-app.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForILivingAndroidPortal12',
    appId: '1:123456789012:android:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'iliving-app',
    storageBucket: 'iliving-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForILivingIOSPortal12345',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'iliving-app',
    storageBucket: 'iliving-app.appspot.com',
    iosBundleId: 'com.iliving.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForILivingMacOsPortal123',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'iliving-app',
    storageBucket: 'iliving-app.appspot.com',
    iosBundleId: 'com.iliving.app',
  );
}

