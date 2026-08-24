import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/maintenance_request.dart';
import 'package:iliving/models/installment.dart';
import 'package:iliving/models/contract.dart';
import 'package:iliving/models/unit_ledger_model.dart';
import 'package:iliving/repositories/interfaces/ledger_repository.dart';
import 'package:iliving/repositories/interfaces/contract_repository.dart';
import 'package:iliving/screens/admin/maintenance_module_screen.dart';
import 'package:iliving/theme/luxury_theme.dart';
import 'package:iliving/l10n/app_localizations.dart';
import 'render_screens_3_4_5_7_test.dart';

class MockLedgerRepo implements LedgerRepository {
  final List<Installment> installments;
  MockLedgerRepo(this.installments);

  @override
  Future<UnitLedger?> getLedgerByUnitId(String unitId) async => null;

  @override
  Stream<UnitLedger?> streamLedgerForUnit(String unitId) => Stream.value(null);

  @override
  Stream<List<UnitLedger>> streamAllLedgers() => Stream.value([]);

  @override
  Stream<List<Installment>> streamInstallmentsForUser(String userId) => Stream.value([]);

  @override
  Stream<List<Installment>> streamAllInstallments() => Stream.value(installments);

  @override
  Future<List<Installment>> getAllInstallments() async => installments;

  @override
  Future<List<UnitLedger>> getLedgers({
    String? compoundId,
    String? clientId,
    int? limit,
    String? startAfterId,
  }) async => [];

  @override
  Future<void> saveLedger(UnitLedger ledger) async {}

  @override
  Future<void> createInstallment(Installment installment) async {}

  @override
  Future<void> updateInstallment(Installment installment) async {}

  @override
  Future<void> deleteInstallment(String contractId, String installmentId) async {}

  @override
  Future<void> deleteLedger(String unitId) async {}

  @override
  Future<void> batchUpdateInstallments(List<Installment> installments) async {}
}

class MockContractRepo implements ContractRepository {
  @override
  Future<Contract?> getContractById(String id) async => null;

  @override
  Stream<Contract?> streamContract(String id) => Stream.value(null);

  @override
  Stream<List<Contract>> streamContractsForUser(String userId) => Stream.value([]);

  @override
  Stream<List<Contract>> streamAllContracts() => Stream.value([]);

  @override
  Future<List<Contract>> getContracts({
    String? buyerUserId,
    String? compoundId,
    String? clientCode,
    SignatureStatus? status,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  }) async => [];

  @override
  Future<void> createContract(Contract contract) async {}

  @override
  Future<void> updateContract(Contract contract) async {}

  @override
  Future<void> deleteContract(String id) async {}

  @override
  Future<void> batchSaveContracts(List<Contract> contracts) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const brainDir = '/Users/hazemhany/.gemini/antigravity-ide/brain/338380e5-ce7c-4f74-b446-66a78a8d4e91';

  setUpAll(() async {
    await loadSystemFonts();
  });

  testWidgets('Artifact 07: Admin Maintenance Hub Trace', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    final sampleInstallments = [
      Installment(
        id: 'inst_01',
        contractId: 'cnt_89',
        unitId: 'B02B409',
        buyerUserId: 'client_89',
        sequenceNumber: 1,
        principalAmount: 280000.0,
        paidAmount: 280000.0,
        dueDate: DateTime(2024, 1, 1),
        gracePeriodEndDate: DateTime(2024, 1, 15),
        status: InstallmentStatus.paid,
        installmentType: InstallmentType.maintenanceFund,
      ),
    ];

    final adminMockRepo = MockMaintenanceRepo(sampleTickets);
    final adminLedgerRepo = MockLedgerRepo(sampleInstallments);
    final adminContractRepo = MockContractRepo();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LuxuryTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: RepaintBoundary(
            key: const Key('admin_capture_boundary'),
            child: SizedBox(
              width: 1280,
              height: 1000,
              child: MaintenanceModuleScreen(
                maintRepo: adminMockRepo,
                ledgerRepo: adminLedgerRepo,
                contractRepo: adminContractRepo,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    final boundaryFinder = find.byKey(const Key('admin_capture_boundary'));
    final RenderRepaintBoundary boundary = tester.renderObject(boundaryFinder);
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      File('$brainDir/07_maintenance_valid_submission_admin.png').writeAsBytesSync(byteData.buffer.asUint8List());
    }
  });
}
