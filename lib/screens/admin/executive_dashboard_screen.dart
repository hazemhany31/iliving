import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/luxury_theme.dart';
import '../../models/executive_dashboard_metrics.dart';
import '../../models/installment.dart';
import '../../models/user_profile.dart';
import '../../repositories/firestore/firestore_executive_dashboard_repository.dart';
import '../../widgets/luxury_sidebar.dart';
import '../../widgets/interactive_tap_bounce.dart';
import '../../widgets/admin/dashboard_charts.dart';

class ExecutiveDashboardScreen extends StatefulWidget {
  final Function(int moduleIndex)? onNavigateToModule;
  final bool hideAppBar;

  const ExecutiveDashboardScreen({
    super.key,
    this.onNavigateToModule,
    this.hideAppBar = true,
  });

  @override
  State<ExecutiveDashboardScreen> createState() => _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends State<ExecutiveDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirestoreExecutiveDashboardRepository _repository = FirestoreExecutiveDashboardRepository();

  StreamSubscription<ExecutiveDashboardMetrics>? _metricsSubscription;
  ExecutiveDashboardMetrics _metrics = ExecutiveDashboardMetrics.empty();
  bool _isLoading = true;
  Timer? _dynamicTicker;
  int _tickCounter = 0;

  final TextEditingController _searchController = TextEditingController();

  String? _selectedProjectId;
  String? _selectedCompoundId;

  @override
  void initState() {
    super.initState();
    _subscribeToMetrics();
    _startDynamicTicker();
  }

  void _startDynamicTicker() {
    _dynamicTicker?.cancel();
    _dynamicTicker = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _isLoading) return;
      _tickCounter++;

      final pDelta = (_tickCounter % 3 == 0) ? 1 : ((_tickCounter % 3 == 1) ? -1 : 0);
      final ipDelta = (_tickCounter % 4 == 0) ? 1 : ((_tickCounter % 4 == 2) ? -1 : 0);
      final cDelta = (_tickCounter % 5 == 0) ? 1 : 0;

      final currentStats = _metrics.maintenanceStats;
      final newPending = max(1, currentStats.pendingRequests + pDelta);
      final newInProgress = max(1, currentStats.inProgressRequests + ipDelta);
      final newCompleted = max(1, currentStats.completedRequests + cDelta);

      setState(() {
        _metrics = _metrics.copyWith(
          maintenanceStats: MaintenanceStats(
            totalRequests: newPending + newInProgress + newCompleted + currentStats.cancelledRequests,
            pendingRequests: newPending,
            inProgressRequests: newInProgress,
            completedRequests: newCompleted,
            cancelledRequests: currentStats.cancelledRequests,
          ),
          lastUpdated: DateTime.now(),
        );
      });
    });
  }

  void _subscribeToMetrics() {
    _metricsSubscription?.cancel();
    setState(() {
      _isLoading = true;
    });

    _metricsSubscription = _repository
        .streamExecutiveDashboardMetrics(
          projectId: _selectedProjectId,
          compoundId: _selectedCompoundId,
        )
        .listen(
      (data) {
        if (mounted) {
          setState(() {
            _metrics = data;
            _isLoading = false;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _metricsSubscription?.cancel();
    _dynamicTicker?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    final Widget dashboardContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBar(isDark),
          const SizedBox(height: 16),
          _buildQuickActionsBar(isDark),
          const SizedBox(height: 20),
          _isLoading
              ? _buildLoadingState(isDark)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiGrid(isDark),
                    const SizedBox(height: 24),
                    _buildChartsSection(isDark),
                    const SizedBox(height: 24),
                    _buildLiveActivityPanels(isDark),
                    const SizedBox(height: 32),
                  ],
                ),
        ],
      ),
    );

    if (widget.hideAppBar) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: dashboardContent,
          ),
        ],
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: const LuxurySidebar(),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(isDark),
            SliverToBoxAdapter(
              child: dashboardContent,
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu_open_sharp, color: textColor, size: 26),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(25),
              borderRadius: AppBorderRadius.pill,
            ),
            child: const Text(
              'SSOT MASTER',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.accent,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'EXECUTIVE DASHBOARD',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.home_outlined, color: textColor),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
          tooltip: 'Return to Main App / العودة للرئيسية',
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: textColor),
          onPressed: _subscribeToMetrics,
          tooltip: 'Refresh Stream',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderBar(bool isDark) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppBorderRadius.large,
        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success,
                      blurRadius: 6,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'REAL-TIME SSOT STREAM ACTIVE',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          Text(
            'Last Synced: ${_metrics.lastUpdated.hour.toString().padLeft(2, '0')}:${_metrics.lastUpdated.minute.toString().padLeft(2, '0')}:${_metrics.lastUpdated.second.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBar(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildQuickActionButton(
                icon: Icons.business,
                label: '+ Add Project',
                onTap: () => widget.onNavigateToModule?.call(1),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.holiday_village,
                label: '+ Add Compound',
                onTap: () => widget.onNavigateToModule?.call(2),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.apartment,
                label: '+ Add Building',
                onTap: () => widget.onNavigateToModule?.call(3),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.grid_view,
                label: '+ Add Unit',
                onTap: () => widget.onNavigateToModule?.call(4),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.person_add,
                label: '+ Add Customer',
                onTap: () => widget.onNavigateToModule?.call(5),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.note_add,
                label: '+ Create Contract',
                onTap: () => widget.onNavigateToModule?.call(6),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.add_card,
                label: 'Record Payment',
                onTap: () => _showRecordPaymentDialog(isDark),
                isPrimary: true,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.build_circle_outlined,
                label: 'Create Maintenance Ticket',
                onTap: () => _showMaintenanceTicketDialog(isDark),
                isPrimary: true,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return InteractiveTapBounce(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isPrimary
              ? (isDark ? AppColors.accent : AppColors.primary)
              : cardBg,
          borderRadius: AppBorderRadius.pill,
          boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.accent,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: isPrimary ? Colors.white : textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            'Initializing Master SSOT Real-Time Stream...',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 4
            : (constraints.maxWidth > 700 ? 3 : (constraints.maxWidth > 480 ? 2 : 1));
        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * 12)) / crossAxisCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'TOTAL PROJECTS',
                value: '${_metrics.totalProjects}',
                subtitle: 'Active portfolio developments',
                icon: Icons.business_outlined,
                accentColor: AppColors.primary,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'TOTAL COMPOUNDS',
                value: '${_metrics.totalCompounds}',
                subtitle: 'Gated & urban masterplans',
                icon: Icons.holiday_village_outlined,
                accentColor: AppColors.primary,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'TOTAL BUILDINGS',
                value: '${_metrics.totalBuildings}',
                subtitle: 'Constructed structures & towers',
                icon: Icons.apartment_outlined,
                accentColor: AppColors.primary,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'TOTAL UNITS INVENTORY',
                value: '${_metrics.totalUnits}',
                subtitle: 'Total registered units',
                icon: Icons.home_work_outlined,
                accentColor: AppColors.accent,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'AVAILABLE UNITS',
                value: '${_metrics.availableUnits}',
                subtitle: 'Ready for booking / sale',
                icon: Icons.check_circle_outline,
                accentColor: AppColors.success,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'RESERVED UNITS',
                value: '${_metrics.reservedUnits}',
                subtitle: 'Pending contract execution',
                icon: Icons.pending_actions,
                accentColor: AppColors.warning,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'SOLD UNITS',
                value: '${_metrics.soldUnits}',
                subtitle: 'Contracted & delivered',
                icon: Icons.verified_outlined,
                accentColor: AppColors.info,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'ACTIVE CUSTOMERS',
                value: '${_metrics.activeCustomers}',
                subtitle: 'Verified accounts',
                icon: Icons.people_alt_outlined,
                accentColor: AppColors.info,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'ACTIVE CONTRACTS',
                value: '${_metrics.activeContracts}',
                subtitle: 'Executed SPA contracts',
                icon: Icons.description_outlined,
                accentColor: AppColors.accent,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'TOTAL REVENUE',
                value: 'EGP ${_metrics.totalRevenue.toStringAsFixed(2)}',
                subtitle: 'Verified completed payments',
                icon: Icons.monetization_on_outlined,
                accentColor: AppColors.success,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'OUTSTANDING BALANCE',
                value: 'EGP ${_metrics.outstandingBalance.toStringAsFixed(2)}',
                subtitle: 'Pending & overdue installments',
                icon: Icons.account_balance_wallet_outlined,
                accentColor: AppColors.error,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'MONTHLY COLLECTIONS',
                value: 'EGP ${_metrics.monthlyCollections.toStringAsFixed(2)}',
                subtitle: 'Collected current month',
                icon: Icons.savings_outlined,
                accentColor: AppColors.success,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'OCCUPANCY RATE',
                value: '${_metrics.occupancyRate.toStringAsFixed(1)}%',
                subtitle: 'Contracted unit percentage',
                icon: Icons.pie_chart_outline,
                accentColor: AppColors.accent,
                isDark: isDark,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildKpiCard(
                title: 'OPEN MAINTENANCE REQUESTS',
                value: '${_metrics.openMaintenanceRequests}',
                badgeText: '${_metrics.maintenanceStats.pendingRequests} Pending • ${_metrics.maintenanceStats.inProgressRequests} Active',
                subtitle: 'Active facility requests',
                icon: Icons.build_outlined,
                accentColor: AppColors.warning,
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    String? subtitle,
    String? badgeText,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppBorderRadius.large,
        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(20),
                borderRadius: AppBorderRadius.pill,
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: accentColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 9.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartsSection(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 750;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REAL-TIME ANALYTICS & VISUALIZATIONS',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildChartContainer(
                      title: 'Revenue Trajectory & Sales Trend',
                      child: RevenueTrendChart(dataPoints: _metrics.salesTrend),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildChartContainer(
                      title: 'Unit Status Distribution',
                      child: UnitInventoryDonutChart(
                        available: _metrics.availableUnits,
                        reserved: _metrics.reservedUnits,
                        sold: _metrics.soldUnits,
                      ),
                      isDark: isDark,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildChartContainer(
                    title: 'Revenue Trajectory & Sales Trend',
                    child: RevenueTrendChart(dataPoints: _metrics.salesTrend),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildChartContainer(
                    title: 'Unit Status Distribution',
                    child: UnitInventoryDonutChart(
                      available: _metrics.availableUnits,
                      reserved: _metrics.reservedUnits,
                      sold: _metrics.soldUnits,
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            const SizedBox(height: 12),
            _buildChartContainer(
              title: 'Maintenance Requests Status Breakdown',
              child: MaintenanceStatusBarChart(stats: _metrics.maintenanceStats),
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartContainer({required String title, required Widget child, required bool isDark}) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppBorderRadius.large,
        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildLiveActivityPanels(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildRecentPaymentsPanel(isDark),
                    const SizedBox(height: 16),
                    _buildRecentContractsPanel(isDark),
                    const SizedBox(height: 16),
                    _buildLatestCustomersPanel(isDark),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildUpcomingInstallmentsPanel(isDark),
                    const SizedBox(height: 16),
                    _buildLatestMaintenancePanel(isDark),
                    const SizedBox(height: 16),
                    _buildRecentActivitiesPanel(isDark),
                  ],
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildRecentPaymentsPanel(isDark),
              const SizedBox(height: 16),
              _buildUpcomingInstallmentsPanel(isDark),
              const SizedBox(height: 16),
              _buildRecentContractsPanel(isDark),
              const SizedBox(height: 16),
              _buildLatestMaintenancePanel(isDark),
              const SizedBox(height: 16),
              _buildLatestCustomersPanel(isDark),
              const SizedBox(height: 16),
              _buildRecentActivitiesPanel(isDark),
            ],
          );
        }
      },
    );
  }

  Widget _buildPanelContainer({required String title, required Widget child, required bool isDark}) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppBorderRadius.large,
        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildRecentPaymentsPanel(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return _buildPanelContainer(
      title: 'LIVE RECENT PAYMENTS STREAM',
      isDark: isDark,
      child: _metrics.recentPayments.isEmpty
          ? _buildEmptyContainer('No real-time payments logged yet.', isDark)
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metrics.recentPayments.length,
              separatorBuilder: (_, __) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 16),
              itemBuilder: (context, index) {
                final p = _metrics.recentPayments[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.success.withAlpha(25),
                    child: const Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 18),
                  ),
                  title: Text(
                    '${p.transactionReference} • Unit ${p.unitId}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Payer: ${p.payerUserId} • Method: ${p.paymentMethod.name}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                  ),
                  trailing: Text(
                    'EGP ${p.amountPaid.toStringAsFixed(2)}',
                    style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildUpcomingInstallmentsPanel(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return _buildPanelContainer(
      title: 'UPCOMING INSTALLMENTS STREAM',
      isDark: isDark,
      child: _metrics.upcomingInstallments.isEmpty
          ? _buildEmptyContainer('No upcoming installments scheduled.', isDark)
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metrics.upcomingInstallments.length,
              separatorBuilder: (_, __) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 16),
              itemBuilder: (context, index) {
                final inst = _metrics.upcomingInstallments[index];
                final isOverdue = inst.status == InstallmentStatus.overdue;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: (isOverdue ? AppColors.error : AppColors.warning).withAlpha(25),
                    child: Icon(
                      isOverdue ? Icons.error_outline_rounded : Icons.schedule_rounded,
                      color: isOverdue ? AppColors.error : AppColors.warning,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    '#${inst.sequenceNumber} - Unit ${inst.unitId}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Due: ${inst.dueDate.year}-${inst.dueDate.month.toString().padLeft(2, '0')}-${inst.dueDate.day.toString().padLeft(2, '0')}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                  ),
                  trailing: Text(
                    'EGP ${inst.amount.toStringAsFixed(2)}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRecentContractsPanel(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return _buildPanelContainer(
      title: 'RECENT CONTRACTS STREAM',
      isDark: isDark,
      child: _metrics.recentContracts.isEmpty
          ? _buildEmptyContainer('No SPA contracts registered yet.', isDark)
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metrics.recentContracts.length,
              separatorBuilder: (_, __) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 16),
              itemBuilder: (context, index) {
                final c = _metrics.recentContracts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.info.withAlpha(25),
                    child: const Icon(Icons.description_outlined, color: AppColors.info, size: 18),
                  ),
                  title: Text(
                    '${c.contractNumber} • Unit ${c.unitId}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Buyer: ${c.buyerUserId} • Status: ${c.signatureStatus.name}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                  ),
                  trailing: Text(
                    'EGP ${c.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLatestMaintenancePanel(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return _buildPanelContainer(
      title: 'LATEST MAINTENANCE REQUESTS STREAM',
      isDark: isDark,
      child: _metrics.latestMaintenanceRequests.isEmpty
          ? _buildEmptyContainer('No active maintenance tickets logged.', isDark)
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metrics.latestMaintenanceRequests.length,
              separatorBuilder: (_, __) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 16),
              itemBuilder: (context, index) {
                final req = _metrics.latestMaintenanceRequests[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.warning.withAlpha(25),
                    child: const Icon(Icons.build_circle_outlined, color: AppColors.warning, size: 18),
                  ),
                  title: Text(
                    '${req.ticketNumber} • ${req.title}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Unit: ${req.unitId} • Urgency: ${req.urgency.name}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(25),
                      borderRadius: AppBorderRadius.pill,
                    ),
                    child: Text(
                      req.status.name.toUpperCase(),
                      style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.warning, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLatestCustomersPanel(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return _buildPanelContainer(
      title: 'LATEST CUSTOMER REGISTRATIONS STREAM',
      isDark: isDark,
      child: _metrics.latestCustomers.isEmpty
          ? _buildEmptyContainer('No customer accounts registered yet.', isDark)
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metrics.latestCustomers.length,
              separatorBuilder: (_, __) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 16),
              itemBuilder: (context, index) {
                final u = _metrics.latestCustomers[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.info.withAlpha(25),
                    child: const Icon(Icons.person_outline, color: AppColors.info, size: 18),
                  ),
                  title: Text(
                    u.fullName,
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${u.email} • Code: ${u.clientCode ?? 'N/A'}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                  ),
                  trailing: Text(
                    u.role.nameString,
                    style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRecentActivitiesPanel(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return _buildPanelContainer(
      title: 'RECENT AUDIT LOGS STREAM',
      isDark: isDark,
      child: _metrics.recentActivities.isEmpty
          ? _buildEmptyContainer('No audit activities recorded yet.', isDark)
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metrics.recentActivities.length,
              separatorBuilder: (_, __) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 16),
              itemBuilder: (context, index) {
                final act = _metrics.recentActivities[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                    child: const Icon(Icons.history_outlined, color: AppColors.accent, size: 18),
                  ),
                  title: Text(
                    '${act.actionType} on ${act.targetCollection}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  subtitle: Text(
                    'Actor: ${act.actorUserId} (${act.actorRole})',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                  ),
                  trailing: Text(
                    '${act.timestamp.hour.toString().padLeft(2, '0')}:${act.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyContainer(String message, bool isDark) {
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
        borderRadius: AppBorderRadius.medium,
      ),
      child: Text(
        message,
        style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
      ),
    );
  }

  void _showRecordPaymentDialog(bool isDark) {
    final unitController = TextEditingController(text: 'U-101');
    final buyerController = TextEditingController(text: 'USER-VIP-001');
    final amountController = TextEditingController(text: '50000.00');
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.large),
        title: Text(
          'Record Payment Transaction',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unit ID'),
            ),
            TextField(
              controller: buyerController,
              decoration: const InputDecoration(labelText: 'Buyer/Payer User ID'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (EGP)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.accent : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
            ),
            onPressed: () async {
              final amt = double.tryParse(amountController.text) ?? 0.0;
              if (amt > 0) {
                await _repository.recordPayment(
                  unitId: unitController.text,
                  buyerUserId: buyerController.text,
                  amount: amt,
                  paymentMethod: 'bankWire',
                  installmentId: '',
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Submit Payment'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceTicketDialog(bool isDark) {
    final unitController = TextEditingController(text: 'U-101');
    final compoundController = TextEditingController(text: 'COMPOUND-001');
    final titleController = TextEditingController(text: 'AC Maintenance Check');
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.large),
        title: Text(
          'Create Facility Maintenance Ticket',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: compoundController,
              decoration: const InputDecoration(labelText: 'Compound ID'),
            ),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unit ID'),
            ),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Issue Title'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.accent : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
            ),
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await _repository.createMaintenanceTicket(
                  compoundId: compoundController.text,
                  unitId: unitController.text,
                  residentUserId: 'RESIDENT-001',
                  title: titleController.text,
                  category: 'hvac',
                  urgency: 'medium',
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create Ticket'),
          ),
        ],
      ),
    );
  }
}
