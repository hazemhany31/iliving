import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AdminSearchBar extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onSearch;
  final String hintText;
  final int debounceMs;
  final double? width;

  const AdminSearchBar({
    super.key,
    this.initialQuery = '',
    required this.onSearch,
    this.hintText = 'Search records...',
    this.debounceMs = 300,
    this.width,
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant AdminSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (widget.debounceMs <= 0) {
      widget.onSearch(text);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      widget.onSearch(text);
    });
  }

  void _clearSearch() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onSearch('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final widgetChild = SizedBox(
      height: 42,
      child: TextField(
        controller: _controller,
        onChanged: (val) {
          _onTextChanged(val);
          setState(() {});
        },
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textLight : AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                  onPressed: _clearSearch,
                  tooltip: 'Clear Search',
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: AppBorderRadius.pill,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.pill,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppBorderRadius.pill,
            borderSide: const BorderSide(
              color: AppColors.accent,
              width: 1.5,
            ),
          ),
        ),
      ),
    );

    if (widget.width != null) {
      return SizedBox(width: widget.width, child: widgetChild);
    }

    return widgetChild;
  }
}
