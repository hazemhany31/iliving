import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/maintenance_request.dart';
import 'package:iliving/models/unit_model.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/repositories/interfaces/maintenance_repository.dart';
import 'package:iliving/models/maintenance_comment.dart';
import 'package:iliving/widgets/maintenance_request_modal.dart';
import 'package:iliving/screens/admin/maintenance_module_screen.dart';
import 'package:iliving/l10n/app_localizations.dart';

class InMemoryMaintenanceRepository implements MaintenanceRepository {
  final List<MaintenanceRequest> _tickets = [];

  InMemoryMaintenanceRepository([List<MaintenanceRequest>? initial]) {
    if (initial != null) _tickets.addAll(initial);
  }

  @override
  Future<void> createTicket(MaintenanceRequest ticket) async {
    _tickets.insert(0, ticket);
  }

  @override
  Future<void> updateTicket(MaintenanceRequest ticket) async {
    final idx = _tickets.indexWhere((t) => t.id == ticket.id);
    if (idx != -1) _tickets[idx] = ticket;
  }

  @override
  Future<void> deleteTicket(String ticketId) async {
    _tickets.removeWhere((t) => t.id == ticketId);
  }

  @override
  Future<MaintenanceRequest?> getTicketById(String ticketId) async {
    try {
      return _tickets.firstWhere((t) => t.id == ticketId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<MaintenanceRequest?> streamTicket(String ticketId) {
    return Stream.value(getTicketById(ticketId) as MaintenanceRequest?);
  }

  @override
  Stream<List<MaintenanceRequest>> streamTicketsForUser(String userId) =>
      Stream.value(_tickets.where((t) => t.residentUserId == userId).toList());

  @override
  Stream<List<MaintenanceRequest>> streamTicketsForCompound(String compoundId) =>
      Stream.value(_tickets.where((t) => t.compoundId == compoundId).toList());

  @override
  Stream<List<MaintenanceRequest>> streamAllTickets() => Stream.value(_tickets);

  @override
  Future<List<MaintenanceRequest>> getTickets({
    String? compoundId,
    String? residentUserId,
    MaintenanceStatus? status,
    String? category,
    String? urgency,
    int? limit,
    String? startAfterId,
  }) async => _tickets;

  @override
  Future<void> updateTicketStatus(String ticketId, MaintenanceStatus status, {String? technicianId}) async {
    final t = await getTicketById(ticketId);
    if (t != null) {
      final updated = t.copyWith(status: status, assignedTechnicianUserId: technicianId, updatedAt: DateTime.now());
      await updateTicket(updated);
    }
  }

  @override
  Stream<List<MaintenanceComment>> streamCommentsForTicket(String ticketId) => Stream.value([]);

  @override
  Future<void> addComment(MaintenanceComment comment) async {}

  @override
  Future<void> batchUpdateTicketStatus(List<String> ticketIds, MaintenanceStatus status) async {
    for (final id in ticketIds) {
      await updateTicketStatus(id, status);
    }
  }
}

Future<void> saveRepaintScreenshot(WidgetTester tester, String filepath) async {
  await tester.runAsync(() async {
    await Future.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
  final boundaryFinder = find.byKey(const Key('test_repaint_boundary'));
  final RenderRepaintBoundary boundary = tester.renderObject(boundaryFinder);
  final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData != null) {
    File(filepath).writeAsBytesSync(byteData.buffer.asUint8List());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const brainDir = '/Users/hazemhany/.gemini/antigravity-ide/brain/338380e5-ce7c-4f74-b446-66a78a8d4e91';

  final testUnit = const Unit(
    unitNumber: 'A01-207',
    configuration: 'Penthouse 4BR',
    areaSqFt: 2583.3,
    priceEGP: 12500000,
    isVacant: false,
    assetClass: 'Residential',
    furnishingStatus: 'Finished',
    pricePerSqFt: 4838.7,
    parkingSpaces: 2,
    constructionPhase: 'Delivered',
    parentCompoundId: 'dev_1',
  );

  final testResident = UserProfile(
    uid: 'client_87',
    clientCode: '87',
    email: 'ahmed.shazly.abdelgawad@new-build-egypt.com',
    fullName: 'أحمد شاذلي عبد الجواد',
    phoneNumber: '01127633326',
    role: UserRole.customer,
    associatedUnitIds: ['A01-207'],
    createdAt: DateTime.now(),
  );

  testWidgets('Maintenance Visual Verification: (a) Garbage input rejection & (b) Valid submission in Admin Hub',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockMaintRepo = InMemoryMaintenanceRepository();

    // -------------------------------------------------------------------------
    // (a) Garbage Input Rejection Test & Screenshot
    // -------------------------------------------------------------------------
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('test_repaint_boundary'),
            child: Container(
              color: const Color(0xFF0F172A),
              alignment: Alignment.center,
              child: MaintenanceRequestModal(
                unit: testUnit,
                trade: 'Plumbing',
                compoundTitle: 'Sky Hills (سكي هيلز)',
                assignedCustomer: testResident,
                maintRepo: mockMaintRepo,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    // Type garbage title and garbage description
    await tester.enterText(textFields.at(0), r'\\\\\\\\');
    await tester.enterText(textFields.at(1), r'\\\\\\\\\\\\\\\\');

    // Submit to trigger validation error banners and red error borders
    await tester.tap(find.text('FILE SERVICE REQUEST'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a meaningful title (avoid repeated characters/symbols)'), findsOneWidget);
    expect(find.text('Meaningless text. Please describe the required service clearly'), findsOneWidget);

    await saveRepaintScreenshot(tester, '$brainDir/06_maintenance_garbage_rejection.png');

    // -------------------------------------------------------------------------
    // (b) Valid Ticket Submission & Admin Portal Hub Trace
    // -------------------------------------------------------------------------
    // Now enter real valid ticket data
    await tester.enterText(textFields.at(0), 'Water Pipe Leak in Bathroom');
    await tester.enterText(textFields.at(1), 'Main water valve has a continuous leak damaging floor tiles.');
    await tester.tap(find.text('HIGH'));
    await tester.pumpAndSettle();

    // Tap submit
    await tester.tap(find.text('FILE SERVICE REQUEST'));
    await tester.pumpAndSettle();

    expect(mockMaintRepo._tickets.length, 1);
    final validTicket = mockMaintRepo._tickets.first;
    expect(validTicket.title, 'Water Pipe Leak in Bathroom');
    expect(validTicket.urgency, MaintenanceUrgency.high);

    // Render Admin Maintenance & Deposit Hub with the new ticket
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('test_repaint_boundary'),
            child: Container(
              color: const Color(0xFF0F172A),
              child: MaintenanceModuleScreen(maintRepo: mockMaintRepo),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Tickets Tab (index 1)
    await tester.tap(find.text('بلاغات الصيانة (Tickets & SLAs)'));
    await tester.pumpAndSettle();

    await saveRepaintScreenshot(tester, '$brainDir/07_maintenance_valid_submission_admin.png');
  });
}
