import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../../repositories/firestore/firestore_payment_repository.dart';
import '../../theme/luxury_theme.dart';
import '../../widgets/admin/shared/admin_data_table.dart';

class PaymentsModuleScreen extends StatefulWidget {
  const PaymentsModuleScreen({super.key});

  @override
  State<PaymentsModuleScreen> createState() => _PaymentsModuleScreenState();
}

class _PaymentsModuleScreenState extends State<PaymentsModuleScreen> {
  final FirestorePaymentRepository _repository = FirestorePaymentRepository();
  late final Stream<List<Payment>> _paymentsStream;
  String _searchQuery = '';
  PaymentStatus? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentsStream = _repository.streamAllPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final Color textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return StreamBuilder<List<Payment>>(
      stream: _paymentsStream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final payments = snapshot.data ?? [];

        final filteredPayments = payments.where((p) {
          if (_selectedStatus != null && p.status != _selectedStatus) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return p.transactionReference.toLowerCase().contains(q) ||
                p.payerUserId.toLowerCase().contains(q) ||
                p.contractId.toLowerCase().contains(q) ||
                p.unitId.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAYMENTS & RECEIPTS RECONCILIATION',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Live Financial Transactions Master SSOT (${payments.length} Records)',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Row
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Container(
                    width: 210,
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                      borderRadius: AppBorderRadius.pill,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PaymentStatus?>(
                        value: _selectedStatus,
                        isExpanded: true,
                        hint: Text('All Payment Statuses', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12)),
                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        items: [
                          DropdownMenuItem<PaymentStatus?>(
                            value: null,
                            child: Text('All Payment Statuses', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12)),
                          ),
                          ...PaymentStatus.values.map((s) {
                            return DropdownMenuItem<PaymentStatus?>(
                              value: s,
                              child: Text(s.name.toUpperCase(), style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12)),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _selectedStatus = val),
                      ),
                    ),
                  ),

                  // Search Field
                  Container(
                    width: 280,
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                      borderRadius: AppBorderRadius.pill,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: textMuted, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search transaction, payer, unit...',
                              hintStyle: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Data Table
              Expanded(
                child: AdminDataTable<Payment>(
                  isLoading: isLoading,
                  items: filteredPayments,
                  emptyTitle: 'No Payment Transactions Found',
                  emptyMessage: _searchQuery.isEmpty
                      ? 'No payment transaction records found in Firestore.'
                      : 'No payments match your query filters.',
                  columns: [
                    AdminTableColumn<Payment>(
                      title: 'Ref #',
                      cellBuilder: (p) => Text(
                        p.transactionReference,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    AdminTableColumn<Payment>(
                      title: 'Payer ID / Client',
                      cellBuilder: (p) => Text(
                        p.payerUserId,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    AdminTableColumn<Payment>(
                      title: 'Method',
                      cellBuilder: (p) => Text(
                        p.paymentMethod.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    AdminTableColumn<Payment>(
                      title: 'Amount Paid',
                      cellBuilder: (p) => Text(
                        '${p.currency} ${_formatNumber(p.amountPaid)}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    AdminTableColumn<Payment>(
                      title: 'Timestamp',
                      cellBuilder: (p) => Text(
                        p.paymentTimestamp.toIso8601String().split('T').first,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    AdminTableColumn<Payment>(
                      title: 'Receipt URL',
                      cellBuilder: (p) => p.receiptPdfUrl != null && p.receiptPdfUrl!.isNotEmpty
                          ? const Text(
                              'Available',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.info,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text('None', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11)),
                    ),
                    AdminTableColumn<Payment>(
                      title: 'Status',
                      cellBuilder: (p) {
                        final color = p.status == PaymentStatus.success
                            ? AppColors.success
                            : p.status == PaymentStatus.failed
                                ? AppColors.error
                                : AppColors.warning;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: AppBorderRadius.pill,
                          ),
                          child: Text(
                            p.status.name.toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatNumber(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
