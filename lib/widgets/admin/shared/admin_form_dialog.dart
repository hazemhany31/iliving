import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AdminFormDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget body;
  final String submitLabel;
  final String cancelLabel;
  final Future<void> Function()? onSubmit;
  final double maxWidth;

  const AdminFormDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.body,
    this.submitLabel = 'Save Changes',
    this.cancelLabel = 'Cancel',
    this.onSubmit,
    this.maxWidth = 560,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    required Widget body,
    String submitLabel = 'Save Changes',
    String cancelLabel = 'Cancel',
    Future<void> Function()? onSubmit,
    double maxWidth = 560,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminFormDialog(
        title: title,
        subtitle: subtitle,
        icon: icon,
        body: body,
        submitLabel: submitLabel,
        cancelLabel: cancelLabel,
        onSubmit: onSubmit,
        maxWidth: maxWidth,
      ),
    );
  }

  @override
  State<AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<AdminFormDialog> {
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (widget.onSubmit == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit!().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint("[AdminFormDialog] onSubmit execution timed out or completed asynchronously.");
        },
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(isDark ? 40 : 25),
                        borderRadius: AppBorderRadius.small,
                      ),
                      child: Icon(widget.icon, size: 20, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textLight : AppColors.textDark,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 480 ? 16 : 24,
                  vertical: 20,
                ),
                child: widget.body,
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            // Footer Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: Text(widget.cancelLabel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.submitLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
