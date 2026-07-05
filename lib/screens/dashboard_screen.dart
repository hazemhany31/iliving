import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../models/compound_model.dart';
import '../repositories/compound_repository.dart';
import '../models/unit_price_tick.dart';
import '../widgets/progress_wheel.dart';
import '../widgets/luxury_sidebar.dart';
import '../widgets/luxury_shimmer.dart';
import '../widgets/interactive_tap_bounce.dart';
import 'unit_details_screen.dart';
import '../services/sync_state.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _pageController;
  double _pageOffset = 0.0;
  bool _isLoading = true;

  final CompoundRepository _repository = CompoundRepository();
  List<CompoundModel> _compounds = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0.0;
      });
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final compounds = await _repository.fetchCompounds();
    if (mounted) {
      setState(() {
        _compounds = compounds;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: LuxuryTheme.backgroundBlack,
      drawer: const LuxurySidebar(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: true,
            backgroundColor: LuxuryTheme.backgroundBlack,
            leading: IconButton(
              icon: const Icon(Icons.menu_open_sharp, color: LuxuryTheme.primaryGold, size: 28),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: const Text(
              'iHOME SALES & BROKERAGE',
              style: TextStyle(
                color: LuxuryTheme.primaryGold,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading ? _buildShimmerView() : _buildContentGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 230,
            decoration: BoxDecoration(
              color: LuxuryTheme.surfaceBrown,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const LuxuryShimmer(width: double.infinity, height: 230),
          ),
          const SizedBox(height: 24),
          const LuxuryShimmer(width: 150, height: 16),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.6,
            ),
            itemBuilder: (context, index) => const LuxuryShimmer(width: double.infinity, height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroSlider(),
        _buildSectionHeader('EGYPTIAN LUXURY PORTFOLIO'),
        _buildProjectsGrid3Column(),
        _buildSectionHeader('LIVE CONSTRUCTION PROGRESS'),
        _buildConstructionGrid3Column(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 28.0, bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: LuxuryTheme.primaryGold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
            ),
          ),
          Container(width: 80, height: 1.5, color: LuxuryTheme.cardBrown),
        ],
      ),
    );
  }

  Widget _buildHeroSlider() {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _compounds.length,
            itemBuilder: (context, index) {
              final compound = _compounds[index];
              double offset = 0.0;
              if (_pageController.position.haveDimensions) {
                offset = _pageOffset - index;
              }
              double translationBg = offset * 45.0;
              double translationFg = offset * -140.0;
              double textOpacity = (1.0 - offset.abs().clamp(0.0, 1.0));

              return ClipRRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform.translate(
                      offset: Offset(translationBg, 0),
                      child: Image.network(
                        compound.heroImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: LuxuryTheme.cardBrown),
                      ),
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
                      bottom: 24,
                      left: 20,
                      right: 20,
                      child: Transform.translate(
                        offset: Offset(translationFg, 0),
                        child: Opacity(
                          opacity: textOpacity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: LuxuryTheme.primaryGold,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'EXCLUSIVE NEW CAMPAIGN',
                                  style: TextStyle(
                                    color: LuxuryTheme.backgroundBlack,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                compound.title,
                                style: const TextStyle(
                                  color: LuxuryTheme.textWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${compound.description.split('.').first}.',
                                style: const TextStyle(
                                  color: LuxuryTheme.textSilver,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            right: 20,
            child: Row(
              children: List.generate(_compounds.length, (index) {
                double currentActive = (_pageOffset - index).abs();
                double width = lerpDouble(6.0, 16.0, (1.0 - currentActive).clamp(0.0, 1.0)) ?? 6.0;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: width,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: currentActive < 0.5 ? LuxuryTheme.primaryGold : LuxuryTheme.textMuted,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsGrid3Column() {
    final syncState = SyncScope.of(context);
    return StreamBuilder<List<UnitPriceTick>>(
      stream: syncState.priceFeed,
      initialData: syncState.latestPrices,
      builder: (context, snapshot) {
        final ticks = snapshot.data ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _compounds.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.60,
            ),
            itemBuilder: (context, index) {
              final compound = _compounds[index];
              UnitPriceTick? tick;
              for (final t in ticks) {
                if (t.compoundId == compound.id) {
                  tick = t;
                  break;
                }
              }
              final price = tick?.priceEGP ?? compound.basePriceEGP;
              final isLive = tick != null && tick.status == PriceSyncStatus.live;
              final delta = price - compound.basePriceEGP;

              return InteractiveTapBounce(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UnitDetailsScreen(compound: compound),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: LuxuryTheme.surfaceBrown,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                child: Image.network(
                                  compound.cardImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: LuxuryTheme.cardBrown),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: LuxuryTheme.backgroundBlack.withAlpha(200),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: LuxuryTheme.primaryGold, width: 1),
                                ),
                                child: Text(
                                  compound.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: LuxuryTheme.primaryGold,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (isLive)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: _LiveBadge(),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              compound.title,
                              style: const TextStyle(
                                color: LuxuryTheme.textWhite,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              compound.location,
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
                                Text(
                                  '${compound.areaSqFt.toInt()} SQFT',
                                  style: const TextStyle(
                                    color: LuxuryTheme.textSilver,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        if (isLive)
                                          Container(
                                            width: 5,
                                            height: 5,
                                            margin: const EdgeInsets.only(right: 4),
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Text(
                                          '${(price / 1000000).toStringAsFixed(1)}M EGP',
                                          style: const TextStyle(
                                            color: LuxuryTheme.primaryGold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (delta != 0) ...[
                                      const SizedBox(height: 2),
                                      _PriceDeltaChip(delta: delta),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: LuxuryTheme.cardBrown,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text(
                                  'EXPLORE MEDIA & UNITS',
                                  style: TextStyle(
                                    color: LuxuryTheme.textWhite,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
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
        );
      },
    );
  }




  Widget _buildConstructionGrid3Column() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _compounds.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.90,
        ),
        itemBuilder: (context, index) {
          final compound = _compounds[index];
          return ProgressWheel(
            percentage: compound.completionPercentage,
            label: compound.title,
            size: 110,
          );
        },
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: LuxuryTheme.primaryGold,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: LuxuryTheme.backgroundBlack,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              'LIVE',
              style: TextStyle(
                color: LuxuryTheme.backgroundBlack,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceDeltaChip extends StatefulWidget {
  final double delta;
  const _PriceDeltaChip({required this.delta});

  @override
  State<_PriceDeltaChip> createState() => _PriceDeltaChipState();
}

class _PriceDeltaChipState extends State<_PriceDeltaChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(_PriceDeltaChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delta != widget.delta) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.delta > 0;
    final prefix = isPositive ? '+' : '';
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;
    final formattedDelta = '$prefix${(widget.delta / 1000000).toStringAsFixed(1)}M';

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 0.8),
        ),
        child: Text(
          formattedDelta,
          style: TextStyle(
            color: color,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

