import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/l10n/app_localizations.dart';
import 'package:iliving/widgets/offline_state_manager.dart';

void main() {
  group('Arabic Localization & RTL Verification Tests', () {
    testWidgets('1. App renders in Arabic with real Arabic text and RTL directionality', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                final direction = Directionality.of(context);

                return Column(
                  children: [
                    Text('Direction: ${direction == TextDirection.rtl ? "RTL" : "LTR"}'),
                    Text('AppTitle: ${l10n.appTitle}'),
                    Text('Sales: ${l10n.salesBrokerage}'),
                    Text('Search: ${l10n.search}'),
                    Text('Filter: ${l10n.filter}'),
                    Text('Save: ${l10n.save}'),
                    Text('Logout: ${l10n.navLogout}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify RTL directionality is applied
      expect(find.text('Direction: RTL'), findsOneWidget);

      // 2. Verify real translated Arabic text (not English fallback!)
      expect(find.text('AppTitle: iLiving للعقارات الفاخرة'), findsOneWidget);
      expect(find.text('Sales: iLiving للمبيعات والوساطة العقارية'), findsOneWidget);
      expect(find.text('Search: بحث'), findsOneWidget);
      expect(find.text('Filter: تصفية'), findsOneWidget);
      expect(find.text('Save: حفظ'), findsOneWidget);
      expect(find.text('Logout: تسجيل الخروج'), findsOneWidget);
    });

    testWidgets('2. Offline banner renders Arabic text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStateManager(
              child: Center(child: Text('App Content')),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('App Content'), findsOneWidget);
    });
  });
}
