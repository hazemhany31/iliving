import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/main.dart';
import 'package:iliving/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Error Handling and Stability Tests', () {
    setUp(() async {
      await AuthService.instance.logout();
    });

    testWidgets('Entering invalid password shows clear error banner without resetting screen', (WidgetTester tester) async {
      await tester.pumpWidget(const LuxuryRealEstateApp());
      await tester.pumpAndSettle();

      // Open Login Form Sheet
      final getStartedBtn = find.byKey(const Key('get_started_btn'));
      expect(getStartedBtn, findsOneWidget);
      await tester.tap(getStartedBtn);
      await tester.pumpAndSettle();

      // Enter known email but intentionally incorrect password
      final emailField = find.byKey(const Key('login_email_field'));
      final passField = find.byKey(const Key('login_password_field'));
      expect(emailField, findsOneWidget);
      expect(passField, findsOneWidget);

      await tester.enterText(emailField, 'ahmed.shazly.abdelgawad@new-build-egypt.com');
      await tester.enterText(passField, 'completely_wrong_pass_999');
      await tester.pumpAndSettle();

      // Tap Submit
      final submitBtn = find.byKey(const Key('login_submit_btn'));
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify that user is NOT authenticated
      expect(AuthService.instance.isAuthenticated, isFalse);

      // Verify that the login form sheet is STILL open and email is preserved
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.text('ahmed.shazly.abdelgawad@new-build-egypt.com'), findsOneWidget);

      // Verify that error banner or error icon is visible
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('Demo quick login chips are permanently removed from release UI', (WidgetTester tester) async {
      await tester.pumpWidget(const LuxuryRealEstateApp());
      await tester.pumpAndSettle();

      // Open Login Form Sheet
      await tester.tap(find.byKey(const Key('get_started_btn')));
      await tester.pumpAndSettle();

      // Verify that demo quick-login chips are ABSOLUTELY GONE
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Owner (Demo)'), findsNothing);
      expect(find.text('Client 87'), findsNothing);
      expect(find.text('Broker'), findsNothing);
      expect(find.byIcon(Icons.flash_on_rounded), findsNothing);

      // Verify manual entry works
      final emailField = find.byKey(const Key('login_email_field'));
      final passField = find.byKey(const Key('login_password_field'));
      await tester.enterText(emailField, 'admin@new-build-egypt.com');
      await tester.enterText(passField, 'iliving2026');
      await tester.pumpAndSettle();

      expect(find.text('admin@new-build-egypt.com'), findsOneWidget);
    });
  });
}
