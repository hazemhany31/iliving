import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../repositories/compound_repository.dart';
import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';
import '../services/auth_service.dart';
import '../services/live_price_state.dart';
import '../repositories/operations_mock_data.dart';
import '../l10n/app_localizations.dart';

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
    
    final user = AuthService.instance.currentProfile;
    double targetPropertyVal = 25000000;
    double targetMonthlySalary = 150000;
    
    if (user != null && user.ownedUnitIds.isNotEmpty) {
      final unitId = user.ownedUnitIds.first;
      double? foundPrice;
      
      final tick = LivePriceState.instance.tickForUnit(unitId);
      if (tick != null) {
        foundPrice = tick.priceEGP;
      }
      
      if (foundPrice == null) {
        final unit = CompoundRepository.findUnitByNumber(unitId);
        if (unit != null) {
          foundPrice = unit.priceEGP;
        }
      }
      
      if (foundPrice == null) {
        try {
          final ledger = OperationsMockData.dummyLedgers.firstWhere(
            (l) => l.clientId == user.clientId || l.unitId == unitId,
          );
          foundPrice = ledger.downPayment.amountEGP +
              ledger.installments.fold(0.0, (sum, inst) => sum + inst.amountEGP);
        } catch (_) {}
      }
      
      if (foundPrice != null && foundPrice > 0) {
        targetPropertyVal = foundPrice;
        
        final double loanAmount = targetPropertyVal * 0.80;
        const double monthlyInterestRate = (12.5 / 100) / 12;
        const int numberOfPayments = 15 * 12;
        final double powFactor = pow(1 + monthlyInterestRate, numberOfPayments).toDouble();
        final double monthlyPayment = powFactor > 1
            ? loanAmount * (monthlyInterestRate * powFactor) / (powFactor - 1)
            : loanAmount / numberOfPayments;
            
        final calculatedSalary = (monthlyPayment / 0.35);
        targetMonthlySalary = calculatedSalary.clamp(20000, 2000000);
      }
    }

    if (mounted) {
      setState(() {
        _fractionalBlocks = blocks;
        _propertyValue = targetPropertyVal;
        _monthlySalary = targetMonthlySalary;
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
          l10n.prypcoHubTitle.toUpperCase(),
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
                Tab(text: l10n.fractionalBlocks.toUpperCase()),
                Tab(text: l10n.mortgagePreApproval.toUpperCase()),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading ? _buildLoadingView(isDark) : _buildFractionalBlocksTab(isDark),
          _buildMortgageAssistTab(isDark),
        ],
      ),
    );
  }

  Widget _buildLoadingView(bool isDark) {
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
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.55,
            ),
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppBorderRadius.medium,
              ),
              child: const LuxuryShimmer(width: double.infinity, height: 160),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFractionalBlocksTab(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fractionalMicroAssets.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.fractionalSubtitle,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _fractionalBlocks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.52,
              ),
              itemBuilder: (context, index) {
                final block = _fractionalBlocks[index];

                return InteractiveTapBounce(
                  onTap: () {
                    _showPurchaseBlockDialog(block, isDark);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: AppBorderRadius.medium,
                      boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image(
                              image: block['image']!.startsWith('http')
                                  ? NetworkImage(block['image']!)
                                  : AssetImage(block['image']!) as ImageProvider,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (e, s, _) => Container(
                                color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
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
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                block['location']!,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.estRoi.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: textMuted,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    block['roi']!,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: AppColors.success,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.minEntry.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: textMuted,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${block['shareEGP']}',
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: AppColors.accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: AppBorderRadius.pill,
                                child: LinearProgressIndicator(
                                  value: block['percentage']!,
                                  backgroundColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${l10n.funded} ${(block['percentage']! * 100).toInt()}%',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w600,
                                ),
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

  Widget _buildMortgageAssistTab(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    final double downPaymentAmount = _propertyValue * (_downPaymentPercent / 100);
    final double loanAmount = _propertyValue - downPaymentAmount;
    final double monthlyInterestRate = (_interestRate / 100) / 12;
    final int numberOfPayments = _loanTenureYears * 12;
    
    final double powFactor = pow(1 + monthlyInterestRate, numberOfPayments).toDouble();
    final double monthlyPayment = monthlyInterestRate > 0 && powFactor > 1
        ? loanAmount * (monthlyInterestRate * powFactor) / (powFactor - 1)
        : loanAmount / numberOfPayments;

    final double dbrRatio = (monthlyPayment / _monthlySalary) * 100;
    final bool isEligible = dbrRatio <= 50;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ELITE MORTGAGE PRE-APPROVAL ENGINE',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Perform high-fidelity debt-burden ratio analysis against regional bank compliance standards.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 20),
            _buildCalculatorSlider(
              'Target Property Value (EGP)',
              _propertyValue,
              1000000,
              150000000,
              (val) {
                setState(() {
                  _propertyValue = val;
                });
              },
              isCurrency: true,
              isDark: isDark,
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
              isDark: isDark,
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
              isDark: isDark,
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
              isDark: isDark,
            ),
            _buildCalculatorSlider(
              'Customer Monthly Verified Income (EGP)',
              _monthlySalary,
              20000,
              2000000,
              (val) {
                setState(() {
                  _monthlySalary = val;
                });
              },
              isCurrency: true,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: AppBorderRadius.large,
                boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                border: Border.all(
                  color: isEligible ? AppColors.success.withAlpha(80) : AppColors.error.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CALCULATED LOAN AMOUNT',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(loanAmount / 1000000).toStringAsFixed(2)}M EGP',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ESTIMATED MONTHLY INSTALLMENT',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${monthlyPayment.toStringAsFixed(0)} EGP',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DEBT BURDEN RATIO (DBR)',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${dbrRatio.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: isEligible ? AppColors.success : AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'REGULATORY ELIGIBILITY STATUS',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isEligible ? AppColors.success : AppColors.error).withAlpha(25),
                          borderRadius: AppBorderRadius.pill,
                        ),
                        child: Text(
                          isEligible ? 'QUALIFIED (DBR <= 50%)' : 'REJECTED (EXCEEDS LIMITS)',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: isEligible ? AppColors.success : AppColors.error,
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
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isEligible
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Secure digital bank pre-approval reference generated.'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.pill,
                  ),
                ),
                child: Text(
                  'DISPATCH BANK PRE-APPROVAL',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: isEligible
                        ? Colors.white
                        : (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    letterSpacing: 0.5,
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
    required bool isDark,
  }) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

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
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(minVal, maxVal),
          min: minVal,
          max: maxVal,
          activeColor: isDark ? AppColors.accent : AppColors.primary,
          inactiveColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
          onChanged: onChanged,
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  void _showPurchaseBlockDialog(Map<String, dynamic> block, bool isDark) {
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: textMuted.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'OWN FRACTIONAL MICRO-BLOCK',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                block['title']!,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                block['location']!,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated Annualized Return',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    block['roi']!,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Individual Share Base Value',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${block['shareEGP']} EGP',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.pill,
                    ),
                  ),
                  child: const Text(
                    'CLOSE ANALYTICS VIEW',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
