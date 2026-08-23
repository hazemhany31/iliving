import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class AdminPagination extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;

  const AdminPagination({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    this.onPageSizeChanged,
    this.pageSizeOptions = const [10, 25, 50, 100],
  });

  int get totalPages => (totalItems / pageSize).ceil().clamp(1, 999999);
  int get startItem => totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
  int get endItem => (currentPage * pageSize).clamp(0, totalItems);

  bool get canGoPrevious => currentPage > 1;
  bool get canGoNext => currentPage < totalPages;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final infoText = Text(
          l10n?.showingResults(startItem, endItem, totalItems) ?? 'Showing $startItem-$endItem of $totalItems entries',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
          ),
        );

        final pageSizeSelector = onPageSizeChanged != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${l10n?.itemsPerPage ?? 'Items per page'}:',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: AppBorderRadius.small,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: pageSizeOptions.contains(pageSize) ? pageSize : pageSizeOptions.first,
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 18),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                        items: pageSizeOptions.map((size) {
                          return DropdownMenuItem<int>(
                            value: size,
                            child: Text('$size'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            onPageSizeChanged!(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink();

        final navButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First Page
            IconButton(
              icon: const Icon(Icons.first_page, size: 18),
              onPressed: canGoPrevious ? () => onPageChanged(1) : null,
              tooltip: l10n?.back ?? 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            // Previous
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: canGoPrevious ? () => onPageChanged(currentPage - 1) : null,
              tooltip: l10n?.back ?? 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 4),
            // Page badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$currentPage / $totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Next
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: canGoNext ? () => onPageChanged(currentPage + 1) : null,
              tooltip: 'Next Page',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            // Last Page
            IconButton(
              icon: const Icon(Icons.last_page, size: 18),
              onPressed: canGoNext ? () => onPageChanged(totalPages) : null,
              tooltip: 'Last Page',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  infoText,
                  pageSizeSelector,
                ],
              ),
              const SizedBox(height: 8),
              Center(child: navButtons),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                infoText,
                const SizedBox(width: 16),
                pageSizeSelector,
              ],
            ),
            navButtons,
          ],
        );
      },
    );
  }
}
