import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Premium card container matching the Abu Hossain real estate design system.
/// Features clean white surface, generous corner radius (16px), and ultra-soft floating shadows.
class IHomeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? customShadow;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  const IHomeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.customShadow,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? AppBorderRadius.medium;
    final bg = backgroundColor ?? (isDark ? AppColors.darkCard : AppColors.lightCard);
    final shadows = customShadow ?? (isDark ? AppShadows.dark : AppShadows.soft);

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: r,
        border: border,
        boxShadow: shadows,
      ),
      clipBehavior: clipBehavior,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          child: content,
        ),
      );
    }

    return content;
  }
}
