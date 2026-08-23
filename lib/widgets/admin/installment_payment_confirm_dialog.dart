import 'package:flutter/material.dart';
import '../../models/installment.dart';
import '../../models/payment.dart';
import '../../models/user_profile.dart';
import '../../theme/luxury_theme.dart';

class PaymentConfirmData {
  final PaymentMethod paymentMethod;
  final String? receiptReference;
  final double amountPaid;
  final String? receiptUrl;
  final String? notes;
  final DateTime paymentDate;

  const PaymentConfirmData({
    required this.paymentMethod,
    this.receiptReference,
    required this.amountPaid,
    this.receiptUrl,
    this.notes,
    required this.paymentDate,
  });
}

class InstallmentPaymentConfirmDialog extends StatefulWidget {
  final Installment installment;
  final UserProfile customer;
  final String contractNumber;
  final String unitNumber;

  const InstallmentPaymentConfirmDialog({
    super.key,
    required this.installment,
    required this.customer,
    required this.contractNumber,
    required this.unitNumber,
  });

  static Future<PaymentConfirmData?> show({
    required BuildContext context,
    required Installment installment,
    required UserProfile customer,
    required String contractNumber,
    required String unitNumber,
  }) {
    return showDialog<PaymentConfirmData>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InstallmentPaymentConfirmDialog(
        installment: installment,
        customer: customer,
        contractNumber: contractNumber,
        unitNumber: unitNumber,
      ),
    );
  }

  @override
  State<InstallmentPaymentConfirmDialog> createState() =>
      _InstallmentPaymentConfirmDialogState();
}

class _InstallmentPaymentConfirmDialogState
    extends State<InstallmentPaymentConfirmDialog> {
  late PaymentMethod _selectedMethod;
  late final TextEditingController _amountController;
  late final TextEditingController _refController;
  late final TextEditingController _receiptUrlController;
  late final TextEditingController _notesController;
  late DateTime _selectedPaymentDate;

  String? _validationError;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _selectedMethod = PaymentMethod.bankTransfer;
    final initialAmount = widget.installment.remainingAmount > 0
        ? widget.installment.remainingAmount
        : widget.installment.totalAmountDue;
    _amountController =
        TextEditingController(text: initialAmount.toStringAsFixed(0));
    _refController = TextEditingController();
    _receiptUrlController = TextEditingController();
    _notesController = TextEditingController();
    _selectedPaymentDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _receiptUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatMoney(double amount) {
    return 'EGP ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color get _statusColor {
    switch (widget.installment.status) {
      case InstallmentStatus.paid:
        return AppColors.success;
      case InstallmentStatus.partiallyPaid:
        return AppColors.warning;
      case InstallmentStatus.overdue:
        return AppColors.error;
      default:
        return widget.installment.dueDate.isBefore(DateTime.now())
            ? AppColors.error
            : AppColors.accent;
    }
  }

  Future<void> _pickPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPaymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.accent,
                    surface: AppColors.darkSurface,
                    onSurface: AppColors.textLight,
                  )
                : const ColorScheme.light(
                    primary: AppColors.accent,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedPaymentDate = picked);
    }
  }

  void _onConfirmPressed() {
    final amountText = _amountController.text.trim();
    final parsedAmount = double.tryParse(amountText);

    if (parsedAmount == null || parsedAmount <= 0) {
      setState(() => _validationError = 'Please enter a valid payment amount (> 0).');
      return;
    }

    setState(() {
      _validationError = null;
      _isConfirming = true;
    });

    final ref = _refController.text.trim();
    final receiptUrl = _receiptUrlController.text.trim();
    final notes = _notesController.text.trim();

    Navigator.pop(
      context,
      PaymentConfirmData(
        paymentMethod: _selectedMethod,
        receiptReference: ref,
        amountPaid: parsedAmount,
        receiptUrl: receiptUrl.isNotEmpty ? receiptUrl : null,
        notes: notes.isNotEmpty ? notes : null,
        paymentDate: _selectedPaymentDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final Color textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final Color cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    final clientCode = widget.customer.clientCode?.isNotEmpty == true
        ? widget.customer.clientCode!
        : '-';

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.large,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Modal Header ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payment_rounded, color: AppColors.success, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Management',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Review installment details & confirm customer payment',
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── 1. Installment Information Card ──────────────────────────
                const Text(
                  '1. INSTALLMENT & CUSTOMER INFORMATION',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: AppBorderRadius.medium,
                    boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Customer Name',
                        value: widget.customer.fullName,
                        valueStyle: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        icon: Icons.person_outline,
                        isDark: isDark,
                      ),
                      _Divider(color: border),
                      _InfoRow(
                        label: 'Client Code',
                        value: clientCode,
                        valueStyle: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        icon: Icons.badge_outlined,
                        isDark: isDark,
                      ),
                      _Divider(color: border),
                      _InfoRow(
                        label: 'Contract No.',
                        value: widget.contractNumber,
                        icon: Icons.description_outlined,
                        isDark: isDark,
                      ),
                      _Divider(color: border),
                      _InfoRow(
                        label: 'Unit Number',
                        value: widget.unitNumber,
                        icon: Icons.home_outlined,
                        isDark: isDark,
                      ),
                      _Divider(color: border),
                      _InfoRow(
                        label: 'Installment',
                        value: '#${widget.installment.sequenceNumber} — ${_typeLabel(widget.installment.installmentType)}',
                        icon: Icons.receipt_long_outlined,
                        isDark: isDark,
                      ),
                      _Divider(color: border),
                      _InfoRow(
                        label: 'Amount Due',
                        value: _formatMoney(widget.installment.totalAmountDue),
                        valueStyle: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        icon: Icons.attach_money_rounded,
                        isDark: isDark,
                      ),
                      _Divider(color: border),
                      _InfoRow(
                        label: 'Due Date',
                        value: _formatDate(widget.installment.dueDate),
                        icon: Icons.calendar_today_outlined,
                        isDark: isDark,
                      ),
                      _Divider(color: border),
                      _InfoRow(
                        label: 'Current Status',
                        value: widget.installment.status.nameString,
                        valueStyle: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        icon: Icons.info_outline,
                        isDark: isDark,
                      ),
                      _Divider(color: border),
                      _InfoRow(
                        label: 'Remaining',
                        value: _formatMoney(widget.installment.remainingAmount),
                        valueStyle: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: widget.installment.remainingAmount > 0
                              ? AppColors.warning
                              : AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        icon: Icons.account_balance_wallet_outlined,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 2. Payment Method Selection ──────────────────────────────
                const Text(
                  '2. SELECT PAYMENT METHOD',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: AppBorderRadius.pill,
                    border: Border.all(color: border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PaymentMethod>(
                      value: _selectedMethod,
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      items: [
                        DropdownMenuItem(
                          value: PaymentMethod.bankTransfer,
                          child: Text('🏦  Bank Transfer (${PaymentMethod.bankTransfer.displayNameAr})'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.instaPay,
                          child: Text('⚡  InstaPay (${PaymentMethod.instaPay.displayNameAr})'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.card,
                          child: Text('💳  Card (${PaymentMethod.card.displayNameAr})'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.cash,
                          child: Text('💵  Cash (${PaymentMethod.cash.displayNameAr})'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.cheque,
                          child: Text('📄  Cheque (${PaymentMethod.cheque.displayNameAr})'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.other,
                          child: Text('🔖  Other (${PaymentMethod.other.displayNameAr})'),
                        ),
                      ],
                      style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMethod = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── 3. Payment Confirmation Details ──────────────────────────
                const Text(
                  '3. PAYMENT CONFIRMATION DETAILS',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                // Payment Amount Field
                Text('Payment Amount (EGP)', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.numbers, color: AppColors.accent, size: 18),
                    filled: true,
                    fillColor: cardBg,
                    enabledBorder: OutlineInputBorder(borderRadius: AppBorderRadius.pill, borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: AppBorderRadius.pill, borderSide: const BorderSide(color: AppColors.accent)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Transaction Reference Field
                Text('Transaction / Reference ID', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _refController,
                  style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. TXN-2026-8849 (Optional)',
                    hintStyle: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
                    prefixIcon: Icon(Icons.tag, color: textMuted, size: 18),
                    filled: true,
                    fillColor: cardBg,
                    enabledBorder: OutlineInputBorder(borderRadius: AppBorderRadius.pill, borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: AppBorderRadius.pill, borderSide: const BorderSide(color: AppColors.accent)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Receipt URL / Attachment Link
                Text('Payment Receipt URL', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _receiptUrlController,
                  style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'https://storage.iliving.eg/receipts/doc.pdf (Optional)',
                    hintStyle: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
                    prefixIcon: Icon(Icons.receipt, color: textMuted, size: 18),
                    filled: true,
                    fillColor: cardBg,
                    enabledBorder: OutlineInputBorder(borderRadius: AppBorderRadius.pill, borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: AppBorderRadius.pill, borderSide: const BorderSide(color: AppColors.accent)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Payment Date Selection
                Text('Payment Date', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickPaymentDate,
                  borderRadius: AppBorderRadius.pill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: AppBorderRadius.pill,
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppColors.accent, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _formatDate(_selectedPaymentDate),
                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        const Text('Change', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Payment Notes Field
                Text('Payment Notes', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add internal admin notes or deposit reference...',
                    hintStyle: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
                    prefixIcon: Icon(Icons.note_alt_outlined, color: textMuted, size: 18),
                    filled: true,
                    fillColor: cardBg,
                    enabledBorder: OutlineInputBorder(borderRadius: AppBorderRadius.medium, borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: AppBorderRadius.medium, borderSide: const BorderSide(color: AppColors.accent)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Validation Error Banner
                if (_validationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(25),
                      borderRadius: AppBorderRadius.small,
                      border: Border.all(color: AppColors.error.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.error, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Workflow Warning Banner ────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(25),
                    borderRadius: AppBorderRadius.small,
                    border: Border.all(color: AppColors.warning.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Status remains PENDING until explicitly confirmed. Confirming will update Firestore real-time ledger and notify customer.',
                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Action Buttons ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isConfirming ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                        ),
                        child: Text('Cancel', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isConfirming ? null : _onConfirmPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                          elevation: 0,
                        ),
                        icon: _isConfirming
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                        label: const Text(
                          'CONFIRM PAYMENT',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(InstallmentType type) {
    switch (type) {
      case InstallmentType.downPayment:
        return 'Down Payment';
      case InstallmentType.regularQuarterly:
        return 'Quarterly';
      case InstallmentType.semiAnnual:
        return 'Semi-Annual';
      case InstallmentType.annual:
        return 'Annual';
      case InstallmentType.balloon:
        return 'Balloon';
      case InstallmentType.maintenanceFund:
        return 'Maintenance';
      case InstallmentType.deliveryPayment:
        return 'Handover';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final IconData icon;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final Color textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 0.5, color: color);
  }
}
