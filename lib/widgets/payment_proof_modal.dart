import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/installment.dart';
import '../models/payment.dart';
import '../repositories/firestore/firestore_ledger_repository.dart';
import '../repositories/firestore/firestore_payment_repository.dart';
import '../services/storage_service.dart';
import '../theme/luxury_theme.dart';

/// Modal sheets for submitting and reviewing payment transfer screenshots.
class PaymentProofModal {
  // Preset demo transfer receipts for convenient testing & selection
  static const List<Map<String, String>> presetScreenshots = [
    {
      'title': 'InstaPay Receipt',
      'url': 'preset:instapay',
      'notes': 'InstaPay Ref: #98421074',
    },
    {
      'title': 'Vodafone Cash',
      'url': 'preset:vodafone',
      'notes': 'VFCash Transfer ID #889312',
    },
  ];

  /// Render helper for Base64, Presets, or Network image sources
  static Widget buildProofImage(String src, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (src == 'preset:instapay' || src.toLowerCase().contains('instapay')) {
      return _buildInstaPayReceipt(width: width, height: height);
    }
    if (src == 'preset:vodafone' || src.toLowerCase().contains('vodafone') || src.toLowerCase().contains('vfcash')) {
      return _buildVodafoneCashReceipt(width: width, height: height);
    }
    if (src.startsWith('data:image/') || src.contains(';base64,')) {
      try {
        final base64Str = src.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white70, size: 28),
          ),
        );
      } catch (_) {}
    }
    return Image.network(
      src,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.black45,
        child: const Center(
          child: Text('Image Preview Unavailable', style: TextStyle(color: Colors.white, fontSize: 10)),
        ),
      ),
    );
  }

  static Widget _buildInstaPayReceipt({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF23074D), Color(0xFF4A148C), Color(0xFF6A1B9A)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'instapay',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Instant Payment Network',
                    style: TextStyle(color: Colors.white70, fontSize: 8),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'CBE / EBC',
                  style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          // Center Status & Amount
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Transfer Successful • تم التحويل بنجاح',
                      style: TextStyle(color: Color(0xFF00E676), fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1),
                    Text(
                      '79,100.00 EGP',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Details Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(70),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('To IPA / إلى:', style: TextStyle(color: Colors.white60, fontSize: 8)),
                    Text('iLiving.estate@instapay', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ref No. / رقم المرجع:', style: TextStyle(color: Colors.white60, fontSize: 8)),
                    Text('#98421074', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fee / الرسوم:', style: TextStyle(color: Colors.white60, fontSize: 8)),
                    Text('0.00 EGP (Free)', style: TextStyle(color: Colors.white, fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildVodafoneCashReceipt({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B0000), Color(0xFFE60000), Color(0xFFFF2A2A)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_tethering, color: Color(0xFFE60000), size: 12),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'vodafone cash',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'فودافون كاش',
                  style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          // Center Status & Amount
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Color(0xFFE60000), size: 14),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Money Sent Successfully • تم التحويل',
                      style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1),
                    Text(
                      '79,100.00 EGP',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Details Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('To Wallet / إلى محفظة:', style: TextStyle(color: Colors.white70, fontSize: 8)),
                    Text('01099887766', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Txn ID / رقم العملية:', style: TextStyle(color: Colors.white70, fontSize: 8)),
                    Text('VF-889312', style: TextStyle(color: Color(0xFFFFEB3B), fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recipient / المستلم:', style: TextStyle(color: Colors.white70, fontSize: 8)),
                    Text('iLiving Real Estate', style: TextStyle(color: Colors.white, fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show sheet for client to attach transfer screenshot & submit for approval.
  static Future<bool?> showUploadSheet({
    required BuildContext context,
    required Installment installment,
    required FirestoreLedgerRepository ledgerRepo,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UploadProofSheet(
        installment: installment,
        ledgerRepo: ledgerRepo,
      ),
    );
  }

  /// Show modal for admin (or client preview) to review submitted proof screenshot and approve/reject.
  static Future<bool?> showReviewModal({
    required BuildContext context,
    required Installment installment,
    required FirestoreLedgerRepository ledgerRepo,
    bool isAdmin = true,
    String? clientName,
    String? unitId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _ReviewProofDialog(
        installment: installment,
        ledgerRepo: ledgerRepo,
        isAdmin: isAdmin,
        clientName: clientName,
        unitId: unitId,
      ),
    );
  }
}

// ── Client Upload Sheet ────────────────────────────────────────────────────────

class _UploadProofSheet extends StatefulWidget {
  final Installment installment;
  final FirestoreLedgerRepository ledgerRepo;

  const _UploadProofSheet({
    required this.installment,
    required this.ledgerRepo,
  });

  @override
  State<_UploadProofSheet> createState() => _UploadProofSheetState();
}

class _UploadProofSheetState extends State<_UploadProofSheet> {
  final _notesController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedImage = PaymentProofModal.presetScreenshots[0]['url']!;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = PaymentProofModal.presetScreenshots[0]['notes']!;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _isSubmitting = true;
          _selectedImage = image.path; // temporary local path for preview
        });

        final bytes = await image.readAsBytes();
        final downloadUrl = await StorageService.instance.uploadPaymentProof(
          paymentId: widget.installment.id,
          file: bytes,
          fileName: image.name,
        );

        if (mounted) {
          setState(() {
            _selectedImage = downloadUrl;
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _submitProof() async {
    if (_selectedImage.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or upload a transfer screenshot proof.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updated = widget.installment.copyWith(
        status: InstallmentStatus.pendingApproval,
        proofScreenshotUrl: _selectedImage.trim(),
        submittedAt: DateTime.now(),
        submissionNotes: _notesController.text.trim(),
      );

      // Write to Firestore asynchronously with timeout so UI never hangs
      await widget.ledgerRepo.updateInstallment(updated).timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم إرسال إثبات التحويل بنجاح! في انتظار موافقة الإدارة.\nPayment proof submitted! Waiting for admin approval.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: LuxuryTheme.surfaceBrown,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('[PaymentProofModal] Error submitting proof: $e');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inst = widget.installment;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle line
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(isDark ? 35 : 20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.upload_file, color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.submitPaymentProofModalTitle,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.installmentSequenceHeader(inst.sequenceNumber.toString(), inst.installmentType.name.toUpperCase()),
                              style: TextStyle(color: textMuted, fontSize: 10),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Card
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard.withAlpha(120) : AppColors.lightCardAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.amountDue, style: TextStyle(color: textMuted, fontSize: 9)),
                            const SizedBox(height: 2),
                            Text(
                              '${inst.amount.toStringAsFixed(0)} ${inst.currency}',
                              style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_top, color: Colors.orange, size: 12),
                              const SizedBox(width: 4),
                              Text(l10n.statusUnpaid, style: const TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Bank / InstaPay Transfer Info Box
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(isDark ? 35 : 15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withAlpha(isDark ? 70 : 45)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance, color: AppColors.accent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              l10n.bankTransferInfo,
                              style: const TextStyle(color: AppColors.accent, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '• InstaPay IPA: iLiving.estate@instapay\n• Vodafone Cash: 01099887766',
                          style: TextStyle(color: textPrimary, fontSize: 10, height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Native File / Image Picker Buttons
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.uploadScreenshotLabel,
                        style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: Text(
                                l10n.gallery,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: Icon(Icons.camera_alt, size: 18, color: textPrimary),
                              label: Text(
                                l10n.camera,
                                style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: border, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Presets Row for convenience
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    l10n.sampleReceipts,
                    style: TextStyle(color: textMuted, fontSize: 10),
                  );
                },
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: PaymentProofModal.presetScreenshots.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final item = PaymentProofModal.presetScreenshots[idx];
                    final isSelected = _selectedImage == item['url'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = item['url']!;
                          _notesController.text = item['notes']!;
                        });
                      },
                      child: Container(
                        width: 125,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withAlpha(isDark ? 40 : 25)
                              : (isDark ? AppColors.darkCard : AppColors.lightCardAlt),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.image_outlined,
                              color: isSelected ? AppColors.accent : textMuted,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.accent : textPrimary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item['notes']!,
                                    style: TextStyle(color: textMuted, fontSize: 7.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Image Preview Card
              if (_selectedImage.isNotEmpty)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PaymentProofModal.buildProofImage(_selectedImage, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 12),
                                  const SizedBox(width: 4),
                                  Text(l10n.proofScreenshotSelected, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // Transaction Notes / Reference Input
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return TextField(
                    controller: _notesController,
                    maxLines: 2,
                    style: TextStyle(color: textPrimary, fontSize: 11),
                    decoration: InputDecoration(
                      labelText: l10n.transferRefNotes,
                      labelStyle: TextStyle(color: textMuted, fontSize: 10),
                      hintText: l10n.transferRefExample,
                      hintStyle: TextStyle(color: textMuted.withAlpha(120), fontSize: 10),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard.withAlpha(120) : AppColors.lightCardAlt,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Submit Button
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitProof,
                      icon: _isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSubmitting ? l10n.loading : l10n.submitForApproval,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Admin Review Dialog ───────────────────────────────────────────────────────

class _ReviewProofDialog extends StatefulWidget {
  final Installment installment;
  final FirestoreLedgerRepository ledgerRepo;
  final bool isAdmin;
  final String? clientName;
  final String? unitId;

  const _ReviewProofDialog({
    required this.installment,
    required this.ledgerRepo,
    this.isAdmin = true,
    this.clientName,
    this.unitId,
  });

  @override
  State<_ReviewProofDialog> createState() => _ReviewProofDialogState();
}

class _ReviewProofDialogState extends State<_ReviewProofDialog> {
  bool _isProcessing = false;

  Future<void> _approvePayment() async {
    setState(() => _isProcessing = true);
    final txnRef = 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final now = DateTime.now();

    final updated = widget.installment.copyWith(
      status: InstallmentStatus.paid,
      paidAt: now,
      paidAmount: widget.installment.totalAmountDue,
      receiptNumber: txnRef,
    );

    try {
      final paymentRepo = FirestorePaymentRepository();
      await paymentRepo.logPayment(
        Payment(
          id: 'PAY-${now.millisecondsSinceEpoch}',
          transactionReference: txnRef,
          contractId: widget.installment.contractId,
          installmentId: widget.installment.id,
          unitId: widget.installment.unitId,
          payerUserId: widget.installment.buyerUserId,
          paymentMethod: PaymentMethod.bankTransfer,
          amountPaid: widget.installment.totalAmountDue,
          currency: widget.installment.currency,
          status: PaymentStatus.success,
          createdAt: now,
        ),
      ).timeout(const Duration(seconds: 3), onTimeout: () {});

      await widget.ledgerRepo.updateInstallment(updated).timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent),
                const SizedBox(width: 10),
                Text(l10n.paymentApprovedNotice, style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('[PaymentProofModal] Error approving payment: $e');
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectPayment() async {
    setState(() => _isProcessing = true);
    final updated = widget.installment.copyWith(
      status: InstallmentStatus.unpaid,
    );

    try {
      await widget.ledgerRepo.updateInstallment(updated).timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel, color: Colors.white),
                const SizedBox(width: 10),
                Text(l10n.paymentRejectedNotice, style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('[PaymentProofModal] Error rejecting payment: $e');
      if (mounted) Navigator.pop(context, false);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inst = widget.installment;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? LuxuryTheme.surfaceBrown : Colors.white;
    final border = isDark ? LuxuryTheme.cardBrown : LuxuryTheme.lightBorder;
    final textPrimary = isDark ? LuxuryTheme.textWhite : LuxuryTheme.lightText;
    final textMuted = isDark ? LuxuryTheme.textMuted : LuxuryTheme.lightTextMuted;

    final subDateStr = inst.submittedAt != null
        ? '${inst.submittedAt!.day}/${inst.submittedAt!.month}/${inst.submittedAt!.year} - ${inst.submittedAt!.hour}:${inst.submittedAt!.minute.toString().padLeft(2, '0')}'
        : '-';

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: LuxuryTheme.primaryGold.withAlpha(80), width: 1.5),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rate_review, color: Colors.orange, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.submitPaymentProofModalTitle,
                            style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            l10n.installmentSequenceHeader(inst.sequenceNumber.toString(), inst.installmentType.name.toUpperCase()),
                            style: TextStyle(color: textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? LuxuryTheme.cardBrown.withAlpha(60) : const Color(0xFFF7F7F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    if (widget.clientName != null || widget.unitId != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.clientCustomerLabel, style: TextStyle(color: textMuted, fontSize: 10)),
                          Text(widget.clientName ?? l10n.unassignedCustomer, style: TextStyle(color: textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.unitIdLabel, style: TextStyle(color: textMuted, fontSize: 10)),
                          Text(widget.unitId ?? inst.unitId, style: TextStyle(color: textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.amountDueLabel, style: TextStyle(color: textMuted, fontSize: 10)),
                        Text('${inst.amount.toStringAsFixed(0)} ${inst.currency}', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.submittedAtLabel, style: TextStyle(color: textMuted, fontSize: 10)),
                        Text(subDateStr, style: TextStyle(color: textPrimary, fontSize: 10)),
                      ],
                    ),
                    if (inst.submissionNotes != null && inst.submissionNotes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.notesRefLabel, style: TextStyle(color: textMuted, fontSize: 10)),
                          Expanded(
                            child: Text(inst.submissionNotes!, style: TextStyle(color: textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Image Display Card
              Text(l10n.proofScreenshotLabel, style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                  color: Colors.black,
                ),
                clipBehavior: Clip.antiAlias,
                child: inst.proofScreenshotUrl != null && inst.proofScreenshotUrl!.isNotEmpty
                    ? PaymentProofModal.buildProofImage(inst.proofScreenshotUrl!, fit: BoxFit.contain)
                    : Center(
                        child: Text(l10n.noScreenshotUploaded, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              if (widget.isAdmin && inst.status == InstallmentStatus.pendingApproval)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _rejectPayment,
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
                        label: Text(l10n.reject, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _approvePayment,
                        icon: _isProcessing
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(
                          _isProcessing ? l10n.loading : l10n.approve,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: inst.isPaid ? Colors.green.withAlpha(40) : Colors.orange.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'STATUS: ${inst.status.name.toUpperCase()}',
                      style: TextStyle(
                        color: inst.isPaid ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

