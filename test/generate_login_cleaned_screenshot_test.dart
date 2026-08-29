import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:iliving/screens/login_screen.dart';
import 'package:iliving/screens/change_password_screen.dart';
import 'package:iliving/l10n/app_localizations.dart';
import 'package:iliving/theme/luxury_theme.dart';
import 'package:iliving/services/sync_state.dart';

void main() {
  testWidgets('Capture Cleaned Login Screen and Forced Change Password Screen', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final syncManager = SyncStateManager();

    // 1. Render Login Screen
    await tester.pumpWidget(
      SyncScope(
        manager: syncManager,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LuxuryTheme.lightTheme,
          darkTheme: LuxuryTheme.darkTheme,
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that quick-login chips are ABSOLUTELY GONE
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Owner (Demo)'), findsNothing);
    expect(find.text('Client 87'), findsNothing);
    expect(find.text('Broker'), findsNothing);
    expect(find.byIcon(Icons.flash_on_rounded), findsNothing);

    // Verify Sign In form components
    expect(find.byKey(const Key('login_submit_btn')), findsOneWidget);
    expect(find.byKey(const Key('login_email_input')), findsOneWidget);
    expect(find.byKey(const Key('login_password_input')), findsOneWidget);

    print('✓ LoginScreen verification passed: Quick-login chips completely absent.');

    // 2. Render Forced Change Password Screen
    await tester.pumpWidget(
      SyncScope(
        manager: syncManager,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LuxuryTheme.lightTheme,
          darkTheme: LuxuryTheme.darkTheme,
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChangePasswordScreen(forced: true),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Set New Password'), findsOneWidget);
    expect(find.text('Mandatory First-Time Security Requirement:\nPlease set a new personal password before accessing your account.'), findsOneWidget);
    expect(find.byType(PopScope), findsOneWidget);
    // Confirm back button is absent in forced mode
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);

    print('✓ ChangePasswordScreen (forced) verification passed: PopScope active & no back button.');
  });
}
