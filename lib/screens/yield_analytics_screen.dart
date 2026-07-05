import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../repositories/compound_repository.dart';
import '../widgets/luxury_shimmer.dart';

class YieldAnalyticsScreen extends StatefulWidget {
  const YieldAnalyticsScreen({super.key});

  @override
  State<YieldAnalyticsScreen> createState() => _YieldAnalyticsScreenState();
}

class _YieldAnalyticsScreenState extends State<YieldAnalyticsScreen> {
  final _investmentController = TextEditingController(text: '120000000');
  final _rentController = TextEditingController(text: '9600000');
  bool _isLoading = true;

  double _calculatedYield = 8.0;

  final CompoundRepository _repository = CompoundRepository();
  List<Map<String, String>> _regionalAverages = [];
  List<Map<String, String>> _brokerHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final averages = await _repository.fetchRegionalAverages();
    final history = await _repository.fetchBrokerHistory();
    if (mounted) {
      setState(() {
        _regionalAverages = averages;
        _brokerHistory = history;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _investmentController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  void _calculateYieldAction() {
    final double inv = double.tryParse(_investmentController.text) ?? 1.0;
    final double rent = double.tryParse(_rentController.text) ?? 0.0;
    setState(() {
      _calculatedYield = (rent / inv) * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxuryTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text(
          'YIELD & BROKER ANALYTICS',
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
      ),
      body: _isLoading
          ? _buildLoadingView()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RENTAL YIELD PREDICTION MODEL',
                      style: TextStyle(
                        color: LuxuryTheme.primaryGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: LuxuryTheme.surfaceBrown,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _investmentController,
                            decoration: const InputDecoration(
                              labelText: 'Total Capital Outlay (EGP)',
                              prefixIcon: Icon(Icons.money_outlined, color: LuxuryTheme.primaryGold),
                            ),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 13),
                            onChanged: (_) => _calculateYieldAction(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _rentController,
                            decoration: const InputDecoration(
                              labelText: 'Expected Gross Annual Rental Income (EGP)',
                              prefixIcon: Icon(Icons.apartment_outlined, color: LuxuryTheme.primaryGold),
                            ),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 13),
                            onChanged: (_) => _calculateYieldAction(),
                          ),
                          const Divider(color: LuxuryTheme.cardBrown, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CALCULATED GROSS YIELD',
                                style: TextStyle(color: LuxuryTheme.textSilver, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_calculatedYield.toStringAsFixed(2)}% P.A.',
                                style: const TextStyle(
                                  color: LuxuryTheme.primaryGold,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'REGIONAL AVERAGE ROBUSTNESS',
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
                      itemCount: _regionalAverages.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.25,
                      ),
                      itemBuilder: (context, index) {
                        final reg = _regionalAverages[index];

                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: LuxuryTheme.surfaceBrown,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                reg['region']!.toUpperCase(),
                                style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 7.5, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reg['avg']!,
                                style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'BROKER REVENUES & SLABS',
                      style: TextStyle(
                        color: LuxuryTheme.primaryGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: LuxuryTheme.surfaceBrown,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PLATINUM COMMISSIONS ACCREDITATION',
                                style: TextStyle(color: LuxuryTheme.textWhite, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '15.2M / 20M EGP',
                                style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 15.2 / 20.0,
                              backgroundColor: LuxuryTheme.cardBrown,
                              valueColor: AlwaysStoppedAnimation<Color>(LuxuryTheme.primaryGold),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Achieve 20M EGP to unlock 5.0% Platinum commissions tier.',
                            style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _brokerHistory.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final hist = _brokerHistory[index];

                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: LuxuryTheme.surfaceBrown,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: LuxuryTheme.cardBrown, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                hist['date']!,
                                style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 8),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  hist['details']!,
                                  style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hist['payout']!,
                                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LuxuryShimmer(width: 200, height: 16),
          const SizedBox(height: 16),
          const LuxuryShimmer(width: double.infinity, height: 180),
          const SizedBox(height: 24),
          const LuxuryShimmer(width: 160, height: 14),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) => const LuxuryShimmer(width: double.infinity, height: 60),
          ),
        ],
      ),
    );
  }
}
