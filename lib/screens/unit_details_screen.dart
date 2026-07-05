import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../models/compound_model.dart';
import '../models/unit_model.dart';
import '../repositories/compound_repository.dart';
import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';
import 'document_viewer_screen.dart';

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
    return Scaffold(
      backgroundColor: LuxuryTheme.backgroundBlack,
      body: _isLoading ? _buildLoadingView() : _buildLoadedView(),
    );
  }

  Widget _buildLoadingView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: LuxuryTheme.primaryGold, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(child: const LuxuryShimmer(width: double.infinity, height: 20)),
              ],
            ),
            const SizedBox(height: 24),
            const LuxuryShimmer(width: double.infinity, height: 260),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) => const LuxuryShimmer(width: double.infinity, height: 60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedView() {
    final selectedUnit = _units[_selectedUnitIndex];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: LuxuryTheme.backgroundBlack,
              leading: CircleAvatar(
                backgroundColor: Colors.black.withAlpha(128),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: LuxuryTheme.primaryGold, size: 18),
                  onPressed: () => Navigator.pop(context),
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
                        return Image.network(
                          _mediaImages[idx],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(color: LuxuryTheme.cardBrown),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            LuxuryTheme.backgroundBlack.withAlpha(230),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      right: 16,
                      child: Row(
                        children: [
                          _buildCircleButton(Icons.bookmark_border_outlined, () {}),
                          const SizedBox(width: 8),
                          _buildCircleButton(Icons.share_outlined, () {}),
                          const SizedBox(width: 8),
                          _buildCircleButton(Icons.map_outlined, () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening secure location routing...'),
                                backgroundColor: LuxuryTheme.primaryGold,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      right: 20,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(102),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: LuxuryTheme.primaryGold.withAlpha(128), width: 1),
                            ),
                            child: Text(
                              '${_activeMediaIndex + 1} / ${_mediaImages.length}',
                              style: const TextStyle(
                                color: LuxuryTheme.primaryGold,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.compound.title,
                                style: const TextStyle(
                                  color: LuxuryTheme.textWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: LuxuryTheme.primaryGold, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.compound.location,
                                    style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: LuxuryTheme.cardBrown,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: LuxuryTheme.primaryGold, width: 1),
                            ),
                            child: const Text(
                              'VERSACE COLLAB',
                              style: TextStyle(
                                color: LuxuryTheme.primaryGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AnimatedSlideUp(
                      delay: 100,
                      child: _buildSectionTitle('LIVE VACANT UNITS INVENTORY'),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSlideUp(
                      delay: 150,
                      child: _buildLiveInventoryTabSlider(),
                    ),
                    const SizedBox(height: 24),
                    _AnimatedSlideUp(
                      delay: 200,
                      child: _buildSectionTitle('UNIT COMPREHENSIVE SPECIFICATIONS'),
                    ),
                    const SizedBox(height: 12),
                    _buildAnimatedSpecsGrid(selectedUnit),
                    const SizedBox(height: 24),
                    _AnimatedSlideUp(
                      delay: 300,
                      child: _buildSectionTitle('FINANCIAL SUMMARY & INSTALMENTS'),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedSlideUp(
                      delay: 350,
                      child: _buildFinancialSummaryPanel(selectedUnit),
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
          child: _buildPersistentActionUtilityBar(selectedUnit),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: LuxuryTheme.primaryGold,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return InteractiveTapBounce(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: Colors.black.withAlpha(128),
        child: Icon(icon, color: LuxuryTheme.primaryGold, size: 20),
      ),
    );
  }

  Widget _buildLiveInventoryTabSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double totalWidth = constraints.maxWidth;
        double selectorWidth = totalWidth / _units.length;

        return Container(
          height: 70,
          decoration: BoxDecoration(
            color: LuxuryTheme.backgroundDarkBrown,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                left: _selectedUnitIndex * selectorWidth,
                top: 2,
                bottom: 2,
                child: Container(
                  width: selectorWidth - 4,
                  decoration: BoxDecoration(
                    color: LuxuryTheme.surfaceBrown,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: LuxuryTheme.primaryGold,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(_units.length, (idx) {
                  final unit = _units[idx];
                  final bool isSelected = _selectedUnitIndex == idx;

                  return Expanded(
                    child: InteractiveTapBounce(
                      onTap: () {
                        setState(() {
                          _selectedUnitIndex = idx;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  unit.unitNumber,
                                  style: TextStyle(
                                    color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.textWhite,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              unit.configuration,
                              style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSpecsGrid(UnitModel unit) {
    final List<Map<String, String>> specs = [
      {'label': 'ASSET CLASS', 'val': unit.assetClass},
      {'label': 'FURNISHING STATUS', 'val': unit.furnishingStatus},
      {'label': 'PRICE PER SQFT', 'val': '${unit.pricePerSqFt.toInt()} EGP'},
      {'label': 'PARKING SPACES', 'val': '${unit.parkingSpaces} BAYS'},
      {'label': 'CURRENT PHASE', 'val': unit.constructionPhase},
      {'label': 'STATUS', 'val': unit.isVacant ? 'VACANT' : 'RESERVED'},
      {'label': 'FLOOR TIER', 'val': unit.floorTier},
      {'label': 'REALISTIC AREA', 'val': '${unit.areaSquareMeters.toInt()} m²'},
      {'label': 'UNIT GEOMETRY', 'val': unit.unitNumber},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: specs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final item = specs[index];
        return _AnimatedSlideUp(
          delay: 200 + (index * 50),
          child: Container(
            padding: const EdgeInsets.all(8.0),
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
                  item['label']!,
                  style: const TextStyle(
                    color: LuxuryTheme.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['val']!,
                  style: const TextStyle(
                    color: LuxuryTheme.primaryGold,
                    fontSize: 10,
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

  Widget _buildFinancialSummaryPanel(UnitModel unit) {
    final basePrice = unit.priceEGP;
    final vat = basePrice * 0.05;
    final netPrice = basePrice + vat;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LuxuryTheme.primaryGold.withAlpha(31),
                LuxuryTheme.surfaceBrown.withAlpha(217),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LuxuryTheme.primaryGold.withAlpha(64), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinancialRow('Unit Premium Base Price', _formatPrice(basePrice)),
              const SizedBox(height: 6),
              _buildFinancialRow('Government Tax (VAT 5%)', _formatPrice(vat)),
              const Divider(color: LuxuryTheme.cardBrown, height: 16),
              _buildFinancialRow(
                'Total Client Net Due',
                _formatPrice(netPrice),
                isTotal: true,
              ),
              const SizedBox(height: 20),
              const Text(
                'INSTALMENT TIMELINE SCHEDULER',
                style: TextStyle(
                  color: LuxuryTheme.primaryGold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              ...unit.paymentMilestones.map((milestone) {
                final milestoneAmount = netPrice * (milestone.percentageDue / 100);
                return _buildMilestoneStep(
                  '${milestone.title} (${milestone.isPaid ? "Paid" : "Due"})',
                  '${_formatPrice(milestoneAmount)} (${milestone.percentageDue.toInt()}%)',
                  milestone.isPaid,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? LuxuryTheme.textWhite : LuxuryTheme.textSilver,
            fontSize: isTotal ? 13 : 11,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? LuxuryTheme.primaryGold : LuxuryTheme.textWhite,
            fontSize: isTotal ? 14 : 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneStep(String label, String value, bool isPassed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.radio_button_off,
            color: isPassed ? LuxuryTheme.primaryGold : LuxuryTheme.textMuted,
            size: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isPassed ? LuxuryTheme.textWhite : LuxuryTheme.textMuted,
                fontSize: 11,
                fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isPassed ? LuxuryTheme.primaryGold : LuxuryTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistentActionUtilityBar(UnitModel unit) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: LuxuryTheme.surfaceBrown.withAlpha(217),
            border: const Border(
              top: BorderSide(color: LuxuryTheme.cardBrown, width: 1.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              childAspectRatio: 2.1,
              children: [
                _buildBarAction('COMPARE UNIT', () => _showCompareDialog(context, unit)),
                _buildBarAction(
                  'GENERATE INVOICE',
                  () => _viewSecureDocument(
                    context,
                    'Proforma Invoice - ${unit.unitNumber}',
                    'https://gateway.ihome.com.eg/escrow/invoice_${unit.unitNumber}.pdf',
                  ),
                ),
                _buildBarAction('ESCROW ACCOUNT', () => _showEscrowDialog(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarAction(String label, VoidCallback onTap) {
    return InteractiveTapBounce(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LuxuryTheme.cardBrown,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: LuxuryTheme.primaryGold, width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: LuxuryTheme.primaryGold,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return '${(price / 1000000).toStringAsFixed(1)}M EGP';
  }

  void _showCompareDialog(BuildContext context, UnitModel active) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Compare Dismiss',
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
                    children: [
                      const Text(
                        'UNIT MATRIX COMPARE',
                        style: TextStyle(
                          color: LuxuryTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCompareRow('Metric', 'Active Unit', 'Standard Spec'),
                      const Divider(color: LuxuryTheme.cardBrown),
                      _buildCompareRow('Number', active.unitNumber, 'AJ/27/STD'),
                      _buildCompareRow('Config', active.configuration, '1 BR + Den'),
                      _buildCompareRow('Parking', '${active.parkingSpaces} spaces', '1 space'),
                      _buildCompareRow('Premium', 'Bespoke Dior', 'Standard Line'),
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

  Widget _buildCompareRow(String metric, String activeVal, String targetVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric, style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 11)),
          Text(activeVal, style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(targetVal, style: const TextStyle(color: LuxuryTheme.textSilver, fontSize: 11)),
        ],
      ),
    );
  }

  void _showEscrowDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Escrow Dismiss',
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
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BROKER SECURE ESCROW',
                        style: TextStyle(
                          color: LuxuryTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Official Escrow Registry Details',
                        style: TextStyle(color: LuxuryTheme.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Beneficiary: iHome Escrow Trust EGP', style: TextStyle(color: LuxuryTheme.textSilver, fontSize: 11)),
                      Text('Bank: National Bank of Egypt (NBE) (Headquarters)', style: TextStyle(color: LuxuryTheme.textSilver, fontSize: 11)),
                      Text('IBAN: EG22 0020 0000 1194 0009 942', style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('Swift Code: NBEGEGXXXX', style: TextStyle(color: LuxuryTheme.textSilver, fontSize: 11)),
                      SizedBox(height: 16),
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
