import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/maintenance_request.dart';
import 'package:iliving/models/maintenance_comment.dart';
import 'package:iliving/models/unit_model.dart';
import 'package:iliving/repositories/interfaces/maintenance_repository.dart';
import 'package:iliving/widgets/maintenance_request_modal.dart';
import 'package:iliving/l10n/app_localizations.dart';

class MockMaintenanceRepository implements MaintenanceRepository {
  final List<MaintenanceRequest> createdTickets = [];
  bool shouldThrowError = false;
  int createCallsCount = 0;

  @override
  Future<void> createTicket(MaintenanceRequest ticket) async {
    createCallsCount++;
    if (shouldThrowError) {
      throw Exception('Network connection timed out');
    }
    createdTickets.add(ticket);
  }

  @override
  Future<void> addComment(MaintenanceComment comment) async {}

  @override
  Future<void> batchUpdateTicketStatus(List<String> ticketIds, MaintenanceStatus status) async {}

  @override
  Stream<List<MaintenanceComment>> streamCommentsForTicket(String ticketId) => Stream.value([]);

  @override
  Future<void> deleteTicket(String ticketId) async {}

  @override
  Future<MaintenanceRequest?> getTicketById(String ticketId) async => null;

  @override
  Future<List<MaintenanceRequest>> getTickets({
    String? compoundId,
    String? residentUserId,
    MaintenanceStatus? status,
    String? category,
    String? urgency,
    int? limit,
    String? startAfterId,
  }) async => createdTickets;

  @override
  Stream<List<MaintenanceRequest>> streamAllTickets() => Stream.value(createdTickets);

  @override
  Stream<List<MaintenanceRequest>> streamTicketsForCompound(String compoundId) => Stream.value(createdTickets);

  @override
  Stream<List<MaintenanceRequest>> streamTicketsForUser(String userId) => Stream.value(createdTickets);

  @override
  Stream<MaintenanceRequest?> streamTicket(String ticketId) => Stream.value(null);

  @override
  Future<void> updateTicket(MaintenanceRequest ticket) async {}

  @override
  Future<void> updateTicketStatus(String ticketId, MaintenanceStatus status, {String? technicianId}) async {}
}

void main() {
  group('Maintenance Request Form - Complete 7-Point Stress Test Checklist', () {
    late Unit testUnit;
    late MockMaintenanceRepository mockRepo;

    setUp(() {
      testUnit = const Unit(
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
      mockRepo = MockMaintenanceRepository();
    });

    Widget buildTestModal({MaintenanceRepository? repo, ValueChanged<MaintenanceRequest>? onTicketCreated}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MaintenanceRequestModal(
            unit: testUnit,
            trade: 'Plumbing',
            compoundTitle: 'Sky Hills (سكي هيلز)',
            maintRepo: repo ?? mockRepo,
            onTicketCreated: onTicketCreated,
          ),
        ),
      );
    }

    testWidgets('1. Empty/invalid submission: triggers validation for Title (<3 chars) and Description (<5 chars)', (tester) async {
      await tester.pumpWidget(buildTestModal());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      // 1.1 Test empty Title
      await tester.enterText(textFields.at(0), ''); // clear title
      await tester.enterText(textFields.at(1), 'Proper description for ticket');
      await tester.tap(find.text('FILE SERVICE REQUEST'));
      await tester.pumpAndSettle();

      expect(find.text('Ticket title is required (min 3 characters)'), findsOneWidget);
      expect(mockRepo.createCallsCount, 0); // No ticket created

      // 1.2 Test empty / short Description
      await tester.enterText(textFields.at(0), 'Main Water Pipe Leak');
      await tester.enterText(textFields.at(1), 'bad'); // only 3 chars (< 5)
      await tester.tap(find.text('FILE SERVICE REQUEST'));
      await tester.pumpAndSettle();

      expect(find.text('Verification requirement: minimum 5 characters details'), findsOneWidget);
      expect(mockRepo.createCallsCount, 0); // Still blocked
    });

    testWidgets('2. Successful submission: creates ticket in repository, fires callback, closes modal', (tester) async {
      MaintenanceRequest? createdCallbackTicket;

      await tester.pumpWidget(
        buildTestModal(
          onTicketCreated: (t) => createdCallbackTicket = t,
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Water Heater Not Heating');
      await tester.enterText(textFields.at(1), 'Water heater stopped functioning in the master bathroom.');

      // Tap submit
      await tester.tap(find.text('FILE SERVICE REQUEST'));
      await tester.pumpAndSettle();

      // Verify ticket in repository
      expect(mockRepo.createdTickets.length, 1);
      final createdTicket = mockRepo.createdTickets.first;
      expect(createdTicket.title, 'Water Heater Not Heating');
      expect(createdTicket.description, 'Water heater stopped functioning in the master bathroom.');
      expect(createdTicket.unitId, 'A01-207');
      expect(createdTicket.compoundId, 'dev_1');
      expect(createdTicket.category, MaintenanceCategory.plumbing);
      expect(createdTicket.status, MaintenanceStatus.submitted);

      // Verify callback triggered
      expect(createdCallbackTicket, isNotNull);
      expect(createdCallbackTicket?.title, 'Water Heater Not Heating');
    });

    testWidgets('3. Duplicate / rapid taps protection: multiple taps produce only one submission', (tester) async {
      await tester.pumpWidget(buildTestModal());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Kitchen Sink Clogged');
      await tester.enterText(textFields.at(1), 'Water is draining very slowly from kitchen sink.');

      // Rapidly tap submit button 5 times
      final submitButton = find.text('FILE SERVICE REQUEST');
      await tester.tap(submitButton);
      await tester.tap(submitButton);
      await tester.tap(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Only 1 ticket should ever be created
      expect(mockRepo.createdTickets.length, 1);
      expect(mockRepo.createCallsCount, 1);
    });

    testWidgets('4. Keyboard behavior: form is wrapped in SingleChildScrollView preventing RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestModal());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull); // Zero overflow errors
    });

    testWidgets('5. Priority selection: single-select amongst Low/Medium/High/Emergency and saves correctly', (tester) async {
      await tester.pumpWidget(buildTestModal());
      await tester.pumpAndSettle();

      // Select 'EMERGENCY'
      await tester.tap(find.text('EMERGENCY'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Major Pipe Burst');
      await tester.enterText(textFields.at(1), 'Water flooding into the living room hallway.');

      await tester.tap(find.text('FILE SERVICE REQUEST'));
      await tester.pumpAndSettle();

      expect(mockRepo.createdTickets.first.urgency, MaintenanceUrgency.emergency);
    });

    testWidgets('6. Closing without saving: tapping close discards cleanly without saving', (tester) async {
      await tester.pumpWidget(buildTestModal());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Draft Title That Should Be Discarded');
      await tester.enterText(textFields.at(1), 'Draft description that should not be saved.');

      // Tap close button (X)
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(mockRepo.createdTickets.isEmpty, isTrue);
      expect(mockRepo.createCallsCount, 0);
    });

    testWidgets('7. Network failure mid-submit: retains typed data, keeps modal open, displays error banner for retry', (tester) async {
      mockRepo.shouldThrowError = true; // Simulate network timeout

      await tester.pumpWidget(buildTestModal());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Electrical Spark in Breaker Box');
      await tester.enterText(textFields.at(1), 'Main circuit breaker keeps tripping when AC is turned on.');

      // Tap submit
      await tester.tap(find.text('FILE SERVICE REQUEST'));
      await tester.pumpAndSettle();

      // Verify error banner is shown
      expect(find.textContaining('Network connection timed out'), findsOneWidget);

      // Verify modal is STILL open and data is 100% PRESERVED
      expect(find.text('Electrical Spark in Breaker Box'), findsOneWidget);
      expect(find.text('Main circuit breaker keeps tripping when AC is turned on.'), findsOneWidget);

      // Fix network and tap retry
      mockRepo.shouldThrowError = false;
      await tester.tap(find.text('FILE SERVICE REQUEST'));
      await tester.pumpAndSettle();

      // Now successfully created
      expect(mockRepo.createdTickets.length, 1);
      expect(mockRepo.createdTickets.first.title, 'Electrical Spark in Breaker Box');
    });
  });
}
