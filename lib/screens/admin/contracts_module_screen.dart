import 'package:flutter/material.dart';
import '../../models/contract.dart';
import '../../repositories/firestore/firestore_contract_repository.dart';
import '../../theme/luxury_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/admin/shared/admin_data_table.dart';

class ContractsModuleScreen extends StatefulWidget {
  const ContractsModuleScreen({super.key});

  @override
  State<ContractsModuleScreen> createState() => _ContractsModuleScreenState();
}

class _ContractsModuleScreenState extends State<ContractsModuleScreen> {
  final FirestoreContractRepository _repository = FirestoreContractRepository();
  String _searchQuery = '';
  SignatureStatus? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return StreamBuilder<List<Contract>>(
      stream: _repository.streamAllContracts(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final contracts = snapshot.data ?? [];

        final filteredContracts = contracts.where((c) {
          if (_selectedStatus != null && c.signatureStatus != _selectedStatus) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return c.contractNumber.toLowerCase().contains(q) ||
                (c.clientCode != null && c.clientCode!.toLowerCase().contains(q)) ||
                c.buyerUserId.toLowerCase().contains(q) ||
                c.unitId.toLowerCase().contains(q);
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
                        l10n.contractsModule.toUpperCase(),
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
                        '${l10n.contractsModule} (${contracts.length} total contracts)',
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
                      child: DropdownButton<SignatureStatus?>(
                        value: _selectedStatus,
                        isExpanded: true,
                        hint: Text('All Signature Statuses', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12)),
                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        items: [
                          DropdownMenuItem<SignatureStatus?>(
                            value: null,
                            child: Text('All Signature Statuses', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12)),
                          ),
                          ...SignatureStatus.values.map((s) {
                            return DropdownMenuItem<SignatureStatus?>(
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
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textColor,
                              fontSize: 12,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search contract #, client, unit...',
                              hintStyle: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
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
                child: AdminDataTable<Contract>(
                  isLoading: isLoading,
                  items: filteredContracts,
                  emptyTitle: 'No Contracts Found',
                  emptyMessage: _searchQuery.isEmpty
                      ? 'No contract records found in Firestore.'
                      : 'No contracts match your query filters.',
                  columns: [
                    AdminTableColumn<Contract>(
                      title: 'Contract #',
                      cellBuilder: (c) => Text(
                        c.contractNumber,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    AdminTableColumn<Contract>(
                      title: 'Buyer / Client Code',
                      cellBuilder: (c) => Text(
                        c.clientCode ?? c.buyerUserId,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    AdminTableColumn<Contract>(
                      title: 'Unit ID',
                      cellBuilder: (c) => Text(
                        c.unitId,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    AdminTableColumn<Contract>(
                      title: 'Agreed Price',
                      cellBuilder: (c) => Text(
                        'EGP ${_formatNumber(c.agreedTotalPrice)}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    AdminTableColumn<Contract>(
                      title: 'Down Payment',
                      cellBuilder: (c) => Text(
                        'EGP ${_formatNumber(c.downPaymentAmount)}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    AdminTableColumn<Contract>(
                      title: 'Maint. Deposit',
                      cellBuilder: (c) {
                        final amt = c.maintenanceDepositAmount > 0
                            ? c.maintenanceDepositAmount
                            : (c.agreedTotalPrice * 0.08);
                        return Text(
                          'EGP ${_formatNumber(amt)}',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    AdminTableColumn<Contract>(
                      title: 'Term',
                      cellBuilder: (c) => Text(
                        '${c.totalInstallmentsCount} Inst. (${c.installmentDurationYears} yrs)',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    AdminTableColumn<Contract>(
                      title: 'Status',
                      cellBuilder: (c) {
                        final color = c.signatureStatus == SignatureStatus.fullyExecuted
                            ? AppColors.success
                            : c.signatureStatus == SignatureStatus.cancelled
                                ? AppColors.error
                                : AppColors.warning;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: AppBorderRadius.pill,
                          ),
                          child: Text(
                            c.signatureStatus.name.toUpperCase(),
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
