import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/contract.dart';
import '../../models/installment.dart';
import '../../models/user_profile.dart';
import '../../repositories/firestore/firestore_contract_repository.dart';
import '../../repositories/firestore/firestore_ledger_repository.dart';
import '../../repositories/firestore/firestore_user_repository.dart';
import '../../services/admin_payment_action_service.dart';
import '../../services/auth_service.dart';
import '../../theme/luxury_theme.dart';
import '../../widgets/admin/customer_payment_history_panel.dart';
import '../../widgets/admin/installment_payment_confirm_dialog.dart';
import '../../widgets/admin/shared/admin_status_badge.dart';
import '../../widgets/payment_proof_modal.dart';

// ── Data model used in the customer-payment overview table ────────────────────

class _CustomerPaymentRow {
  final UserProfile user;
  final Contract contract;
  final Installment? currentInstallment;    // next unpaid (or last paid)
  final Installment? nextInstallment;       // installment after current paid one
  final List<Installment> allInstallments;

  const _CustomerPaymentRow({
    required this.user,
    required this.contract,
    this.currentInstallment,
    this.nextInstallment,
    this.allInstallments = const [],
  });

  double get remainingBalance =>
      allInstallments.fold(0.0, (s, i) => s + i.remainingAmount);

  String get unitDisplay => contract.unitId;

  String get clientCodeDisplay => user.clientCode ?? contract.clientCode ?? '-';

  Installment? get displayedInstallment =>
      currentInstallment ?? allInstallments.lastOrNull;
}

// ── Filter chips ───────────────────────────────────────────────────────────────

enum _InstallmentFilter { all, pending, paid, overdue, partial, dueSoon }

// ── Main screen ───────────────────────────────────────────────────────────────

class InstallmentsModuleScreen extends StatefulWidget {
  const InstallmentsModuleScreen({super.key});

  @override
  State<InstallmentsModuleScreen> createState() =>
      _InstallmentsModuleScreenState();
}

class _InstallmentsModuleScreenState extends State<InstallmentsModuleScreen>
    with SingleTickerProviderStateMixin {
  // ── Repositories / services ──────────────────────────────────────────────
  final _userRepo = FirestoreUserRepository();
  final _contractRepo = FirestoreContractRepository();
  final _ledgerRepo = FirestoreLedgerRepository();
  final _paymentService = AdminPaymentActionService();

  // ── Tab controller (Customer Overview | Due Soon) ────────────────────────
  late final TabController _tabController;

  // ── Streams ──────────────────────────────────────────────────────────────
  StreamSubscription? _usersSubscription;
  StreamSubscription? _contractsSubscription;
  StreamSubscription? _installmentsSubscription;

  List<UserProfile> _users = [];
  List<Contract> _contracts = [];
  List<Installment> _installments = [];

  bool _isLoading = true;
  String? _errorMessage;

  // ── Filter / Search state ────────────────────────────────────────────────
  _InstallmentFilter _activeFilter = _InstallmentFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ── Mark-as-Paid tracking ────────────────────────────────────────────────
  final Set<String> _processingInstallmentIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startStreams();
  }

  void _startStreams() {
    // Stream all users
    _usersSubscription = _userRepo.streamAllUsers().listen(
      (users) {
        if (mounted) setState(() { _users = users; _isLoading = false; });
      },
      onError: (e) {
        if (mounted) {
          setState(() { _errorMessage = e.toString(); _isLoading = false; });
        }
      },
    );

    // Stream all contracts
    _contractsSubscription = _contractRepo.streamAllContracts().listen(
      (contracts) {
        if (mounted) setState(() => _contracts = contracts);
      },
    );

    // Stream all installments
    _installmentsSubscription =
        _ledgerRepo.streamAllInstallments().listen(
      (installments) {
        if (mounted) setState(() => _installments = installments);
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _usersSubscription?.cancel();
    _contractsSubscription?.cancel();
    _installmentsSubscription?.cancel();
    super.dispose();
  }

  // ── Build customer payment rows ───────────────────────────────────────────

  List<_CustomerPaymentRow> _buildRows() {
    final rows = <_CustomerPaymentRow>[];

    for (final contract in _contracts) {
      // Find the associated user
      final user = _users.firstWhere(
        (u) => u.uid == contract.buyerUserId,
        orElse: () => UserProfile(
          uid: contract.buyerUserId,
          email: '-',
          phoneNumber: '-',
          fullName: contract.buyerUserId,
          role: UserRole.customer,
          createdAt: DateTime.now(),
        ),
      );

      // Get installments for this contract
      final contractInstallments = _installments
          .where((i) => i.contractId == contract.id)
          .toList()
        ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));

      if (contractInstallments.isEmpty) {
        rows.add(_CustomerPaymentRow(
          user: user,
          contract: contract,
          currentInstallment: null,
          nextInstallment: null,
          allInstallments: const [],
        ));
        continue;
      }

      // Current = first unpaid/overdue
      final currentInst = contractInstallments.firstWhere(
        (i) =>
            i.status != InstallmentStatus.paid &&
            i.status != InstallmentStatus.waived,
        orElse: () => contractInstallments.last,
      );

      // If currentInst is actually paid (all paid scenario), show null
      final Installment? current = contractInstallments.every(
              (i) => i.status == InstallmentStatus.paid || i.status == InstallmentStatus.waived)
          ? null
          : currentInst;

      // Next = installment after current
      Installment? next;
      if (current != null) {
        next = contractInstallments.firstWhere(
          (i) =>
              i.sequenceNumber > current.sequenceNumber &&
              i.status != InstallmentStatus.paid &&
              i.status != InstallmentStatus.waived,
          orElse: () => contractInstallments.last,
        );
        if (next.id == current.id) next = null;
      }

      rows.add(_CustomerPaymentRow(
        user: user,
        contract: contract,
        currentInstallment: current,
        nextInstallment: next,
        allInstallments: contractInstallments,
      ));
    }

    return rows;
  }

  List<_CustomerPaymentRow> _applyFilters(List<_CustomerPaymentRow> rows) {
    final now = DateTime.now();

    return rows.where((row) {
      // Text search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = row.user.fullName.toLowerCase().contains(q);
        final matchesEmail = row.user.email.toLowerCase().contains(q);
        final matchesClient =
            row.clientCodeDisplay.toLowerCase().contains(q);
        final matchesUnit = row.unitDisplay.toLowerCase().contains(q);
        final matchesContract =
            row.contract.contractNumber.toLowerCase().contains(q);
        if (!matchesName &&
            !matchesEmail &&
            !matchesClient &&
            !matchesUnit &&
            !matchesContract) { return false; }
      }

      // Status filter
      final inst = row.displayedInstallment;
      switch (_activeFilter) {
        case _InstallmentFilter.all:
          return true;
        case _InstallmentFilter.pending:
          return inst != null && inst.status == InstallmentStatus.unpaid;
        case _InstallmentFilter.paid:
          return row.allInstallments.isNotEmpty &&
              row.allInstallments
                  .every((i) => i.status == InstallmentStatus.paid);
        case _InstallmentFilter.overdue:
          return inst != null &&
              (inst.status == InstallmentStatus.overdue ||
                  (inst.status == InstallmentStatus.unpaid &&
                      inst.dueDate.isBefore(now)));
        case _InstallmentFilter.partial:
          return inst != null &&
              inst.status == InstallmentStatus.partiallyPaid;
        case _InstallmentFilter.dueSoon:
          if (inst == null) return false;
          final diff = inst.dueDate.difference(now).inDays;
          return diff >= 0 && diff <= 7;
      }
    }).toList();
  }

  List<Installment> _buildDueSoonList() {
    final now = DateTime.now();
    final dueSoon = _installments.where((i) {
      if (i.status == InstallmentStatus.paid ||
          i.status == InstallmentStatus.waived) { return false; }
      final diff = i.dueDate.difference(now).inDays;
      return diff >= -30 && diff <= 7; // overdue up to 30 days back + 7 days forward
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return dueSoon;
  }

  // ── Mark as paid handler ──────────────────────────────────────────────────

  Future<void> _handleMarkAsPaid(_CustomerPaymentRow row, Installment inst) async {
    final confirmData = await InstallmentPaymentConfirmDialog.show(
      context: context,
      customer: row.user,
      unitNumber: row.unitDisplay,
      contractNumber: row.contract.contractNumber,
      installment: inst,
    );

    if (confirmData == null || !mounted) return;

    setState(() => _processingInstallmentIds.add(inst.id));

    try {
      final adminUid = AuthService.instance.currentProfile?.uid ?? 'admin';

      final result = await _paymentService.markAsPaid(
        installment: inst,
        customer: row.user,
        adminUserId: adminUid,
        paymentMethod: confirmData.paymentMethod,
        receiptReference: confirmData.receiptReference,
        receiptPdfUrl: confirmData.receiptUrl,
        notes: confirmData.notes,
        paymentDate: confirmData.paymentDate,
        confirmedAmount: confirmData.amountPaid,
        allContractInstallments: row.allInstallments,
      );

      if (!mounted) return;

      setState(() => _processingInstallmentIds.remove(inst.id));

      final nextMsg = result.nextInstallment != null
          ? ' • Next: Installment #${result.nextInstallment!.sequenceNumber} UPCOMING'
          : ' • Contract Fully Paid!';

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Installment #${result.paidInstallment.sequenceNumber} marked as PAID (EGP ${result.payment.amountPaid.toStringAsFixed(0)})$nextMsg',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processingInstallmentIds.remove(inst.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          content: Text('Error: $e'),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final Color textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final Color surfaceColor = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final rows = _applyFilters(_buildRows());
    final dueSoonList = _buildDueSoonList();
    final pendingList = _installments.where((i) => i.status == InstallmentStatus.pendingApproval).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, hdrConstraints) {
              final isNarrow = hdrConstraints.maxWidth < 480;
              final chips = [
                _StatChip(
                  label: 'PENDING APPROVAL',
                  count: pendingList.length,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8, height: 6),
                _StatChip(
                  label: 'OVERDUE',
                  count: _installments.where((i) =>
                      i.status == InstallmentStatus.overdue ||
                      (i.status == InstallmentStatus.unpaid &&
                          i.dueDate.isBefore(DateTime.now()))).length,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8, height: 6),
                _StatChip(
                  label: 'DUE SOON',
                  count: dueSoonList
                      .where((i) =>
                          i.dueDate.isAfter(DateTime.now()) &&
                          i.dueDate.difference(DateTime.now()).inDays <= 7)
                      .length,
                  color: Colors.orangeAccent,
                ),
              ];

              if (isNarrow) {
                // Stack: title above, chips below
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSTALLMENTS & PAYMENT STATUS',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_contracts.length} contracts • ${_installments.length} installments',
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(children: chips),
                  ],
                );
              }

              // Wide layout: title + chips on one row
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INSTALLMENTS & PAYMENT STATUS',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_contracts.length} contracts • ${_installments.length} installments • SSOT Live',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ...chips,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Search bar ───────────────────────────────────────────────
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search, color: textMuted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(color: textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Search by name, email, client code, unit, contract...',
                      hintStyle: TextStyle(color: textMuted, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.close, color: textMuted, size: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Filter chips ─────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _InstallmentFilter.values.map((filter) {
                final isActive = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _activeFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark ? AppColors.accent : AppColors.primary)
                            : surfaceColor,
                        borderRadius: AppBorderRadius.pill,
                        border: Border.all(
                          color: isActive
                              ? (isDark ? AppColors.accent : AppColors.primary)
                              : borderColor,
                        ),
                      ),
                      child: Text(
                        _filterLabel(filter),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: isActive
                              ? Colors.white
                              : textMuted,
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // ── Tabs ─────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: AppBorderRadius.pill,
              border: Border.all(color: borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: isDark ? AppColors.accent : AppColors.primary,
              unselectedLabelColor: textMuted,
              indicatorColor: isDark ? AppColors.accent : AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        'Overview (${rows.length})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_top, size: 15, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'Pending Approvals (${pendingList.length})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: pendingList.isNotEmpty ? Colors.orange : textMuted,
                          fontWeight: pendingList.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alarm_outlined, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        'Due Soon (${dueSoonList.length})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Tab bodies ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Customer Overview
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent))
                    : _errorMessage != null
                        ? _buildError(_errorMessage!, textMuted)
                        : rows.isEmpty
                            ? _buildEmpty(
                                'No customers match your filters.',
                                textMuted)
                            : _buildCustomerOverview(
                                rows, isDark, textPrimary, textMuted,
                                surfaceColor, borderColor),

                // Tab 2: Pending Approvals
                _buildPendingApprovalsTab(
                    pendingList, isDark, textPrimary, textMuted,
                    surfaceColor, borderColor),

                // Tab 3: Due Soon
                _buildDueSoonTab(
                    dueSoonList, isDark, textPrimary, textMuted,
                    surfaceColor, borderColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Customer Overview (Responsive) ──────────────────────────────────────

  Widget _buildCustomerOverview(
    List<_CustomerPaymentRow> rows,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color surfaceColor,
    Color borderColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildMobileCardList(
              rows, isDark, textPrimary, textMuted, surfaceColor, borderColor);
        }
        return _buildDesktopTable(rows, isDark, textPrimary, textMuted,
            surfaceColor, borderColor, constraints);
      },
    );
  }

  /// Desktop / tablet (≥ 600 px): horizontally-scrollable table with a fixed
  /// minimum width so no column ever squeezes, overlaps, or clips.
  Widget _buildDesktopTable(
    List<_CustomerPaymentRow> rows,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color surfaceColor,
    Color borderColor,
    BoxConstraints outerConstraints,
  ) {
    const double minTableWidth = 1050.0;
    final double tableWidth = outerConstraints.maxWidth > minTableWidth
        ? outerConstraints.maxWidth
        : minTableWidth;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (ctx, inner) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              height: inner.maxHeight,
              child: Column(
                children: [
                  // Table header
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : AppColors.lightCard,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      border: Border(bottom: BorderSide(color: borderColor)),
                    ),
                    child: _TableRow(
                      cells: const [
                        'CUSTOMER',
                        'UNIT / CONTRACT',
                        'CURRENT INSTALLMENT',
                        'AMOUNT',
                        'DUE DATE',
                        'STATUS',
                        'BALANCE',
                        'ACTIONS',
                      ],
                      isHeader: true,
                      isDark: isDark,
                    ),
                  ),
                  // Data rows
                  Expanded(
                    child: ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: borderColor),
                      itemBuilder: (ctx, idx) {
                        final row = rows[idx];
                        final inst = row.displayedInstallment;
                        return _buildCustomerRow(row, inst, isDark,
                            textPrimary, textMuted, borderColor);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Mobile (< 600 px): card-based list — one card per customer / installment.
  Widget _buildMobileCardList(
    List<_CustomerPaymentRow> rows,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color surfaceColor,
    Color borderColor,
  ) {
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (ctx, idx) {
        final row = rows[idx];
        final inst = row.displayedInstallment;
        final isAllPaid = row.allInstallments.isNotEmpty &&
            row.allInstallments.every((i) =>
                i.status == InstallmentStatus.paid ||
                i.status == InstallmentStatus.waived);
        final isProcessing =
            inst != null && _processingInstallmentIds.contains(inst.id);
        final canPay =
            inst != null && inst.status != InstallmentStatus.paid && !isAllPaid;

        return _InstallmentCard(
          row: row,
          isDark: isDark,
          textPrimary: textPrimary,
          textMuted: textMuted,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          isProcessing: isProcessing,
          onMarkAsPaid: canPay
              ? (isProcessing ? null : () => _handleMarkAsPaid(row, inst))
              : null,
          onViewHistory: () => CustomerPaymentHistoryPanel.show(
            context: context,
            customer: row.user,
            contractId: row.contract.id,
            contractNumber: row.contract.contractNumber,
            unitNumber: row.unitDisplay,
          ),
          onRowTap: () => CustomerPaymentHistoryPanel.show(
            context: context,
            customer: row.user,
            contractId: row.contract.id,
            contractNumber: row.contract.contractNumber,
            unitNumber: row.unitDisplay,
          ),
        );
      },
    );
  }

  Widget _buildCustomerRow(
    _CustomerPaymentRow row,
    Installment? inst,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
  ) {
    final isProcessing =
        inst != null && _processingInstallmentIds.contains(inst.id);
    final isPaid = inst?.status == InstallmentStatus.paid;
    final isAllPaid = row.allInstallments.isNotEmpty &&
        row.allInstallments.every((i) =>
            i.status == InstallmentStatus.paid ||
            i.status == InstallmentStatus.waived);

    return InkWell(
      onTap: () {
        // Tapping the row opens payment history
        CustomerPaymentHistoryPanel.show(
          context: context,
          customer: row.user,
          contractId: row.contract.id,
          contractNumber: row.contract.contractNumber,
          unitNumber: row.unitDisplay,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            // Customer name + email + client code
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(name: row.user.fullName),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.user.fullName,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              row.user.email,
                              style: TextStyle(
                                  color: textMuted, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (row.clientCodeDisplay != '-')
                              Text(
                                'Code: ${row.clientCodeDisplay}',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: AppColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Unit / Contract
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.unitDisplay,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    row.contract.contractNumber,
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Installment # + type
            Expanded(
              flex: 2,
              child: inst != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Installment #${inst.sequenceNumber}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          inst.installmentType.name.toUpperCase(),
                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 10),
                        ),
                      ],
                    )
                  : const Text('All Paid',
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
            ),

            // Amount
            Expanded(
              flex: 2,
              child: inst != null
                  ? Text(
                      'EGP ${_fmt(inst.totalAmountDue)}',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Due date
            Expanded(
              flex: 2,
              child: inst != null
                  ? _DueDateChip(dueDate: inst.dueDate, isDark: isDark)
                  : const SizedBox.shrink(),
            ),

            // Status badge
            Expanded(
              flex: 2,
              child: inst != null
                  ? PaymentStatusChip(status: inst.status, isDense: true)
                  : _buildAllPaidBadge(),
            ),

            // Remaining balance
            Expanded(
              flex: 2,
              child: Text(
                'EGP ${_fmt(row.remainingBalance)}',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: row.remainingBalance > 0
                      ? AppColors.warning
                      : AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            // Actions
            Expanded(
              flex: 3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mark as Paid button
                  if (inst != null && !isPaid && !isAllPaid)
                    _ActionButton(
                      label: isProcessing ? 'PROCESSING...' : 'MARK AS PAID',
                      icon: isProcessing
                          ? null
                          : Icons.check_circle_outline,
                      color: AppColors.success,
                      isLoading: isProcessing,
                      onTap: isProcessing
                          ? null
                          : () => _handleMarkAsPaid(row, inst),
                    ),

                  const SizedBox(width: 6),

                  // View History button
                  _ActionButton(
                    label: 'HISTORY',
                    icon: Icons.history,
                    color: AppColors.accent,
                    onTap: () => CustomerPaymentHistoryPanel.show(
                      context: context,
                      customer: row.user,
                      contractId: row.contract.id,
                      contractNumber: row.contract.contractNumber,
                      unitNumber: row.unitDisplay,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pending Approvals Tab ──────────────────────────────────────────────────

  Widget _buildPendingApprovalsTab(
    List<Installment> pendingList,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color surfaceColor,
    Color borderColor,
  ) {
    if (pendingList.isEmpty) {
      return _buildEmpty('No payment proof screenshots waiting for approval.', textMuted);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: pendingList.length,
      itemBuilder: (context, index) {
        final inst = pendingList[index];
        final contract = _contracts.where(
          (c) => c.id == inst.contractId || c.unitId == inst.unitId,
        ).firstOrNull;

        final user = _users.where(
          (u) => u.uid == inst.buyerUserId || (contract != null && u.uid == contract.buyerUserId),
        ).firstOrNull ?? UserProfile(
          uid: inst.buyerUserId,
          email: '-',
          phoneNumber: '-',
          fullName: inst.buyerUserId.isNotEmpty ? inst.buyerUserId : 'Customer',
          role: UserRole.customer,
          createdAt: DateTime.now(),
        );

        final unitIdStr = contract?.unitId ?? (inst.unitId.isNotEmpty ? inst.unitId : '-');
        final clientCodeStr = user.clientCode ?? contract?.clientCode ?? '-';

        final subDateStr = inst.submittedAt != null
            ? '${inst.submittedAt!.day}/${inst.submittedAt!.month}/${inst.submittedAt!.year} - ${inst.submittedAt!.hour}:${inst.submittedAt!.minute.toString().padLeft(2, '0')}'
            : '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.withAlpha(120), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.hourglass_top, color: Colors.orange, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Unit $unitIdStr • Code: $clientCodeStr',
                              style: TextStyle(color: textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${inst.amount.toStringAsFixed(0)} ${inst.currency}',
                      style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (inst.proofScreenshotUrl != null && inst.proofScreenshotUrl!.isNotEmpty)
                      GestureDetector(
                        onTap: () => PaymentProofModal.showReviewModal(
                          context: context,
                          installment: inst,
                          ledgerRepo: _ledgerRepo,
                          isAdmin: true,
                          clientName: user.fullName,
                          unitId: unitIdStr,
                        ),
                        child: Container(
                          width: 85,
                          height: 65,
                          decoration: BoxDecoration(
                            borderRadius: AppBorderRadius.small,
                            border: Border.all(color: AppColors.accent),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: PaymentProofModal.buildProofImage(
                                  inst.proofScreenshotUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(color: Colors.black.withAlpha(180), borderRadius: BorderRadius.circular(4)),
                                  child: const Icon(Icons.zoom_in, color: AppColors.accent, size: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sequence #${inst.sequenceNumber} - ${inst.installmentType.name.toUpperCase()}',
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Submitted: $subDateStr',
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 9.5),
                          ),
                          if (inst.submissionNotes != null && inst.submissionNotes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Notes: ${inst.submissionNotes}',
                              style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => PaymentProofModal.showReviewModal(
                        context: context,
                        installment: inst,
                        ledgerRepo: _ledgerRepo,
                        isAdmin: true,
                        clientName: user.fullName,
                        unitId: unitIdStr,
                      ),
                      icon: const Icon(Icons.rate_review, size: 14),
                      label: const Text('مراجعة وتحديد / REVIEW PROOF', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Due Soon Tab ──────────────────────────────────────────────────────────

  Widget _buildDueSoonTab(
    List<Installment> dueSoonList,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color surfaceColor,
    Color borderColor,
  ) {
    final now = DateTime.now();
    if (dueSoonList.isEmpty) {
      return _buildEmpty('No upcoming installments due in the next 7 days.', textMuted);
    }

    // Group by urgency
    final overdue = dueSoonList.where((i) => i.dueDate.isBefore(now)).toList();
    final today = dueSoonList.where((i) {
      final diff = i.dueDate.difference(now).inDays;
      return diff == 0;
    }).toList();
    final thisWeek = dueSoonList.where((i) {
      final diff = i.dueDate.difference(now).inDays;
      return diff > 0 && diff <= 7;
    }).toList();

    final items = <Widget>[
      if (overdue.isNotEmpty) ...[
        _DueSoonSectionHeader(
            label: '🔴 OVERDUE (${overdue.length})', color: Colors.redAccent),
        for (final i in overdue)
          _DueSoonCard(
            installment: i,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            borderColor: borderColor,
            onMarkPaid: () => _handleMarkAsPaidFromDueSoon(i),
            isProcessing: _processingInstallmentIds.contains(i.id),
          ),
      ],
      if (today.isNotEmpty) ...[
        _DueSoonSectionHeader(
            label: '🟠 DUE TODAY (${today.length})',
            color: Colors.orangeAccent),
        for (final i in today)
          _DueSoonCard(
            installment: i,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            borderColor: borderColor,
            onMarkPaid: () => _handleMarkAsPaidFromDueSoon(i),
            isProcessing: _processingInstallmentIds.contains(i.id),
          ),
      ],
      if (thisWeek.isNotEmpty) ...[
        _DueSoonSectionHeader(
            label: '🔵 DUE THIS WEEK (${thisWeek.length})',
            color: Colors.blueAccent),
        for (final i in thisWeek)
          _DueSoonCard(
            installment: i,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            borderColor: borderColor,
            onMarkPaid: () => _handleMarkAsPaidFromDueSoon(i),
            isProcessing: _processingInstallmentIds.contains(i.id),
          ),
      ],
    ];

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  Future<void> _handleMarkAsPaidFromDueSoon(Installment inst) async {
    // Find associated customer and contract for context
    final contract = _contracts.firstWhere(
      (c) => c.id == inst.contractId,
      orElse: () => Contract(
        id: inst.contractId,
        contractNumber: inst.contractId,
        unitId: inst.unitId,
        compoundId: '',
        buyerUserId: inst.buyerUserId,
        salesAgentUserId: '',
        agreedTotalPrice: 0,
        downPaymentAmount: 0,
        installmentDurationYears: 1,
        totalInstallmentsCount: 1,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        deliveryDateExpected: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final user = _users.firstWhere(
      (u) => u.uid == inst.buyerUserId,
      orElse: () => UserProfile(
        uid: inst.buyerUserId,
        email: '-',
        phoneNumber: '-',
        fullName: inst.buyerUserId,
        role: UserRole.customer,
        createdAt: DateTime.now(),
      ),
    );

    final contractInstallments =
        _installments.where((i) => i.contractId == inst.contractId).toList();

    final row = _CustomerPaymentRow(
      user: user,
      contract: contract,
      currentInstallment: inst,
      allInstallments: contractInstallments,
    );

    await _handleMarkAsPaid(row, inst);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildError(String msg, Color textMuted) {
    return Center(
      child: Text('Error: $msg', style: TextStyle(color: textMuted)),
    );
  }

  Widget _buildEmpty(String msg, Color textMuted) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAllPaidBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.green, size: 12),
          SizedBox(width: 4),
          Text(
            'ALL PAID',
            style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _filterLabel(_InstallmentFilter f) {
    switch (f) {
      case _InstallmentFilter.all: return 'All';
      case _InstallmentFilter.pending: return 'Pending';
      case _InstallmentFilter.paid: return 'Paid Off';
      case _InstallmentFilter.overdue: return '🔴 Overdue';
      case _InstallmentFilter.partial: return '🟡 Partial';
      case _InstallmentFilter.dueSoon: return '⏰ Due Soon';
    }
  }

  static String _fmt(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.accent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  final DateTime dueDate;
  final bool isDark;
  const _DueDateChip({required this.dueDate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;
    Color color;
    String label;

    if (dueDate.isBefore(now)) {
      final overdueDays = now.difference(dueDate).inDays;
      color = AppColors.error;
      label = overdueDays == 0 ? 'Today' : '${overdueDays}d overdue';
    } else if (diff == 0) {
      color = AppColors.warning;
      label = 'Due today';
    } else if (diff <= 3) {
      color = AppColors.warning;
      label = 'In $diff days';
    } else if (diff <= 7) {
      color = AppColors.warning;
      label = 'In $diff days';
    } else {
      color = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      label = '${dueDate.day} ${months[dueDate.month - 1]} ${dueDate.year}';
    }

    return Text(label, style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: color, fontSize: 11, fontWeight: FontWeight.w600));
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    this.icon,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: AppBorderRadius.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                    color: color, strokeWidth: 1.5),
              )
            else if (icon != null)
              Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;
  final bool isDark;

  const _TableRow({
    required this.cells,
    required this.isHeader,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isHeader
        ? (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted)
        : (isDark ? AppColors.textLight : AppColors.textDark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: cells.map((cell) {
          return Expanded(
            flex: cell == 'CUSTOMER' ? 3 : cell == 'ACTIONS' ? 3 : 2,
            child: Text(
              cell,
              style: TextStyle(
                color: textColor,
                fontSize: isHeader ? 10 : 13,
                fontWeight:
                    isHeader ? FontWeight.bold : FontWeight.normal,
                letterSpacing: isHeader ? 0.8 : 0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DueSoonSectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _DueSoonSectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DueSoonCard extends StatelessWidget {
  final Installment installment;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color borderColor;
  final VoidCallback? onMarkPaid;
  final bool isProcessing;

  const _DueSoonCard({
    required this.installment,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.borderColor,
    this.onMarkPaid,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = installment.dueDate.isBefore(now);
    final diff = installment.dueDate.difference(now).inDays;
    final Color urgencyColor = isOverdue
        ? Colors.redAccent
        : diff == 0
            ? Colors.orangeAccent
            : Colors.blueAccent;

    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dueDateStr =
        '${installment.dueDate.day} ${months[installment.dueDate.month - 1]} ${installment.dueDate.year}';

    final dueLabelStr = isOverdue
        ? 'Overdue by ${now.difference(installment.dueDate).inDays} day(s)'
        : diff == 0
            ? 'Due TODAY'
            : 'Due in $diff day(s)';

    final amountStr = installment.totalAmountDue
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: isDark ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: urgencyColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgency indicator
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: urgencyColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title: installment # + urgency badge (flex to avoid overflow)
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Installment #${installment.sequenceNumber}',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: urgencyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dueLabelStr,
                          style: TextStyle(
                              color: urgencyColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Amount / date / unit — wraps on narrow screens instead of overflowing
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'EGP $amountStr',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: textMuted),
                        const SizedBox(width: 4),
                        Text(dueDateStr,
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_outlined, size: 12, color: textMuted),
                        const SizedBox(width: 4),
                        Text(installment.unitId,
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                // MARK AS PAID button inside the column, right-aligned
                if (installment.status != InstallmentStatus.paid) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ActionButton(
                      label: isProcessing ? 'PROCESSING...' : 'MARK AS PAID',
                      icon: isProcessing ? null : Icons.check_circle_outline,
                      color: AppColors.success,
                      isLoading: isProcessing,
                      onTap: isProcessing ? null : onMarkPaid,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared amount-format helper ───────────────────────────────────────────────

String _fmtAmount(double v) {
  return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

// ── Mobile installment card ───────────────────────────────────────────────────
//
// Displayed when the available width is < 600 px.  Shows all data that the
// desktop table shows, but as a vertically-stacked card that never overflows.

class _InstallmentCard extends StatelessWidget {
  final _CustomerPaymentRow row;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color surfaceColor;
  final Color borderColor;
  final bool isProcessing;

  /// Null → can't pay (already paid / all paid / no installment).
  final VoidCallback? onMarkAsPaid;
  final VoidCallback? onViewHistory;
  final VoidCallback? onRowTap;

  const _InstallmentCard({
    required this.row,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.surfaceColor,
    required this.borderColor,
    required this.isProcessing,
    this.onMarkAsPaid,
    this.onViewHistory,
    this.onRowTap,
  });

  Widget _allPaidBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(25),
          borderRadius: AppBorderRadius.pill,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, color: AppColors.success, size: 12),
            SizedBox(width: 4),
            Text(
              'ALL PAID',
              style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final inst = row.displayedInstallment;
    final isAllPaid = row.allInstallments.isNotEmpty &&
        row.allInstallments.every((i) =>
            i.status == InstallmentStatus.paid ||
            i.status == InstallmentStatus.waived);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRowTap,
          borderRadius: AppBorderRadius.medium,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: AppBorderRadius.medium,
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── CUSTOMER ─────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(name: row.user.fullName),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.user.fullName,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.user.email,
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (row.clientCodeDisplay != '-') ...[
                            const SizedBox(height: 2),
                            Text(
                              'Code: ${row.clientCodeDisplay}',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 10),

                // ── UNIT / CONTRACT ───────────────────────────────────────
                Row(
                  children: [
                    Icon(Icons.home_outlined, size: 13, color: textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        row.unitDisplay,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.article_outlined, size: 13, color: textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        row.contract.contractNumber,
                        style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // ── INSTALLMENT ───────────────────────────────────────────
                if (inst != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 13, color: textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Installment #${inst.sequenceNumber}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          inst.installmentType.name.toUpperCase(),
                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 10),

                // ── AMOUNT / DUE DATE / BALANCE ───────────────────────────
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AMOUNT',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              inst != null
                                  ? 'EGP ${_fmtAmount(inst.totalAmountDue)}'
                                  : '—',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(width: 16, color: borderColor),
                      // Due Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DUE DATE',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (inst != null)
                              _DueDateChip(
                                  dueDate: inst.dueDate, isDark: isDark)
                            else
                              Text('—',
                                  style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      VerticalDivider(width: 16, color: borderColor),
                      // Balance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BALANCE',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'EGP ${_fmtAmount(row.remainingBalance)}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: row.remainingBalance > 0
                                    ? AppColors.warning
                                    : AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── STATUS + ACTIONS ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (inst != null)
                      PaymentStatusChip(status: inst.status, isDense: true)
                    else if (isAllPaid)
                      _allPaidBadge()
                    else
                      const SizedBox.shrink(),
                    const Spacer(),
                    // Show MARK AS PAID button when eligible or still processing
                    if (onMarkAsPaid != null || isProcessing) ...[
                      _ActionButton(
                        label:
                            isProcessing ? 'PROCESSING...' : 'MARK AS PAID',
                        icon:
                            isProcessing ? null : Icons.check_circle_outline,
                        color: AppColors.success,
                        isLoading: isProcessing,
                        onTap: isProcessing ? null : onMarkAsPaid,
                      ),
                      const SizedBox(width: 6),
                    ],
                    _ActionButton(
                      label: 'HISTORY',
                      icon: Icons.history,
                      color: AppColors.accent,
                      onTap: onViewHistory,
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
}
