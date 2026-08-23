import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

enum ExportFormat { csv, json, pdf }

class ExportButton extends StatefulWidget {
  final ValueChanged<ExportFormat>? onExport;
  final bool isLoading;
  final String label;

  const ExportButton({
    super.key,
    this.onExport,
    this.isLoading = false,
    this.label = 'Export',
  });

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isLoading) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<ExportFormat>(
      onSelected: (format) {
        if (widget.onExport != null) {
          widget.onExport!(format);
        }
      },
      tooltip: 'Export Data',
      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.small,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<ExportFormat>(
          value: ExportFormat.csv,
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, size: 18, color: AppColors.success),
              SizedBox(width: 10),
              Text('Export as CSV (.csv)'),
            ],
          ),
        ),
        const PopupMenuItem<ExportFormat>(
          value: ExportFormat.json,
          child: Row(
            children: [
              Icon(Icons.code_rounded, size: 18, color: AppColors.accent),
              SizedBox(width: 10),
              Text('Export as JSON (.json)'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
          borderRadius: AppBorderRadius.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_rounded,
              size: 18,
              color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
