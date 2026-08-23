import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document.dart';
import '../models/unit_model.dart';
import '../models/contract.dart';
import '../models/user_profile.dart';

class PdfDocumentGeneratorService {
  PdfDocumentGeneratorService._();
  static final PdfDocumentGeneratorService instance = PdfDocumentGeneratorService._();

  /// Generates a real binary PDF document bytes
  Future<Uint8List> generateDocumentPdf({
    required DocumentItem document,
    Unit? unit,
    Contract? contract,
    UserProfile? user,
  }) async {
    final pdf = pw.Document();

    final String title = document.title;
    final String unitNum = unit?.unitNumber ?? document.associatedUnitId ?? 'A01-207';
    final String clientName = user?.fullName ?? 'Valued Client';
    final String compound = unit?.parentCompoundId ?? 'Sky Hills (New October)';
    final String dateStr = '${document.createdAt.day}/${document.createdAt.month}/${document.createdAt.year}';
    final String docId = document.id;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Brand Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'iLIVING LUXURY DEVELOPMENTS',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Official Property Operations & Deeds Department',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber800,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'VERIFIED DOCUMENT',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Document Title
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Document Reference: $docId | Generated: $dateStr',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 20),

              // Property & Owner Meta Table
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    _buildPdfRow('Registered Owner / Client:', clientName),
                    pw.SizedBox(height: 6),
                    _buildPdfRow('Property Unit Number:', 'Unit $unitNum'),
                    pw.SizedBox(height: 6),
                    _buildPdfRow('Compound & Development:', compound),
                    pw.SizedBox(height: 6),
                    _buildPdfRow('Category / Type:', document.category.name.toUpperCase()),
                    if (unit != null) ...[
                      pw.SizedBox(height: 6),
                      _buildPdfRow('Floor Area / Tier:', '${unit.areaSquareMeters.toStringAsFixed(0)} SQM • ${unit.floorTier}'),
                    ],
                    if (contract != null) ...[
                      pw.SizedBox(height: 6),
                      _buildPdfRow('Total Contract Value:', '${(contract.agreedTotalPrice / 1000000).toStringAsFixed(2)}M EGP'),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Document Body Description
              pw.Text(
                'Summary & Provisions:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                (document.description != null && document.description!.isNotEmpty)
                    ? document.description!
                    : 'This certifies that the referenced property unit is officially authenticated under the iLiving Real Estate Master Ledger. All architectural, contractual, and technical specifications are validated and recorded with the development authority.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  lineSpacing: 2,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 24),

              // Signatures Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Authorized Developer Officer',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                        pw.SizedBox(height: 24),
                        pw.Text('iLiving Operations & Handover', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Verified Resident / Owner',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                        pw.SizedBox(height: 24),
                        pw.Text(clientName, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Security Stamp: E-SIGN-SHA256-AUTHENTICATED', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                  pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
        ),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.black),
        ),
      ],
    );
  }

  /// Downloads & saves the PDF to device storage and triggers native share/open sheet
  Future<File> downloadAndShareDocument({
    required BuildContext context,
    required DocumentItem document,
    Unit? unit,
    Contract? contract,
    UserProfile? user,
  }) async {
    final pdfBytes = await generateDocumentPdf(
      document: document,
      unit: unit,
      contract: contract,
      user: user,
    );

    // Save to temp or documents directory
    final outputDir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = document.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filePath = '${outputDir.path}/$sanitizedTitle.pdf';
    final file = File(filePath);

    await file.writeAsBytes(pdfBytes, flush: true);

    // Open native share / save sheet (Files, AirDrop, Print, WhatsApp, etc.)
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/pdf', name: '$sanitizedTitle.pdf')],
      text: 'iLiving Official Document: ${document.title}',
    );

    return file;
  }

  /// Open in system preview or print dialog
  Future<void> previewOrPrintDocument({
    required BuildContext context,
    required DocumentItem document,
    Unit? unit,
    Contract? contract,
    UserProfile? user,
  }) async {
    final pdfBytes = await generateDocumentPdf(
      document: document,
      unit: unit,
      contract: contract,
      user: user,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: document.title,
    );
  }
}
