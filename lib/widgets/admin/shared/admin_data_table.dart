import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'state_widgets.dart';

class AdminTableColumn<T> {
  final String title;
  final Widget Function(T item) cellBuilder;
  final double? width;
  final bool isSortable;
  final String? sortFieldKey;
  final Alignment alignment;

  const AdminTableColumn({
    required this.title,
    required this.cellBuilder,
    this.width,
    this.isSortable = false,
    this.sortFieldKey,
    this.alignment = Alignment.centerLeft,
  });
}

class AdminDataTable<T> extends StatelessWidget {
  final List<T> items;
  final List<AdminTableColumn<T>> columns;
  final bool isLoading;
  final String? emptyTitle;
  final String? emptyMessage;
  final String? sortColumnKey;
  final bool sortAscending;
  final ValueChanged<String>? onSort;
  final ValueChanged<T>? onItemTap;
  final List<Widget> Function(T item)? rowActions;
  final Set<T> selectedItems;
  final ValueChanged<Set<T>>? onSelectionChanged;

  const AdminDataTable({
    super.key,
    required this.items,
    required this.columns,
    this.isLoading = false,
    this.emptyTitle,
    this.emptyMessage,
    this.sortColumnKey,
    this.sortAscending = true,
    this.onSort,
    this.onItemTap,
    this.rowActions,
    this.selectedItems = const {},
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    if (isLoading) {
      return LoadingState(message: l10n?.loading ?? 'Loading...');
    }

    if (items.isEmpty) {
      return EmptyState(
        title: emptyTitle ?? l10n?.noData ?? 'No data available',
        description: emptyMessage ?? l10n?.noData ?? 'No data available',
        icon: Icons.table_rows_outlined,
      );
    }

    final bool hasSelection = onSelectionChanged != null;
    final bool allSelected = hasSelection && items.isNotEmpty && items.every((i) => selectedItems.contains(i));

    return Container(
      decoration: AppDecorations.card(isDark: isDark),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: hasSelection,
            headingRowColor: WidgetStateProperty.all(
              isDark ? AppColors.darkSurface : AppColors.lightCard,
            ),
            dataRowMinHeight: 52,
            dataRowMaxHeight: 64,
            horizontalMargin: 16,
            columnSpacing: 24,
            dividerThickness: 1,
            columns: [
              if (hasSelection)
                DataColumn(
                  label: Checkbox(
                    value: allSelected,
                    onChanged: (val) {
                      if (val == true) {
                        onSelectionChanged!(Set.from(items));
                      } else {
                        onSelectionChanged!({});
                      }
                    },
                  ),
                ),
              ...columns.map((col) {
                return DataColumn(
                  label: Container(
                    width: col.width,
                    alignment: col.alignment,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          col.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textLightSecondary : AppColors.textDark,
                          ),
                        ),
                        if (col.isSortable && col.sortFieldKey != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            sortColumnKey == col.sortFieldKey
                                ? (sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                : Icons.unfold_more,
                            size: 16,
                            color: sortColumnKey == col.sortFieldKey
                                ? AppColors.accent
                                : (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  onSort: (col.isSortable && col.sortFieldKey != null && onSort != null)
                      ? (_, __) => onSort!(col.sortFieldKey!)
                      : null,
                );
              }),
              if (rowActions != null)
                DataColumn(
                  label: Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n?.actions ?? 'Actions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
            ],
            rows: items.map((item) {
              final isSelected = selectedItems.contains(item);

              return DataRow(
                selected: isSelected,
                onSelectChanged: (val) {
                  if (hasSelection) {
                    final updated = Set<T>.from(selectedItems);
                    if (val == true) {
                      updated.add(item);
                    } else {
                      updated.remove(item);
                    }
                    onSelectionChanged!(updated);
                  } else if (onItemTap != null) {
                    onItemTap!(item);
                  }
                },
                cells: [
                  ...columns.map((col) {
                    return DataCell(
                      Container(
                        width: col.width,
                        alignment: col.alignment,
                        child: col.cellBuilder(item),
                      ),
                    );
                  }),
                  if (rowActions != null)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: rowActions!(item),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
