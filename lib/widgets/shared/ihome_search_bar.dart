import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Pill-shaped search bar matching the reference image.
/// Features a subtle neutral fill, minimal search icon, and an optional filter button.
class IHomeSearchBar extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onSearch;
  final VoidCallback? onFilterTap;
  final String hintText;
  final int debounceMs;
  final double height;
  final bool showFilterButton;

  const IHomeSearchBar({
    super.key,
    this.initialQuery = '',
    required this.onSearch,
    this.onFilterTap,
    this.hintText = 'Search properties, locations...',
    this.debounceMs = 250,
    this.height = 50,
    this.showFilterButton = true,
  });

  @override
  State<IHomeSearchBar> createState() => _IHomeSearchBarState();
}

class _IHomeSearchBarState extends State<IHomeSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant IHomeSearchBar oldWidget) {
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

  void _onChanged(String text) {
    if (widget.debounceMs <= 0) {
      widget.onSearch(text);
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      widget.onSearch(text);
    });
  }

  void _clear() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onSearch('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final textStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 14,
      color: isDark ? AppColors.textLight : AppColors.textDark,
      fontWeight: FontWeight.w400,
    );
    final hintStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 14,
      color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
      fontWeight: FontWeight.w400,
    );

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppBorderRadius.pill,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (val) {
                _onChanged(val);
                setState(() {});
              },
              style: textStyle,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: hintStyle,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: _clear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                ),
              ),
            ),
          if (widget.showFilterButton) ...[
            Container(
              height: 20,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
