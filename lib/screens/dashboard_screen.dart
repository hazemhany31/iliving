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
import '../widgets/image_loader.dart';
import '../l10n/app_localizations.dart';

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
    _pageController = PageController(viewportFraction: 0.92);
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
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final iconColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: const LuxurySidebar(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 70,
            floating: true,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            leading: IconButton(
              icon: Icon(Icons.menu_rounded, color: iconColor, size: 24),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Text(
              l10n.salesBrokerage.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search_rounded, color: iconColor, size: 22),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: _isLoading ? _buildShimmerView(isDark) : _buildContentGrid(l10n, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerView(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppBorderRadius.large,
            ),
            child: const LuxuryShimmer(width: double.infinity, height: 240),
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
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.65,
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

  Widget _buildContentGrid(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroSlider(isDark),
        const SizedBox(height: 8),
        _buildSectionHeader(l10n.portfolioTitle, isDark),
        _buildProjectsGrid3Column(isDark),
        const SizedBox(height: 12),
        _buildSectionHeader(l10n.constructionTitle, isDark),
        _buildConstructionGrid3Column(isDark),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(isDark ? 30 : 15),
              borderRadius: AppBorderRadius.pill,
            ),
            child: const Text(
              'EXPLORE ALL',
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
    );
  }

  Widget _buildHeroSlider(bool isDark) {
    if (_compounds.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _compounds.length,
            itemBuilder: (context, index) {
              final compound = _compounds[index];
              double offset = 0.0;
              if (_pageController.position.haveDimensions) {
                offset = _pageOffset - index;
              }
              double translationBg = offset * 30.0;
              double textOpacity = (1.0 - offset.abs().clamp(0.0, 1.0));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: GestureDetector(
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
                      borderRadius: AppBorderRadius.large,
                      boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
                    ),
                    child: ClipRRect(
                      borderRadius: AppBorderRadius.large,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Transform.translate(
                            offset: Offset(translationBg, 0),
                            child: ImageLoader(
                              imageUrl: compound.heroImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                              ),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                stops: [0.0, 0.45, 1.0],
                                colors: [
                                  Color(0xCC1A1A2E),
                                  Color(0x551A1A2E),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(225),
                                borderRadius: AppBorderRadius.pill,
                              ),
                              child: const Text(
                                'FEATURED COMPOUND',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: AppColors.textDark,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Opacity(
                              opacity: textOpacity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    compound.title,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        compound.location,
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${(compound.basePriceEGP / 1000000).toStringAsFixed(1)}M EGP',
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_compounds.length, (index) {
            double currentActive = (_pageOffset - index).abs();
            double width = lerpDouble(6.0, 20.0, (1.0 - currentActive).clamp(0.0, 1.0)) ?? 6.0;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                color: currentActive < 0.5
                    ? AppColors.primary
                    : (isDark ? AppColors.textLightMuted.withAlpha(80) : AppColors.textDarkMuted.withAlpha(80)),
                borderRadius: AppBorderRadius.pill,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProjectsGrid3Column(bool isDark) {
    final syncState = SyncScope.of(context);
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

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
              mainAxisSpacing: 12,
              childAspectRatio: 0.58,
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
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: AppBorderRadius.medium,
                    boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: ImageLoader(
                                  imageUrl: compound.cardImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(220),
                                  borderRadius: AppBorderRadius.pill,
                                ),
                                child: Text(
                                  compound.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: AppColors.textDark,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            if (isLive)
                              Positioned(
                                top: 6,
                                right: 6,
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
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              compound.location,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
                                fontSize: 8.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${compound.areaSqFt.toInt()} SQFT',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textMuted,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${(price / 1000000).toStringAsFixed(1)}M',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: AppColors.accent,
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
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                borderRadius: AppBorderRadius.pill,
                              ),
                              child: Center(
                                child: Text(
                                  'DETAILS',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textColor,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
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

  Widget _buildConstructionGrid3Column(bool isDark) {
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
          return GestureDetector(
            onTap: () => _showConstructionGallery(context, compound, isDark),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppBorderRadius.medium,
                boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
              ),
              child: ProgressWheel(
                percentage: compound.completionPercentage,
                label: compound.title,
                size: 90,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showConstructionGallery(BuildContext context, CompoundModel compound, bool isDark) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: textMuted.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                compound.title,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'LIVE CONSTRUCTION PROGRESS',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: AppColors.accent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                            borderRadius: AppBorderRadius.pill,
                          ),
                          child: Text(
                            '${compound.completionPercentage.toInt()}% COMPLETE',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, thickness: 1),
                  Expanded(
                    child: compound.galleryPhotos.isEmpty
                        ? Center(
                            child: Text(
                              'No construction images available.',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
                              ),
                            ),
                          )
                        : GridView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: compound.galleryPhotos.length,
                            itemBuilder: (context, idx) {
                              final photo = compound.galleryPhotos[idx];
                              return GestureDetector(
                                onTap: () => _openFullscreenGallery(context, compound, idx),
                                child: ClipRRect(
                                  borderRadius: AppBorderRadius.medium,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ImageLoader(
                                        imageUrl: photo.url,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Color(0xCC000000),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        right: 8,
                                        child: Text(
                                          photo.title,
                                          style: const TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openFullscreenGallery(BuildContext context, CompoundModel compound, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          int currentIndex = initialIndex;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    '${compound.title} - Photo ${currentIndex + 1}/${compound.galleryPhotos.length}',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                body: PageView.builder(
                  controller: PageController(initialPage: initialIndex),
                  itemCount: compound.galleryPhotos.length,
                  onPageChanged: (idx) {
                    setDialogState(() {
                      currentIndex = idx;
                    });
                  },
                  itemBuilder: (context, idx) {
                    final photo = compound.galleryPhotos[idx];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Center(
                              child: ImageLoader(
                                imageUrl: photo.url,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: const Color(0xFF101014),
                          width: double.infinity,
                          child: Text(
                            photo.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: AppBorderRadius.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3),
            const Text(
              'LIVE',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.white,
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
    final color = isPositive ? AppColors.success : AppColors.error;
    final formattedDelta = '$prefix${(widget.delta / 1000000).toStringAsFixed(1)}M';

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: AppBorderRadius.pill,
        ),
        child: Text(
          formattedDelta,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: color,
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
