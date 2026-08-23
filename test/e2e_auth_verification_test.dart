import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/main.dart';
import 'package:iliving/screens/login_screen.dart';
import 'package:iliving/services/auth_service.dart';
import 'package:iliving/services/sync_state.dart';

void main() {
  testWidgets('E2E Auth Flow: Login A -> Persist -> Logout -> Login B -> Persist', (WidgetTester tester) async {
    // 1. Launch App (Fresh State)
    await AuthService.instance.signOut();
    await tester.pumpWidget(const LuxuryRealEstateApp());
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    print('All widget types: ${tester.allWidgets.map((w) => w.runtimeType).toSet()}');
    print('Found get_started_btn: ${find.byKey(const Key('get_started_btn')).evaluate().length}');

    // 2. Open Login Form
    await tester.tap(find.byKey(const Key('get_started_btn')));
    await tester.pump(const Duration(milliseconds: 500));

    // Enter User A Credentials
    final emailField = find.byType(TextFormField).first;
    final passField = find.byType(TextFormField).last;

    await tester.enterText(emailField, 'ahmed.shazly.abdelgawad@new-build-egypt.com');
    await tester.enterText(passField, 'iliving2026');
    await tester.pump(const Duration(milliseconds: 500));

    // Tap Login Button
    await tester.tap(find.byKey(const Key('login_submit_btn')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Verify User A is logged in
    expect(AuthService.instance.isAuthenticated, isTrue);
    expect(AuthService.instance.currentProfile?.fullName, 'أحمد شاذلي عبد الجواد');
    expect(AuthService.instance.currentProfile?.associatedUnitIds, contains('A301B208'));

    // Verify UI reflects User A
    expect(find.textContaining('A301B208'), findsWidgets);

    // 3. Simulate App Restart with User A
    // In restart, LuxuryRealEstateApp bootstraps from persistent AuthService state
    await tester.pumpWidget(const LuxuryRealEstateApp());
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Must still be User A Home screen, not Login screen
    expect(AuthService.instance.isAuthenticated, isTrue);
    expect(AuthService.instance.currentProfile?.fullName, 'أحمد شاذلي عبد الجواد');
    expect(find.textContaining('A301B208'), findsWidgets);
    expect(find.byKey(const Key('get_started_btn')), findsNothing);

    // 4. Logout User A
    await AuthService.instance.signOut();
    await tester.pumpWidget(const LuxuryRealEstateApp());
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Must show Login screen
    expect(AuthService.instance.isAuthenticated, isFalse);
    expect(find.byKey(const Key('get_started_btn')), findsOneWidget);

    // 5. Login User B
    await tester.tap(find.byKey(const Key('get_started_btn')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextFormField).first, 'mahmoud.ghanem.ibrahim@new-build-egypt.com');
    await tester.enterText(find.byType(TextFormField).last, 'iliving2026');
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('login_submit_btn')));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Verify User B is logged in
    expect(AuthService.instance.isAuthenticated, isTrue);
    expect(AuthService.instance.currentProfile?.fullName, 'محمود غانم إبراهيم');
    expect(AuthService.instance.currentProfile?.associatedUnitIds, contains('B101B409'));

    // Verify UI reflects User B (not User A)
    expect(find.textContaining('B101B409'), findsWidgets);

    // 6. Simulate App Restart with User B
    await tester.pumpWidget(const LuxuryRealEstateApp());
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(AuthService.instance.isAuthenticated, isTrue);
    expect(AuthService.instance.currentProfile?.fullName, 'محمود غانم إبراهيم');
    expect(find.textContaining('B101B409'), findsWidgets);
    expect(find.byKey(const Key('get_started_btn')), findsNothing);
  });
}
