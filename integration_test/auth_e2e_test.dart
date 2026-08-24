import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iliving/main.dart' as app;
import 'package:iliving/services/auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Real Auth Flow: Login A -> Persist -> Logout -> Login B -> Persist', (WidgetTester tester) async {
    // 1. Initial Fresh Launch
    app.main();
    // Pump frames to let seeder & initial routes settle
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Capture Step 1: Fresh install Login screen
    Process.runSync('xcrun', [
      'simctl',
      'io',
      '1FFBA0F0-2C99-4132-ACDB-887563CCD557',
      'screenshot',
      '/Users/hazemhany/.gemini/antigravity-ide/brain/536d143c-157f-48ed-86ae-496607ae16e6/01_fresh_install_login_screen.png'
    ]);

    // 2. Open Login Form
    await tester.tap(find.byKey(const Key('get_started_btn')));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Enter User A Credentials
    final emailFieldA = find.byType(TextFormField).first;
    final passFieldA = find.byType(TextFormField).last;
    await tester.enterText(emailFieldA, 'ahmed.shazly.abdelgawad@new-build-egypt.com');
    await tester.enterText(passFieldA, 'iliving2026');
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Submit Sign In
    await tester.tap(find.byKey(const Key('login_submit_btn')));
    for (int i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Capture Step 2: User A Home Screen
    Process.runSync('xcrun', [
      'simctl',
      'io',
      '1FFBA0F0-2C99-4132-ACDB-887563CCD557',
      'screenshot',
      '/Users/hazemhany/.gemini/antigravity-ide/brain/536d143c-157f-48ed-86ae-496607ae16e6/02_user_a_home_screen.png'
    ]);

    // 3. Simulate App Restart with User A session persisted
    await tester.pumpWidget(const app.LuxuryRealEstateApp());
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Capture Step 3: User A Persisted Home Screen (No login prompt)
    Process.runSync('xcrun', [
      'simctl',
      'io',
      '1FFBA0F0-2C99-4132-ACDB-887563CCD557',
      'screenshot',
      '/Users/hazemhany/.gemini/antigravity-ide/brain/536d143c-157f-48ed-86ae-496607ae16e6/03_user_a_persisted_after_force_quit.png'
    ]);

    // 4. Logout User A
    await AuthService.instance.signOut();
    await tester.pumpWidget(const app.LuxuryRealEstateApp());
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Open Login Form for User B
    await tester.tap(find.byKey(const Key('get_started_btn')));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Enter User B Credentials
    final emailFieldB = find.byType(TextFormField).first;
    final passFieldB = find.byType(TextFormField).last;
    await tester.enterText(emailFieldB, 'mahmoud.ghanem.ibrahim@new-build-egypt.com');
    await tester.enterText(passFieldB, 'iliving2026');
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Submit Sign In User B
    await tester.tap(find.byKey(const Key('login_submit_btn')));
    for (int i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Capture Step 4: User B Home Screen
    Process.runSync('xcrun', [
      'simctl',
      'io',
      '1FFBA0F0-2C99-4132-ACDB-887563CCD557',
      'screenshot',
      '/Users/hazemhany/.gemini/antigravity-ide/brain/536d143c-157f-48ed-86ae-496607ae16e6/04_user_b_home_screen.png'
    ]);

    // 5. Simulate App Restart with User B session persisted
    await tester.pumpWidget(const app.LuxuryRealEstateApp());
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Capture Step 5: User B Persisted Home Screen
    Process.runSync('xcrun', [
      'simctl',
      'io',
      '1FFBA0F0-2C99-4132-ACDB-887563CCD557',
      'screenshot',
      '/Users/hazemhany/.gemini/antigravity-ide/brain/536d143c-157f-48ed-86ae-496607ae16e6/05_user_b_persisted_after_force_quit.png'
    ]);
  });
}
