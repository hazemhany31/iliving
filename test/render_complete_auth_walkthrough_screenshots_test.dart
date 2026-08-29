import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/services/auth_service.dart';
import 'package:iliving/screens/login_screen.dart';
import 'package:iliving/screens/change_password_screen.dart';
import 'package:iliving/screens/admin/admin_portal_shell.dart';
import 'package:iliving/screens/admin/executive_dashboard_screen.dart';
import 'package:iliving/screens/owner_home_screen.dart';
import 'package:iliving/theme/luxury_theme.dart';
import 'package:iliving/l10n/app_localizations.dart';
import 'package:iliving/services/sync_state.dart';

const artifactDir = '/Users/hazemhany/.gemini/antigravity-ide/brain/07070bd3-82ca-407d-bfc3-cae0b58d1eb6';

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

Future<void> saveScreenshot(WidgetTester tester, String filename) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final boundaryFinder = find.byKey(const Key('screenshot_root'));
  final RenderRepaintBoundary boundary = tester.renderObject(boundaryFinder);
  final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData != null) {
    final filePath = '$artifactDir/$filename';
    File(filePath).writeAsBytesSync(byteData.buffer.asUint8List());
    print('✓ Saved UI Screenshot: $filePath');
  }
}

Widget buildFrame({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: LuxuryTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: RepaintBoundary(
        key: const Key('screenshot_root'),
        child: child,
      ),
    ),
  );
}

void main() {
  setupMocks();

  testWidgets('Generate Complete UI Flow Screenshots for Release Verification', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final syncManager = SyncStateManager();

    // ── STEP 1: Sign In Screen (Cleaned, Demo Chips Removed) ───────────
    await tester.pumpWidget(
      SyncScope(
        manager: syncManager,
        child: buildFrame(child: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Open Bottom Sheet Form
    final getStartedBtn = find.byKey(const Key('get_started_btn'));
    if (getStartedBtn.evaluate().isNotEmpty) {
      await tester.tap(getStartedBtn);
      await tester.pumpAndSettle();
    }

    // Verify Demo Chips are completely gone
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Owner (Demo)'), findsNothing);
    expect(find.text('Client 87'), findsNothing);
    expect(find.text('Broker'), findsNothing);

    await saveScreenshot(tester, '01_login_screen_cleaned_no_demo_chips.png');

    // ── STEP 2: Forced Password Change Screen for Admin ────────────────
    await tester.pumpWidget(
      SyncScope(
        manager: syncManager,
        child: buildFrame(child: const ChangePasswordScreen(forced: true)),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Forced State
    expect(find.text('Set New Password'), findsOneWidget);
    expect(find.text('Mandatory First-Time Security Requirement:\nPlease set a new personal password before accessing your account.'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);

    await saveScreenshot(tester, '02_admin_forced_password_change_screen.png');

    // ── STEP 3: Admin Landing on Executive Dashboard ───────────────────
    await tester.pumpWidget(
      SyncScope(
        manager: syncManager,
        child: buildFrame(
          child: const AdminPortalShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveScreenshot(tester, '03_admin_post_password_change_dashboard.png');

    // ── STEP 4: Client Landing on Owner Portal ─────────────────────────
    await tester.pumpWidget(
      SyncScope(
        manager: syncManager,
        child: buildFrame(
          child: const OwnerHomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveScreenshot(tester, '04_client_owner_portal_home_screen.png');
  });
}
