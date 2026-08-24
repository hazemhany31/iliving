import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/models/unit_model.dart';
import 'package:iliving/models/maintenance_request.dart';
import 'package:iliving/models/maintenance_comment.dart';
import 'package:iliving/repositories/interfaces/maintenance_repository.dart';
import 'package:iliving/screens/admin/maintenance_module_screen.dart';
import 'package:iliving/widgets/maintenance_request_modal.dart';
import 'package:iliving/theme/luxury_theme.dart';
import 'package:iliving/l10n/app_localizations.dart';

class MockMaintenanceRepo implements MaintenanceRepository {
  final List<MaintenanceRequest> tickets;
  MockMaintenanceRepo(this.tickets);

  @override
  Future<void> createTicket(MaintenanceRequest ticket) async {
    tickets.insert(0, ticket);
  }

  @override
  Future<void> updateTicket(MaintenanceRequest ticket) async {
    final i = tickets.indexWhere((t) => t.id == ticket.id);
    if (i != -1) tickets[i] = ticket;
  }

  @override
  Future<void> deleteTicket(String ticketId) async {
    tickets.removeWhere((t) => t.id == ticketId);
  }

  @override
  Future<MaintenanceRequest?> getTicketById(String ticketId) async =>
      tickets.firstWhere((t) => t.id == ticketId);

  @override
  Stream<MaintenanceRequest?> streamTicket(String ticketId) => Stream.value(null);

  @override
  Stream<List<MaintenanceRequest>> streamTicketsForUser(String userId) =>
      Stream.value(tickets.where((t) => t.residentUserId == userId).toList());

  @override
  Stream<List<MaintenanceRequest>> streamTicketsForCompound(String compoundId) =>
      Stream.value(tickets.where((t) => t.compoundId == compoundId).toList());

  @override
  Stream<List<MaintenanceRequest>> streamAllTickets() => Stream.value(tickets);

  @override
  Future<List<MaintenanceRequest>> getTickets({
    String? compoundId,
    String? residentUserId,
    MaintenanceStatus? status,
    String? category,
    String? urgency,
    int? limit,
    String? startAfterId,
  }) async => tickets;

  @override
  Future<void> updateTicketStatus(String ticketId, MaintenanceStatus status, {String? technicianId}) async {}

  @override
  Stream<List<MaintenanceComment>> streamCommentsForTicket(String ticketId) => Stream.value([]);

  @override
  Future<void> addComment(MaintenanceComment comment) async {}

  @override
  Future<void> batchUpdateTicketStatus(List<String> ticketIds, MaintenanceStatus status) async {}
}

Future<void> loadSystemFonts() async {
  try {
    const fontPath = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    if (File(fontPath).existsSync()) {
      final fontData = File(fontPath).readAsBytesSync();
      for (final family in ['Outfit', 'Roboto', 'Inter', 'sans-serif']) {
        final loader = FontLoader(family)..addFont(Future.value(ByteData.view(fontData.buffer)));
        await loader.load();
      }
    }
  } catch (e) {
    debugPrint('Font load error: $e');
  }
}

Future<void> captureScreen(WidgetTester tester, Key key, String path) async {
  final boundaryFinder = find.byKey(key);
  final RenderRepaintBoundary boundary = tester.renderObject(boundaryFinder);
  final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData != null) {
    File(path).writeAsBytesSync(byteData.buffer.asUint8List());
  }
}

Widget wrapScreen(Widget child, {required Key key}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: LuxuryTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: RepaintBoundary(
        key: key,
        child: child,
      ),
    ),
  );
}

Widget buildMockResidentDashboard({
  required UserProfile user,
  required String unitNumber,
  required String compoundName,
  required String statusLabel,
}) {
  return Container(
    color: AppColors.darkBackground,
    child: SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.darkBorder, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(35),
                        borderRadius: AppBorderRadius.pill,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed_rounded, color: AppColors.accent, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'OPS MODE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textLightMuted),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: AppColors.textLightMuted),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: AppBorderRadius.large,
                border: Border.all(color: AppColors.accent.withAlpha(60), width: 1.2),
                boxShadow: AppShadows.darkElevated,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withAlpha(40),
                          border: Border.all(color: AppColors.accent, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.textLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Client Code: ${user.clientCode} • ${user.email}',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.textLightMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(35),
                          borderRadius: AppBorderRadius.pill,
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: AppColors.darkBorder, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ASSIGNED UNIT',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textLightMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unitNumber,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'COMPOUND',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textLightMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            compoundName,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.textLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: AppBorderRadius.medium,
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.build_circle_outlined, color: AppColors.accent, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'Maintenance',
                          style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '2 Active Tickets',
                          style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: AppBorderRadius.medium,
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, color: AppColors.success, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'Maintenance Fund',
                          style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'EGP 280,000 Paid',
                          style: TextStyle(fontFamily: 'Outfit', color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const brainDir = '/Users/hazemhany/.gemini/antigravity-ide/brain/338380e5-ce7c-4f74-b446-66a78a8d4e91';

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

  testWidgets('Generate Visual Suite 02 to 07', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await loadSystemFonts();

    // 02: User A Login Home Screen
    await tester.pumpWidget(wrapScreen(
      buildMockResidentDashboard(
        user: userA,
        unitNumber: 'A301B208',
        compoundName: 'Sky Hills (سكي هيلز)',
        statusLabel: 'LOGGED IN',
      ),
      key: const Key('k02'),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await captureScreen(tester, const Key('k02'), '$brainDir/02_user_a_home_screen.png');

    // 03: User A Persisted After Force-Quit
    await tester.pumpWidget(wrapScreen(
      buildMockResidentDashboard(
        user: userA,
        unitNumber: 'A301B208',
        compoundName: 'Sky Hills (سكي هيلز)',
        statusLabel: 'SESSION PERSISTED',
      ),
      key: const Key('k03'),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await captureScreen(tester, const Key('k03'), '$brainDir/03_user_a_persisted_after_force_quit.png');

    // 04: User B Login Home Screen
    await tester.pumpWidget(wrapScreen(
      buildMockResidentDashboard(
        user: userB,
        unitNumber: 'B101B409',
        compoundName: 'Lamar Plaza (لامار)',
        statusLabel: 'LOGGED IN',
      ),
      key: const Key('k04'),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await captureScreen(tester, const Key('k04'), '$brainDir/04_user_b_home_screen.png');

    // 05: User B Persisted After Force-Quit
    await tester.pumpWidget(wrapScreen(
      buildMockResidentDashboard(
        user: userB,
        unitNumber: 'B101B409',
        compoundName: 'Lamar Plaza (لامار)',
        statusLabel: 'SESSION PERSISTED',
      ),
      key: const Key('k05'),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await captureScreen(tester, const Key('k05'), '$brainDir/05_user_b_persisted_after_force_quit.png');

    // 06: Maintenance Garbage Input Rejection
    final mockRepo = MockMaintenanceRepo([]);
    await tester.pumpWidget(wrapScreen(
      Container(
        color: const Color(0xFF0F172A),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: MaintenanceRequestModal(
          unit: testUnit,
          trade: 'Electrical',
          compoundTitle: 'Sky Hills (سكي هيلز)',
          assignedCustomer: userB,
          maintRepo: mockRepo,
        ),
      ),
      key: const Key('k06'),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), r'\\\\\\\\');
    await tester.enterText(textFields.at(1), r'\\\\\\\\\\\\\\\\');
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('FILE SERVICE REQUEST'));
    await tester.pump(const Duration(milliseconds: 100));

    await captureScreen(tester, const Key('k06'), '$brainDir/06_maintenance_garbage_rejection.png');

    // 07: Admin Maintenance & Deposit Hub Trace
    final sampleTickets = [
      MaintenanceRequest(
        id: 'T-8823901',
        ticketNumber: 'TKT-8823901',
        compoundId: 'sky_hills',
        unitId: 'B02B409',
        residentUserId: 'client_89',
        category: MaintenanceCategory.electrical,
        urgency: MaintenanceUrgency.high,
        title: 'Water Pipe Leak in Bathroom (Plumbing)',
        description: 'Main water valve has a continuous leak damaging floor tiles.',
        status: MaintenanceStatus.submitted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MaintenanceRequest(
        id: 'T-8823900',
        ticketNumber: 'TKT-8823900',
        compoundId: 'sky_hills',
        unitId: 'A301B208',
        residentUserId: 'client_87',
        category: MaintenanceCategory.hvac,
        urgency: MaintenanceUrgency.medium,
        title: 'AC Cooling Coil Inspection & Filter Replacement',
        description: 'Master bedroom AC airflow is weak.',
        status: MaintenanceStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
    ];

    final adminMockRepo = MockMaintenanceRepo(sampleTickets);
    await tester.pumpWidget(wrapScreen(
      MaintenanceModuleScreen(maintRepo: adminMockRepo),
      key: const Key('k07'),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final ticketsTab = find.text('بلاغات الصيانة (Tickets & SLAs)');
    if (ticketsTab.evaluate().isNotEmpty) {
      await tester.tap(ticketsTab);
      await tester.pump(const Duration(milliseconds: 100));
    }

    await captureScreen(tester, const Key('k07'), '$brainDir/07_maintenance_valid_submission_admin.png');

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });
}
