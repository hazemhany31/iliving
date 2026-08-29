import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:iliving/screens/login_screen.dart';
import 'package:iliving/screens/change_password_screen.dart';
import 'package:iliving/theme/luxury_theme.dart';
import 'package:iliving/l10n/app_localizations.dart';
import 'package:iliving/services/sync_state.dart';

void setupMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_core'),
    (MethodCall methodCall) async {
      return [
        {
          'name': defaultFirebaseAppName,
          'options': {
            'apiKey': 'test_api_key',
            'appId': 'test_app_id',
            'messagingSenderId': 'test_sender_id',
            'projectId': 'iliving-app',
          },
          'pluginConstants': {},
        }
      ];
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_firestore'),
    (MethodCall methodCall) async {
      return {};
    },
  );
}

Future<void> captureBoundary(WidgetTester tester, String path) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final boundaryFinder = find.byKey(const Key('screenshot_boundary'));
  final RenderRepaintBoundary boundary = tester.renderObject(boundaryFinder);
  final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData != null) {
    File(path).writeAsBytesSync(byteData.buffer.asUint8List());
    print('Saved screenshot to $path');
  }
}

void main() {
  setupMocks();

  testWidgets('Capture Login Screen and Forced Change Password Screen Artifacts', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final syncManager = SyncStateManager();
    const artifactDir = '/Users/hazemhany/.gemini/antigravity-ide/brain/07070bd3-82ca-407d-bfc3-cae0b58d1eb6';

    // 1. Render Login Screen & Open Sign In Form
    await tester.pumpWidget(
      SyncScope(
        manager: syncManager,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LuxuryTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            backgroundColor: Colors.black,
            body: RepaintBoundary(
              key: const Key('screenshot_boundary'),
              child: const LoginScreen(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Get Started" to bring up the Sign In form sheet
    final getStartedBtn = find.byKey(const Key('get_started_btn'));
    if (getStartedBtn.evaluate().isNotEmpty) {
      await tester.tap(getStartedBtn);
      await tester.pumpAndSettle();
    }

    // Capture cleaned Login screen
    await captureBoundary(tester, '$artifactDir/login_screen_cleaned.png');

    // 2. Render Forced Change Password Screen
    await tester.pumpWidget(
      SyncScope(
        manager: syncManager,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LuxuryTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            backgroundColor: Colors.black,
            body: RepaintBoundary(
              key: const Key('screenshot_boundary'),
              child: ChangePasswordScreen(forced: true),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Capture forced change password screen
    await captureBoundary(tester, '$artifactDir/forced_change_password_screen.png');
  });
}
