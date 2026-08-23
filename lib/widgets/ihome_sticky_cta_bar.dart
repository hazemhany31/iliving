import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ihome_button.dart';

/// Sticky bottom CTA bar matching the detail sheet in the reference image.
/// Left side: price / amount with meta label.
/// Right side: pill action button.
class IHomeStickyCtaBar extends StatelessWidget {
  final String priceLabel;
  final String priceValue;
  final String? pricePeriod;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final IHomeButtonVariant buttonVariant;
  final bool isLoading;

  const IHomeStickyCtaBar({
    super.key,
    this.priceLabel = 'Price',
    required this.priceValue,
    this.pricePeriod,
    required this.buttonText,
    required this.onButtonPressed,
    this.buttonVariant = IHomeButtonVariant.highlight,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : Colors.white;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        14,
        AppSpacing.pageHorizontal,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
      ),
      child: Row(
        children: [
          // Price information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  priceLabel,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      priceValue,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textLight : AppColors.textDark,
                      ),
                    ),
                    if (pricePeriod != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        pricePeriod!,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // CTA Button
          IHomeButton(
            text: buttonText,
            onPressed: onButtonPressed,
            variant: buttonVariant,
            isLoading: isLoading,
            height: 48,
          ),
        ],
      ),
    );
  }
}
