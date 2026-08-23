import 'package:flutter/material.dart';
import 'admin_filter_bar.dart';
import 'admin_search_bar.dart';
import 'export_button.dart';

class ResponsiveActionToolbar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;
  final List<FilterFieldGroup> filterGroups;
  final ValueChanged<FilterFieldGroup>? onFilterChanged;
  final VoidCallback? onClearFilters;
  final int activeFilterCount;
  final ValueChanged<ExportFormat>? onExport;
  final bool isExporting;
  final List<Widget> primaryActions;

  const ResponsiveActionToolbar({
    super.key,
    this.searchQuery = '',
    required this.onSearchChanged,
    this.searchHint = 'Search...',
    this.filterGroups = const [],
    this.onFilterChanged,
    this.onClearFilters,
    this.activeFilterCount = 0,
    this.onExport,
    this.isExporting = false,
    this.primaryActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AdminSearchBar(
                      initialQuery: searchQuery,
                      onSearch: onSearchChanged,
                      hintText: searchHint,
                    ),
                  ),
                  if (onExport != null) ...[
                    const SizedBox(width: 8),
                    ExportButton(
                      onExport: onExport,
                      isLoading: isExporting,
                      label: '',
                    ),
                  ],
                ],
              ),
              if (filterGroups.isNotEmpty && onFilterChanged != null) ...[
                const SizedBox(height: 10),
                AdminFilterBar(
                  filterGroups: filterGroups,
                  onFilterChanged: onFilterChanged!,
                  onClearAll: onClearFilters ?? () {},
                  activeCount: activeFilterCount,
                ),
              ],
              if (primaryActions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: primaryActions.map((action) => Expanded(child: action)).toList(),
                ),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: AdminSearchBar(
                initialQuery: searchQuery,
                onSearch: onSearchChanged,
                hintText: searchHint,
              ),
            ),
            const SizedBox(width: 12),
            if (filterGroups.isNotEmpty && onFilterChanged != null) ...[
              AdminFilterBar(
                filterGroups: filterGroups,
                onFilterChanged: onFilterChanged!,
                onClearAll: onClearFilters ?? () {},
                activeCount: activeFilterCount,
              ),
              const SizedBox(width: 12),
            ],
            if (onExport != null) ...[
              ExportButton(
                onExport: onExport,
                isLoading: isExporting,
              ),
              const SizedBox(width: 12),
            ],
            if (primaryActions.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: primaryActions,
              ),
          ],
        );
      },
    );
  }
}
