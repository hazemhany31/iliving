import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../models/property_model.dart';
import '../repositories/compound_repository.dart';
import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';
import 'document_viewer_screen.dart';
import '../l10n/app_localizations.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  final CompoundRepository _repository = CompoundRepository();
  List<Lead> _leads = [];
  List<BookingTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final leads = await _repository.fetchLeads();
    final transactions = await _repository.fetchTransactions();
    if (mounted) {
      setState(() {
        _leads = leads;
        _transactions = transactions;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openInvoiceBrowser(String title, String invoiceUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerScreen(
          title: title,
          documentUrl: invoiceUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final iconColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        title: Text(
          l10n.bookingLeadConsole.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
              borderRadius: AppBorderRadius.pill,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? AppColors.accent : AppColors.primary,
                borderRadius: AppBorderRadius.pill,
                boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
              labelStyle: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              tabs: [
                Tab(text: l10n.liveLeads.toUpperCase()),
                Tab(text: l10n.bookingTransactions.toUpperCase()),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView(isDark)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeadsTab(l10n, isDark),
                _buildTransactionsTab(isDark),
              ],
            ),
    );
  }

  Widget _buildLoadingView(bool isDark) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600
        ? 2
        : (screenWidth < 900 ? 3 : (screenWidth < 1200 ? 4 : 5));
    final double gridWidth = screenWidth - 32;
    final double cardWidth = (gridWidth - (8 * (crossAxisCount - 1))) / crossAxisCount;
    final double targetHeight = screenWidth < 600 ? 140.0 : 160.0;
    final double childAspectRatio = cardWidth / targetHeight;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LuxuryShimmer(width: 160, height: 16),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppBorderRadius.medium,
              ),
              child: const LuxuryShimmer(width: double.infinity, height: 120),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsTab(AppLocalizations l10n, bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600
        ? 2
        : (screenWidth < 900 ? 3 : (screenWidth < 1200 ? 4 : 5));
    final double gridWidth = screenWidth - 32;
    final double cardWidth = (gridWidth - (10 * (crossAxisCount - 1))) / crossAxisCount;
    final double targetHeight = screenWidth < 600 ? 150.0 : 170.0;
    final double childAspectRatio = cardWidth / targetHeight;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.activeLeadsPipeline.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _leads.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final lead = _leads[index];

                String statusLabel;
                Color statusColor;
                switch (lead.status) {
                  case LeadStatus.newLead:
                    statusLabel = l10n.statusNew.toUpperCase();
                    statusColor = AppColors.accent;
                    break;
                  case LeadStatus.contacted:
                    statusLabel = l10n.active.toUpperCase();
                    statusColor = AppColors.warning;
                    break;
                  case LeadStatus.meetingScheduled:
                    statusLabel = l10n.statusMeeting.toUpperCase();
                    statusColor = AppColors.primary;
                    break;
                  case LeadStatus.proposalSent:
                    statusLabel = l10n.statusProposal.toUpperCase();
                    statusColor = AppColors.success;
                    break;
                  case LeadStatus.closed:
                    statusLabel = l10n.completed.toUpperCase();
                    statusColor = AppColors.success;
                    break;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: AppBorderRadius.medium,
                    boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded, color: AppColors.accent, size: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: AppBorderRadius.pill,
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: statusColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lead.clientName,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lead.email,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 8.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      InteractiveTapBounce(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${l10n.info}: ${lead.clientName}'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                            borderRadius: AppBorderRadius.pill,
                          ),
                          child: Center(
                            child: Text(
                              l10n.contactNow.toUpperCase(),
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600
        ? 2
        : (screenWidth < 900 ? 3 : (screenWidth < 1200 ? 4 : 5));
    final double gridWidth = screenWidth - 32;
    final double cardWidth = (gridWidth - (10 * (crossAxisCount - 1))) / crossAxisCount;
    final double targetHeight = screenWidth < 600 ? 155.0 : 175.0;
    final double childAspectRatio = cardWidth / targetHeight;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VERIFIED ESCROW TRANSACTIONS',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final tx = _transactions[index];

                String statusLabel;
                Color statusColor;
                switch (tx.status) {
                  case BookingStatus.spaExecuted:
                    statusLabel = 'SPA EXECUTED';
                    statusColor = AppColors.success;
                    break;
                  case BookingStatus.pendingApproval:
                    statusLabel = 'PENDING';
                    statusColor = AppColors.warning;
                    break;
                  case BookingStatus.rejected:
                    statusLabel = 'REJECTED';
                    statusColor = AppColors.error;
                    break;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: AppBorderRadius.medium,
                    boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tx.transactionId,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: AppColors.accent,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: AppBorderRadius.pill,
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: statusColor,
                                fontSize: 6.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tx.buyerName,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Unit: ${tx.unitId}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 8.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(tx.contractedPriceEGP / 1000000).toStringAsFixed(1)}M EGP',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      InteractiveTapBounce(
                        onTap: () => _openInvoiceBrowser('Invoice — ${tx.transactionId}', tx.invoiceUrl),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                            borderRadius: AppBorderRadius.pill,
                          ),
                          child: Center(
                            child: Text(
                              'VIEW INVOICE',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textColor,
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
