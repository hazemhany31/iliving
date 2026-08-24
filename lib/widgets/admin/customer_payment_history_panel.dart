import 'package:flutter/material.dart';
import '../../models/installment.dart';
import '../../models/payment.dart';
import '../../models/user_profile.dart';
import '../../repositories/firestore/firestore_ledger_repository.dart';
import '../../repositories/firestore/firestore_payment_repository.dart';
import '../../theme/luxury_theme.dart';
import '../payment_proof_modal.dart';

/// Displays a real-time payment history panel for a single customer.
class CustomerPaymentHistoryPanel extends StatefulWidget {
  final UserProfile customer;
  final String contractId;
  final String contractNumber;
  final String unitNumber;

  const CustomerPaymentHistoryPanel({
    super.key,
    required this.customer,
    required this.contractId,
    required this.contractNumber,
    required this.unitNumber,
  });

  /// Show as a bottom sheet modal.
  static Future<void> show({
    required BuildContext context,
    required UserProfile customer,
    required String contractId,
    required String contractNumber,
    required String unitNumber,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerPaymentHistoryPanel(
        customer: customer,
        contractId: contractId,
        contractNumber: contractNumber,
        unitNumber: unitNumber,
      ),
    );
  }

  @override
  State<CustomerPaymentHistoryPanel> createState() => _CustomerPaymentHistoryPanelState();
}

class _CustomerPaymentHistoryPanelState extends State<CustomerPaymentHistoryPanel> {
  final FirestoreLedgerRepository _ledgerRepo = FirestoreLedgerRepository();
  final FirestorePaymentRepository _paymentRepo = FirestorePaymentRepository();
  late final Stream<List<Installment>> _installmentsStream;
  late final Stream<List<Payment>> _paymentsStream;

  UserProfile get customer => widget.customer;
  String get contractId => widget.contractId;
  String get contractNumber => widget.contractNumber;
  String get unitNumber => widget.unitNumber;

  @override
  void initState() {
    super.initState();
    _installmentsStream = _ledgerRepo.streamInstallmentsForContract(widget.contractId);
    _paymentsStream = _paymentRepo.streamPaymentsForUser(widget.customer.uid);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final Color textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ────────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    // Avatar initial
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          customer.fullName.isNotEmpty
                              ? customer.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: AppColors.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.fullName,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Unit $unitNumber',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Contract: $contractNumber',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: border),

              // ── Installment Timeline ────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<Installment>>(
                  stream: _installmentsStream,
                  builder: (context, instSnap) {
                    if (instSnap.connectionState ==
                            ConnectionState.waiting &&
                        !instSnap.hasData) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent),
                      );
                    }

                    final installments = instSnap.data ?? [];
                    if (installments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                color: textMuted, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No installments found',
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    // Determine summary stats.
                    final totalInstallments = installments.length;
                    final paidCount = installments
                        .where((i) => i.status == InstallmentStatus.paid)
                        .length;
                    final totalAmount = installments.fold(
                        0.0, (sum, i) => sum + i.totalAmountDue);
                    final totalPaid = installments.fold(
                        0.0, (sum, i) => sum + i.paidAmount);
                    final remaining = totalAmount - totalPaid;

                    // Find next due installment (first unpaid).
                    final nextDue = installments
                        .where((i) =>
                            i.status != InstallmentStatus.paid &&
                            i.status != InstallmentStatus.waived)
                        .firstOrNull;

                    return StreamBuilder<List<Payment>>(
                      stream: _paymentsStream,
                      builder: (ctx2, paySnap) {
                        final allPayments = paySnap.data ?? [];

                        return ListView(
                          controller: scrollController,
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          children: [
                            // Summary cards row
                            _buildSummaryRow(
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                              border: border,
                              paidCount: paidCount,
                              totalCount: totalInstallments,
                              totalPaid: totalPaid,
                              remaining: remaining,
                            ),
                            const SizedBox(height: 20),

                            // Section header
                            Row(
                              children: [
                                const Icon(Icons.timeline,
                                    color: AppColors.accent, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'PAYMENT TIMELINE',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Installment items
                            ...installments.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final inst = entry.value;
                              final isLast =
                                   idx == installments.length - 1;
                              final isNext = nextDue?.id == inst.id;

                              // Find matching payments for this installment
                              final matchingPayments = allPayments
                                  .where((p) =>
                                      p.installmentId == inst.id)
                                  .toList()
                                ..sort((a, b) => b.createdAt
                                    .compareTo(a.createdAt));

                              return _InstallmentTimelineItem(
                                installment: inst,
                                isLast: isLast,
                                isNext: isNext,
                                matchingPayments: matchingPayments,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                border: border,
                                clientName: customer.fullName,
                                unitNumber: unitNumber,
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
    required int paidCount,
    required int totalCount,
    required double totalPaid,
    required double remaining,
  }) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Paid',
            value: '$paidCount / $totalCount',
            valueColor: AppColors.success,
            icon: Icons.check_circle_outline,
            isDark: isDark,
            border: border,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Collected',
            value: 'EGP ${_fmt(totalPaid)}',
            valueColor: AppColors.success,
            icon: Icons.account_balance_wallet_outlined,
            isDark: isDark,
            border: border,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Remaining',
            value: 'EGP ${_fmt(remaining)}',
            valueColor: remaining > 0 ? AppColors.warning : AppColors.success,
            icon: Icons.pending_outlined,
            isDark: isDark,
            border: border,
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

// ── Timeline Item ────────────────────────────────────────────────────────────

class _InstallmentTimelineItem extends StatelessWidget {
  final Installment installment;
  final bool isLast;
  final bool isNext;
  final List<Payment> matchingPayments;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color border;
  final String? clientName;
  final String? unitNumber;

  const _InstallmentTimelineItem({
    required this.installment,
    required this.isLast,
    required this.isNext,
    required this.matchingPayments,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
    this.clientName,
    this.unitNumber,
  });

  Color get _dotColor {
    if (installment.status == InstallmentStatus.paid) return AppColors.success;
    if (isNext) return AppColors.accent;
    if (installment.status == InstallmentStatus.overdue ||
        (installment.status == InstallmentStatus.unpaid &&
            installment.dueDate.isBefore(DateTime.now()))) {
      return AppColors.error;
    }
    if (installment.status == InstallmentStatus.partiallyPaid) {
      return AppColors.warning;
    }
    return Colors.grey.shade400;
  }

  Color get _cardBg {
    if (installment.status == InstallmentStatus.paid) {
      return AppColors.success.withAlpha(isDark ? 20 : 12);
    }
    if (isNext) {
      return AppColors.accent.withAlpha(isDark ? 20 : 12);
    }
    if (installment.status == InstallmentStatus.overdue) {
      return AppColors.error.withAlpha(isDark ? 20 : 12);
    }
    return isDark ? AppColors.darkCard : AppColors.lightCard;
  }

  String get _statusLabel {
    if (isNext) return 'NEXT DUE';
    switch (installment.status) {
      case InstallmentStatus.pendingApproval:
        return '⏳ WAITING APPROVAL';
      case InstallmentStatus.paid:
        return '✓ PAID';
      case InstallmentStatus.partiallyPaid:
        return 'PARTIAL';
      case InstallmentStatus.overdue:
        return '⚠ OVERDUE';
      case InstallmentStatus.gracePeriod:
        return 'GRACE PERIOD';
      case InstallmentStatus.waived:
        return 'WAIVED';
      case InstallmentStatus.unpaid:
        if (installment.dueDate.isBefore(DateTime.now())) return '⚠ OVERDUE';
        return 'PENDING';
    }
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _fmt(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                  ),
                  child: installment.status == InstallmentStatus.paid
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: AppBorderRadius.medium,
                boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Installment # + Status badge
                  Row(
                    children: [
                      Text(
                        'Installment #${installment.sequenceNumber}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _dotColor.withAlpha(25),
                          borderRadius: AppBorderRadius.pill,
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: _dotColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Amount
                  Row(
                    children: [
                      const Icon(Icons.attach_money_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'EGP ${_fmt(installment.totalAmountDue)}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (installment.status ==
                          InstallmentStatus.partiallyPaid) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${_fmt(installment.remainingAmount)} remaining)',
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textMuted, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Due Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_fmtDate(installment.dueDate)}',
                        style:
                            TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  // Paid Date (if paid)
                  if (installment.paidAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 13, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Paid: ${_fmtDate(installment.paidAt!)}',
                          style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: AppColors.success, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  // Payment method & receipt
                  if (matchingPayments.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.payment_outlined,
                            size: 13, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          matchingPayments.first.paymentMethod.name.toUpperCase(),
                          style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        if (matchingPayments.first.transactionReference
                            .isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.tag, size: 12, color: textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              matchingPayments.first.transactionReference,
                              style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (installment.status == InstallmentStatus.pendingApproval) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => PaymentProofModal.showReviewModal(
                        context: context,
                        installment: installment,
                        ledgerRepo: FirestoreLedgerRepository(),
                        isAdmin: true,
                        clientName: clientName,
                        unitId: unitNumber,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(25),
                          borderRadius: AppBorderRadius.pill,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.rate_review, size: 14, color: AppColors.warning),
                            SizedBox(width: 6),
                            Text(
                              'مراجعة إثبات التحويل / REVIEW PROOF',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final bool isDark;
  final Color border;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.isDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final Color textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final Color bg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppBorderRadius.medium,
        boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: valueColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
