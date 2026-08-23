import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../repositories/compound_repository.dart';
import '../widgets/luxury_shimmer.dart';
import '../models/compound_model.dart';

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
  List<CompoundModel> _compounds = [];
  CompoundModel? _selectedCompound;

  double get _totalAccruedRevenue {
    double total = 0.0;
    for (final item in _brokerHistory) {
      final amtStr = item['amount'] ?? '0';
      total += double.tryParse(amtStr) ?? 0.0;
    }
    return total;
  }

  String get _accreditationText {
    final double millions = _totalAccruedRevenue / 1000000.0;
    return "${millions.toStringAsFixed(1)}M / 20M EGP";
  }

  double get _progressValue {
    final val = _totalAccruedRevenue / 20000000.0;
    return val.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final averages = await _repository.fetchRegionalAverages();
    final history = await _repository.fetchBrokerHistory();
    final compounds = await _repository.fetchCompounds();
    if (mounted) {
      setState(() {
        _regionalAverages = averages;
        _brokerHistory = history;
        _compounds = compounds;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final iconColor = isDark ? AppColors.textLight : AppColors.textDark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        title: Text(
          'YIELD & BROKER ANALYTICS',
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
      ),
      body: _isLoading
          ? _buildLoadingView(isDark)
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RENTAL YIELD PREDICTION MODEL',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppBorderRadius.large,
                        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                              borderRadius: AppBorderRadius.medium,
                            ),
                            child: DropdownButtonFormField<CompoundModel>(
                              initialValue: _selectedCompound,
                              dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              decoration: InputDecoration(
                                labelText: 'Select Portfolio Property (Optional)',
                                labelStyle: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                                prefixIcon: const Icon(Icons.location_city_rounded, color: AppColors.accent, size: 18),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textColor,
                                fontSize: 13,
                              ),
                              iconEnabledColor: AppColors.accent,
                              items: _compounds.map((CompoundModel compound) {
                                return DropdownMenuItem<CompoundModel>(
                                  value: compound,
                                  child: Text(compound.title),
                                );
                              }).toList(),
                              onChanged: (CompoundModel? newValue) {
                                setState(() {
                                  _selectedCompound = newValue;
                                  if (newValue != null) {
                                    _investmentController.text = newValue.basePriceEGP.toString();
                                    final double expectedRent = newValue.basePriceEGP * 0.08;
                                    _rentController.text = expectedRent.toInt().toString();
                                    _calculateYieldAction();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _investmentController,
                            label: 'Total Capital Outlay (EGP)',
                            icon: Icons.money_rounded,
                            isDark: isDark,
                            onChanged: (_) => _calculateYieldAction(),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _rentController,
                            label: 'Expected Gross Annual Rental Income (EGP)',
                            icon: Icons.apartment_rounded,
                            isDark: isDark,
                            onChanged: (_) => _calculateYieldAction(),
                          ),
                          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CALCULATED GROSS YIELD',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_calculatedYield.toStringAsFixed(2)}% P.A.',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: AppColors.accent,
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
                    Text(
                      'REGIONAL AVERAGE ROBUSTNESS',
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
                      itemCount: _regionalAverages.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.25,
                      ),
                      itemBuilder: (context, index) {
                        final reg = _regionalAverages[index];

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: AppBorderRadius.medium,
                            boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                reg['region']!.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reg['avg']!,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: AppColors.accent,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'BROKER REVENUES & SLABS',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
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
                              Text(
                                'PLATINUM COMMISSIONS ACCREDITATION',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _accreditationText,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: AppColors.accent,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: AppBorderRadius.pill,
                            child: LinearProgressIndicator(
                              value: _progressValue,
                              backgroundColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Achieve 20M EGP to unlock 5.0% Platinum commissions tier.',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textMuted,
                              fontSize: 9.5,
                            ),
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
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final hist = _brokerHistory[index];

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: AppBorderRadius.medium,
                            boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                hist['date']!,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  hist['details']!,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hist['payout']!,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required ValueChanged<String> onChanged,
  }) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
        borderRadius: AppBorderRadius.medium,
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: textColor,
          fontSize: 13,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: textMuted,
            fontSize: 12,
          ),
          prefixIcon: Icon(icon, color: AppColors.accent, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
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
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppBorderRadius.large,
            ),
            child: const LuxuryShimmer(width: double.infinity, height: 180),
          ),
          const SizedBox(height: 24),
          const LuxuryShimmer(width: 160, height: 14),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppBorderRadius.medium,
              ),
              child: const LuxuryShimmer(width: double.infinity, height: 60),
            ),
          ),
        ],
      ),
    );
  }
}
