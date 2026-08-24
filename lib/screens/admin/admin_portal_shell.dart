import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/luxury_theme.dart';
import '../../services/auth_service.dart';
import '../../main.dart' show luxuryThemeNotifier;
import 'executive_dashboard_screen.dart';
import 'projects_module_screen.dart';
import 'compounds_module_screen.dart';
import 'buildings_module_screen.dart';
import 'unit_inventory_module_screen.dart';
import 'customers_module_screen.dart';
import 'contracts_module_screen.dart';
import 'installments_module_screen.dart';
import 'maintenance_module_screen.dart';
import 'admin_settings_module_screen.dart';
import '../booking_history_screen.dart';
import '../../services/firestore_seeder_service.dart';
import '../../services/locale_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/profile_picture_dialog.dart';

class AdminModuleItem {
  final int index;
  final String title;
  final String titleAr;
  final IconData icon;
  final String badgeText;
  final Color? badgeColor;

  const AdminModuleItem({
    required this.index,
    required this.title,
    required this.titleAr,
    required this.icon,
    this.badgeText = '',
    this.badgeColor,
  });
}

class AdminPortalShell extends StatefulWidget {
  final int initialModuleIndex;
  const AdminPortalShell({super.key, this.initialModuleIndex = 0});

  static const List<AdminModuleItem> modules = [
    AdminModuleItem(
      index: 0,
      title: 'Executive Dashboard',
      titleAr: 'لوحة القيادة التنفيذية',
      icon: Icons.dashboard_outlined,
      badgeText: 'SSOT',
      badgeColor: AppColors.accent,
    ),
    AdminModuleItem(
      index: 1,
      title: 'Projects',
      titleAr: 'المشروعات',
      icon: Icons.business_outlined,
    ),
    AdminModuleItem(
      index: 2,
      title: 'Compounds',
      titleAr: 'المجمعات السكنية',
      icon: Icons.holiday_village_outlined,
    ),
    AdminModuleItem(
      index: 3,
      title: 'Buildings',
      titleAr: 'المباني والعمائر',
      icon: Icons.apartment_outlined,
    ),
    AdminModuleItem(
      index: 4,
      title: 'Unit Inventory',
      titleAr: 'مخزون الوحدات',
      icon: Icons.grid_view_outlined,
      badgeText: 'LIVE',
      badgeColor: AppColors.info,
    ),
    AdminModuleItem(
      index: 5,
      title: 'Customers',
      titleAr: 'العملاء والمالكين',
      icon: Icons.people_alt_outlined,
    ),
    AdminModuleItem(
      index: 6,
      title: 'Contracts',
      titleAr: 'العقود والاتفاقيات',
      icon: Icons.description_outlined,
    ),
    AdminModuleItem(
      index: 7,
      title: 'Bookings',
      titleAr: 'الحجوزات والعملاء',
      icon: Icons.bookmark_added_outlined,
    ),
    AdminModuleItem(
      index: 8,
      title: 'Installments & Payments',
      titleAr: 'الأقساط والمدفوعات',
      icon: Icons.payments_outlined,
      badgeText: 'SSOT',
      badgeColor: AppColors.success,
    ),
    AdminModuleItem(
      index: 9,
      title: 'Maintenance',
      titleAr: 'الصيانة والبلاغات',
      icon: Icons.build_circle_outlined,
      badgeText: 'SLAs',
      badgeColor: AppColors.warning,
    ),
    AdminModuleItem(
      index: 10,
      title: 'Documents',
      titleAr: 'الأرشيف والمستندات',
      icon: Icons.folder_shared_outlined,
    ),
    AdminModuleItem(
      index: 11,
      title: 'Reports',
      titleAr: 'التقارير التحليلية',
      icon: Icons.assessment_outlined,
    ),
    AdminModuleItem(
      index: 12,
      title: 'Settings',
      titleAr: 'إعدادات النظام',
      icon: Icons.settings_outlined,
    ),
  ];

  @override
  State<AdminPortalShell> createState() => _AdminPortalShellState();
}

class _AdminPortalShellState extends State<AdminPortalShell> {
  late int _selectedIndex;
  final Set<int> _visitedModules = {};
  bool _isSidebarCollapsed = false;
  bool _isOnline = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _connectionSubscription;

  List<AdminModuleItem> get modules => AdminPortalShell.modules;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialModuleIndex;
    _visitedModules.add(_selectedIndex);
    _listenToConnectionStatus();
  }

  void _listenToConnectionStatus() {
    if (Firebase.apps.isNotEmpty) {
      _connectionSubscription = FirebaseFirestore.instance
          .collection('_healthcheck')
          .doc('status')
          .snapshots()
          .listen(
        (_) {
          if (mounted && !_isOnline) {
            setState(() => _isOnline = true);
          }
        },
        onError: (_) {
          if (mounted && _isOnline) {
            setState(() => _isOnline = false);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _selectModule(int index) {
    if (_selectedIndex == index) {
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
        Navigator.pop(context);
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
      _visitedModules.add(index);
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  Future<void> _triggerFirestoreImport() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double progressVal = 0.0;
    String statusMsg = "0% Loading JSON - Initializing ERP Importer...";
    bool hasError = false;
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSt) {
            dialogSetState = setSt;
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.large,
              ),
              title: Row(
                children: [
                  Icon(
                    hasError ? Icons.error_outline_rounded : Icons.cloud_upload_outlined,
                    color: hasError ? AppColors.error : AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    hasError ? 'ERP Import Error' : 'Firestore ERP Importer',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusMsg,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: hasError ? AppColors.error : (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                      fontSize: 12,
                      fontWeight: hasError ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: AppBorderRadius.pill,
                    child: LinearProgressIndicator(
                      value: progressVal,
                      backgroundColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                      color: hasError ? AppColors.error : AppColors.accent,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(progressVal * 100).toInt()}% Completed',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: hasError ? AppColors.error : AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: hasError
                  ? [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                      ),
                    ]
                  : null,
            );
          },
        );
      },
    );

    try {
      final seeder = FirestoreSeederService();
      await seeder.runFirestoreImport(
        onProgress: (msg, p) {
          if (dialogSetState != null) {
            dialogSetState!(() {
              statusMsg = msg;
              progressVal = p;
              if (msg.contains("Error") || msg.contains("error")) {
                hasError = true;
              }
            });
          }
        },
      );
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('100% Complete! All ERP statements & inventory dataset successfully imported to Firestore!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint("[AdminPortalShell] ERP Import error: $e");
      if (dialogSetState != null) {
        dialogSetState!(() {
          hasError = true;
          statusMsg = "ERROR during ERP Import: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final Color surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final Color borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final Color textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final Color textMutedColor = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 992;
        final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 992;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bgColor,
          drawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: surfaceColor,
                  child: SafeArea(
                    child: _buildSidebarContent(
                      isDesktop: false,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      textMutedColor: textMutedColor,
                      isDark: isDark,
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (isDesktop)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isSidebarCollapsed ? 80 : 280,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      border: Border(right: BorderSide(color: borderColor, width: 1)),
                    ),
                    child: _buildSidebarContent(
                      isDesktop: true,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      textMutedColor: textMutedColor,
                      isDark: isDark,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeaderBar(
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        textMutedColor: textMutedColor,
                      ),
                      Expanded(
                        child: Container(
                          color: bgColor,
                          child: _buildModuleBody(isDark: isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarContent({
    required bool isDesktop,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color textMutedColor,
    required bool isDark,
  }) {
    final bool collapsed = isDesktop && _isSidebarCollapsed;

    return Column(
      children: [
        // Brand Header
        Container(
          height: 72,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.accent : AppColors.primary,
                  borderRadius: AppBorderRadius.medium,
                  boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                ),
                child: const Icon(Icons.domain_rounded, color: Colors.white, size: 22),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'iLIVING',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (_isOnline ? AppColors.success : AppColors.warning).withAlpha(25),
                              borderRadius: AppBorderRadius.pill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _isOnline ? AppColors.success : AppColors.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isOnline ? 'LIVE' : 'OFFLINE',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: _isOnline ? AppColors.success : AppColors.warning,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'ADMIN PORTAL SSOT',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMutedColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isDesktop)
                IconButton(
                  icon: Icon(
                    collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                ),
            ],
          ),
        ),

        // Navigation Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            itemCount: modules.length,
            itemBuilder: (context, idx) {
              final module = modules[idx];
              final bool isSelected = _selectedIndex == module.index;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectModule(module.index),
                    borderRadius: AppBorderRadius.pill,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                        horizontal: collapsed ? 12 : 16,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.accent.withAlpha(40) : AppColors.primary.withAlpha(20))
                            : Colors.transparent,
                        borderRadius: AppBorderRadius.pill,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            module.icon,
                            color: isSelected
                                ? (isDark ? AppColors.accent : AppColors.primary)
                                : textMutedColor,
                            size: 20,
                          ),
                          if (!collapsed) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                module.title,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: isSelected ? textColor : textMutedColor,
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (module.badgeText.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (module.badgeColor ?? AppColors.accent).withAlpha(25),
                                  borderRadius: AppBorderRadius.pill,
                                ),
                                child: Text(
                                  module.badgeText,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: module.badgeColor ?? AppColors.accent,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // System Controls & Utilities Section
        Container(
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: collapsed
              ? Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.accent, size: 20),
                      tooltip: 'Sync ERP Data / مزامنة البيانات',
                      onPressed: _triggerFirestoreImport,
                    ),
                    IconButton(
                      icon: const Icon(Icons.language_rounded, color: AppColors.accent, size: 20),
                      tooltip: 'Switch Language / تغيير اللغة',
                      onPressed: () => LocaleService.instance.toggleLocale(),
                    ),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: luxuryThemeNotifier,
                      builder: (context, mode, _) {
                        final bool isDarkMode = mode == ThemeMode.dark;
                        return IconButton(
                          icon: Icon(
                            isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          tooltip: 'Toggle Theme / المظهر',
                          onPressed: () {
                            luxuryThemeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                          },
                        );
                      },
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'SYSTEM CONTROLS',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMutedColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _triggerFirestoreImport,
                        icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.white),
                        label: const Text(
                          'Sync ERP Data / مزامنة',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => LocaleService.instance.toggleLocale(),
                            borderRadius: AppBorderRadius.pill,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                borderRadius: AppBorderRadius.pill,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.language_rounded, color: AppColors.accent, size: 15),
                                  const SizedBox(width: 5),
                                  Text(
                                    LocaleService.instance.isArabic ? 'English' : 'العربية',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: textColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ValueListenableBuilder<ThemeMode>(
                            valueListenable: luxuryThemeNotifier,
                            builder: (context, mode, _) {
                              final bool isDarkMode = mode == ThemeMode.dark;
                              return InkWell(
                                onTap: () {
                                  luxuryThemeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                                },
                                borderRadius: AppBorderRadius.pill,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                    borderRadius: AppBorderRadius.pill,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                                        color: AppColors.accent,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isDarkMode ? 'Light' : 'Dark',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: textColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),

        // Return to Main App Home
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: InkWell(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            borderRadius: AppBorderRadius.pill,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 16, vertical: 9),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                borderRadius: AppBorderRadius.pill,
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_rounded, color: AppColors.accent, size: 18),
                  if (!collapsed) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Main App Home',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'العودة للتطبيق الرئيسي',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textMutedColor,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // User Profile Footer
        Container(
          padding: EdgeInsets.all(collapsed ? 8 : 14),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            children: [
              UserAvatar(
                radius: 18,
                showEditBadge: true,
                onTap: () => ProfilePictureDialog.show(context),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AuthService.instance.currentProfile?.displayName ?? 'Admin User',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'SYSTEM ADMINISTRATOR',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.accent,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                  onPressed: () async {
                    await AuthService.instance.logout();
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBar({
    required bool isDesktop,
    required bool isTablet,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color textMutedColor,
  }) {
    final currentModule = modules.firstWhere((m) => m.index == _selectedIndex);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: Icon(Icons.menu_rounded, color: textColor, size: 24),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Open Navigation Drawer',
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentModule.title} (${currentModule.titleAr})',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textColor,
                    fontSize: isDesktop || isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  'Module ${_selectedIndex + 1} of ${modules.length} • iLiving Unified SSOT',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textMutedColor,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          if (isDesktop || isTablet) ...[
            const SizedBox(width: 16),
            _AdminSearchBar(
              borderColor: borderColor,
              textColor: textColor,
              textMutedColor: textMutedColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModuleBody({required bool isDark}) {
    return Stack(
      children: List.generate(modules.length, (idx) {
        final bool hasBeenVisited = _visitedModules.contains(idx);
        final bool isActive = _selectedIndex == idx;

        if (!hasBeenVisited) return const SizedBox.shrink();

        return Offstage(
          offstage: !isActive,
          child: _buildSingleModule(idx, isDark: isDark),
        );
      }),
    );
  }

  Widget _buildSingleModule(int idx, {required bool isDark}) {
    switch (idx) {
      case 0:
        return ExecutiveDashboardScreen(
          onNavigateToModule: (navIdx) => _selectModule(navIdx),
        );
      case 1:
        return const ProjectsModuleScreen();
      case 2:
        return const CompoundsModuleScreen();
      case 3:
        return const BuildingsModuleScreen();
      case 4:
        return const UnitInventoryModuleScreen();
      case 5:
        return const CustomersModuleScreen();
      case 6:
        return const ContractsModuleScreen();
      case 7:
        return const BookingHistoryScreen();
      case 8:
        return const InstallmentsModuleScreen();
      case 9:
        return const MaintenanceModuleScreen();
      case 12:
        return const AdminSettingsModuleScreen();
      default:
        return _buildModulePlaceholder(modules[idx], isDark: isDark);
    }
  }

  Widget _buildModulePlaceholder(AdminModuleItem module, {required bool isDark}) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppBorderRadius.large,
          boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.layers_rounded, color: AppColors.accent, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              module.title,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: isDark ? AppColors.textLight : AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              module.titleAr,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(25),
                borderRadius: AppBorderRadius.pill,
              ),
              child: const Text(
                'ADMIN SHELL READY • AWAITING MODULE IMPLEMENTATION',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.accent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSearchBar extends StatefulWidget {
  final Color borderColor;
  final Color textColor;
  final Color textMutedColor;

  const _AdminSearchBar({
    required this.borderColor,
    required this.textColor,
    required this.textMutedColor,
  });

  @override
  State<_AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<_AdminSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 240,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
        borderRadius: AppBorderRadius.pill,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: widget.textMutedColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (val) {
                final hasText = val.isNotEmpty;
                if (hasText != _hasText) {
                  setState(() => _hasText = hasText);
                }
              },
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: widget.textColor,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: 'Search module...',
                hintStyle: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: widget.textMutedColor,
                  fontSize: 12,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_hasText)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() => _hasText = false);
              },
              child: Icon(Icons.close_rounded, color: widget.textMutedColor, size: 16),
            ),
        ],
      ),
    );
  }
}
