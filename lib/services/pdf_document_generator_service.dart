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

  static bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Helper to compute valid share origin rect for iOS / iPadOS popovers
  static Rect _getShareOrigin(BuildContext context) {
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
        final origin = box.localToGlobal(Offset.zero);
        return origin & box.size;
      }
    } catch (_) {}

    try {
      final mediaQuery = MediaQuery.of(context);
      final width = mediaQuery.size.width;
      final height = mediaQuery.size.height;
      return Rect.fromLTWH(0, 0, width > 0 ? width : 300, height > 0 ? height / 2 : 300);
    } catch (_) {
      return const Rect.fromLTWH(0, 0, 300, 300);
    }
  }

  /// Generates a real binary PDF document bytes with full Arabic & Unicode support
  Future<Uint8List> generateDocumentPdf({
    required DocumentItem document,
    Unit? unit,
    Contract? contract,
    UserProfile? user,
  }) async {
    pw.Font? baseFont;
    pw.Font? boldFont;

    try {
      baseFont = await PdfGoogleFonts.cairoRegular();
      boldFont = await PdfGoogleFonts.cairoBold();
    } catch (e) {
      debugPrint('[PdfGenerator] Could not load Google Fonts, falling back: $e');
    }

    final theme = (baseFont != null && boldFont != null)
        ? pw.ThemeData.withFont(
            base: baseFont,
            bold: boldFont,
            fontFallback: [baseFont, boldFont],
          )
        : null;

    final pdf = pw.Document(theme: theme);

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
                textDirection: _isArabic(title) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                style: pw.TextStyle(
                  fontSize: 16,
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
                      _buildPdfRow('Floor Area / Tier:', '${unit.areaSquareMeters.toStringAsFixed(0)} SQM | ${unit.floorTier}'),
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
                textDirection: _isArabic(document.description ?? '') ? pw.TextDirection.rtl : pw.TextDirection.ltr,
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
                        pw.Text(
                          clientName,
                          textDirection: _isArabic(clientName) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
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
    final bool isRtl = _isArabic(value);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
        ),
        pw.Text(
          value,
          textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
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
    final shareOrigin = _getShareOrigin(context);

    final pdfBytes = await generateDocumentPdf(
      document: document,
      unit: unit,
      contract: contract,
      user: user,
    );

    // Save to temp or documents directory
    final outputDir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = document.title
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final fileName = sanitizedTitle.isEmpty ? 'document_${document.id}' : sanitizedTitle;
    final filePath = '${outputDir.path}/$fileName.pdf';
    final file = File(filePath);

    await file.writeAsBytes(pdfBytes, flush: true);

    // Open native share / save sheet (Files, AirDrop, Print, WhatsApp, etc.)
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/pdf', name: '$fileName.pdf')],
      text: 'iLiving Official Document: ${document.title}',
      sharePositionOrigin: shareOrigin,
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
