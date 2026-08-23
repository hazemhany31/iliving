import 'package:flutter/foundation.dart';

@immutable
class AdminFilterOption<T> {
  final String label;
  final T value;
  final int? count;

  const AdminFilterOption({
    required this.label,
    required this.value,
    this.count,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFilterOption<T> &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == other.value;

  @override
  int get hashCode => label.hashCode ^ value.hashCode;
}

enum SortOrder { ascending, descending }

@immutable
class SortOption {
  final String fieldKey;
  final String label;
  final SortOrder order;

  const SortOption({
    required this.fieldKey,
    required this.label,
    this.order = SortOrder.ascending,
  });

  SortOption copyWith({
    String? fieldKey,
    String? label,
    SortOrder? order,
  }) {
    return SortOption(
      fieldKey: fieldKey ?? this.fieldKey,
      label: label ?? this.label,
      order: order ?? this.order,
    );
  }
}

@immutable
class AdminSearchFilterState {
  final String searchQuery;
  final Map<String, dynamic> activeFilters;
  final SortOption? currentSort;
  final int currentPage;
  final int pageSize;

  const AdminSearchFilterState({
    this.searchQuery = '',
    this.activeFilters = const {},
    this.currentSort,
    this.currentPage = 1,
    this.pageSize = 10,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      activeFilters.values.any((val) => val != null && val != '');

  int get activeFilterCount {
    int count = searchQuery.isNotEmpty ? 1 : 0;
    for (final val in activeFilters.values) {
      if (val != null && val != '') {
        count++;
      }
    }
    return count;
  }

  AdminSearchFilterState copyWith({
    String? searchQuery,
    Map<String, dynamic>? activeFilters,
    SortOption? currentSort,
    int? currentPage,
    int? pageSize,
  }) {
    return AdminSearchFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilters: activeFilters ?? this.activeFilters,
      currentSort: currentSort ?? this.currentSort,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  AdminSearchFilterState resetFilters() {
    return AdminSearchFilterState(
      searchQuery: '',
      activeFilters: const {},
      currentSort: currentSort,
      currentPage: 1,
      pageSize: pageSize,
    );
  }
}
