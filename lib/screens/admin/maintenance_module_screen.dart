import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/installment.dart';
import '../../models/maintenance_request.dart';
import '../../repositories/interfaces/maintenance_repository.dart';
import '../../repositories/interfaces/ledger_repository.dart';
import '../../repositories/firestore/firestore_contract_repository.dart';
import '../../repositories/firestore/firestore_ledger_repository.dart';
import '../../repositories/firestore/firestore_maintenance_repository.dart';
import '../../theme/luxury_theme.dart';
import '../../utils/maintenance_validator.dart';
import '../../widgets/admin/shared/admin_data_table.dart';
import '../../widgets/admin/shared/admin_form_dialog.dart';
import '../../widgets/admin/shared/admin_status_badge.dart';
import '../../repositories/interfaces/contract_repository.dart';
import '../../widgets/interactive_tap_bounce.dart';

class MaintenanceModuleScreen extends StatefulWidget {
  final MaintenanceRepository? maintRepo;
  final LedgerRepository? ledgerRepo;
  final ContractRepository? contractRepo;
  const MaintenanceModuleScreen({super.key, this.maintRepo, this.ledgerRepo, this.contractRepo});

  @override
  State<MaintenanceModuleScreen> createState() => _MaintenanceModuleScreenState();
}

class _MaintenanceModuleScreenState extends State<MaintenanceModuleScreen>
    with SingleTickerProviderStateMixin {
  late final MaintenanceRepository _maintRepo;
  late final LedgerRepository _ledgerRepo;
  late final ContractRepository _contractRepo;

  late final TabController _tabController;

  StreamSubscription? _ticketsSub;
  StreamSubscription? _installmentsSub;

  List<MaintenanceRequest> _tickets = [];
  List<Installment> _maintenanceInstallments = [];

  bool _isLoading = true;
  String _searchQuery = '';
  MaintenanceStatus? _selectedStatusFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _maintRepo = widget.maintRepo ?? FirestoreMaintenanceRepository();
    _ledgerRepo = widget.ledgerRepo ?? FirestoreLedgerRepository();
    _contractRepo = widget.contractRepo ?? FirestoreContractRepository();
    _tabController = TabController(length: 2, vsync: this);
    _startStreams();
  }

  void _startStreams() {
    _ticketsSub = _maintRepo.streamAllTickets().listen(
      (tickets) {
        if (mounted) setState(() { _tickets = tickets; _isLoading = false; });
      },
      onError: (e) {
        if (mounted) setState(() => _isLoading = false);
      },
    );

    final repo = _ledgerRepo;
    final stream = repo is FirestoreLedgerRepository
        ? repo.streamAllInstallmentsLimited(limit: 1000)
        : repo.streamAllInstallments();
    _installmentsSub = stream.listen(
      (allInst) {
        final mntInst = allInst.where((i) => i.installmentType == InstallmentType.maintenanceFund).toList();
        if (mounted) setState(() => _maintenanceInstallments = mntInst);
      },
      onError: (e) {},
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _ticketsSub?.cancel();
    _installmentsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final Color textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header ───────────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 600;
              final titleWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MAINTENANCE & DEPOSIT HUB',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textColor,
                      fontSize: isSmall ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'وديعة الصيانة والبلاغات الفنية • Real-time Firestore',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              );

              final actionButton = InteractiveTapBounce(
                onTap: () => _showCreateMaintenanceTicketDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppBorderRadius.pill,
                    boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        '+ بلاغ صيانة جديد',
                        style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 10),
                    actionButton,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleWidget,
                  actionButton,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // ── Tabs Navigation ───────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
              borderRadius: AppBorderRadius.pill,
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: isDark ? AppColors.accent : AppColors.primary,
              labelColor: isDark ? AppColors.accent : AppColors.primary,
              unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, fontSize: 12),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('وديعة الصيانة (Deposits)'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.build_circle_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('بلاغات الصيانة (Tickets & SLAs)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Tab Views ─────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMaintenanceDepositsTab(isDark, textColor, textMuted),
                _buildMaintenanceTicketsTab(isDark, textColor, textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Maintenance Deposits (ودائع الصيانة) ───────────────────────────

  Widget _buildMaintenanceDepositsTab(bool isDark, Color textColor, Color textMuted) {
    // Calculate summary statistics
    final double totalCollected = _maintenanceInstallments.fold(0.0, (s, i) => s + i.paidAmount);
    final double totalScheduled = _maintenanceInstallments.fold(0.0, (s, i) => s + i.principalAmount);
    final int paidCount = _maintenanceInstallments.where((i) => i.isPaid).length;
    final int pendingCount = _maintenanceInstallments.where((i) => !i.isPaid).length;

    return Column(
      children: [
        // Responsive Summary Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 650;
            final card1 = _buildSummaryCard('إجمالي المنفذ / المجمع', 'EGP ${_formatNumber(totalCollected)}', AppColors.success, Icons.check_circle_outline, isDark);
            final card2 = _buildSummaryCard('إجمالي الودائع المجدولة', 'EGP ${_formatNumber(totalScheduled)}', AppColors.accent, Icons.account_balance, isDark);
            final card3 = _buildSummaryCard('ودائع مدفوعة بالكامل', '$paidCount وحدة', AppColors.info, Icons.task_alt, isDark);
            final card4 = _buildSummaryCard('ودائع قيد الانتظار', '$pendingCount وحدة', AppColors.warning, Icons.pending_actions, isDark);

            if (isNarrow) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.1,
                children: [card1, card2, card3, card4],
              );
            }

            return Row(
              children: [
                Expanded(child: card1),
                const SizedBox(width: 10),
                Expanded(child: card2),
                const SizedBox(width: 10),
                Expanded(child: card3),
                const SizedBox(width: 10),
                Expanded(child: card4),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // Table of Maintenance Deposits
        Expanded(
          child: _maintenanceInstallments.isEmpty
              ? _buildEmptyState('لا توجد أقساط لوديعة الصيانة مسجلة حالياً.', 'أضف وديعة صيانة من شاشة العميل أو العقد لتظهر فوراً هنا.')
              : AdminDataTable<Installment>(
                  isLoading: _isLoading,
                  items: _maintenanceInstallments,
                  emptyTitle: 'No Maintenance Deposits Found',
                  emptyMessage: 'No maintenance deposit records found in Firestore.',
                  columns: [
                    AdminTableColumn<Installment>(
                      title: 'Unit / Contract ID',
                      cellBuilder: (inst) => Text(
                        inst.unitId.isNotEmpty ? inst.unitId : inst.contractId,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    AdminTableColumn<Installment>(
                      title: 'Client Code',
                      cellBuilder: (inst) => Text(
                        inst.buyerUserId,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    AdminTableColumn<Installment>(
                      title: 'Deposit Amount (مبلغ الوديعة)',
                      cellBuilder: (inst) => Text(
                        'EGP ${_formatNumber(inst.principalAmount)}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    AdminTableColumn<Installment>(
                      title: 'Paid Amount (المدفوع)',
                      cellBuilder: (inst) => Text(
                        'EGP ${_formatNumber(inst.paidAmount)}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    AdminTableColumn<Installment>(
                      title: 'Due Date (التاريخ)',
                      cellBuilder: (inst) {
                        final dt = inst.dueDate;
                        return Text(
                          '${dt.day}/${dt.month}/${dt.year}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textMuted,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                    AdminTableColumn<Installment>(
                      title: 'Status',
                      cellBuilder: (inst) {
                        final isPaid = inst.isPaid;
                        final color = isPaid ? AppColors.success : AppColors.warning;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: AppBorderRadius.pill,
                          ),
                          child: Text(
                            inst.status.nameString.toUpperCase(),
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
                    AdminTableColumn<Installment>(
                      title: 'Actions',
                      cellBuilder: (inst) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: AppColors.accent, size: 20),
                            tooltip: 'تعديل المبلغ أو السداد',
                            onPressed: () => _showEditDepositDialog(context, inst),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ── Tab 2: Maintenance Tickets (بلاغات وتذاكر الصيانة) ─────────────────────

  Widget _buildMaintenanceTicketsTab(bool isDark, Color textColor, Color textMuted) {
    final filteredTickets = _tickets.where((t) {
      if (_selectedStatusFilter != null && t.status != _selectedStatusFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return t.title.toLowerCase().contains(q) ||
            t.unitId.toLowerCase().contains(q) ||
            t.ticketNumber.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Controls
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isSmall = constraints.maxWidth < 600;
            final dropdown = Container(
              width: isSmall ? double.infinity : 220,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                borderRadius: AppBorderRadius.pill,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MaintenanceStatus?>(
                  value: _selectedStatusFilter,
                  isExpanded: true,
                  hint: Text('جميع حالات البلاغات', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12)),
                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  items: [
                    DropdownMenuItem<MaintenanceStatus?>(
                      value: null,
                      child: Text('جميع الحالات (All Statuses)', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12)),
                    ),
                    ...MaintenanceStatus.values.map((s) {
                      return DropdownMenuItem<MaintenanceStatus?>(
                        value: s,
                        child: Text(s.name.toUpperCase(), style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12)),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() => _selectedStatusFilter = val),
                ),
              ),
            );

            final searchBar = Container(
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
                        hintText: 'بحث برقم التذكرة، الوحدة، أو عنوان البلاغ...',
                        hintStyle: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (isSmall) {
              return Column(
                children: [
                  dropdown,
                  const SizedBox(height: 10),
                  searchBar,
                ],
              );
            }

            return Row(
              children: [
                dropdown,
                const SizedBox(width: 12),
                Expanded(child: searchBar),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // Tickets Table
        Expanded(
          child: filteredTickets.isEmpty
              ? _buildEmptyState('لا توجد تذاكر صيانة حالية.', 'يمكنك إنشاء بلاغ صيانة جديد من الأعلى.')
              : AdminDataTable<MaintenanceRequest>(
                  isLoading: _isLoading,
                  items: filteredTickets,
                  emptyTitle: 'No Maintenance Tickets Found',
                  emptyMessage: 'No maintenance ticket records found in Firestore.',
                  columns: [
                    AdminTableColumn<MaintenanceRequest>(
                      title: 'Ticket #',
                      cellBuilder: (t) => Text(
                        t.ticketNumber.isNotEmpty ? t.ticketNumber : t.id.substring(0, 8),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    AdminTableColumn<MaintenanceRequest>(
                      title: 'Unit ID',
                      cellBuilder: (t) => Text(
                        t.unitId,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    AdminTableColumn<MaintenanceRequest>(
                      title: 'Category',
                      cellBuilder: (t) => Text(
                        t.category.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    AdminTableColumn<MaintenanceRequest>(
                      title: 'Title / Description',
                      cellBuilder: (t) => Text(
                        t.title,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AdminTableColumn<MaintenanceRequest>(
                      title: 'Urgency',
                      cellBuilder: (t) {
                        final isEmerg = t.urgency == MaintenanceUrgency.emergency || t.urgency == MaintenanceUrgency.high;
                        final color = isEmerg ? AppColors.error : AppColors.info;
                        return Text(
                          t.urgency.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                    AdminTableColumn<MaintenanceRequest>(
                      title: 'Status',
                      cellBuilder: (t) => MaintenanceStatusChip(status: t.status.name),
                    ),
                    AdminTableColumn<MaintenanceRequest>(
                      title: 'Actions',
                      cellBuilder: (t) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.published_with_changes, color: AppColors.info, size: 20),
                            tooltip: 'تغيير حالة التذكرة',
                            onPressed: () => _showUpdateTicketStatusDialog(context, t),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                            tooltip: 'حذف التذكرة',
                            onPressed: () async {
                              await _maintRepo.deleteTicket(t.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ── Helper Widgets & Sub-Dialogs ──────────────────────────────────────────

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppBorderRadius.medium,
        boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.build_circle_outlined, color: AppColors.accent, size: 48),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.textLightMuted, fontSize: 12)),
        ],
      ),
    );
  }

  void _showCreateMaintenanceTicketDialog(BuildContext context) {
    final unitController = TextEditingController(text: 'B01B202');
    final titleController = TextEditingController();
    final descController = TextEditingController();
    MaintenanceCategory category = MaintenanceCategory.plumbing;
    MaintenanceUrgency urgency = MaintenanceUrgency.medium;

    AdminFormDialog.show(
      context: context,
      title: 'إنشاء بلاغ صيانة جديد',
      subtitle: 'تسجيل بلاغ صيانة جديد وتوجيهه للفنيين المختصين',
      icon: Icons.build_circle_outlined,
      submitLabel: 'إنشاء البلاغ',
      cancelLabel: 'إلغاء',
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'رقم الوحدة (Unit ID)', hintText: 'مثال: B01B202'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MaintenanceCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'تصنيف الصيانة'),
                items: MaintenanceCategory.values.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => category = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MaintenanceUrgency>(
                initialValue: urgency,
                decoration: const InputDecoration(labelText: 'درجة الأهمية / الأولوية'),
                items: MaintenanceUrgency.values.map((u) {
                  return DropdownMenuItem(value: u, child: Text(u.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => urgency = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'عنوان البلاغ', hintText: 'مثال: تسريب مياه بمحبس الحمام'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'تفاصيل المشكلة / الملاحظات'),
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        final messenger = ScaffoldMessenger.of(context);
        final titleErr = MaintenanceValidator.validateTitle(titleController.text, isAr: true);
        if (titleErr != null) throw Exception(titleErr);

        final descErr = MaintenanceValidator.validateDescription(descController.text, isAr: true);
        if (descErr != null) throw Exception(descErr);

        final ticketId = 'ticket_${DateTime.now().millisecondsSinceEpoch}';
        final ticketNo = 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        final ticket = MaintenanceRequest(
          id: ticketId,
          ticketNumber: ticketNo,
          compoundId: 'zayed_lagoons',
          unitId: unitController.text.trim().isNotEmpty ? unitController.text.trim() : 'B01B202',
          residentUserId: 'CLI-202',
          category: category,
          urgency: urgency,
          title: titleController.text.trim(),
          description: descController.text.trim(),
          status: MaintenanceStatus.submitted,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _maintRepo.createTicket(ticket);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء بلاغ الصيانة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  void _showUpdateTicketStatusDialog(BuildContext context, MaintenanceRequest ticket) {
    MaintenanceStatus status = ticket.status;

    AdminFormDialog.show(
      context: context,
      title: 'تحديث حالة تذكرة الصيانة',
      subtitle: 'تذكرة رقم ${ticket.ticketNumber} • الوحدة ${ticket.unitId}',
      icon: Icons.published_with_changes,
      submitLabel: 'حفظ والتأكيد',
      cancelLabel: 'إلغاء',
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MaintenanceStatus>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'الحالة الجديدة (New Status)'),
                items: MaintenanceStatus.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => status = val);
                },
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        final messenger = ScaffoldMessenger.of(context);
        final updated = ticket.copyWith(status: status, updatedAt: DateTime.now());
        await _maintRepo.updateTicket(updated);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم تحديث حالة تذكرة الصيانة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  void _showEditDepositDialog(BuildContext context, Installment inst) {
    final amountController = TextEditingController(text: inst.principalAmount.toStringAsFixed(0));
    final paidController = TextEditingController(text: inst.paidAmount.toStringAsFixed(0));

    AdminFormDialog.show(
      context: context,
      title: 'تعديل/تسديد وديعة الصيانة',
      subtitle: 'الوحدة: ${inst.unitId} • العميل: ${inst.buyerUserId}',
      icon: Icons.edit_note,
      submitLabel: 'حفظ وتأكيد السداد',
      cancelLabel: 'إلغاء',
      body: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'إجمالي مبلغ وديعة الصيانة (EGP)',
                  hintText: 'أدخل قيمة الوديعة بالجنيه',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: paidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع حتى الآن (Paid EGP)',
                  hintText: 'أدخل المبلغ المسدد فعلياً من العميل',
                ),
              ),
            ],
          );
        },
      ),
      onSubmit: () async {
        final messenger = ScaffoldMessenger.of(context);
        final principal = double.tryParse(amountController.text.trim()) ?? inst.principalAmount;
        final paid = double.tryParse(paidController.text.trim()) ?? inst.paidAmount;
        final isPaid = paid >= principal && principal > 0;
        final effectiveContractId = inst.contractId.isNotEmpty ? inst.contractId : (inst.unitId.isNotEmpty ? 'CNT-${inst.unitId}' : 'CNT-DEFAULT');

        final updated = inst.copyWith(
          contractId: effectiveContractId,
          principalAmount: principal,
          paidAmount: paid,
          status: isPaid ? InstallmentStatus.paid : (paid > 0 ? InstallmentStatus.partiallyPaid : InstallmentStatus.unpaid),
          paidAt: isPaid ? DateTime.now() : inst.paidAt,
        );

        // 1. Update installment doc in Firestore (immediate local cache write)
        await _ledgerRepo.updateInstallment(updated).timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );

        // 2. Sync maintenanceDepositAmount into Contract in Firestore
        try {
          final contract = await _contractRepo.getContractById(effectiveContractId).timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
          if (contract != null) {
            final updatedContract = contract.copyWith(maintenanceDepositAmount: principal);
            await _contractRepo.updateContract(updatedContract).timeout(
              const Duration(seconds: 2),
              onTimeout: () {},
            );
          }
        } catch (_) {
          // Contract fallback if doc doesn't exist yet
        }

        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم حفظ وديعة الصيانة وتأكيد سداد العميل بنجاح في الحسابات!'),
            backgroundColor: Colors.green,
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
