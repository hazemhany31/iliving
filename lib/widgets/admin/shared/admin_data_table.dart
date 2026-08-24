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

class AdminDataTable<T> extends StatefulWidget {
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
  final int pageSize;
  final bool enablePagination;

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
    this.pageSize = 15,
    this.enablePagination = true,
  });

  @override
  State<AdminDataTable<T>> createState() => _AdminDataTableState<T>();
}

class _AdminDataTableState<T> extends State<AdminDataTable<T>> {
  int _currentPage = 1;

  @override
  void didUpdateWidget(covariant AdminDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final totalPages = widget.pageSize > 0 ? (widget.items.length / widget.pageSize).ceil() : 1;
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    if (widget.isLoading) {
      return LoadingState(message: l10n?.loading ?? 'Loading...');
    }

    if (widget.items.isEmpty) {
      return EmptyState(
        title: widget.emptyTitle ?? l10n?.noData ?? 'No data available',
        description: widget.emptyMessage ?? l10n?.noData ?? 'No data available',
        icon: Icons.table_rows_outlined,
      );
    }

    final bool hasSelection = widget.onSelectionChanged != null;
    final bool allSelected = hasSelection &&
        widget.items.isNotEmpty &&
        widget.items.every((i) => widget.selectedItems.contains(i));

    final totalItems = widget.items.length;
    final pageSize = widget.pageSize;
    final bool paginate = widget.enablePagination && pageSize > 0 && totalItems > pageSize;
    final totalPages = paginate ? (totalItems / pageSize).ceil() : 1;
    final currentPage = _currentPage.clamp(1, totalPages);

    final displayedItems = paginate
        ? widget.items.skip((currentPage - 1) * pageSize).take(pageSize).toList()
        : widget.items;

    final startIdx = paginate ? (currentPage - 1) * pageSize + 1 : 1;
    final endIdx = paginate ? (startIdx + displayedItems.length - 1) : totalItems;

    return Container(
      decoration: AppDecorations.card(isDark: isDark),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
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
                            widget.onSelectionChanged!(Set.from(widget.items));
                          } else {
                            widget.onSelectionChanged!({});
                          }
                        },
                      ),
                    ),
                  ...widget.columns.map((col) {
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
                                widget.sortColumnKey == col.sortFieldKey
                                    ? (widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                    : Icons.unfold_more,
                                size: 16,
                                color: widget.sortColumnKey == col.sortFieldKey
                                    ? AppColors.accent
                                    : (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      onSort: (col.isSortable && col.sortFieldKey != null && widget.onSort != null)
                          ? (_, __) => widget.onSort!(col.sortFieldKey!)
                          : null,
                    );
                  }),
                  if (widget.rowActions != null)
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
                rows: displayedItems.map((item) {
                  final isSelected = widget.selectedItems.contains(item);

                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (val) {
                      if (hasSelection) {
                        final updated = Set<T>.from(widget.selectedItems);
                        if (val == true) {
                          updated.add(item);
                        } else {
                          updated.remove(item);
                        }
                        widget.onSelectionChanged!(updated);
                      } else if (widget.onItemTap != null) {
                        widget.onItemTap!(item);
                      }
                    },
                    cells: [
                      ...widget.columns.map((col) {
                        return DataCell(
                          Container(
                            width: col.width,
                            alignment: col.alignment,
                            child: col.cellBuilder(item),
                          ),
                        );
                      }),
                      if (widget.rowActions != null)
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: widget.rowActions!(item),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        if (paginate) ...[
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isVeryNarrow = constraints.maxWidth < 340;
                  final infoWidget = Text(
                    'Showing $startIdx–$endIdx of $totalItems',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                    ),
                  );

                  final navRow = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: currentPage > 1
                            ? () => setState(() => _currentPage = currentPage - 1)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Page $currentPage of $totalPages',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textLight : AppColors.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: currentPage < totalPages
                            ? () => setState(() => _currentPage = currentPage + 1)
                            : null,
                      ),
                    ],
                  );

                  if (isVeryNarrow) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        infoWidget,
                        const SizedBox(height: 2),
                        navRow,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: infoWidget),
                      const SizedBox(width: 8),
                      navRow,
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
