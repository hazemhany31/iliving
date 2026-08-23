import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/luxury_theme.dart';
import '../services/auth_service.dart';
import '../models/auth_model.dart';

/// Default luxury fallback avatar URL
const String kDefaultAvatarUrl =
    'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=200';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final Color borderColor;
  final double borderWidth;
  final bool showEditBadge;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.radius = 28,
    this.borderColor = LuxuryTheme.primaryGold,
    this.borderWidth = 2,
    this.showEditBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthService.instance.stateNotifier,
      builder: (context, state, child) {
        final profile = AuthService.instance.currentProfile;
        final effectiveUrl = avatarUrl ?? profile?.avatarUrl;

        Widget avatarImage;
        if (effectiveUrl == null || effectiveUrl.trim().isEmpty) {
          avatarImage = _buildDefaultAvatar();
        } else if (effectiveUrl.startsWith('http://') ||
            effectiveUrl.startsWith('https://')) {
          avatarImage = CachedNetworkImage(
            imageUrl: effectiveUrl,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
            placeholder: (context, url) => Center(
              child: SizedBox(
                width: radius,
                height: radius,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(borderColor),
                ),
              ),
            ),
            errorWidget: (context, url, error) => _buildDefaultAvatar(),
          );
        } else {
          avatarImage = _buildDefaultAvatar();
        }

        Widget avatarContent = Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LuxuryTheme.surfaceBrown,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: ClipOval(
            child: avatarImage,
          ),
        );

        if (showEditBadge) {
          avatarContent = Stack(
            children: [
              avatarContent,
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: LuxuryTheme.primaryGold,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: LuxuryTheme.backgroundBlack,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 12,
                    color: LuxuryTheme.backgroundBlack,
                  ),
                ),
              ),
            ],
          );
        }

        if (onTap != null) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: avatarContent,
          );
        }

        return avatarContent;
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: LuxuryTheme.cardBrown,
      child: Center(
        child: Icon(
          Icons.person,
          size: radius * 1.1,
          color: LuxuryTheme.primaryGold,
        ),
      ),
    );
  }
}
