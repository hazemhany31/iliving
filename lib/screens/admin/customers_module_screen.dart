import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/unit_model.dart';
import '../../models/contract.dart';
import '../../models/installment.dart';
import '../../models/payment.dart';
import '../../repositories/firestore/firestore_user_repository.dart';
import '../../repositories/firestore/firestore_unit_repository.dart';
import '../../repositories/firestore/firestore_contract_repository.dart';
import '../../repositories/firestore/firestore_ledger_repository.dart';
import '../../repositories/firestore/firestore_payment_repository.dart';
import '../../services/ledger_service.dart';
import '../../theme/luxury_theme.dart';
import '../../widgets/admin/shared/admin_data_table.dart';
import '../../widgets/admin/shared/admin_form_dialog.dart';
import '../../widgets/admin/shared/admin_confirm_dialog.dart';

class CustomerAggregateData {
  final UserProfile user;
  final List<Unit> units;
  final List<Contract> contracts;
  final List<Installment> installments;
  final List<Payment> payments;

  CustomerAggregateData({
    required this.user,
    required this.units,
    required this.contracts,
    required this.installments,
    required this.payments,
  });

  String get unitNumbersDisplay =>
      units.isEmpty ? 'Unassigned' : units.map((u) => u.unitNumber).join(', ');

  String get contractNumbersDisplay =>
      contracts.isEmpty ? 'No Contract' : contracts.map((c) => c.contractNumber).join(', ');

  int get installmentCount => installments.length;
  int get totalInstallmentsCount => installments.length;

  // 1. Total Contract Value
  double get totalContractValue {
    if (contracts.isNotEmpty) {
      return contracts.fold(0.0, (sum, c) => sum + c.agreedTotalPrice);
    }
    if (units.isNotEmpty) {
      return units.fold(0.0, (sum, u) => sum + u.priceEGP);
    }
    return 0.0;
  }

  // 3. Number of Installments Paid
  int get paidInstallmentsCount {
    return installments.where((i) =>
        i.status == InstallmentStatus.paid ||
        i.remainingAmount <= 0.001 ||
        (i.paidAmount >= i.totalAmountDue && i.totalAmountDue > 0)).length;
  }

  // 4. Number of Installments Remaining
  int get remainingInstallmentsCount {
    return installments.where((i) =>
        i.status != InstallmentStatus.paid &&
        i.status != InstallmentStatus.waived &&
        i.remainingAmount > 0.001).length;
  }

  // 5. Total Amount Paid
  double get totalAmountPaid {
    if (installments.isNotEmpty) {
      return installments.fold(0.0, (sum, item) => sum + item.paidAmount);
    }
    return payments.fold(0.0, (sum, item) => sum + item.amountPaid);
  }

  double get paidAmount => totalAmountPaid;

  // 6. Total Amount Remaining (Reconciled Balance)
  double get totalAmountRemaining {
    final contractVal = totalContractValue;
    final paid = totalAmountPaid;
    final calcRem = contractVal - paid;
    return calcRem.clamp(0.0, double.infinity);
  }

  double get remainingAmount => totalAmountRemaining;

  // Sum of principal amounts across scheduled installments
  double get totalInstallmentsPrincipal {
    return installments.fold(0.0, (sum, item) => sum + item.principalAmount);
  }

  // ERP Discrepancy Detection & Cross-checking
  bool get hasDiscrepancy {
    if (contracts.isNotEmpty && installments.isNotEmpty) {
      if ((totalContractValue - totalInstallmentsPrincipal).abs() > 1.0) {
        return true;
      }
    }
    if (installments.isNotEmpty && payments.isNotEmpty) {
      final paidInst = installments.fold(0.0, (s, i) => s + i.paidAmount);
      final paidPay = payments.fold(0.0, (s, p) => s + p.amountPaid);
      if ((paidInst - paidPay).abs() > 1.0) {
        return true;
      }
    }
    return false;
  }

  String get discrepancyMessage {
    if (!hasDiscrepancy) return '';
    final List<String> reasons = [];
    if (contracts.isNotEmpty && installments.isNotEmpty) {
      final diff = (totalContractValue - totalInstallmentsPrincipal).abs();
      if (diff > 1.0) {
        reasons.add(
          'Agreed Contract Total (EGP ${_formatNumber(totalContractValue)}) differs from Installments Schedule Sum (EGP ${_formatNumber(totalInstallmentsPrincipal)}). Variance: EGP ${_formatNumber(diff)}.',
        );
      }
    }
    if (installments.isNotEmpty && payments.isNotEmpty) {
      final paidInst = installments.fold(0.0, (s, i) => s + i.paidAmount);
      final paidPay = payments.fold(0.0, (s, p) => s + p.amountPaid);
      final diff = (paidInst - paidPay).abs();
      if (diff > 1.0) {
        reasons.add(
          'Paid Installments Sum (EGP ${_formatNumber(paidInst)}) differs from Payment Transactions Log (EGP ${_formatNumber(paidPay)}). Variance: EGP ${_formatNumber(diff)}.',
        );
      }
    }
    return reasons.join(' ');
  }

  // 7 & 8. Next Installment Amount and Due Date
  Installment? get nextInstallment {
    if (installments.isEmpty) return null;
    final pending = installments
        .where((i) =>
            i.status != InstallmentStatus.paid &&
            i.status != InstallmentStatus.waived &&
            i.remainingAmount > 0.001)
        .toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.first;
  }

  double get nextInstallmentAmount {
    final next = nextInstallment;
    return next != null ? next.remainingAmount : 0.0;
  }

  DateTime? get nextInstallmentDueDate {
    final next = nextInstallment;
    return next?.dueDate;
  }

  // 9. Overdue Amount
  double get overdueAmount {
    final now = DateTime.now();
    final overdueList = installments.where((i) {
      if (i.status == InstallmentStatus.paid || i.status == InstallmentStatus.waived) return false;
      return i.status == InstallmentStatus.overdue || i.dueDate.isBefore(now);
    });
    return overdueList.fold(0.0, (sum, item) => sum + item.remainingAmount);
  }

  // 10. Payment Status
  String get paymentStatusDisplay {
    if (hasDiscrepancy) {
      return 'DISCREPANCY DETECTED';
    }
    if (contracts.isEmpty && installments.isEmpty) {
      return 'NO CONTRACT';
    }
    if (overdueAmount > 0) {
      return 'OVERDUE';
    }
    if (installments.isNotEmpty && paidInstallmentsCount == installments.length) {
      return 'PAID OFF';
    }
    if (totalAmountPaid > 0) {
      return 'PARTIAL';
    }
    return 'UP TO DATE';
  }

  Color get paymentStatusColor {
    final status = paymentStatusDisplay;
    switch (status) {
      case 'DISCREPANCY DETECTED':
        return Colors.purpleAccent;
      case 'OVERDUE':
        return Colors.redAccent;
      case 'PAID OFF':
        return Colors.green;
      case 'PARTIAL':
        return Colors.orangeAccent;
      case 'UP TO DATE':
        return AppColors.accent;
      case 'NO CONTRACT':
      default:
        return Colors.grey;
    }
  }

  static String _formatNumber(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

class CustomersModuleScreen extends StatefulWidget {
  const CustomersModuleScreen({super.key});

  @override
  State<CustomersModuleScreen> createState() => _CustomersModuleScreenState();
}

class _CustomersModuleScreenState extends State<CustomersModuleScreen> {
  final FirestoreUserRepository _userRepo = FirestoreUserRepository();
  final FirestoreUnitRepository _unitRepo = FirestoreUnitRepository();
  final FirestoreContractRepository _contractRepo = FirestoreContractRepository();
  final FirestoreLedgerRepository _ledgerRepo = FirestoreLedgerRepository();
  final FirestorePaymentRepository _paymentRepo = FirestorePaymentRepository();

  UserRole? _selectedRole;
  KycStatus? _selectedKyc;
  String? _selectedPaymentStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<UserProfile>>(
      stream: _userRepo.streamAllUsers(),
      builder: (context, userSnap) {
        return StreamBuilder<List<Unit>>(
          stream: _unitRepo.streamAllUnits(),
          builder: (context, unitSnap) {
            return StreamBuilder<List<Contract>>(
              stream: _contractRepo.streamAllContracts(),
              builder: (context, contractSnap) {
                return StreamBuilder<List<Installment>>(
                  stream: _ledgerRepo.streamAllInstallments(),
                  builder: (context, instSnap) {
                    return StreamBuilder<List<Payment>>(
                      stream: _paymentRepo.streamAllPayments(),
                      builder: (context, paySnap) {

                        final isLoading =
                            userSnap.connectionState == ConnectionState.waiting &&
                            !userSnap.hasData;

                        final users = userSnap.data ?? [];
                        final allUnits = unitSnap.data ?? [];
                        final allContracts = contractSnap.data ?? [];
                        final allInstallments = instSnap.data ?? [];
                        final allPayments = paySnap.data ?? [];

                        final List<CustomerAggregateData> aggregatedList = users.map((u) {
                          final userUnits = allUnits.where((unit) {
                            return unit.currentOwnerId == u.uid ||
                                (u.clientCode != null && u.clientCode!.isNotEmpty && unit.currentOwnerId == u.clientCode);
                          }).toList();

                          final userContracts = allContracts.where((c) {
                            return c.buyerUserId == u.uid ||
                                (u.clientCode != null && u.clientCode!.isNotEmpty && (c.buyerUserId == u.clientCode || c.clientCode == u.clientCode));
                          }).toList();

                          final userContractIds = userContracts.map((c) => c.id).toSet();

                          final userInstallments = allInstallments.where((inst) {
                            return inst.buyerUserId == u.uid ||
                                (u.clientCode != null && u.clientCode!.isNotEmpty && inst.buyerUserId == u.clientCode) ||
                                userContractIds.contains(inst.contractId);
                          }).toList();

                          final userPayments = allPayments.where((p) {
                            return p.payerUserId == u.uid ||
                                (u.clientCode != null && u.clientCode!.isNotEmpty && p.payerUserId == u.clientCode);
                          }).toList();

                          return CustomerAggregateData(
                            user: u,
                            units: userUnits,
                            contracts: userContracts,
                            installments: userInstallments,
                            payments: userPayments,
                          );
                        }).toList();

                        final filteredAggregates = aggregatedList.where((agg) {
                          final u = agg.user;
                          if (_selectedRole != null && u.role != _selectedRole) return false;
                          if (_selectedKyc != null && u.kycStatus != _selectedKyc) return false;
                          if (_selectedPaymentStatus != null &&
                              agg.paymentStatusDisplay != _selectedPaymentStatus) {
                            return false;
                          }

                          if (_searchQuery.isNotEmpty) {
                            final q = _searchQuery.toLowerCase();
                            return u.fullName.toLowerCase().contains(q) ||
                                u.email.toLowerCase().contains(q) ||
                                u.phoneNumber.contains(q) ||
                                (u.clientCode != null && u.clientCode!.toLowerCase().contains(q)) ||
                                agg.unitNumbersDisplay.toLowerCase().contains(q) ||
                                agg.contractNumbersDisplay.toLowerCase().contains(q);
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CUSTOMERS & OWNERS MANAGEMENT',
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            color: isDark ? AppColors.textLight : AppColors.textDark,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Live Master Single Source of Truth (${users.length} Customers Registered)',
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                                            fontSize: 11.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    height: 42,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                                      ),
                                      icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                                      label: const Text(
                                        'Create Customer',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onPressed: () => _showUserFormDialog(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Filter Row
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  // Role Filter
                                  Container(
                                    width: 160,
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                      borderRadius: AppBorderRadius.pill,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<UserRole?>(
                                        value: _selectedRole,
                                        isExpanded: true,
                                        hint: Text('All Roles', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted, fontSize: 12)),
                                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                        items: [
                                          DropdownMenuItem<UserRole?>(
                                            value: null,
                                            child: Text('All Roles', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLight : AppColors.textDark, fontSize: 12)),
                                          ),
                                          ...UserRole.values.map((r) {
                                            return DropdownMenuItem<UserRole?>(
                                              value: r,
                                              child: Text(r.nameString, style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLight : AppColors.textDark, fontSize: 12)),
                                            );
                                          }),
                                        ],
                                        onChanged: (val) => setState(() => _selectedRole = val),
                                      ),
                                    ),
                                  ),

                                  // KYC Filter
                                  Container(
                                    width: 160,
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                      borderRadius: AppBorderRadius.pill,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<KycStatus?>(
                                        value: _selectedKyc,
                                        isExpanded: true,
                                        hint: Text('All KYC Statuses', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted, fontSize: 12)),
                                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                        items: [
                                          DropdownMenuItem<KycStatus?>(
                                            value: null,
                                            child: Text('All KYC Statuses', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLight : AppColors.textDark, fontSize: 12)),
                                          ),
                                          ...KycStatus.values.map((k) {
                                            return DropdownMenuItem<KycStatus?>(
                                              value: k,
                                              child: Text(k.name.toUpperCase(), style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLight : AppColors.textDark, fontSize: 12)),
                                            );
                                          }),
                                        ],
                                        onChanged: (val) => setState(() => _selectedKyc = val),
                                      ),
                                    ),
                                  ),

                                  // Payment Status Filter
                                  Container(
                                    width: 180,
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                      borderRadius: AppBorderRadius.pill,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String?>(
                                        value: _selectedPaymentStatus,
                                        isExpanded: true,
                                        hint: Text('All Payment Statuses', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted, fontSize: 12)),
                                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                        items: [
                                          DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('All Payment Statuses', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLight : AppColors.textDark, fontSize: 12)),
                                          ),
                                          ...['UP TO DATE', 'OVERDUE', 'PAID OFF', 'PARTIAL', 'NO CONTRACT'].map((st) {
                                            return DropdownMenuItem<String?>(
                                              value: st,
                                              child: Text(st, style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLight : AppColors.textDark, fontSize: 12)),
                                            );
                                          }),
                                        ],
                                        onChanged: (val) => setState(() => _selectedPaymentStatus = val),
                                      ),
                                    ),
                                  ),

                                  // Search Field
                                  Container(
                                    width: 260,
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                      borderRadius: AppBorderRadius.pill,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.search_rounded, color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            onChanged: (val) => setState(() => _searchQuery = val),
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              color: isDark ? AppColors.textLight : AppColors.textDark,
                                              fontSize: 12,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Search customer, unit, contract...',
                                              hintStyle: TextStyle(
                                                fontFamily: AppTextStyles.fontFamily,
                                                color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                                                fontSize: 12,
                                              ),
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
                                child: AdminDataTable<CustomerAggregateData>(
                                  isLoading: isLoading,
                                  items: filteredAggregates,
                                  emptyTitle: 'No Customers Found',
                                  emptyMessage: _searchQuery.isEmpty
                                      ? 'No user records exist in Firestore. Click "+ Create Customer" to add one.'
                                      : 'No users match your query filter parameters.',
                                  columns: [
                                    AdminTableColumn<CustomerAggregateData>(
                                      title: 'Customer Name & Email',
                                      cellBuilder: (agg) => Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            agg.user.fullName,
                                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                          ),
                                          Text(
                                            agg.user.email,
                                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AdminTableColumn<CustomerAggregateData>(
                                      title: 'Client Code',
                                      cellBuilder: (agg) => Text(
                                        agg.user.clientCode ?? agg.user.uid,
                                        style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, color: AppColors.accent),
                                      ),
                                    ),
                                    AdminTableColumn<CustomerAggregateData>(
                                      title: 'Assigned Unit',
                                      cellBuilder: (agg) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: agg.units.isEmpty ? Colors.grey.withAlpha(25) : AppColors.info.withAlpha(25),
                                          borderRadius: AppBorderRadius.pill,
                                        ),
                                        child: Text(
                                          agg.unitNumbersDisplay,
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            color: agg.units.isEmpty ? Colors.grey : AppColors.info,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    AdminTableColumn<CustomerAggregateData>(
                                      title: 'Contract',
                                      cellBuilder: (agg) => Text(
                                        agg.contractNumbersDisplay,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: isDark ? AppColors.textLight : AppColors.textDark,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    AdminTableColumn<CustomerAggregateData>(
                                      title: 'Installments',
                                      cellBuilder: (agg) => Text(
                                        '${agg.installmentCount} Schedule',
                                        style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted, fontSize: 11),
                                      ),
                                    ),
                                    AdminTableColumn<CustomerAggregateData>(
                                      title: 'Paid Amount',
                                      cellBuilder: (agg) => Text(
                                        'EGP ${_formatNumber(agg.paidAmount)}',
                                        style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                    AdminTableColumn<CustomerAggregateData>(
                                      title: 'Remaining Amount',
                                      cellBuilder: (agg) => Text(
                                        'EGP ${_formatNumber(agg.remainingAmount)}',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: agg.remainingAmount > 0 ? AppColors.warning : AppColors.success,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    AdminTableColumn<CustomerAggregateData>(
                                      title: 'Payment Status',
                                      cellBuilder: (agg) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: agg.paymentStatusColor.withAlpha(25),
                                          borderRadius: AppBorderRadius.pill,
                                        ),
                                        child: Text(
                                          agg.paymentStatusDisplay,
                                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: agg.paymentStatusColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    AdminTableColumn<CustomerAggregateData>(
                                      title: 'Manage Actions',
                                      cellBuilder: (agg) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accent, size: 20),
                                            tooltip: 'View Financial Summary & ERP Reconciliation',
                                            onPressed: () => _showCustomerFinancialSummary(context, agg),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, color: AppColors.accent, size: 20),
                                            tooltip: 'Admin Operations Menu',
                                            onSelected: (action) {
                                              switch (action) {
                                                case 'view_financials':
                                                  _showCustomerFinancialSummary(context, agg);
                                                  break;
                                                case 'edit_profile':
                                                  _showUserFormDialog(context, user: agg.user);
                                                  break;
                                                case 'assign_unit':
                                                  _showAssignUnitDialog(context, agg, allUnits);
                                                  break;
                                                case 'manage_contract':
                                                  _showContractFormDialog(context, agg, allUnits);
                                                  break;
                                                case 'manage_installments':
                                                  _showManageInstallmentsDialog(context, agg);
                                                  break;
                                                case 'mark_paid':
                                                  _showMarkPaidDialog(context, agg);
                                                  break;
                                                case 'change_unit_price':
                                                  _showChangeUnitPriceDialog(context, agg);
                                                  break;
                                                case 'delete_user':
                                                  _confirmDeleteUser(context, agg.user);
                                                  break;
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'view_financials',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.account_balance_wallet, size: 16, color: AppColors.accent),
                                                    SizedBox(width: 8),
                                                    Text('View Financial Summary (SSOT)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'edit_profile',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 16, color: AppColors.info),
                                                    SizedBox(width: 8),
                                                    Text('Edit Customer Info', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'assign_unit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.home_work_outlined, size: 16, color: AppColors.info),
                                                    SizedBox(width: 8),
                                                    Text('Assign / Unassign Unit', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'manage_contract',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.description_outlined, size: 16, color: AppColors.accent),
                                                    SizedBox(width: 8),
                                                    Text('Create / Edit Contract', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'manage_installments',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.calendar_month_outlined, size: 16, color: Colors.purpleAccent),
                                                    SizedBox(width: 8),
                                                    Text('Manage Installments Schedule', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'mark_paid',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.receipt_long, size: 16, color: Colors.green),
                                                    SizedBox(width: 8),
                                                    Text('Mark Paid & Upload Receipt', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'change_unit_price',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.price_change, size: 16, color: Colors.orangeAccent),
                                                    SizedBox(width: 8),
                                                    Text('Change Unit Price', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete_user',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_forever, size: 16, color: Colors.redAccent),
                                                    SizedBox(width: 8),
                                                    Text('Delete Customer Record', style: TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
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

  void _showUserFormDialog(BuildContext context, {UserProfile? user}) {
    final isEditing = user != null;
    final uidController = TextEditingController(text: user?.uid ?? 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '+201000000000');
    final clientCodeController = TextEditingController(text: user?.clientCode ?? 'CLI-VIP-101');
    final nationalIdController = TextEditingController(text: user?.nationalIdOrPassport ?? '29901010101010');
    UserRole role = user?.role ?? UserRole.customer;
    KycStatus kycStatus = user?.kycStatus ?? KycStatus.verified;

    AdminFormDialog.show(
      context: context,
      title: isEditing ? 'Edit Customer Info' : 'Create New Customer Account',
      subtitle: isEditing ? 'Update customer profile in Firestore Master SSOT' : 'Register new customer profile in Firestore',
      icon: isEditing ? Icons.manage_accounts : Icons.person_add_alt_1,
      body: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEditing)
              TextField(
                controller: uidController,
                decoration: const InputDecoration(labelText: 'User ID (UID)', hintText: 'e.g. USR-001'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. Ahmed Ali'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email Address', hintText: 'user@iliving.com'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+20100...'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: clientCodeController,
                    decoration: const InputDecoration(labelText: 'Client Code', hintText: 'CLI-101'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: nationalIdController,
                    decoration: const InputDecoration(labelText: 'National ID / Passport'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<UserRole>(
                    isExpanded: true,
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: UserRole.values.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r.nameString, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => role = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<KycStatus>(
                    isExpanded: true,
                    initialValue: kycStatus,
                    decoration: const InputDecoration(labelText: 'KYC Status'),
                    items: KycStatus.values.map((k) {
                      return DropdownMenuItem(value: k, child: Text(k.name.toUpperCase(), overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => kycStatus = val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      onSubmit: () async {
        if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
          throw Exception('Full Name and Email are required');
        }

        final u = UserProfile(
          uid: uidController.text.trim(),
          email: emailController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          fullName: nameController.text.trim(),
          nationalIdOrPassport: nationalIdController.text.trim(),
          clientCode: clientCodeController.text.trim(),
          role: role,
          kycStatus: kycStatus,
          createdAt: user?.createdAt ?? DateTime.now(),
        );

        if (isEditing) {
          await _userRepo.updateUser(u);
        } else {
          await _userRepo.createUser(u);
        }
      },
    );
  }

  void _showAssignUnitDialog(BuildContext context, CustomerAggregateData agg, List<Unit> allUnits) {
    Unit? selectedUnit;

    AdminFormDialog.show(
      context: context,
      title: 'Assign Unit to Customer',
      subtitle: 'Link property unit to customer "${agg.user.fullName}" (${agg.user.clientCode ?? agg.user.uid})',
      icon: Icons.home_work_outlined,
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currently Assigned Units: ${agg.unitNumbersDisplay}',
                style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Unit>(
                decoration: const InputDecoration(labelText: 'Select Unit from Inventory'),
                items: allUnits.map((unit) {
                  final isAssignedToThisUser = unit.currentOwnerId == agg.user.uid || unit.currentOwnerId == agg.user.clientCode;
                  final ownerLabel = isAssignedToThisUser
                      ? ' (Currently Assigned)'
                      : (unit.currentOwnerId != null && unit.currentOwnerId!.isNotEmpty ? ' (Owned by ${unit.currentOwnerId})' : ' (Available)');
                  return DropdownMenuItem(
                    value: unit,
                    child: Text('${unit.unitNumber} - ${unit.compoundId} | EGP ${_formatNumber(unit.priceEGP)}$ownerLabel'),
                  );
                }).toList(),
                onChanged: (val) => setModalState(() => selectedUnit = val),
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        if (selectedUnit == null) {
          throw Exception('Please select a unit to assign');
        }
        await _unitRepo.updateUnitStatus(
          selectedUnit!.id,
          UnitStatus.contracted,
          ownerId: agg.user.clientCode ?? agg.user.uid,
        );
      },
    );
  }

  void _showContractFormDialog(BuildContext context, CustomerAggregateData agg, List<Unit> allUnits) {
    final existingContract = agg.contracts.isNotEmpty ? agg.contracts.first : null;
    final initialPrice = existingContract?.agreedTotalPrice ?? (agg.units.isNotEmpty ? agg.units.first.priceEGP : 1500000.0);
    final contractNoController = TextEditingController(text: existingContract?.contractNumber ?? 'CNT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}');
    final priceController = TextEditingController(text: initialPrice.toStringAsFixed(0));
    final downPaymentController = TextEditingController(text: (existingContract?.downPaymentAmount ?? (initialPrice * 0.10)).toStringAsFixed(0));
    final maintenanceDepositController = TextEditingController(
      text: (existingContract != null && existingContract.maintenanceDepositAmount > 0
              ? existingContract.maintenanceDepositAmount
              : (initialPrice * 0.08))
          .toStringAsFixed(0),
    );
    final pdfUrlController = TextEditingController(text: existingContract?.pdfContractUrl ?? 'https://gateway.iliving.com.eg/contracts/contract_spa.pdf');
    int installmentsCount = existingContract?.totalInstallmentsCount ?? 4;
    SignatureStatus signatureStatus = existingContract?.signatureStatus ?? SignatureStatus.fullyExecuted;
    Unit? targetUnit = agg.units.isNotEmpty ? agg.units.first : (allUnits.isNotEmpty ? allUnits.first : null);
    bool autoGenerateSchedule = true;

    AdminFormDialog.show(
      context: context,
      title: existingContract != null ? 'Edit Contract' : 'Create Customer Contract',
      subtitle: 'Bind agreement & Maintenance Deposit for "${agg.user.fullName}"',
      icon: Icons.description_outlined,
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contractNoController,
                decoration: const InputDecoration(labelText: 'Contract Number', hintText: 'e.g. CNT-801'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Unit>(
                initialValue: targetUnit,
                decoration: const InputDecoration(labelText: 'Target Unit'),
                items: allUnits.map((u) {
                  return DropdownMenuItem(value: u, child: Text('${u.unitNumber} (${u.compoundId})'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() {
                      targetUnit = val;
                      priceController.text = val.priceEGP.toStringAsFixed(0);
                      downPaymentController.text = (val.priceEGP * 0.10).toStringAsFixed(0);
                      maintenanceDepositController.text = (val.priceEGP * 0.08).toStringAsFixed(0);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Agreed Total Price (EGP)'),
                      onChanged: (val) {
                        final p = double.tryParse(val) ?? 0;
                        if (p > 0) {
                          setModalState(() {
                            downPaymentController.text = (p * 0.10).toStringAsFixed(0);
                            maintenanceDepositController.text = (p * 0.08).toStringAsFixed(0);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: downPaymentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Down Payment (EGP)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: maintenanceDepositController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maintenance Deposit / وديعة الصيانة (EGP)',
                        hintText: 'e.g. 120000 (8%)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: installmentsCount,
                      decoration: const InputDecoration(labelText: 'Installments Count'),
                      items: [1, 2, 4, 8, 12, 16, 20].map((n) {
                        return DropdownMenuItem(value: n, child: Text('$n Installments'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => installmentsCount = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<SignatureStatus>(
                      initialValue: signatureStatus,
                      decoration: const InputDecoration(labelText: 'Signature Status'),
                      items: SignatureStatus.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => signatureStatus = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pdfUrlController,
                decoration: const InputDecoration(labelText: 'PDF Document Link / Storage URL'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: autoGenerateSchedule,
                title: const Text(
                  'Auto-generate Ledger & Maintenance Deposit (وديعة الصيانة)',
                  style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
                subtitle: const Text(
                  'Creates schedule including Maintenance Deposit in client view',
                  style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 10),
                ),
                activeColor: AppColors.accent,
                onChanged: (val) {
                  if (val != null) setModalState(() => autoGenerateSchedule = val);
                },
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        if (targetUnit == null) throw Exception('Target Unit is required');
        final contractId = existingContract?.id ?? 'cnt_${DateTime.now().millisecondsSinceEpoch}';
        final buyerId = agg.user.clientCode ?? agg.user.uid;
        final totalPrice = double.tryParse(priceController.text.trim()) ?? 1500000.0;
        final downPayment = double.tryParse(downPaymentController.text.trim()) ?? 150000.0;
        final maintDeposit = double.tryParse(maintenanceDepositController.text.trim()) ?? (totalPrice * 0.08);

        final contract = Contract(
          id: contractId,
          contractNumber: contractNoController.text.trim(),
          unitId: targetUnit!.id,
          compoundId: targetUnit!.compoundId,
          buyerUserId: buyerId,
          salesAgentUserId: 'sales_admin',
          agreedTotalPrice: totalPrice,
          downPaymentAmount: downPayment,
          maintenanceDepositAmount: maintDeposit,
          clientCode: buyerId,
          installmentDurationYears: (installmentsCount / 4).ceil(),
          totalInstallmentsCount: installmentsCount,
          startDate: existingContract?.startDate ?? DateTime.now(),
          endDate: existingContract?.endDate ?? DateTime.now().add(const Duration(days: 365 * 3)),
          deliveryDateExpected: existingContract?.deliveryDateExpected ?? DateTime.now().add(const Duration(days: 365 * 2)),
          pdfContractUrl: pdfUrlController.text.trim(),
          signatureStatus: signatureStatus,
          createdAt: existingContract?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (existingContract != null) {
          await _contractRepo.updateContract(contract);
        } else {
          await _contractRepo.createContract(contract);
        }

        await _unitRepo.updateUnitStatus(targetUnit!.id, UnitStatus.contracted, ownerId: buyerId);

        // Auto-generate installments including Maintenance Deposit if requested
        if (autoGenerateSchedule) {
          final ledgerService = LedgerService(ledgerRepository: _ledgerRepo);
          final schedule = ledgerService.generateInstallmentScheduleWithAmount(
            contractId: contractId,
            unitId: targetUnit!.id,
            buyerUserId: buyerId,
            totalUnitValue: totalPrice,
            downPayment: downPayment,
            maintenanceDepositAmount: maintDeposit,
            totalInstallmentsCount: installmentsCount,
            startDate: contract.startDate,
          );
          for (final inst in schedule) {
            await _ledgerRepo.createInstallment(inst);
          }
        }
      },
    );
  }

  void _showManageInstallmentsDialog(BuildContext context, CustomerAggregateData agg) {
    if (agg.contracts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer must have an active Contract before managing installments.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final contract = agg.contracts.first;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.large),
          title: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: AppColors.accent),
              const SizedBox(width: 10),
              Text(
                'Installment Schedule (${agg.user.fullName})',
                style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 450,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Scheduled: ${agg.installments.length}',
                      style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.accent, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                          ),
                          icon: const Icon(Icons.shield_outlined, size: 14),
                          label: const Text(
                            '+ وديعة الصيانة (Deposit)',
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            _showAddUpdateMaintenanceDepositDialog(context, agg, contract);
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Installment', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            _showCreateInstallmentSubDialog(context, agg, contract);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: agg.installments.isEmpty
                      ? const Center(child: Text('No installments generated for this customer.'))
                      : ListView.builder(
                          itemCount: agg.installments.length,
                          itemBuilder: (context, idx) {
                            final inst = agg.installments[idx];
                            final isMnt = inst.installmentType == InstallmentType.maintenanceFund;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMnt
                                    ? AppColors.accent.withAlpha(25)
                                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                                borderRadius: AppBorderRadius.medium,
                                border: Border.all(
                                  color: isMnt ? AppColors.accent : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  width: isMnt ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (isMnt) ...[
                                    const Icon(Icons.shield_outlined, color: AppColors.accent, size: 14),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isMnt
                                              ? 'وديعة الصيانة (MAINTENANCE DEPOSIT)'
                                              : 'Installment #${inst.sequenceNumber} - ${inst.installmentType.name.toUpperCase()}',
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isMnt ? AppColors.accent : (isDark ? AppColors.textLight : AppColors.textDark),
                                          ),
                                        ),
                                        Text(
                                          'Due: ${inst.dueDate.toIso8601String().split("T").first} | Paid: EGP ${_formatNumber(inst.paidAmount)} / EGP ${_formatNumber(inst.principalAmount)}',
                                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (inst.isPaid ? AppColors.success : AppColors.warning).withAlpha(25),
                                      borderRadius: AppBorderRadius.pill,
                                    ),
                                    child: Text(
                                      inst.status.nameString,
                                      style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: inst.isPaid ? AppColors.success : AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_calendar, color: AppColors.info, size: 18),
                                    tooltip: 'Edit Due Date',
                                    onPressed: () {
                                      _showEditInstallmentDateSubDialog(context, inst);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                    tooltip: 'Delete Installment',
                                    onPressed: () async {
                                      await _ledgerRepo.deleteInstallment(inst.contractId, inst.id);
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddUpdateMaintenanceDepositDialog(BuildContext context, CustomerAggregateData agg, Contract contract) {
    Installment? existingMnt;
    for (final i in agg.installments) {
      if (i.installmentType == InstallmentType.maintenanceFund) {
        existingMnt = i;
        break;
      }
    }

    final double initialAmount = existingMnt?.principalAmount ??
        (contract.maintenanceDepositAmount > 0
            ? contract.maintenanceDepositAmount
            : contract.agreedTotalPrice * 0.08);

    final amountController = TextEditingController(text: initialAmount.toStringAsFixed(0));
    DateTime dueDate = existingMnt?.dueDate ?? contract.deliveryDateExpected;

    AdminFormDialog.show(
      context: context,
      title: 'وديعة الصيانة (Maintenance Deposit)',
      subtitle: 'تحديد وتنزل وديعة الصيانة لـ ${agg.user.fullName} في حساب العميل',
      icon: Icons.shield_outlined,
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'مبلغ وديعة الصيانة (EGP)',
                  hintText: 'مثال: 120000 (8% من إجمالي الوحدة)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('تاريخ الاستحقاق: ${dueDate.toIso8601String().split("T").first}'),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('تغيير التاريخ'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) setModalState(() => dueDate = picked);
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        final amount = double.tryParse(amountController.text.trim()) ?? initialAmount;

        // Update contract maintenance deposit
        final updatedContract = contract.copyWith(maintenanceDepositAmount: amount);
        await _contractRepo.updateContract(updatedContract);

        // Create or update installment in Firestore
        final instId = existingMnt?.id ?? 'INS-${contract.id}-MNT';
        final seq = existingMnt?.sequenceNumber ?? (agg.installments.length + 1);

        final mntInst = Installment(
          id: instId,
          contractId: contract.id,
          unitId: contract.unitId,
          buyerUserId: agg.user.clientCode ?? agg.user.uid,
          sequenceNumber: seq,
          installmentType: InstallmentType.maintenanceFund,
          dueDate: dueDate,
          gracePeriodEndDate: dueDate.add(const Duration(days: 14)),
          principalAmount: amount,
          currency: 'EGP',
          status: existingMnt?.status ?? InstallmentStatus.unpaid,
        );

        if (existingMnt != null) {
          await _ledgerRepo.updateInstallment(mntInst);
        } else {
          await _ledgerRepo.createInstallment(mntInst);
        }

        if (context.mounted) {
          Navigator.pop(context); // Close parent manage installments dialog to refresh
        }
      },
    );
  }

  void _showCreateInstallmentSubDialog(BuildContext context, CustomerAggregateData agg, Contract contract) {
    final amountController = TextEditingController(text: '125000');
    DateTime dueDate = DateTime.now().add(const Duration(days: 90));
    InstallmentType type = InstallmentType.regularQuarterly;

    AdminFormDialog.show(
      context: context,
      title: 'Create New Installment',
      subtitle: 'Add custom payment term for contract ${contract.contractNumber}',
      icon: Icons.add_card,
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Principal Amount (EGP)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<InstallmentType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Installment Type'),
                items: InstallmentType.values.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => type = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Due Date: ${dueDate.toIso8601String().split("T").first}'),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Pick Date'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) setModalState(() => dueDate = picked);
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        final amount = double.tryParse(amountController.text.trim()) ?? 125000.0;
        final seq = agg.installments.length + 1;
        final instId = 'inst_${DateTime.now().millisecondsSinceEpoch}';

        final inst = Installment(
          id: instId,
          contractId: contract.id,
          unitId: contract.unitId,
          buyerUserId: agg.user.clientCode ?? agg.user.uid,
          sequenceNumber: seq,
          installmentType: type,
          dueDate: dueDate,
          gracePeriodEndDate: dueDate.add(const Duration(days: 14)),
          principalAmount: amount,
          currency: 'EGP',
          status: InstallmentStatus.unpaid,
        );

        await _ledgerRepo.createInstallment(inst);
      },
    );
  }

  void _showEditInstallmentDateSubDialog(BuildContext context, Installment inst) {
    DateTime selectedDate = inst.dueDate;

    AdminFormDialog.show(
      context: context,
      title: 'Edit Installment Due Date',
      subtitle: 'Modify schedule date for installment #${inst.sequenceNumber}',
      icon: Icons.edit_calendar,
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Due Date: ${inst.dueDate.toIso8601String().split("T").first}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('New Due Date: ${selectedDate.toIso8601String().split("T").first}'),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Change Date'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        final updatedInst = inst.copyWith(
          dueDate: selectedDate,
          gracePeriodEndDate: selectedDate.add(const Duration(days: 14)),
        );
        await _ledgerRepo.updateInstallment(updatedInst);
      },
    );
  }

  void _showMarkPaidDialog(BuildContext context, CustomerAggregateData agg) {
    final unpaidList = agg.installments.where((i) => i.status != InstallmentStatus.paid).toList();
    if (unpaidList.isEmpty && agg.installments.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All installments for this customer are already paid!'), backgroundColor: Colors.green),
      );
      return;
    }

    Installment? selectedInst = unpaidList.isNotEmpty ? unpaidList.first : null;
    final receiptNumberController = TextEditingController(text: 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}');
    final receiptUrlController = TextEditingController(text: 'https://gateway.iliving.com.eg/receipts/rec_${DateTime.now().millisecondsSinceEpoch}.pdf');

    AdminFormDialog.show(
      context: context,
      title: 'Mark Installment Paid & Upload Receipt',
      subtitle: 'Record payment for "${agg.user.fullName}" in Master SSOT',
      icon: Icons.receipt_long,
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unpaidList.isNotEmpty)
                DropdownButtonFormField<Installment>(
                  initialValue: selectedInst,
                  decoration: const InputDecoration(labelText: 'Select Unpaid Installment'),
                  items: unpaidList.map((inst) {
                    return DropdownMenuItem(
                      value: inst,
                      child: Text('Inst #${inst.sequenceNumber} - EGP ${_formatNumber(inst.remainingAmount)} (Due ${inst.dueDate.toIso8601String().split("T").first})'),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedInst = val),
                )
              else
                const Text('No existing unpaid installments found. Marking new payment settlement.'),
              const SizedBox(height: 12),
              TextField(
                controller: receiptNumberController,
                decoration: const InputDecoration(labelText: 'Receipt Reference Number', hintText: 'e.g. REC-99210'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: receiptUrlController,
                decoration: const InputDecoration(labelText: 'Uploaded Receipt PDF / File Link', hintText: 'https://...'),
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        final buyerId = agg.user.clientCode ?? agg.user.uid;
        final contractId = selectedInst?.contractId ?? (agg.contracts.isNotEmpty ? agg.contracts.first.id : 'cnt_default');
        final unitId = selectedInst?.unitId ?? (agg.units.isNotEmpty ? agg.units.first.id : 'unit_default');
        final instId = selectedInst?.id ?? 'inst_default';
        final amountPaid = selectedInst?.totalAmountDue ?? 150000.0;

        if (selectedInst != null) {
          final updatedInst = selectedInst!.copyWith(
            status: InstallmentStatus.paid,
            paidAmount: selectedInst!.totalAmountDue,
            paidAt: DateTime.now(),
            receiptNumber: receiptNumberController.text.trim(),
          );
          await _ledgerRepo.updateInstallment(updatedInst);
        }

        final payment = Payment(
          id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
          transactionReference: receiptNumberController.text.trim(),
          contractId: contractId,
          installmentId: instId,
          unitId: unitId,
          payerUserId: buyerId,
          paymentMethod: PaymentMethod.bankWire,
          amountPaid: amountPaid,
          currency: 'EGP',
          receiptPdfUrl: receiptUrlController.text.trim(),
          verifiedByUserId: 'admin_user',
          status: PaymentStatus.success,
          createdAt: DateTime.now(),
        );

        await _paymentRepo.logPayment(payment);
      },
    );
  }

  void _showChangeUnitPriceDialog(BuildContext context, CustomerAggregateData agg) {
    if (agg.units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer has no assigned units to update price for.'), backgroundColor: Colors.orange),
      );
      return;
    }

    Unit selectedUnit = agg.units.first;
    final pricePerSqmController = TextEditingController(text: selectedUnit.pricePerSqFt.toStringAsFixed(0));
    final reasonController = TextEditingController(text: 'Admin price adjustment for customer ${agg.user.fullName}');

    AdminFormDialog.show(
      context: context,
      title: 'Change Unit Price',
      subtitle: 'Update valuation for unit ${selectedUnit.unitNumber}',
      icon: Icons.price_change,
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Unit: ${selectedUnit.unitNumber} (${selectedUnit.compoundId})', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Current Total Valuation: EGP ${_formatNumber(selectedUnit.priceEGP)}'),
              const SizedBox(height: 12),
              TextField(
                controller: pricePerSqmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'New Price per SqFt (EGP)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason for Price Change'),
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        final newPriceSqm = double.tryParse(pricePerSqmController.text.trim()) ?? selectedUnit.pricePerSqFt;
        await _unitRepo.updateUnitPrice(
          selectedUnit.id,
          newPriceSqm,
          reasonController.text.trim(),
          'admin_user',
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, UserProfile user) {
    AdminConfirmDialog.show(
      context: context,
      title: 'Delete Customer Profile',
      message: 'Are you sure you want to permanently delete profile for "${user.fullName}" (${user.email})? This action cannot be undone.',
      confirmLabel: 'Delete Profile',
      isDanger: true,
      onConfirm: () async {
        await _userRepo.deleteUser(user.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Customer profile "${user.fullName}" deleted successfully.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  void _showCustomerFinancialSummary(BuildContext context, CustomerAggregateData agg) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final Color textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    final dueDateStr = agg.nextInstallmentDueDate != null
        ? '${agg.nextInstallmentDueDate!.day.toString().padLeft(2, '0')}/${agg.nextInstallmentDueDate!.month.toString().padLeft(2, '0')}/${agg.nextInstallmentDueDate!.year}'
        : 'N/A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: isDark ? AppShadows.dark : AppShadows.elevated,
              ),
              child: Column(
                children: [
                  // Handle
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
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              agg.user.fullName.isNotEmpty ? agg.user.fullName[0].toUpperCase() : '?',
                              style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agg.user.fullName,
                                style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Client Code: ${agg.user.clientCode ?? agg.user.uid}  •  Units: ${agg.unitNumbersDisplay}',
                                style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: agg.paymentStatusColor.withAlpha(25),
                            borderRadius: AppBorderRadius.pill,
                          ),
                          child: Text(
                            agg.paymentStatusDisplay,
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: agg.paymentStatusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: border),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Discrepancy warning banner if ERP cross-check failed
                        if (agg.hasDiscrepancy)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.purple.withAlpha(25),
                              borderRadius: AppBorderRadius.medium,
                              border: Border.all(color: Colors.purpleAccent, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.purpleAccent, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ERP RECONCILIATION DISCREPANCY FLAGGED',
                                        style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        agg.discrepancyMessage,
                                        style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? Colors.white70 : Colors.black87, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Required Financial Summary Section
                        Text(
                          'FINANCIAL SUMMARY (REAL FIRESTORE SSOT)',
                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.accent : AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),

                        // 7 Financial Cards Grid
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildSummaryCard('TOTAL CONTRACT', 'EGP ${_formatNumber(agg.totalContractValue)}', AppColors.accent, isDark),
                            _buildSummaryCard('TOTAL PAID', 'EGP ${_formatNumber(agg.totalAmountPaid)}', AppColors.success, isDark),
                            _buildSummaryCard('REMAINING', 'EGP ${_formatNumber(agg.totalAmountRemaining)}', agg.totalAmountRemaining > 0 ? AppColors.warning : AppColors.success, isDark),
                            _buildSummaryCard('NEXT INSTALLMENT', 'EGP ${_formatNumber(agg.nextInstallmentAmount)}', AppColors.info, isDark),
                            _buildSummaryCard('DUE DATE', dueDateStr, AppColors.accent, isDark),
                            _buildSummaryCard('PAID INSTALLMENTS', '${agg.paidInstallmentsCount} / ${agg.totalInstallmentsCount}', AppColors.success, isDark),
                            _buildSummaryCard('OVERDUE', 'EGP ${_formatNumber(agg.overdueAmount)}', agg.overdueAmount > 0 ? AppColors.error : AppColors.success, isDark),
                          ],
                        ),

                        const SizedBox(height: 24),
                        // Installment schedule list
                        Text(
                          'INSTALLMENT SCHEDULE (${agg.installments.length} Terms)',
                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLight : AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (agg.installments.isEmpty)
                          Text('No installment records registered.', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12))
                        else
                          ...agg.installments.map((inst) {
                            final isPaid = inst.status == InstallmentStatus.paid || inst.remainingAmount <= 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                borderRadius: AppBorderRadius.medium,
                                boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: (isPaid ? AppColors.success : AppColors.warning).withAlpha(25),
                                    child: Text(
                                      '#${inst.sequenceNumber}',
                                      style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 10, color: isPaid ? AppColors.success : AppColors.warning, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          inst.installmentType.name.toUpperCase(),
                                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary),
                                        ),
                                        Text(
                                          'Due: ${inst.dueDate.toIso8601String().split('T').first}',
                                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, color: textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'EGP ${_formatNumber(inst.principalAmount)}',
                                        style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary),
                                      ),
                                      Text(
                                        isPaid ? 'Paid in full' : 'Remaining: EGP ${_formatNumber(inst.remainingAmount)}',
                                        style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 10, color: isPaid ? AppColors.success : AppColors.warning),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 24),
                        // Payments Log list
                        Text(
                          'PAYMENT TRANSACTIONS LOG (${agg.payments.length} Receipts)',
                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: isDark ? AppColors.textLight : AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (agg.payments.isEmpty)
                          Text('No payment transaction logs registered.', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12))
                        else
                          ...agg.payments.map((p) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                borderRadius: AppBorderRadius.medium,
                                boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.receipt_long, color: AppColors.success, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ref: ${p.transactionReference}',
                                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary),
                                        ),
                                        Text(
                                          'Method: ${p.paymentMethod.name}  •  ${p.createdAt.toIso8601String().split('T').first}',
                                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, color: textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'EGP ${_formatNumber(p.amountPaid)}',
                                    style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String val, Color valColor, bool isDark) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppBorderRadius.medium,
        boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 9.5, fontWeight: FontWeight.bold, color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 13.5, fontWeight: FontWeight.bold, color: valColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
