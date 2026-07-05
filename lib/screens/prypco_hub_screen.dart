import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../repositories/compound_repository.dart';
import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';

class PrypcoHubScreen extends StatefulWidget {
  const PrypcoHubScreen({super.key});

  @override
  State<PrypcoHubScreen> createState() => _PrypcoHubScreenState();
}

class _PrypcoHubScreenState extends State<PrypcoHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  final CompoundRepository _repository = CompoundRepository();
  List<Map<String, dynamic>> _fractionalBlocks = [];

  double _propertyValue = 25000000;
  double _downPaymentPercent = 20;
  double _interestRate = 12.5;
  int _loanTenureYears = 15;
  double _monthlySalary = 150000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final blocks = await _repository.fetchFractionalBlocks();
    if (mounted) {
      setState(() {
        _fractionalBlocks = blocks;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxuryTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text(
          'PRYPCO INVESTMENT HUB',
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
            Tab(text: 'FRACTIONAL BLOCKS'),
            Tab(text: 'MORTGAGE PRE-APPROVAL'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading ? _buildLoadingView() : _buildFractionalBlocksTab(),
          _buildMortgageAssistTab(),
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
          const LuxuryShimmer(width: 200, height: 16),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.55,
            ),
            itemBuilder: (context, index) => const LuxuryShimmer(width: double.infinity, height: 160),
          ),
        ],
      ),
    );
  }

  Widget _buildFractionalBlocksTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRYPCO FRACTIONAL MICRO-ASSETS',
              style: TextStyle(
                color: LuxuryTheme.primaryGold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Co-own highly vetted high-yield luxury real estate starting from minor allocations.',
              style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 10),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _fractionalBlocks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.55,
              ),
              itemBuilder: (context, index) {
                final block = _fractionalBlocks[index];

                return InteractiveTapBounce(
                  onTap: () {
                    _showPurchaseBlockDialog(block);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: LuxuryTheme.surfaceBrown,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                              image: DecorationImage(
                                image: NetworkImage(block['image']!),
                                fit: BoxFit.cover,
                                onError: (e, s) {},
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                block['title']!,
                                style: const TextStyle(
                                  color: LuxuryTheme.textWhite,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                block['location']!,
                                style: const TextStyle(
                                  color: LuxuryTheme.textMuted,
                                  fontSize: 8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'EST. ROI',
                                    style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    block['roi']!,
                                    style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'MIN ENTRY',
                                    style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${block['shareEGP']} EGP',
                                    style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: block['percentage']!,
                                  backgroundColor: LuxuryTheme.cardBrown,
                                  valueColor: const AlwaysStoppedAnimation<Color>(LuxuryTheme.primaryGold),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(block['percentage']! * 100).toInt()}% FUNDED',
                                style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 7, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMortgageAssistTab() {
    final double downPaymentAmount = _propertyValue * (_downPaymentPercent / 100);
    final double loanAmount = _propertyValue - downPaymentAmount;
    final double monthlyInterestRate = (_interestRate / 100) / 12;
    final int numberOfPayments = _loanTenureYears * 12;
    final double monthlyPayment = loanAmount *
        (monthlyInterestRate * (1 + monthlyInterestRate).toDouble() * numberOfPayments.toDouble()) /
        ((1 + monthlyInterestRate).toDouble() * numberOfPayments.toDouble() - 1);

    final double dbrRatio = (monthlyPayment / _monthlySalary) * 100;
    final bool isEligible = dbrRatio <= 50;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ELITE MORTGAGE PRE-APPROVAL ENGINE',
              style: TextStyle(
                color: LuxuryTheme.primaryGold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Perform high-fidelity debt-burden ratio analysis against regional bank compliance standards.',
              style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 10),
            ),
            const SizedBox(height: 20),
            _buildCalculatorSlider(
              'Target Property Value (EGP)',
              _propertyValue,
              5000000,
              150000000,
              (val) {
                setState(() {
                  _propertyValue = val;
                });
              },
              isCurrency: true,
            ),
            _buildCalculatorSlider(
              'Down Payment Ratio (%)',
              _downPaymentPercent,
              20,
              80,
              (val) {
                setState(() {
                  _downPaymentPercent = val;
                });
              },
              isPercent: true,
            ),
            _buildCalculatorSlider(
              'Dynamic Interest Rate (%)',
              _interestRate,
              5.0,
              25.0,
              (val) {
                setState(() {
                  _interestRate = val;
                });
              },
              isPercent: true,
            ),
            _buildCalculatorSlider(
              'Loan Tenure (Years)',
              _loanTenureYears.toDouble(),
              3,
              20,
              (val) {
                setState(() {
                  _loanTenureYears = val.toInt();
                });
              },
            ),
            _buildCalculatorSlider(
              'Customer Monthly Verified Income (EGP)',
              _monthlySalary,
              20000,
              1000000,
              (val) {
                setState(() {
                  _monthlySalary = val;
                });
              },
              isCurrency: true,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LuxuryTheme.surfaceBrown,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEligible ? LuxuryTheme.primaryGold : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CALCULATED LOAN AMOUNT',
                        style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(loanAmount / 1000000).toStringAsFixed(2)}M EGP',
                        style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ESTIMATED MONTHLY INSTALLMENT',
                        style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${monthlyPayment.toStringAsFixed(0)} EGP',
                        style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(color: LuxuryTheme.cardBrown, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DEBT BURDEN RATIO (DBR)',
                        style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${dbrRatio.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isEligible ? Colors.green : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'REGULATORY ELIGIBILITY STATUS',
                        style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isEligible ? Colors.green.withAlpha(38) : Colors.red.withAlpha(38),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isEligible ? Colors.green : Colors.red, width: 1),
                        ),
                        child: Text(
                          isEligible ? 'QUALIFIED (DBR <= 50%)' : 'REJECTED (EXCEEDS LIMITS)',
                          style: TextStyle(
                            color: isEligible ? Colors.green : Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            InteractiveTapBounce(
              onTap: isEligible
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Secure digital bank pre-approval reference generated.'),
                          backgroundColor: LuxuryTheme.primaryGold,
                        ),
                      );
                    }
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isEligible ? LuxuryTheme.primaryGold : LuxuryTheme.cardBrown,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEligible ? LuxuryTheme.primaryGold : LuxuryTheme.cardBrown,
                    width: 1,
                  ),
                ),
                child: Text(
                  'DISPATCH BANK PRE-APPROVAL',
                  style: TextStyle(
                    color: isEligible ? LuxuryTheme.backgroundBlack : LuxuryTheme.textMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorSlider(
    String label,
    double value,
    double minVal,
    double maxVal,
    ValueChanged<double> onChanged, {
    bool isCurrency = false,
    bool isPercent = false,
  }) {
    String displayValue = '';
    if (isCurrency) {
      if (value >= 1000000) {
        displayValue = '${(value / 1000000).toStringAsFixed(1)}M EGP';
      } else {
        displayValue = '${(value / 1000).toStringAsFixed(0)}K EGP';
      }
    } else if (isPercent) {
      displayValue = '${value.toStringAsFixed(1)}%';
    } else {
      displayValue = value.toInt().toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(color: LuxuryTheme.textSilver, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Text(
              displayValue,
              style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: minVal,
          max: maxVal,
          activeColor: LuxuryTheme.primaryGold,
          inactiveColor: LuxuryTheme.cardBrown,
          onChanged: onChanged,
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  void _showPurchaseBlockDialog(Map<String, dynamic> block) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PurchaseBlock Dismiss',
      barrierColor: Colors.black.withAlpha(166),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Material(
                color: LuxuryTheme.surfaceBrown.withAlpha(230),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: LuxuryTheme.primaryGold, width: 2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OWN FRACTIONAL MICRO-BLOCK',
                        style: TextStyle(
                          color: LuxuryTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        block['title']!,
                        style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        block['location']!,
                        style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Annualized Return', style: TextStyle(color: LuxuryTheme.textSilver, fontSize: 12)),
                          Text(block['roi']!, style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Individual Share Base Value', style: TextStyle(color: LuxuryTheme.textSilver, fontSize: 12)),
                          Text('${block['shareEGP']} EGP', style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      InteractiveTapBounce(
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fractional allocation of ${block['title']} purchased successfully!'),
                              backgroundColor: LuxuryTheme.primaryGold,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: LuxuryTheme.primaryGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'CONFIRM MICRO-INVESTMENT SHARE',
                            style: TextStyle(color: LuxuryTheme.backgroundBlack, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim1, curve: Curves.fastLinearToSlowEaseIn),
          ),
          child: child,
        );
      },
    );
  }
}
