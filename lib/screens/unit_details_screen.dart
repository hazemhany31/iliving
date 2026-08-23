import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../models/compound_model.dart';
import '../models/unit_model.dart';
import '../repositories/compound_repository.dart';
import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';
import 'document_viewer_screen.dart';
import 'compound_map_screen.dart';
import '../widgets/image_loader.dart';

class UnitDetailsScreen extends StatefulWidget {
  final CompoundModel compound;

  const UnitDetailsScreen({
    super.key,
    required this.compound,
  });

  @override
  State<UnitDetailsScreen> createState() => _UnitDetailsScreenState();
}

class _UnitDetailsScreenState extends State<UnitDetailsScreen> with TickerProviderStateMixin {
  int _activeMediaIndex = 0;
  int _selectedUnitIndex = 0;
  late PageController _mediaPageController;
  bool _isLoading = true;

  final CompoundRepository _repository = CompoundRepository();
  List<UnitModel> _units = [];
  List<String> _mediaImages = [];

  @override
  void initState() {
    super.initState();
    _mediaPageController = PageController();
    _mediaImages = widget.compound.galleryPhotos.map((p) => p.url).toList();
    if (_mediaImages.isEmpty) {
      _mediaImages = [widget.compound.heroImageUrl];
    }
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final units = await _repository.fetchUnitsForCompound(widget.compound.id);
    if (mounted) {
      setState(() {
        _units = units;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mediaPageController.dispose();
    super.dispose();
  }

  Future<void> _viewSecureDocument(BuildContext context, String title, String url) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerScreen(
          title: title,
          documentUrl: url,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: _isLoading ? _buildLoadingView(isDark) : _buildLoadedView(isDark),
    );
  }

  Widget _buildLoadingView(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? AppColors.textLight : AppColors.textDark, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Expanded(child: LuxuryShimmer(width: double.infinity, height: 20)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppBorderRadius.large,
              ),
              child: const LuxuryShimmer(width: double.infinity, height: 260),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
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
      ),
    );
  }

  Widget _buildLoadedView(bool isDark) {
    if (_units.isEmpty) {
      return Center(
        child: Text(
          'No units available',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
          ),
        ),
      );
    }

    final selectedUnit = _units[_selectedUnitIndex];
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withAlpha(220),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 16),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _mediaPageController,
                      itemCount: _mediaImages.length,
                      onPageChanged: (idx) {
                        setState(() {
                          _activeMediaIndex = idx;
                        });
                      },
                      itemBuilder: (context, idx) {
                        return ImageLoader(
                          imageUrl: _mediaImages[idx],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: [0.0, 0.45, 1.0],
                          colors: [
                            Color(0xBB1A1A2E),
                            Colors.transparent,
                            Color(0x33000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      right: 16,
                      child: Row(
                        children: [
                          _buildCircleButton(Icons.bookmark_border_rounded, () {}),
                          const SizedBox(width: 8),
                          _buildCircleButton(Icons.share_rounded, () {}),
                          const SizedBox(width: 8),
                          _buildCircleButton(Icons.map_rounded, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompoundMapScreen(
                                  compound: widget.compound,
                                  isOperationsMode: false,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: ClipRRect(
                        borderRadius: AppBorderRadius.pill,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(120),
                              borderRadius: AppBorderRadius.pill,
                            ),
                            child: Text(
                              '${_activeMediaIndex + 1} / ${_mediaImages.length}',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnimatedSlideUp(
                      delay: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.compound.title,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: AppColors.accent, size: 15),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.compound.location,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: textMuted,
                                          fontSize: 12.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                              borderRadius: AppBorderRadius.pill,
                            ),
                            child: const Text(
                              'PREMIUM LINE',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.accent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AnimatedSlideUp(
                      delay: 100,
                      child: _buildSectionTitle('LIVE VACANT UNITS INVENTORY', isDark),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSlideUp(
                      delay: 150,
                      child: _buildLiveInventoryTabSlider(isDark),
                    ),
                    const SizedBox(height: 24),
                    _AnimatedSlideUp(
                      delay: 200,
                      child: _buildSectionTitle('UNIT COMPREHENSIVE SPECIFICATIONS', isDark),
                    ),
                    const SizedBox(height: 12),
                    _buildAnimatedSpecsGrid(selectedUnit, isDark),
                    const SizedBox(height: 24),
                    _AnimatedSlideUp(
                      delay: 300,
                      child: _buildSectionTitle('FINANCIAL SUMMARY & INSTALMENTS', isDark),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSlideUp(
                      delay: 350,
                      child: _buildFinancialSummaryPanel(selectedUnit, isDark),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildPersistentActionUtilityBar(selectedUnit, isDark),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return InteractiveTapBounce(
      onTap: onTap,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white.withAlpha(220),
        child: Icon(icon, color: AppColors.textDark, size: 18),
      ),
    );
  }

  Widget _buildLiveInventoryTabSlider(bool isDark) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return SizedBox(
      height: 68,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _units.length,
        itemBuilder: (context, idx) {
          final unit = _units[idx];
          final bool isSelected = _selectedUnitIndex == idx;

          return InteractiveTapBounce(
            onTap: () {
              setState(() {
                _selectedUnitIndex = idx;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 125,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.accent : AppColors.primary)
                    : cardBg,
                borderRadius: AppBorderRadius.medium,
                boxShadow: isSelected
                    ? (isDark ? AppShadows.darkElevated : AppShadows.elevated)
                    : (isDark ? AppShadows.darkSoft : AppShadows.soft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          unit.unitNumber,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: isSelected ? Colors.white : textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: unit.isVacant ? AppColors.success : textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    unit.configuration,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: isSelected ? Colors.white70 : textMuted,
                      fontSize: 9.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedSpecsGrid(UnitModel unit, bool isDark) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    final List<Map<String, String>> specs = [
      {'label': 'ASSET CLASS', 'val': unit.assetClass},
      {'label': 'FURNISHING', 'val': unit.furnishingStatus},
      {'label': 'PRICE/SQFT', 'val': '${unit.pricePerSqFt.toInt()} EGP'},
      {'label': 'PARKING', 'val': '${unit.parkingSpaces} BAYS'},
      {'label': 'PHASE', 'val': unit.constructionPhase},
      {'label': 'STATUS', 'val': unit.isVacant ? 'VACANT' : 'RESERVED'},
      {'label': 'FLOOR', 'val': unit.floorTier},
      {'label': 'AREA', 'val': '${unit.areaSquareMeters.toInt()} m²'},
      {'label': 'UNIT CODE', 'val': unit.unitNumber},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: specs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final item = specs[index];
        return _AnimatedSlideUp(
          delay: 200 + (index * 40),
          child: Container(
            padding: const EdgeInsets.all(10.0),
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
                  item['label']!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['val']!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialSummaryPanel(UnitModel unit, bool isDark) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    final basePrice = unit.priceEGP;
    final vat = basePrice * 0.05;
    final netPrice = basePrice + vat;

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppBorderRadius.large,
        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFinancialRow('Unit Base Price', _formatPrice(basePrice), isDark: isDark),
          const SizedBox(height: 6),
          _buildFinancialRow('Government Tax (VAT 5%)', _formatPrice(vat), isDark: isDark),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 20),
          _buildFinancialRow(
            'Total Client Net Due',
            _formatPrice(netPrice),
            isTotal: true,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          Text(
            'INSTALMENT TIMELINE SCHEDULER',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          ...unit.paymentMilestones.map((milestone) {
            final milestoneAmount = netPrice * (milestone.percentageDue / 100);
            return _buildMilestoneStep(
              '${milestone.title} (${milestone.isPaid ? "Paid" : "Due"})',
              '${_formatPrice(milestoneAmount)} (${milestone.percentageDue.toInt()}%)',
              milestone.isPaid,
              isDark: isDark,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isTotal = false, required bool isDark}) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: isTotal ? textColor : textMuted,
            fontSize: isTotal ? 13.5 : 11.5,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: isTotal ? AppColors.accent : textColor,
            fontSize: isTotal ? 15 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneStep(String label, String value, bool isPassed, {required bool isDark}) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
            color: isPassed ? AppColors.success : textMuted,
            size: 15,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: isPassed ? textColor : textMuted,
                fontSize: 11.5,
                fontWeight: isPassed ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: isPassed ? textColor : textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistentActionUtilityBar(UnitModel unit, bool isDark) {
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _showCompareDialog(context, unit, isDark),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.pill,
                    ),
                  ),
                  child: Text(
                    'COMPARE UNIT',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _viewSecureDocument(
                    context,
                    'Proforma Invoice - ${unit.unitNumber}',
                    'https://gateway.iliving.com.eg/escrow/invoice_${unit.unitNumber}.pdf',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.pill,
                    ),
                  ),
                  child: const Text(
                    'PROFORMA INVOICE',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return '${(price / 1000000).toStringAsFixed(1)}M EGP';
  }

  void _showCompareDialog(BuildContext context, UnitModel active, bool isDark) {
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
                'UNIT MATRIX COMPARE',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildCompareRow('Metric', 'Active Unit', 'Standard Spec', isHeader: true, isDark: isDark),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 16),
              _buildCompareRow('Number', active.unitNumber, 'AJ/27/STD', isDark: isDark),
              _buildCompareRow('Config', active.configuration, '1 BR + Den', isDark: isDark),
              _buildCompareRow('Parking', '${active.parkingSpaces} spaces', '1 space', isDark: isDark),
              _buildCompareRow('Premium', 'Bespoke Line', 'Standard Line', isDark: isDark),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompareRow(String metric, String activeVal, String targetVal, {bool isHeader = false, required bool isDark}) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              metric,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 11,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              activeVal,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: isHeader ? textColor : AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              targetVal,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 11,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSlideUp extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedSlideUp({
    required this.child,
    required this.delay,
  });

  @override
  State<_AnimatedSlideUp> createState() => _AnimatedSlideUpState();
}

class _AnimatedSlideUpState extends State<_AnimatedSlideUp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
