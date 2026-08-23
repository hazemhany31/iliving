import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/screens/change_password_screen.dart';

void main() {
  group('ChangePasswordScreen UI & Validation Tests', () {
    testWidgets('1. Renders all fields, labels and action button properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChangePasswordScreen(),
        ),
      );

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('2. Rejects empty fields on submission', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChangePasswordScreen(),
        ),
      );

      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text('Please enter your current password'), findsOneWidget);
    });

    testWidgets('3. Rejects short password (< 6 characters)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChangePasswordScreen(),
        ),
      );

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'currentPass123');
      await tester.enterText(textFields.at(1), '123'); // short password
      await tester.enterText(textFields.at(2), '123');

      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters long'), findsOneWidget);
    });

    testWidgets('4. Rejects mismatched password confirmation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChangePasswordScreen(),
        ),
      );

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'currentPass123');
      await tester.enterText(textFields.at(1), 'NewSecretPass2026!');
      await tester.enterText(textFields.at(2), 'DifferentPass2026!');

      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
