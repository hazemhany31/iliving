import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../theme/luxury_theme.dart';
import 'luxury_shimmer.dart';

/// Performance-optimized image loader with disk/memory caching and fallback support.
class ImageLoader extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const ImageLoader({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.errorBuilder,
  });

  static bool isNetwork(String path) {
    if (path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  static ImageProvider getImageProvider(String path) {
    if (path.isEmpty) {
      return const AssetImage('images/skyhills/ski-hills.jpg');
    }
    if (isNetwork(path)) {
      return CachedNetworkImageProvider(path);
    } else {
      return AssetImage(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;

    Widget buildErrorWidget() {
      return Container(
        width: width,
        height: height,
        color: fallbackColor,
        child: Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
            size: (height != null && height! < 60) ? 18 : 24,
          ),
        ),
      );
    }

    if (imageUrl.isEmpty) {
      return buildErrorWidget();
    }

    Widget content;

    if (isNetwork(imageUrl)) {
      content = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => LuxuryShimmer(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: 0,
        ),
        errorWidget: (context, url, error) {
          if (errorBuilder != null) {
            return errorBuilder!(context, error, StackTrace.current);
          }
          return buildErrorWidget();
        },
        fadeInDuration: const Duration(milliseconds: 250),
        fadeOutDuration: const Duration(milliseconds: 150),
      );
    } else {
      content = Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          if (errorBuilder != null) {
            return errorBuilder!(context, error, stackTrace);
          }
          return buildErrorWidget();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }
}
