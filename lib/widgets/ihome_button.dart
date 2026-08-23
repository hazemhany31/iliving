import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum IHomeButtonVariant {
  primary,   // Charcoal in light mode / Accent in dark mode
  accent,    // Accent soft blue
  highlight, // Coral / Pink
  outlined,  // Transparent with subtle border
  ghost,     // Transparent with text
}

/// Pill-shaped button matching the Abu Hossain real estate reference ("Get Started", "Book Now").
class IHomeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IHomeButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final double? width;
  final double height;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const IHomeButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = IHomeButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.width,
    this.height = 54,
    this.fontSize = 15,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case IHomeButtonVariant.primary:
        bg = isDark ? AppColors.accent : AppColors.primary;
        fg = Colors.white;
        border = null;
        break;
      case IHomeButtonVariant.accent:
        bg = AppColors.accent;
        fg = Colors.white;
        border = null;
        break;
      case IHomeButtonVariant.highlight:
        bg = AppColors.highlight;
        fg = Colors.white;
        border = null;
        break;
      case IHomeButtonVariant.outlined:
        bg = Colors.transparent;
        fg = isDark ? AppColors.textLight : AppColors.textDark;
        border = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        );
        break;
      case IHomeButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? AppColors.accent : AppColors.primary;
        border = null;
        break;
    }

    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fg,
            letterSpacing: 0.2,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18, color: fg),
        ],
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.pill,
            side: border ?? BorderSide.none,
          ),
          shadowColor: Colors.transparent,
        ),
        child: buttonChild,
      ),
    );
  }
}
