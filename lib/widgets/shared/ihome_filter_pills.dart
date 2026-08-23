import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class IHomeFilterOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? badge;

  const IHomeFilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.badge,
  });
}

/// Horizontal scrolling pill segmented filter matching the reference design.
/// (e.g., [🏢 Apartment] [🏡 Home] [🏬 Office])
class IHomeFilterPills<T> extends StatelessWidget {
  final List<IHomeFilterOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  const IHomeFilterPills({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.value == selectedValue;

          final Color bg = isSelected
              ? (isDark ? AppColors.accent : AppColors.primary)
              : (isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt);

          final Color fg = isSelected
              ? Colors.white
              : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary);

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(opt.value),
                borderRadius: AppBorderRadius.pill,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: AppBorderRadius.pill,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDark ? AppColors.accent : AppColors.primary).withAlpha(40),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (opt.icon != null) ...[
                        Icon(opt.icon, size: 16, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: fg,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (opt.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withAlpha(50)
                                : (isDark ? AppColors.darkCard : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            opt.badge!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textDarkMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
