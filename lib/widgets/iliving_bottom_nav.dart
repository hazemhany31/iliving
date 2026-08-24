import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ILivingNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? badge;

  const ILivingNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge,
  });
}

/// Floating pill bottom navigation bar matching the reference image.
class ILivingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ILivingNavItem> items;
  final double height;

  const ILivingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.height = 68,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : Colors.white.withAlpha(245);
    final activeColor = isDark ? AppColors.accent : AppColors.primary;
    final inactiveColor = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppBorderRadius.round,
        boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 16 : 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.accent.withAlpha(30) : AppColors.primary.withAlpha(15))
                          : Colors.transparent,
                      borderRadius: AppBorderRadius.pill,
                    ),
                    child: Icon(
                      isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                      size: 22,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 4 : 0,
                    height: isSelected ? 4 : 0,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
