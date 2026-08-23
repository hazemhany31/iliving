import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'admin_search_filter_models.dart';

class FilterFieldGroup<T> {
  final String key;
  final String title;
  final List<AdminFilterOption<T>> options;
  final T? selectedValue;

  const FilterFieldGroup({
    required this.key,
    required this.title,
    required this.options,
    this.selectedValue,
  });
}

class AdminFilterBar extends StatelessWidget {
  final List<FilterFieldGroup> filterGroups;
  final ValueChanged<FilterFieldGroup> onFilterChanged;
  final VoidCallback onClearAll;
  final int activeCount;

  const AdminFilterBar({
    super.key,
    required this.filterGroups,
    required this.onFilterChanged,
    required this.onClearAll,
    this.activeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...filterGroups.map((group) => _buildFilterDropdown(context, group, isDark)),
        if (activeCount > 0)
          TextButton.icon(
            onPressed: onClearAll,
            icon: const Icon(Icons.close, size: 14),
            label: Text('Clear Filters ($activeCount)'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context,
    FilterFieldGroup group,
    bool isDark,
  ) {
    final bool hasSelection = group.selectedValue != null && group.selectedValue != '';

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: hasSelection
            ? AppColors.accent.withAlpha(isDark ? 35 : 20)
            : (isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt),
        borderRadius: AppBorderRadius.pill,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: group.selectedValue,
          hint: Text(
            group.title,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: hasSelection ? FontWeight.bold : FontWeight.normal,
            color: hasSelection
                ? AppColors.accent
                : (isDark ? AppColors.textLight : AppColors.textDark),
          ),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          items: [
            DropdownMenuItem<dynamic>(
              value: null,
              child: Text(
                'All ${group.title}',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                ),
              ),
            ),
            ...group.options.map((opt) {
              return DropdownMenuItem<dynamic>(
                value: opt.value,
                child: Text(
                  opt.count != null ? '${opt.label} (${opt.count})' : opt.label,
                  style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 12),
                ),
              );
            }),
          ],
          onChanged: (val) {
            onFilterChanged(
              FilterFieldGroup(
                key: group.key,
                title: group.title,
                options: group.options,
                selectedValue: val,
              ),
            );
          },
        ),
      ),
    );
  }
}
