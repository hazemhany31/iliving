import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/luxury_theme.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../l10n/app_localizations.dart';
import 'user_avatar.dart';

class ProfilePictureDialog extends StatefulWidget {
  const ProfilePictureDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ProfilePictureDialog(),
    );
  }

  @override
  State<ProfilePictureDialog> createState() => _ProfilePictureDialogState();
}

class _ProfilePictureDialogState extends State<ProfilePictureDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _isUploading = false;
  String? _errorMessage;

  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=300',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=300',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=300',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=300',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&q=80&w=300',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=300',
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    final user = AuthService.instance.currentProfile;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image == null) return;

      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      final bytes = await image.readAsBytes();
      final downloadUrl = await StorageService.instance.uploadProfileAvatar(
        userId: user.uid,
        file: bytes,
        fileName: image.name,
      );

      await _updateAvatar(downloadUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = '${l10n.uploadFailed}: ${e.toString()}';
      });
    }
  }

  Future<void> _updateAvatar(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;
    final l10n = AppLocalizations.of(context);

    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      setState(() {
        _errorMessage = l10n.invalidImageUrl;
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.updateProfilePicture(cleanUrl);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profilePictureUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = '${l10n.uploadFailed}: ${e.toString()}';
      });
    }
  }

  Future<void> _removeAvatar() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.removeProfilePicture();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profilePictureRemoved),
          backgroundColor: LuxuryTheme.primaryGold,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = 'Failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentAvatar = AuthService.instance.currentProfile?.avatarUrl;
    final hasCustomAvatar = currentAvatar != null && currentAvatar.trim().isNotEmpty;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.profilePictureTitle.toUpperCase(),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current Avatar Preview
              Stack(
                alignment: Alignment.center,
                children: [
                  const UserAvatar(radius: 44, borderWidth: 3),
                  if (_isUploading)
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Photo Upload Options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => _pickAndUploadPhoto(ImageSource.gallery),
                    icon: Icon(Icons.photo_library_outlined, color: textPrimary, size: 16),
                    label: Text(
                      'Gallery',
                      style: TextStyle(color: textPrimary, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: border, width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => _pickAndUploadPhoto(ImageSource.camera),
                    icon: Icon(Icons.camera_alt_outlined, color: textPrimary, size: 16),
                    label: Text(
                      'Camera',
                      style: TextStyle(color: textPrimary, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: border, width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Error Message if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // URL Input
              TextField(
                controller: _urlController,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: l10n.enterImageUrl,
                  hintText: l10n.imageUrlPlaceholder,
                  hintStyle: TextStyle(color: textMuted, fontSize: 11),
                  prefixIcon: const Icon(Icons.link, color: AppColors.accent, size: 18),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: AppColors.accent, size: 18),
                    onPressed: _isUploading ? null : () => _updateAvatar(_urlController.text),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCardAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                  labelStyle: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Preset Avatars Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.presetAvatars.toUpperCase(),
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presetAvatars.map((url) {
                  final isSelected = currentAvatar == url;
                  return InkWell(
                    onTap: _isUploading ? null : () => _updateAvatar(url),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.accent : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: isDark ? AppColors.darkCard : AppColors.lightCardAlt),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (hasCustomAvatar)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _removeAvatar,
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                        label: Text(
                          l10n.removeProfilePicture,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  if (hasCustomAvatar) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : () => _updateAvatar(_urlController.text),
                      icon: const Icon(Icons.save, color: Colors.white, size: 16),
                      label: Text(
                        l10n.save.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
