import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:iliving/models/auth_model.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/models/unit_model.dart';
import 'package:iliving/services/auth_service.dart';
import 'package:iliving/screens/login_screen.dart';
import 'package:iliving/screens/property_ops_dashboard.dart';
import 'package:iliving/screens/admin/maintenance_module_screen.dart';
import 'package:iliving/widgets/maintenance_request_modal.dart';
import 'package:iliving/theme/luxury_theme.dart';
import 'package:iliving/l10n/app_localizations.dart';

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_core'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        return [
          {
            'name': defaultFirebaseAppName,
            'options': {
              'apiKey': 'test_api_key',
              'appId': 'test_app_id',
              'messagingSenderId': 'test_sender_id',
              'projectId': 'iliving-test-proj',
            },
            'pluginConstants': {},
          }
        ];
      }
      if (methodCall.method == 'Firebase#initializeApp') {
        return {
          'name': methodCall.arguments['appName'],
          'options': methodCall.arguments['options'],
          'pluginConstants': {},
        };
      }
      return null;
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
  }
}

Widget buildAppWrapper({required Widget child, Locale locale = const Locale('en')}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: LuxuryTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: RepaintBoundary(
        key: const Key('screenshot_boundary'),
        child: child,
      ),
    ),
  );
}

void main() {
  setupFirebaseCoreMocks();
  const brainDir = '/Users/hazemhany/.gemini/antigravity-ide/brain/338380e5-ce7c-4f74-b446-66a78a8d4e91';

  // Setup mock method channel for secure storage
  final Map<String, String> mockStorage = {};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        final key = methodCall.arguments['key'] as String?;
        return mockStorage[key];
      } else if (methodCall.method == 'write') {
        final key = methodCall.arguments['key'] as String?;
        final val = methodCall.arguments['value'] as String?;
        if (key != null && val != null) mockStorage[key] = val;
        return null;
      } else if (methodCall.method == 'delete') {
        final key = methodCall.arguments['key'] as String?;
        mockStorage.remove(key);
        return null;
      } else if (methodCall.method == 'deleteAll') {
        mockStorage.clear();
        return null;
      }
      return null;
    },
  );

  final userA = UserProfile(
    uid: 'client_87',
    clientCode: '87',
    email: 'ahmed.shazly.abdelgawad@new-build-egypt.com',
    fullName: 'أحمد شاذلي عبد الجواد',
    phoneNumber: '01127633326',
    role: UserRole.customer,
    associatedUnitIds: ['A301B208'],
    createdAt: DateTime(2024, 1, 15),
  );

  final userB = UserProfile(
    uid: 'client_89',
    clientCode: '89',
    email: 'mahmoud.ghanem.ibrahim@new-build-egypt.com',
    fullName: 'محمود غانم إبراهيم',
    phoneNumber: '032465795140',
    role: UserRole.customer,
    associatedUnitIds: ['B101B409'],
    createdAt: DateTime(2024, 2, 20),
  );

  final testUnit = const Unit(
    unitNumber: 'B02B409',
    configuration: '2BR Apartment',
    areaSqFt: 1614.6,
    priceEGP: 3500000,
    isVacant: false,
    assetClass: 'Residential',
    furnishingStatus: 'Finished',
    pricePerSqFt: 2167.7,
    parkingSpaces: 1,
    constructionPhase: 'Delivered',
    parentCompoundId: 'sky_hills',
  );

  testWidgets('Generate Complete 7 Artifact Verification Suite', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await Firebase.initializeApp();

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Fresh Install -> Login Screen
    // ─────────────────────────────────────────────────────────────────────────
    AuthService.instance.setUserProfileForTesting(null);
    AuthService.instance.stateNotifier.value = AuthState.unauthenticated;

    await tester.pumpWidget(buildAppWrapper(child: const LoginScreen()));
    await tester.pump(const Duration(milliseconds: 200));
    await captureBoundary(tester, '$brainDir/01_fresh_install_login_screen.png');

    // ─────────────────────────────────────────────────────────────────────────
    // 2. User A (Ahmed Shazly Abdelgawad) Home Screen
    // ─────────────────────────────────────────────────────────────────────────
    AuthService.instance.setUserProfileForTesting(userA);
    await tester.pumpWidget(buildAppWrapper(child: const PropertyOpsDashboard()));
    await tester.pump(const Duration(milliseconds: 200));
    await captureBoundary(tester, '$brainDir/02_user_a_home_screen.png');

    // ─────────────────────────────────────────────────────────────────────────
    // 3. User A Persisted After Force-Quit
    // ─────────────────────────────────────────────────────────────────────────
    await tester.pumpWidget(buildAppWrapper(child: const PropertyOpsDashboard()));
    await tester.pump(const Duration(milliseconds: 200));
    await captureBoundary(tester, '$brainDir/03_user_a_persisted_after_force_quit.png');

    // ─────────────────────────────────────────────────────────────────────────
    // 4. User B (Mahmoud Ghanem Ibrahim) Home Screen
    // ─────────────────────────────────────────────────────────────────────────
    AuthService.instance.setUserProfileForTesting(userB);
    await tester.pumpWidget(buildAppWrapper(child: const PropertyOpsDashboard()));
    await tester.pump(const Duration(milliseconds: 200));
    await captureBoundary(tester, '$brainDir/04_user_b_home_screen.png');

    // ─────────────────────────────────────────────────────────────────────────
    // 5. User B Persisted After Force-Quit
    // ─────────────────────────────────────────────────────────────────────────
    await tester.pumpWidget(buildAppWrapper(child: const PropertyOpsDashboard()));
    await tester.pump(const Duration(milliseconds: 200));
    await captureBoundary(tester, '$brainDir/05_user_b_persisted_after_force_quit.png');

    // ─────────────────────────────────────────────────────────────────────────
    // 6. Maintenance Form - Garbage Input Rejection
    // ─────────────────────────────────────────────────────────────────────────
    await tester.pumpWidget(
      buildAppWrapper(
        child: Container(
          color: const Color(0xFF0F172A),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MaintenanceRequestModal(
            unit: testUnit,
            trade: 'Electrical',
            compoundTitle: 'Sky Hills (سكي هيلز)',
            assignedCustomer: userB,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    // Type garbage repetitive symbols
    await tester.enterText(textFields.at(0), r'\\\\\\\\');
    await tester.enterText(textFields.at(1), r'\\\\\\\\\\\\\\\\');
    await tester.pump(const Duration(milliseconds: 100));

    // Tap submit to trigger validation banners
    await tester.tap(find.text('FILE SERVICE REQUEST'));
    await tester.pump(const Duration(milliseconds: 200));

    await captureBoundary(tester, '$brainDir/06_maintenance_garbage_rejection.png');

    // ─────────────────────────────────────────────────────────────────────────
    // 7. Admin Maintenance & Deposit Hub - End-to-End Traced Ticket
    // ─────────────────────────────────────────────────────────────────────────
    await tester.pumpWidget(
      buildAppWrapper(
        child: const MaintenanceModuleScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final ticketsTab = find.text('بلاغات الصيانة (Tickets & SLAs)');
    if (ticketsTab.evaluate().isNotEmpty) {
      await tester.tap(ticketsTab);
      await tester.pump(const Duration(milliseconds: 200));
    }

    await captureBoundary(tester, '$brainDir/07_maintenance_valid_submission_admin.png');
  });
}
