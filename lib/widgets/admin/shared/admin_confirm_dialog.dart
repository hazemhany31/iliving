import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AdminConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? detailText;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final IconData icon;
  final Future<void> Function()? onConfirm;

  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.detailText,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDanger = false,
    this.icon = Icons.warning_amber_rounded,
    this.onConfirm,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? detailText,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
    IconData icon = Icons.warning_amber_rounded,
    Future<void> Function()? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminConfirmDialog(
        title: title,
        message: message,
        detailText: detailText,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
        icon: icon,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<AdminConfirmDialog> createState() => _AdminConfirmDialogState();
}

class _AdminConfirmDialogState extends State<AdminConfirmDialog> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    if (widget.onConfirm == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onConfirm!().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint("[AdminConfirmDialog] onConfirm execution timed out or completed asynchronously.");
        },
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.isDanger ? AppColors.error : AppColors.accent;

    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 16 : 40,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.medium,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: EdgeInsets.all(screenWidth < 600 ? 18 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(isDark ? 40 : 25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 24, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                height: 1.4,
              ),
            ),
            if (widget.detailText != null && widget.detailText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: AppBorderRadius.small,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  widget.detailText!,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppTextStyles.fontFamily,
                    color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                    child: Text(widget.cancelLabel, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.confirmLabel, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
