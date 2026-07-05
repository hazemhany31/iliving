import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../models/property_model.dart';
import '../repositories/compound_repository.dart';
import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';
import 'document_viewer_screen.dart';

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
    return Scaffold(
      backgroundColor: LuxuryTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text(
          'BOOKING & LEAD CONSOLE',
          style: TextStyle(
            color: LuxuryTheme.primaryGold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: LuxuryTheme.primaryGold, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: LuxuryTheme.primaryGold,
          labelColor: LuxuryTheme.primaryGold,
          unselectedLabelColor: LuxuryTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
          tabs: const [
            Tab(text: 'LIVE LEADS'),
            Tab(text: 'BOOKING TRANSACTIONS'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeadsTab(),
                _buildTransactionsTab(),
              ],
            ),
    );
  }

  Widget _buildLoadingView() {
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
            itemCount: 3,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, index) => const LuxuryShimmer(width: double.infinity, height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ACTIVE CLIENT LEADS PIPELINE',
              style: TextStyle(
                color: LuxuryTheme.primaryGold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _leads.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.60,
              ),
              itemBuilder: (context, index) {
                final lead = _leads[index];

                String statusLabel;
                Color statusColor;
                switch (lead.status) {
                  case LeadStatus.newLead:
                    statusLabel = 'NEW';
                    statusColor = Colors.blue;
                    break;
                  case LeadStatus.contacted:
                    statusLabel = 'CONTACTED';
                    statusColor = Colors.orange;
                    break;
                  case LeadStatus.meetingScheduled:
                    statusLabel = 'MEETING';
                    statusColor = LuxuryTheme.primaryGold;
                    break;
                  case LeadStatus.proposalSent:
                    statusLabel = 'PROPOSAL';
                    statusColor = Colors.green;
                    break;
                  case LeadStatus.closed:
                    statusLabel = 'CLOSED';
                    statusColor = Colors.green;
                    break;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: LuxuryTheme.surfaceBrown,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.person, color: LuxuryTheme.primaryGold, size: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(40),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 7, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lead.clientName,
                        style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 10, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lead.email,
                        style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      InteractiveTapBounce(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Initiating secure protocol for ${lead.clientName}'),
                              backgroundColor: LuxuryTheme.primaryGold,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: LuxuryTheme.cardBrown,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: LuxuryTheme.primaryGold.withAlpha(80)),
                          ),
                          child: const Center(
                            child: Text(
                              'CONTACT NOW',
                              style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 7.5, fontWeight: FontWeight.bold),
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

  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VERIFIED ESCROW TRANSACTIONS',
              style: TextStyle(
                color: LuxuryTheme.primaryGold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.55,
              ),
              itemBuilder: (context, index) {
                final tx = _transactions[index];

                String statusLabel;
                Color statusColor;
                switch (tx.status) {
                  case BookingStatus.spaExecuted:
                    statusLabel = 'SPA EXECUTED';
                    statusColor = Colors.green;
                    break;
                  case BookingStatus.pendingApproval:
                    statusLabel = 'PENDING';
                    statusColor = LuxuryTheme.primaryGold;
                    break;
                  case BookingStatus.rejected:
                    statusLabel = 'REJECTED';
                    statusColor = Colors.red;
                    break;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: LuxuryTheme.surfaceBrown,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tx.transactionId,
                            style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(40),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 6, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tx.buyerName,
                        style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 10, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('Unit: ${tx.unitId}', style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 8)),
                      Text(
                        '${(tx.contractedPriceEGP / 1000000).toStringAsFixed(1)}M EGP',
                        style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      InteractiveTapBounce(
                        onTap: () => _openInvoiceBrowser('Invoice — ${tx.transactionId}', tx.invoiceUrl),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: LuxuryTheme.cardBrown,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: LuxuryTheme.primaryGold.withAlpha(80)),
                          ),
                          child: const Center(
                            child: Text(
                              'VIEW INVOICE',
                              style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 7.5, fontWeight: FontWeight.bold),
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
