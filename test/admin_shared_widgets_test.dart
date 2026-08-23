import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/installment.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/widgets/admin/shared/shared_admin_widgets.dart';

void main() {
  group('STEP 2 Shared Admin Components Verification', () {
    testWidgets('AdminStatusBadge and domain chips render properly in Light and Dark themes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: Column(
              children: [
                AdminStatusBadge(label: 'Active', type: BadgeType.success),
                RoleBadge(role: UserRole.superAdmin),
                UnitStatusChip(status: 'Available', isVacant: true),
                PaymentStatusChip(status: InstallmentStatus.paid),
                MaintenanceStatusChip(status: 'In Progress'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('AdminStatCard renders values and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminStatCard(
              title: 'Total Revenue',
              value: 'EGP 2,675,812',
              subtitle: 'vs. last month',
              icon: Icons.payments,
              percentageChange: 12.5,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('EGP 2,675,812'), findsOneWidget);
      expect(find.text('+12.5%'), findsOneWidget);

      await tester.tap(find.byType(AdminStatCard));
      expect(tapped, isTrue);
    });

    testWidgets('AdminDataTable renders columns and rows correctly', (tester) async {
      final sampleItems = ['Unit A01', 'Unit B203'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminDataTable<String>(
              items: sampleItems,
              columns: [
                AdminTableColumn<String>(
                  title: 'Unit Name',
                  cellBuilder: (item) => Text(item),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Unit Name'), findsOneWidget);
      expect(find.text('Unit A01'), findsOneWidget);
      expect(find.text('Unit B203'), findsOneWidget);
    });

    testWidgets('StateWidgets (Loading, Empty, Error) render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const LoadingState(message: 'Loading inventory...'),
                  EmptyState(
                    title: 'No Contracts Found',
                    description: 'Try adjusting your search criteria.',
                    actionLabel: 'Create Contract',
                    onAction: () {},
                  ),
                  const ErrorState(
                    message: 'Database Connection Timeout',
                    details: 'Failed to fetch unit records.',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Loading inventory...'), findsOneWidget);
      expect(find.text('No Contracts Found'), findsOneWidget);
      expect(find.text('Database Connection Timeout'), findsOneWidget);
    });
  });
}
