import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'image_loader.dart';

/// Luxury Property Card matching the reference design.
/// Features full-bleed rounded image, floating favorite heart, location tag,
/// star rating, price, and clean visual hierarchy.
class ILivingPropertyCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? location;
  final String priceText;
  final String? pricePeriod;
  final String imageUrl;
  final double rating;
  final int? reviewsCount;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final String? ctaText;
  final VoidCallback? onCtaTap;
  final double height;
  final double? width;
  final String? tagText;

  const ILivingPropertyCard({
    super.key,
    required this.title,
    this.subtitle,
    this.location,
    required this.priceText,
    this.pricePeriod,
    required this.imageUrl,
    this.rating = 5.0,
    this.reviewsCount,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.onTap,
    this.ctaText,
    this.onCtaTap,
    this.height = 360,
    this.width,
    this.tagText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.large,
        boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
      ),
      child: ClipRRect(
        borderRadius: AppBorderRadius.large,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background image
            ImageLoader(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                child: Center(
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 48,
                    color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                  ),
                ),
              ),
            ),

            // 2. Smooth gradient scrim for text legibility
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.35, 0.7, 1.0],
                    colors: [
                      Colors.black.withAlpha(25),
                      Colors.transparent,
                      Colors.black.withAlpha(160),
                      Colors.black.withAlpha(235),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Top tags & favorite button
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (tagText != null && tagText!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(225),
                        borderRadius: AppBorderRadius.pill,
                      ),
                      child: Text(
                        tagText!,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (onFavoriteTap != null)
                    Material(
                      color: Colors.white.withAlpha(230),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onFavoriteTap,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFavorite ? AppColors.highlight : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 4. Bottom metadata content
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location pill
                  if (location != null && location!.isNotEmpty) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            location!,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Price & Rating Row
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: priceText,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (pricePeriod != null)
                              TextSpan(
                                text: ' $pricePeriod',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (rating > 0) ...[
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (reviewsCount != null)
                          Text(
                            ' ($reviewsCount)',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ],
                  ),

                  // Optional CTA Button
                  if (ctaText != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onCtaTap ?? onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(235),
                          foregroundColor: AppColors.textDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppBorderRadius.pill,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ctaText!,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.textDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Tap surface
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: AppBorderRadius.large,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
