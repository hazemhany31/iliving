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
import 'package:iliving/models/contract.dart';
import 'package:iliving/models/document.dart';
import 'package:iliving/models/notification.dart';
import 'package:iliving/models/maintenance_request.dart';
import 'package:iliving/models/gate_pass.dart';
import 'package:iliving/models/compound_model.dart';
import 'package:iliving/models/unit_ledger_model.dart';
import 'package:iliving/theme/luxury_theme.dart';
import 'package:iliving/widgets/qr_code_painter.dart';

const String brainDir = '/Users/hazemhany/.gemini/antigravity-ide/brain/f08358fd-47d1-4ee0-b3fc-9f80242595e1';

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

Future<void> renderAndSave(WidgetTester tester, Widget content, String filename) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: LuxuryTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: RepaintBoundary(
          key: const Key('capture_boundary'),
          child: content,
        ),
      ),
    ),
  );
  await tester.pump();

  final boundaryFinder = find.byKey(const Key('capture_boundary'));
  final RenderRepaintBoundary boundary = tester.renderObject(boundaryFinder);
  final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData != null) {
    final filePath = '$brainDir/$filename';
    File(filePath).writeAsBytesSync(byteData.buffer.asUint8List());
    debugPrint('Saved: $filePath (${byteData.lengthInBytes} bytes)');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadSystemFonts();
  });

  testWidgets('01_dashboard_screen', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;

    final user = UserProfile.fromJson({
      'uid': 'client_87',
      'clientCode': '87',
      'email': 'ahmed.shazly.abdelgawad@new-build-egypt.com',
      'fullName': 'Ahmed Shazly Abdelgawad',
      'phoneNumber': '+20 112 763 3326',
      'role': 'customer',
      'ownedUnitIds': ['A301B208'],
      'createdAt': '2025-11-14T09:30:00.000Z',
    });

    final compound = CompoundModel.fromJson({
      'id': 'cmp_sky_hills',
      'title': 'Sky Hills Residence',
      'location': 'New Cairo, Fifth Settlement',
      'category': 'Luxury Residential',
      'description': 'Ultra luxury residential community',
      'basePriceEGP': 4850000.0,
      'areaSqFt': 2450.0,
      'completionPercentage': 92.5,
      'heroImageUrl': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      'cardImageUrl': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      'primaryView': 'Panoramic Skyline & Pool View',
    });

    await renderAndSave(
      tester,
      Container(
        color: AppColors.darkBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WELCOME BACK', style: TextStyle(fontFamily: 'Outfit', color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(user.fullName, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.accent.withAlpha(40), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accent.withAlpha(100))),
                      child: Text('Client #${user.clientCode}', style: const TextStyle(fontFamily: 'Outfit', color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.darkSurface, AppColors.darkSurface.withAlpha(200)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(compound.title, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.success.withAlpha(40), borderRadius: BorderRadius.circular(12)),
                            child: const Text('ACTIVE RESIDENT', style: TextStyle(fontFamily: 'Outfit', color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Unit: A301B208 • ${compound.location}', style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 13)),
                      const SizedBox(height: 18),
                      const Divider(color: AppColors.darkBorder),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetric('Total Value', '4,850,000 EGP', AppColors.textLight),
                          _buildMetric('Paid to Date', '3,880,000 EGP', AppColors.success),
                          _buildMetric('Outstanding', '970,000 EGP', AppColors.accent),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('QUICK SERVICES', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildActionTile(Icons.qr_code_rounded, 'Gate Pass', 'Generate QR', AppColors.accent)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionTile(Icons.handyman_outlined, 'Service', 'New Ticket', AppColors.info)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionTile(Icons.payments_outlined, 'Pay', 'Installment', AppColors.success)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      '01_dashboard_screen.png',
    );
  });

  testWidgets('02_unit_details_screen', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;

    final unit = UnitModel.fromJson({
      'unitNumber': 'A301B208',
      'configuration': '3BR Penthouse • Sky Villa',
      'areaSqFt': 2450.0,
      'priceEGP': 4850000.0,
      'parkingSpaces': 2,
      'constructionPhase': 'Finishing & Handover Q4 2026',
      'paymentMilestones': [
        {'title': 'Reservation Deposit (10%)', 'percentageDue': 10.0, 'isPaid': true},
        {'title': 'Contract Signing (15%)', 'percentageDue': 15.0, 'isPaid': true},
        {'title': 'Concrete Structure Milestone (25%)', 'percentageDue': 25.0, 'isPaid': true},
        {'title': 'MEP & Facade Milestone (30%)', 'percentageDue': 30.0, 'isPaid': true},
        {'title': 'Handover & Key Delivery (20%)', 'percentageDue': 20.0, 'isPaid': false},
      ],
    });

    await renderAndSave(
      tester,
      Container(
        color: AppColors.darkBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textLight, size: 20),
                    const SizedBox(width: 16),
                    Text('Unit ${unit.unitNumber}', style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.darkBorder)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unit.configuration, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSpecItem(Icons.aspect_ratio_rounded, '${unit.areaSqFt.toStringAsFixed(0)} sq ft'),
                          _buildSpecItem(Icons.apartment_rounded, unit.floorTier),
                          _buildSpecItem(Icons.local_parking_outlined, '${unit.parkingSpaces} Parking'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.darkBorder),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Valuation:', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 13)),
                          Text('${unit.priceEGP.toStringAsFixed(0)} EGP', style: const TextStyle(fontFamily: 'Outfit', color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Phase Status:', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 13)),
                          Text(unit.constructionPhase, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('PAYMENT MILESTONES', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...unit.paymentMilestones.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: m.isPaid ? AppColors.success.withAlpha(50) : AppColors.darkBorder)),
                      child: Row(
                        children: [
                          Icon(m.isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: m.isPaid ? AppColors.success : AppColors.textLightMuted, size: 22),
                          const SizedBox(width: 14),
                          Expanded(child: Text(m.title, style: TextStyle(fontFamily: 'Outfit', color: m.isPaid ? AppColors.textLight : AppColors.textLightMuted, fontSize: 14, fontWeight: m.isPaid ? FontWeight.bold : FontWeight.normal))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: (m.isPaid ? AppColors.success : AppColors.accent).withAlpha(30), borderRadius: BorderRadius.circular(8)),
                            child: Text(m.isPaid ? 'PAID' : 'DUE', style: TextStyle(fontFamily: 'Outfit', color: m.isPaid ? AppColors.success : AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
      '02_unit_details_screen.png',
    );
  });

  testWidgets('03_installments_screen', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;

    final ledger = UnitLedger.fromJson({
      'compoundId': 'cmp_sky_hills',
      'clientId': 'client_87',
      'unitId': 'A301B208',
      'unitType': 'Sky Penthouse',
      'downPayment': {
        'isPaid': true,
        'status': 'Paid',
        'percentageDue': 10.0,
        'amountEGP': 485000.0,
        'paidTimestamp': '2025-11-15T12:00:00.000Z',
        'receiptUrl': 'https://storage.iliving.com.eg/receipts/dp.pdf',
      },
      'installments': [
        {'id': 'INST-01', 'title': 'Q1 2026 Installment', 'isPaid': true, 'amountEGP': 485000.0, 'dueDateIso': '2026-03-01T00:00:00.000Z', 'dueDateLabel': '01 Mar 2026'},
        {'id': 'INST-02', 'title': 'Q2 2026 Installment', 'isPaid': true, 'amountEGP': 485000.0, 'dueDateIso': '2026-06-01T00:00:00.000Z', 'dueDateLabel': '01 Jun 2026'},
        {'id': 'INST-03', 'title': 'Q3 2026 Installment', 'isPaid': false, 'amountEGP': 485000.0, 'dueDateIso': '2026-09-01T00:00:00.000Z', 'dueDateLabel': '01 Sep 2026'},
        {'id': 'INST-04', 'title': 'Q4 2026 Handover Installment', 'isPaid': false, 'amountEGP': 485000.0, 'dueDateIso': '2026-12-01T00:00:00.000Z', 'dueDateLabel': '01 Dec 2026'},
      ],
      'maintenance': {
        'isPaid': true,
        'status': 'Active Escrow',
        'balanceEGP': 242500.0,
        'annualFeeEGP': 35000.0,
      },
    });

    await renderAndSave(
      tester,
      Container(
        color: AppColors.darkBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FINANCIAL SCHEDULE', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Unit ${ledger.unitId} • ${ledger.unitType}', style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 13)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accent.withAlpha(60))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Total Paid', '${ledger.totalPaidEGP.toStringAsFixed(0)} EGP', AppColors.success),
                      Container(width: 1, height: 40, color: AppColors.darkBorder),
                      _buildMetric('Remaining', '${ledger.totalOutstandingEGP.toStringAsFixed(0)} EGP', AppColors.accent),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('INSTALLMENTS BREAKDOWN', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...ledger.installments.map((inst) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: inst.isPaid ? AppColors.success.withAlpha(40) : AppColors.darkBorder)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inst.title, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Due Date: ${inst.dueDateLabel}', style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 12)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${inst.amountEGP.toStringAsFixed(0)} EGP', style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: (inst.isPaid ? AppColors.success : AppColors.accent).withAlpha(30), borderRadius: BorderRadius.circular(6)),
                                child: Text(inst.isPaid ? 'PAID' : 'PENDING', style: TextStyle(fontFamily: 'Outfit', color: inst.isPaid ? AppColors.success : AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
      '03_installments_screen.png',
    );
  });

  testWidgets('04_contracts_screen', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;

    final contract = Contract.fromJson({
      'id': 'CTR-2025-8821',
      'contractNumber': 'ILIV-CTR-8821',
      'unitId': 'A301B208',
      'compoundId': 'cmp_sky_hills',
      'buyerUserId': 'client_87',
      'salesAgentUserId': 'agent_01',
      'agreedTotalPrice': 4850000.0,
      'downPaymentAmount': 485000.0,
      'installmentDurationYears': 5,
      'totalInstallmentsCount': 20,
      'startDate': '2025-11-15T00:00:00.000Z',
      'endDate': '2030-11-15T00:00:00.000Z',
      'deliveryDateExpected': '2026-12-31T00:00:00.000Z',
      'signatureStatus': 'fullyExecuted',
      'signedByCustomerAt': '2025-11-16T14:20:00.000Z',
      'signedByDeveloperAt': '2025-11-17T10:00:00.000Z',
      'pdfContractUrl': 'https://storage.iliving.com.eg/contracts/CTR-8821.pdf',
      'createdAt': '2025-11-15T00:00:00.000Z',
      'updatedAt': '2025-11-17T10:00:00.000Z',
    });

    final doc = DocumentItem.fromJson({
      'id': 'DOC-1029',
      'title': 'Official Handover & Clear Title Deed',
      'category': 'contract',
      'fileUrl': 'https://storage.iliving.com.eg/docs/deed.pdf',
      'fileExtension': 'pdf',
      'fileSizeBytes': 2450120,
      'createdAt': '2025-11-17T11:00:00.000Z',
    });

    await renderAndSave(
      tester,
      Container(
        color: AppColors.darkBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CONTRACTS & DEEDS', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Official Executed Documents & KYC Files', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 13)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accent.withAlpha(80))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(contract.contractNumber, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.success.withAlpha(40), borderRadius: BorderRadius.circular(12)),
                            child: const Text('EXECUTED', style: TextStyle(fontFamily: 'Outfit', color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.darkBorder),
                      const SizedBox(height: 12),
                      _buildDetailRow('Unit Number:', contract.unitId),
                      _buildDetailRow('Total Contract Value:', '${contract.agreedTotalPrice.toStringAsFixed(0)} EGP'),
                      _buildDetailRow('Expected Delivery:', '31 Dec 2026'),
                      _buildDetailRow('Customer Signature:', '16 Nov 2025'),
                      _buildDetailRow('Developer Signature:', '17 Nov 2025'),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download_rounded, color: Colors.black, size: 18),
                              SizedBox(width: 8),
                              Text('DOWNLOAD EXECUTED PDF', style: TextStyle(fontFamily: 'Outfit', color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('ASSOCIATED ATTACHMENTS', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.title, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Text('${(doc.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB • PDF', style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.visibility_outlined, color: AppColors.accent, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      '04_contracts_screen.png',
    );
  });

  testWidgets('05_notifications_screen', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;

    final notifs = [
      AppNotification.fromJson({
        'id': 'NTF-101',
        'title': 'Payment Reconciled: 485,000 EGP',
        'body': 'Your Q2 2026 installment for Unit A301B208 has been verified and credited successfully.',
        'priority': 'normal',
        'isRead': true,
        'createdAt': '2026-06-02T10:15:00.000Z',
        'type': 'payment',
      }),
      AppNotification.fromJson({
        'id': 'NTF-102',
        'title': 'Maintenance Visit Scheduled',
        'body': 'Technician assigned for Electrical fixture inspection on tomorrow at 02:00 PM.',
        'priority': 'high',
        'isRead': false,
        'createdAt': '2026-08-24T08:30:00.000Z',
        'type': 'maintenance',
      }),
      AppNotification.fromJson({
        'id': 'NTF-103',
        'title': 'Gate Access Pass Granted',
        'body': 'Guest Pass #GP-8839 generated for visitor Mahmoud Ghanem (Vehicle 3419-ABC).',
        'priority': 'normal',
        'isRead': false,
        'createdAt': '2026-08-24T12:00:00.000Z',
        'type': 'gate',
      }),
    ];

    await renderAndSave(
      tester,
      Container(
        color: AppColors.darkBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('NOTIFICATIONS', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 22, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accent.withAlpha(40), borderRadius: BorderRadius.circular(12)),
                      child: const Text('2 UNREAD', style: TextStyle(fontFamily: 'Outfit', color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...notifs.map((n) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: n.isRead ? AppColors.darkSurface : AppColors.darkSurface.withAlpha(240),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: n.isRead ? AppColors.darkBorder : AppColors.accent.withAlpha(80)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (n.type == 'payment' ? AppColors.success : n.type == 'maintenance' ? AppColors.info : AppColors.accent).withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              n.type == 'payment' ? Icons.check_circle_outline_rounded : n.type == 'maintenance' ? Icons.build_circle_outlined : Icons.qr_code_rounded,
                              color: n.type == 'payment' ? AppColors.success : n.type == 'maintenance' ? AppColors.info : AppColors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(n.body, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 12)),
                                const SizedBox(height: 8),
                                Text('24 Aug 2026 • 12:00 PM', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted.withAlpha(150), fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
      '05_notifications_screen.png',
    );
  });

  testWidgets('06_maintenance_tickets_screen', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;

    final req = MaintenanceRequest.fromJson({
      'id': 'TCK-9902',
      'ticketNumber': 'ILIV-TCK-9902',
      'residentUserId': 'client_87',
      'unitId': 'A301B208',
      'compoundId': 'cmp_sky_hills',
      'category': 'electrical',
      'title': 'Smart Home Automation Controller Offline',
      'description': 'Main lighting panel bus disconnected after building generator test.',
      'urgency': 'high',
      'status': 'inProgress',
      'assignedTechnicianUserId': 'USR-TECH-04',
      'preferredScheduleSlot': '2026-08-25T14:00:00.000Z',
      'createdAt': '2026-08-24T09:00:00.000Z',
      'updatedAt': '2026-08-24T10:00:00.000Z',
      'attachments': ['https://storage.iliving.com.eg/tickets/9902/panel.jpg'],
    });

    await renderAndSave(
      tester,
      Container(
        color: AppColors.darkBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('FACILITY TICKETS', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 22, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                      child: const Text('+ NEW TICKET', style: TextStyle(fontFamily: 'Outfit', color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.info.withAlpha(100))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.ticketNumber, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.info.withAlpha(40), borderRadius: BorderRadius.circular(8)),
                            child: const Text('IN PROGRESS', style: TextStyle(fontFamily: 'Outfit', color: AppColors.info, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(req.title, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(req.description, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 13)),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.darkBorder),
                      const SizedBox(height: 10),
                      _buildDetailRow('Trade Category:', 'Electrical & Smart Automation'),
                      _buildDetailRow('Assigned Engineer:', 'Eng. Tarek Mostafa (Lead)'),
                      _buildDetailRow('Scheduled Visit:', '25 Aug 2026 • 02:00 PM'),
                      _buildDetailRow('Reported At:', '24 Aug 2026 • 09:00 AM'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      '06_maintenance_tickets_screen.png',
    );
  });

  testWidgets('07_gate_pass_screen', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;

    final pass = GatePass.fromJson({
      'id': 'GP-88391',
      'compoundId': 'cmp_sky_hills',
      'unitId': 'A301B208',
      'hostUserId': 'client_87',
      'visitorName': 'Mahmoud Ghanem Ibrahim',
      'visitorPhone': '+20 102 993 8472',
      'visitorPlateNumber': '3419-ABC',
      'passType': 'oneTime',
      'validFrom': '2026-08-24T12:00:00.000Z',
      'validUntil': '2026-08-25T12:00:00.000Z',
      'maxUsageCount': 1,
      'currentUsageCount': 0,
      'qrPayloadSigned': 'ILIVING-GATE:GP-88391:cmp_sky_hills:1787612400000:SIG984920',
      'status': 'active',
      'createdAt': '2026-08-24T12:00:00.000Z',
    });

    await renderAndSave(
      tester,
      Container(
        color: AppColors.darkBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GATE ACCESS PASS', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Contactless QR Gate Verification System', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 13)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withAlpha(90)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: QrCodeWidget(
                          qrData: pass.qrPayloadSigned,
                          size: 180,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(pass.visitorName, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Plate: ${pass.visitorPlateNumber} • ${pass.visitorPhone}', style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 13)),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.darkBorder),
                      const SizedBox(height: 12),
                      _buildDetailRow('Pass ID:', pass.id),
                      _buildDetailRow('Access Type:', 'Single Entry (1-Time Scan)'),
                      _buildDetailRow('Valid Until:', '25 Aug 2026 • 12:00 PM'),
                      _buildDetailRow('Remaining Scans:', '${pass.maxUsageCount - pass.currentUsageCount} of ${pass.maxUsageCount}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      '07_gate_pass_screen.png',
    );
  });
}

Widget _buildMetric(String label, String value, Color color) {
  return Column(
    children: [
      Text(label, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontFamily: 'Outfit', color: color, fontSize: 14, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _buildSpecItem(IconData icon, String text) {
  return Column(
    children: [
      Icon(icon, color: AppColors.accent, size: 20),
      const SizedBox(height: 6),
      Text(text, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 12)),
    ],
  );
}

Widget _buildActionTile(IconData icon, String title, String subtitle, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.darkBorder),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 10)),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLightMuted, fontSize: 12)),
        Text(value, style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
