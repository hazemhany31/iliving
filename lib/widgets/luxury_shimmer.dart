import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';

class LuxuryShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LuxuryShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<LuxuryShimmer> createState() => _LuxuryShimmerState();
}

class _LuxuryShimmerState extends State<LuxuryShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                LuxuryTheme.surfaceBrown,
                LuxuryTheme.cardBrown,
                LuxuryTheme.primaryGold,
                LuxuryTheme.cardBrown,
                LuxuryTheme.surfaceBrown,
              ],
              stops: [
                0.0,
                (_animation.value - 0.4).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.4).clamp(0.0, 1.0),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

class LuxuryShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  const LuxuryShimmerGrid({
    super.key,
    this.itemCount = 3,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.8,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LuxuryShimmer(width: 180, height: 20),
          const SizedBox(height: 16),
          const LuxuryShimmer(width: double.infinity, height: 200),
          const SizedBox(height: 24),
          const LuxuryShimmer(width: 140, height: 14),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) => const LuxuryShimmer(
              width: double.infinity,
              height: 120,
            ),
          ),
        ],
      ),
    );
  }
}
