import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'l10n/app_localizations.dart';
import 'services/locale_service.dart';
import 'firebase_options.dart';
import 'core/config/app_secrets.dart';
import 'theme/luxury_theme.dart';
import 'screens/property_ops_dashboard.dart';
import 'screens/document_viewer_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/luxury_shimmer.dart';
import 'widgets/offline_state_manager.dart';
import 'models/auth_model.dart';
import 'services/auth_service.dart';
import 'services/sync_state.dart';
import 'services/firestore_seeder_service.dart';
import 'repositories/price_sync_repository.dart';
import 'screens/admin/executive_dashboard_screen.dart';
import 'screens/admin/admin_portal_shell.dart';
import 'screens/admin/projects_module_screen.dart';
import 'screens/admin/compounds_module_screen.dart';
import 'screens/admin/buildings_module_screen.dart';
import 'screens/admin/unit_inventory_module_screen.dart';
import 'screens/admin/customers_module_screen.dart';
import 'screens/admin/contracts_module_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/admin/installments_module_screen.dart';
import 'screens/admin/maintenance_module_screen.dart';
import 'screens/admin/admin_settings_module_screen.dart';
import 'models/notification.dart';
import 'repositories/firestore/firestore_notification_repository.dart';
import 'services/installment_reminder_service.dart';
import 'services/push_notification_service.dart';

final ValueNotifier<ThemeMode> luxuryThemeNotifier = ValueNotifier(ThemeMode.light);


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Guard: crash early if release build ships with placeholder keys.
    DefaultFirebaseOptions.assertRealCredentials();

    // Configure sensible bounded Firestore cache (100MB) with offline persistence.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024,
    );
    debugPrint("[Firebase] Core platform initialized with bounded 100MB cache & persistence.");
  } catch (e) {
    debugPrint("[Firebase] Core platform initialization bypassed or failed (missing files): $e");
  }
  // Initialize runtime secrets (gate HMAC key, etc.) from secure storage.
  try {
    await AppSecrets.instance.initialize();
  } catch (e) {
    debugPrint("[AppSecrets] Initialization failed: $e");
  }
  runApp(const LuxuryRealEstateApp());
}


class LuxuryRealEstateApp extends StatefulWidget {
  const LuxuryRealEstateApp({super.key});

  @override
  State<LuxuryRealEstateApp> createState() => _LuxuryRealEstateAppState();
}

class _LuxuryRealEstateAppState extends State<LuxuryRealEstateApp> {
  final SyncStateManager _syncManager = SyncStateManager();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await LocaleService.instance.initialize();
      unawaited(_syncManager.initialize());
      await AuthService.instance.initialize();
      // Initialize push notification service (FCM + local notifications)
      await PushNotificationService.instance.initialize();
      // Do NOT await ensureSeeded() here — it can block the first frame.
      // Schedule it after the first frame so the UI becomes interactive first.
    } catch (e) {
      debugPrint("Bootstrap initialization error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
        AuthService.instance.stateNotifier.addListener(_onAuthChanged);
        // Register FCM token if user is already logged in
        final currentUser = AuthService.instance.currentProfile;
        if (currentUser != null) {
          unawaited(PushNotificationService.instance.registerTokenForUser(currentUser.id));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FirestoreSeederService.ensureSeeded();
          if (mounted) {
            precacheImage(const AssetImage('images/skyhills/ski-hills.jpg'), context).catchError((_) {});
            precacheImage(const AssetImage('images/lamar/lamar-1.jpg'), context).catchError((_) {});
            precacheImage(const AssetImage('images/zayed_lagoons/zayed-lahogons1.jpg'), context).catchError((_) {});
          }
        });
      }
    }
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {});
    // Register/unregister FCM token based on auth state
    final user = AuthService.instance.currentProfile;
    if (user != null) {
      unawaited(PushNotificationService.instance.registerTokenForUser(user.id));
    }
  }


  @override
  void dispose() {
    AuthService.instance.stateNotifier.removeListener(_onAuthChanged);
    _syncManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SyncScope(
      manager: _syncManager,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: luxuryThemeNotifier,
        builder: (context, themeMode, _) {
          return ValueListenableBuilder<Locale>(
            valueListenable: LocaleService.instance.localeNotifier,
            builder: (context, currentLocale, _) {
              return MaterialApp(
                title: 'iLiving Luxury Client Portal',
                debugShowCheckedModeBanner: false,
                theme: LuxuryTheme.lightTheme,
                darkTheme: LuxuryTheme.darkTheme,
                themeMode: themeMode,
                locale: currentLocale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                routes: {
                  '/home': (context) {
                    final user = AuthService.instance.currentProfile;
                    if (user != null && user.isStaff) {
                      return const MainNavigationShell();
                    }
                    return const OwnerNavigationShell();
                  },
                  '/login': (context) => const LoginScreen(),
                  '/admin': (context) {
                    final user = AuthService.instance.currentProfile;
                    if (user != null && user.isStaff) {
                      return const AdminPortalShell();
                    }
                    return const OwnerNavigationShell();
                  },
                  '/admin/dashboard': (context) {
                    final user = AuthService.instance.currentProfile;
                    if (user != null && user.isStaff) {
                      return const ExecutiveDashboardScreen();
                    }
                    return const OwnerNavigationShell();
                  },
                  '/owner': (context) => const OwnerNavigationShell(),
                },
                home: _buildInitialRoute(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInitialRoute() {
    if (!_initialized) {
      return _buildSplashScreen();
    }
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthService.instance.stateNotifier,
      builder: (context, authState, _) {
        if (authState == AuthState.authenticating) {
          return _buildSplashScreen();
        }

        if (authState == AuthState.authenticated && AuthService.instance.currentProfile != null) {
          final user = AuthService.instance.currentProfile!;
          if (user.isStaff) {
            return const MainNavigationShell();
          }
          return const OwnerNavigationShell();
        }

        return const LoginScreen();
      },
    );
  }

  Widget _buildSplashScreen() {
    final isDark = luxuryThemeNotifier.value == ThemeMode.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final primary = isDark ? AppColors.accent : AppColors.primary;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(scale: 0.85 + (0.15 * value), child: child),
                );
              },
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: AppBorderRadius.large,
                  boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
                ),
                child: const Icon(Icons.domain_rounded, color: Colors.white, size: 34),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'iLIVING',
              style: TextStyle(
                color: textColor,
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'REAL ESTATE PLATFORM',
              style: TextStyle(
                color: textMuted,
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 140,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  backgroundColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AppMode { brokerage, operations }

enum AppModule {
  discovery,
  crmLedger,
  eoiCapture,
  yieldAnalytics,
  cctvFeed,
  smartGate,
  utilityBills,
  maintenance
}

class OperationNotification {
  final String id;
  final String title;
  final String titleAr;
  final String subtitle;
  final String subtitleAr;
  final String time;
  final IconData icon;
  final Color iconColor;
  final String? pdfUrl;
  final String? pdfTitle;
  final double? amount;
  final DateTime? dueDate;
  final String? unitId;
  final String? installmentId;
  final String? type;
  final bool isRead;
  final VoidCallback onTap;

  const OperationNotification({
    required this.id,
    required this.title,
    this.titleAr = '',
    required this.subtitle,
    this.subtitleAr = '',
    required this.time,
    required this.icon,
    required this.iconColor,
    this.pdfUrl,
    this.pdfTitle,
    this.amount,
    this.dueDate,
    this.unitId,
    this.installmentId,
    this.type,
    this.isRead = false,
    required this.onTap,
  });
}


Widget _buildHeaderActionButtons({
  required BuildContext context,
  required bool showNotifications,
  required int notificationCount,
  required VoidCallback onToggleNotifications,
  required VoidCallback onLogout,
}) {
  final l10n = AppLocalizations.of(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final iconColor = isDark ? AppColors.textLight : AppColors.textDark;
  final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
  final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

  Widget wrapCircularButton({
    required Widget child,
    required VoidCallback onTap,
    required String tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accent.withAlpha(isDark ? 40 : 25)
                  : cardAltBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppColors.accent : borderColor,
                width: 1,
              ),
              boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.only(right: 12.0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Language Switcher Toggle (Globe)
        wrapCircularButton(
          tooltip: l10n.switchLanguage,
          onTap: () => LocaleService.instance.toggleLocale(),
          child: Icon(Icons.language_rounded, color: iconColor, size: 18),
        ),
        const SizedBox(width: 8),

        // 2. Theme Toggle (Sun / Moon)
        ValueListenableBuilder<ThemeMode>(
          valueListenable: luxuryThemeNotifier,
          builder: (context, themeMode, _) {
            final isCurrentlyDark = themeMode == ThemeMode.dark;
            return wrapCircularButton(
              tooltip: isCurrentlyDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onTap: () {
                luxuryThemeNotifier.value = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isCurrentlyDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  key: ValueKey(isCurrentlyDark),
                  color: iconColor,
                  size: 18,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),

        // 3. Notifications Bell + Integrated Live Cloud Sync Dot
        ValueListenableBuilder<SyncStatus>(
          valueListenable: PriceSyncRepository.instance.statusNotifier,
          builder: (context, status, _) {
            final syncColor = status == SyncStatus.live
                ? AppColors.success
                : status == SyncStatus.syncing
                    ? AppColors.accent
                    : status == SyncStatus.offline
                        ? AppColors.error
                        : AppColors.warning;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                wrapCircularButton(
                  tooltip: 'Real-Time Notifications',
                  isActive: showNotifications,
                  onTap: onToggleNotifications,
                  child: Icon(
                    showNotifications ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                    color: showNotifications ? AppColors.accent : iconColor,
                    size: 19,
                  ),
                ),
                // Live Sync glowing dot (bottom-right of the circle)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: OfflineStateManager.forceOnline,
                    builder: (context, forceOnline, _) {
                      return GestureDetector(
                        onTap: () {
                          final nextVal = !forceOnline;
                          OfflineStateManager.forceOnline.value = nextVal;
                          PriceSyncRepository.instance.forceRefresh();
                        },
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: syncColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(color: syncColor.withAlpha(200), blurRadius: 4, spreadRadius: 1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Notification Count Badge (top-right of the circle)
                if (notificationCount > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: AppBorderRadius.pill,
                        border: Border.all(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(color: AppColors.error.withAlpha(120), blurRadius: 4),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          notificationCount > 99 ? '99+' : '$notificationCount',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),

        // 4. Logout / Exit Button
        wrapCircularButton(
          tooltip: 'Sign Out',
          onTap: () => _confirmLogout(context, onLogout),
          child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 17),
        ),
      ],
    ),
  );
}

Future<void> _confirmLogout(BuildContext context, VoidCallback onConfirm) async {
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.large,
      ),
      title: Row(
        children: [
          const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 10),
          Text(
            isAr ? 'تسجيل الخروج' : 'Sign Out',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: isDark ? AppColors.textLight : AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        isAr ? 'هل أنت متأكد من تسجيل الخروج من حسابك؟' : 'Are you sure you want to log out of your session?',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
          fontSize: 13,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            isAr ? 'إلغاء' : 'Cancel',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            isAr ? 'خروج' : 'Log Out',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
  if (result == true) {
    onConfirm();
  }
}

void _showRealPaymentReceiptDialog(BuildContext context, OperationNotification notif) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
  final textColor = isDark ? AppColors.textLight : AppColors.textDark;
  final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
  final isAr = Localizations.localeOf(context).languageCode == 'ar';

  final formattedAmount = notif.amount != null
      ? notif.amount!.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )
      : '405,000';

  final unitText = notif.unitId != null && notif.unitId!.isNotEmpty ? notif.unitId! : 'A01-207';
  final receiptId = notif.id.replaceFirst('NTF-PAY-', '').replaceFirst('NTF-REM-', '');
  final displayRef = receiptId.isNotEmpty ? 'RCP-SH-$receiptId' : 'RCP-SH-984210';

  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.large),
      contentPadding: const EdgeInsets.all(22),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(isDark ? 40 : 25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            isAr ? 'إيصال سداد وتسوية مالية' : 'Official Payment Receipt',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isAr ? 'تسوية معتمدة للوحدة في مشروع Sky Hills' : 'Reconciled & Cleared for Sky Hills Residence',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textMuted,
              fontSize: 11.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: cardAltBg,
              borderRadius: AppBorderRadius.medium,
              border: Border.all(
                color: AppColors.accent.withAlpha(60),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  isAr ? 'المبلغ المسدد' : 'AMOUNT RECONCILED',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formattedAmount,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? 'ج.م' : 'EGP',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(isDark ? 35 : 20),
                    borderRadius: AppBorderRadius.pill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        isAr ? 'تمت التسوية والاعتماد بنجاح' : 'RECONCILED & CLEARED',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardAltBg,
              borderRadius: AppBorderRadius.medium,
            ),
            child: Column(
              children: [
                _buildReceiptInfoRow(
                  label: isAr ? 'رقم الإيصال' : 'Receipt Ref',
                  value: displayRef,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 8),
                _buildReceiptInfoRow(
                  label: isAr ? 'الوحدة والمشروع' : 'Unit & Compound',
                  value: 'Sky Hills • Unit $unitText',
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 8),
                _buildReceiptInfoRow(
                  label: isAr ? 'طريقة السداد' : 'Channel',
                  value: isAr ? 'تحويل مصرفي مباشر' : 'Bank Wire Transfer',
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 8),
                _buildReceiptInfoRow(
                  label: isAr ? 'تاريخ السداد' : 'Timestamp',
                  value: notif.time,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    isAr ? 'إغلاق' : 'Close',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: Text(
                    isAr ? 'كشف الحساب' : 'Statement',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentViewerScreen(
                          title: isAr ? 'كشف حساب الوحدة $unitText' : 'Statement for Unit $unitText',
                          documentUrl: notif.pdfUrl ?? 'https://iliving.app/statement/$unitText.pdf',
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
  );
}

Widget _buildReceiptInfoRow({
  required String label,
  required String value,
  required Color textColor,
  required Color textMuted,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: textMuted,
          fontSize: 11,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

void _showRealMaintenanceTicketDetailDialog(BuildContext context, OperationNotification notif) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
  final textColor = isDark ? AppColors.textLight : AppColors.textDark;
  final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
  final isAr = Localizations.localeOf(context).languageCode == 'ar';

  final unitText = notif.unitId != null && notif.unitId!.isNotEmpty ? notif.unitId! : 'A01-207';
  final titleText = isAr && notif.titleAr.isNotEmpty ? notif.titleAr : notif.title;
  final bodyText = isAr && notif.subtitleAr.isNotEmpty ? notif.subtitleAr : notif.subtitle;

  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.large),
      contentPadding: const EdgeInsets.all(22),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(isDark ? 40 : 25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.build_rounded, color: AppColors.info, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            titleText,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Sky Hills • Unit $unitText',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardAltBg,
              borderRadius: AppBorderRadius.medium,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'حالة الطلب' : 'STATUS',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.info.withAlpha(isDark ? 35 : 20),
                        borderRadius: AppBorderRadius.pill,
                      ),
                      child: Text(
                        isAr ? 'قيد المتابعة والتنفيذ' : 'ACTIVE / IN PROGRESS',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.info,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isAr ? 'تفاصيل البلاغ:' : 'Ticket Details:',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bodyText,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textColor,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'وقت الإشعار:' : 'Logged:',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                    Text(
                      notif.time,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                isAr ? 'تم الاطلاع' : 'Acknowledge',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AdminCategoryOption {
  final int index;
  final String title;
  final String titleAr;
  final IconData icon;
  final String badgeText;
  final Color? badgeColor;

  const AdminCategoryOption({
    required this.index,
    required this.title,
    required this.titleAr,
    required this.icon,
    this.badgeText = '',
    this.badgeColor,
  });
}

const List<AdminCategoryOption> _adminCategories = [
  AdminCategoryOption(
    index: 0,
    title: 'Executive Dashboard',
    titleAr: 'لوحة القيادة التنفيذية',
    icon: Icons.dashboard_outlined,
    badgeText: 'SSOT',
    badgeColor: AppColors.accent,
  ),
  AdminCategoryOption(
    index: 1,
    title: 'Projects',
    titleAr: 'المشروعات',
    icon: Icons.business_outlined,
  ),
  AdminCategoryOption(
    index: 2,
    title: 'Compounds',
    titleAr: 'المجمعات السكنية',
    icon: Icons.holiday_village_outlined,
  ),
  AdminCategoryOption(
    index: 3,
    title: 'Buildings',
    titleAr: 'المباني والعمائر',
    icon: Icons.apartment_outlined,
  ),
  AdminCategoryOption(
    index: 4,
    title: 'Unit Inventory',
    titleAr: 'مخزون الوحدات',
    icon: Icons.grid_view_outlined,
    badgeText: 'LIVE',
    badgeColor: AppColors.info,
  ),
  AdminCategoryOption(
    index: 5,
    title: 'Customers',
    titleAr: 'العملاء والمالكين',
    icon: Icons.people_alt_outlined,
  ),
  AdminCategoryOption(
    index: 6,
    title: 'Contracts',
    titleAr: 'العقود والاتفاقيات',
    icon: Icons.description_outlined,
  ),
  AdminCategoryOption(
    index: 7,
    title: 'Bookings',
    titleAr: 'الحجوزات والعملاء',
    icon: Icons.bookmark_added_outlined,
  ),
  AdminCategoryOption(
    index: 8,
    title: 'Installments & Payments',
    titleAr: 'الأقساط والمدفوعات',
    icon: Icons.payments_outlined,
    badgeText: 'SSOT',
    badgeColor: AppColors.success,
  ),
  AdminCategoryOption(
    index: 9,
    title: 'Maintenance',
    titleAr: 'الصيانة والبلاغات',
    icon: Icons.build_circle_outlined,
    badgeText: 'SLAs',
    badgeColor: AppColors.warning,
  ),
  AdminCategoryOption(
    index: 10,
    title: 'Documents',
    titleAr: 'الأرشيف والمستندات',
    icon: Icons.folder_shared_outlined,
  ),
  AdminCategoryOption(
    index: 11,
    title: 'Reports',
    titleAr: 'التقارير التحليلية',
    icon: Icons.assessment_outlined,
  ),
  AdminCategoryOption(
    index: 12,
    title: 'Settings',
    titleAr: 'إعدادات النظام',
    icon: Icons.settings_outlined,
  ),
];

class MainNavigationShell extends StatefulWidget {

  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with TickerProviderStateMixin {
  final AppMode _appMode = AppMode.operations;
  int _currentIndex = 0;
  bool _isOpsMode = true;
  int _selectedAdminCategoryIndex = 0;
  final Set<int> _visitedAdminCategories = {0};
  final bool _isTransitioning = false;
  bool _showNotifications = false;
  final bool _isFaceIdChecking = false;
  final Set<AppModule> _activeModules = {};
  List<OperationNotification> _notifications = [];
  StreamSubscription<List<AppNotification>>? _notifSubscription;

  @override
  void initState() {
    super.initState();
    _updateActiveModules(_appMode);
    _initializeNotifications();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  void _updateActiveModules(AppMode mode) {
    _activeModules.clear();
    if (mode == AppMode.brokerage) {
      _activeModules.addAll({
        AppModule.discovery,
        AppModule.crmLedger,
        AppModule.eoiCapture,
        AppModule.yieldAnalytics,
      });
    } else {
      _activeModules.addAll({
        AppModule.cctvFeed,
        AppModule.smartGate,
        AppModule.utilityBills,
        AppModule.maintenance,
      });
    }
  }

  void _initializeNotifications() {
    try {
      InstallmentReminderService().checkAndDispatchReminders();
    } catch (_) {}

    final notifRepo = FirestoreNotificationRepository();
    notifRepo.ensureInitialNotificationsFromDatabaseEntities();

    _notifSubscription?.cancel();
    _notifSubscription = notifRepo.streamAllNotifications().listen((firestoreNotifs) {
      if (!mounted) return;

      final sorted = List<AppNotification>.from(firestoreNotifs)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final user = AuthService.instance.currentProfile;
      final isClient = user != null && !user.isStaff;

      final List<OperationNotification> list = [];

      for (final fn in sorted) {
        if (isClient && fn.targetUserId.isNotEmpty && fn.targetUserId != 'ALL') {
          final target = fn.targetUserId.toLowerCase();
          final uid = user.id.toLowerCase();
          final uemail = user.email.toLowerCase();
          if (target != uid && target != uemail) {
            continue;
          }
        }

        final diff = DateTime.now().difference(fn.createdAt);
        final timeStr = diff.inSeconds < 45
            ? 'Just now'
            : diff.inMinutes < 60
                ? '${diff.inMinutes}m ago'
                : diff.inHours < 24
                    ? '${diff.inHours}h ago'
                    : '${diff.inDays}d ago';

        final typeStr = (fn.type ?? '').toLowerCase();
        final titleEn = fn.title.toLowerCase();
        final titleAr = fn.titleAr;

        final isPayment = typeStr == 'payment' ||
            typeStr == 'installment_reminder' ||
            typeStr.contains('payment') ||
            typeStr.contains('installment') ||
            titleEn.contains('payment') ||
            titleEn.contains('installment') ||
            titleEn.contains('reconciled') ||
            titleAr.contains('دفعة') ||
            titleAr.contains('قسط') ||
            titleAr.contains('سداد') ||
            titleAr.contains('تسوية') ||
            fn.installmentAmount != null;

        final isMaintenance = typeStr.startsWith('maintenance') ||
            typeStr.contains('ticket') ||
            titleEn.contains('maintenance') ||
            titleEn.contains('ticket') ||
            titleAr.contains('صيانة') ||
            titleAr.contains('تذكرة');

        final isDocument = typeStr.startsWith('document') ||
            typeStr.contains('document') ||
            titleEn.contains('document') ||
            titleEn.contains('contract') ||
            titleAr.contains('مستند') ||
            titleAr.contains('عقد');

        IconData icon;
        Color iconColor;

        if (isPayment) {
          icon = Icons.receipt_long_outlined;
          iconColor = Colors.green;
        } else if (fn.type == 'maintenance_created' || titleEn.contains('maintenance ticket') || titleAr.contains('صيانة')) {
          icon = Icons.build_circle_outlined;
          iconColor = Colors.blueAccent;
        } else if (fn.type == 'maintenance_updated' || fn.type == 'maintenance_comment') {
          icon = Icons.published_with_changes;
          iconColor = AppColors.accent;
        } else if (isDocument) {
          icon = Icons.description_outlined;
          iconColor = AppColors.accent;
        } else if (fn.priority == NotificationPriority.critical || fn.priority == NotificationPriority.emergency) {
          icon = Icons.warning_amber_rounded;
          iconColor = AppColors.error;
        } else {
          icon = Icons.notifications_active_rounded;
          iconColor = AppColors.accent;
        }

        late final OperationNotification opNotif;
        opNotif = OperationNotification(
          id: fn.id,
          title: fn.title,
          titleAr: fn.titleAr,
          subtitle: fn.body,
          subtitleAr: fn.bodyAr,
          time: timeStr,
          icon: icon,
          iconColor: iconColor,
          pdfUrl: fn.pdfUrl,
          pdfTitle: fn.pdfTitle,
          amount: fn.installmentAmount,
          dueDate: fn.dueDate,
          unitId: fn.unitId,
          installmentId: fn.installmentId,
          type: fn.type,
          isRead: fn.isRead,
          onTap: () async {
            try {
              await notifRepo.markAsRead(fn.id);
            } catch (_) {}

            if (!mounted) return;

            setState(() {
              _showNotifications = false;
            });

            if (fn.pdfUrl != null && fn.pdfUrl!.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentViewerScreen(
                    title: fn.pdfTitle ?? fn.title,
                    documentUrl: fn.pdfUrl!,
                  ),
                ),
              );
            } else if (isPayment) {
              _showRealPaymentReceiptDialog(context, opNotif);
            } else if (isMaintenance) {
              _showRealMaintenanceTicketDetailDialog(context, opNotif);
            } else if (isDocument) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentViewerScreen(
                    title: fn.pdfTitle ?? fn.title,
                    documentUrl: fn.pdfUrl ?? 'https://iliving.app/statement/${fn.unitId ?? "A01-207"}.pdf',
                  ),
                ),
              );
            }
          },
        );

        list.add(opNotif);
      }

      setState(() {
        _notifications = list;
      });
    });
  }

  List<BottomNavigationBarItem> _getNavigationItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.domain_outlined),
        activeIcon: const Icon(Icons.domain),
        label: l10n.navPropertyOps.toUpperCase(),
      ),
    ];
  }

  Future<void> _handleLogout() async {
    await SyncScope.of(context).logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _buildAdminCategoryBar({
    required bool isDark,
    required bool isAr,
  }) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        itemCount: _adminCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final module = _adminCategories[idx];
          final isSelected = _selectedAdminCategoryIndex == module.index;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedAdminCategoryIndex = module.index;
                  _visitedAdminCategories.add(module.index);
                });
              },
              borderRadius: AppBorderRadius.pill,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : cardAltBg,
                  borderRadius: AppBorderRadius.pill,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : borderColor,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? (isDark ? AppShadows.darkSoft : AppShadows.soft)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      module.icon,
                      size: 15,
                      color: isSelected ? Colors.white : (isDark ? AppColors.accent : AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? module.titleAr : module.title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: isSelected ? Colors.white : textColor,
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    if (module.badgeText.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withAlpha(60)
                              : (module.badgeColor ?? AppColors.accent).withAlpha(25),
                          borderRadius: AppBorderRadius.pill,
                        ),
                        child: Text(
                          module.badgeText,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: isSelected
                                ? Colors.white
                                : (module.badgeColor ?? AppColors.accent),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleAdminModule(int idx, {required bool isDark}) {
    switch (idx) {
      case 0:
        return ExecutiveDashboardScreen(
          onNavigateToModule: (navIdx) {
            setState(() {
              _selectedAdminCategoryIndex = navIdx;
              _visitedAdminCategories.add(navIdx);
            });
          },
          hideAppBar: true,
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
        final module = _adminCategories.firstWhere(
          (m) => m.index == idx,
          orElse: () => _adminCategories[0],
        );
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppBorderRadius.large,
              boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(module.icon, color: AppColors.accent, size: 40),
                ),
                const SizedBox(height: 18),
                Text(
                  module.title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module.titleAr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    borderRadius: AppBorderRadius.pill,
                  ),
                  child: const Text(
                    'MODULE READY',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.accent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildAdminView({required bool isDark, required bool isAr}) {
    return Column(
      children: [
        _buildAdminCategoryBar(isDark: isDark, isAr: isAr),
        Expanded(
          child: Stack(
            children: List.generate(_adminCategories.length, (idx) {
              final module = _adminCategories[idx];
              final bool hasBeenVisited = _visitedAdminCategories.contains(module.index);
              final bool isActive = _selectedAdminCategoryIndex == module.index;

              if (!hasBeenVisited) return const SizedBox.shrink();

              return Offstage(
                offstage: !isActive,
                child: _buildSingleAdminModule(module.index, isDark: isDark),
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_isFaceIdChecking) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.face_retouching_natural, color: AppColors.accent, size: 44),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: -40, end: 40),
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, value),
                          child: Container(
                            width: 70,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withAlpha(200),
                                  blurRadius: 5,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'BIOMETRIC SECURE SIGN IN',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Connecting to secure registry assets...',
                style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }

    if (_isTransitioning) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const LuxuryShimmer(width: 180, height: 24),
              const SizedBox(height: 24),
              const LuxuryShimmer(width: double.infinity, height: 160),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  itemCount: 6,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) =>
                      const LuxuryShimmer(width: double.infinity, height: 120),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = _getNavigationItems(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: _buildExecutiveToggle(),
        actions: [
          _buildHeaderActionButtons(
            context: context,
            showNotifications: _showNotifications,
            notificationCount: _notifications.where((n) => !n.isRead).length,
            onToggleNotifications: () {
              setState(() {
                _showNotifications = !_showNotifications;
              });
            },
            onLogout: _handleLogout,
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _isOpsMode ? 0 : 1,
            children: [
              const PropertyOpsDashboard(),
              _buildAdminView(isDark: isDark, isAr: isAr),
            ],
          ),
          _buildNotificationSheetGrid3Column(),
        ],
      ),
      bottomNavigationBar: items.length > 1
          ? Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1)),
              ),
              child: BottomNavigationBar(
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                currentIndex: _currentIndex,
                selectedItemColor: AppColors.accent,
                unselectedItemColor: textMuted,
                selectedFontSize: 9.5,
                unselectedFontSize: 9.5,
                type: BottomNavigationBarType.fixed,
                onTap: (idx) {
                  setState(() {
                    _currentIndex = idx;
                  });
                },
                items: items,
              ),
            )
          : null,
    );
  }

  Widget _buildExecutiveToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final leftLabel = isAr ? 'الإدارة' : 'ADMIN';
    final rightLabel = isAr ? 'العمليات' : 'OPS MODE';

    return Container(
      height: 36,
      width: 175,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cardAltBg,
        borderRadius: AppBorderRadius.pill,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final pillWidth = totalWidth / 2;

          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                alignment: _isOpsMode
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                  width: pillWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppBorderRadius.pill,
                    boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isOpsMode) {
                            setState(() {
                              _isOpsMode = false;
                            });
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Text(
                            leftLabel,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: !_isOpsMode ? Colors.white : textMuted,
                              fontSize: 9.5,
                              fontWeight: !_isOpsMode ? FontWeight.w800 : FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isOpsMode) {
                            setState(() {
                              _isOpsMode = true;
                            });
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Text(
                            rightLabel,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: _isOpsMode ? Colors.white : textMuted,
                              fontSize: 9.5,
                              fontWeight: _isOpsMode ? FontWeight.w800 : FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationSheetGrid3Column() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      bottom: _showNotifications ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      child: Container(
        height: 480,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.realTimeSystemOperations,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (_notifications.any((n) => !n.isRead))
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      tooltip: Localizations.localeOf(context).languageCode == 'ar' ? 'تحديد الكل كمقروء' : 'Mark all as read',
                      icon: const Icon(Icons.done_all_rounded, color: AppColors.accent, size: 20),
                      onPressed: () async {
                        final user = AuthService.instance.currentProfile;
                        await FirestoreNotificationRepository().markAllAsRead(targetUserId: user?.id);
                      },
                    ),
                  if (_notifications.isNotEmpty)
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      tooltip: Localizations.localeOf(context).languageCode == 'ar' ? 'مسح الكل' : 'Clear All',
                      icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 20),
                      onPressed: () async {
                        final currentNotifs = List<OperationNotification>.from(_notifications);
                        setState(() {
                          _notifications.clear();
                        });
                        for (final n in currentNotifs) {
                          if (!n.id.startsWith('notif_')) {
                            try {
                              await FirestoreNotificationRepository().deleteNotification(n.id);
                            } catch (_) {}
                          }
                        }
                      },
                    ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    tooltip: l10n.signOut,
                    icon: Icon(Icons.logout_rounded, color: textMuted, size: 18),
                    onPressed: _handleLogout,
                  ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.close_rounded, color: textMuted, size: 20),
                    onPressed: () {
                      setState(() {
                        _showNotifications = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, color: textMuted.withAlpha(120), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              Localizations.localeOf(context).languageCode == 'ar'
                                  ? 'لا توجد إشعارات حالياً'
                                  : 'No notifications at this time',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final isAr = Localizations.localeOf(context).languageCode == 'ar';
                        final titleText = isAr && notif.titleAr.isNotEmpty ? notif.titleAr : notif.title;
                        final bodyText = isAr && notif.subtitleAr.isNotEmpty ? notif.subtitleAr : notif.subtitle;

                        return Dismissible(
                          key: Key(notif.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: AppBorderRadius.medium,
                            ),
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  isAr ? 'مسح الإشعار' : 'Delete',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                          onDismissed: (direction) async {
                            final messenger = ScaffoldMessenger.of(context);
                            final removed = notif;
                            setState(() {
                              _notifications.removeWhere((n) => n.id == removed.id);
                            });

                            if (!removed.id.startsWith('notif_')) {
                              try {
                                await FirestoreNotificationRepository().deleteNotification(removed.id);
                              } catch (_) {}
                            }

                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr ? 'تم مسح الإشعار بنجاح' : 'Notification removed',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          child: InkWell(
                            onTap: notif.onTap,
                            borderRadius: AppBorderRadius.medium,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: AppBorderRadius.medium,
                                border: !notif.isRead
                                    ? Border.all(
                                        color: AppColors.accent.withAlpha(isDark ? 80 : 60),
                                        width: 1.2,
                                      )
                                    : null,
                                boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: notif.iconColor.withAlpha(isDark ? 35 : 18),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(notif.icon, color: notif.iconColor, size: 18),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                titleText,
                                                style: TextStyle(
                                                  fontFamily: AppTextStyles.fontFamily,
                                                  color: textColor,
                                                  fontSize: 13,
                                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!notif.isRead) ...[
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: AppColors.accent,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.accent.withAlpha(200),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            notif.time,
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              color: notif.isRead ? textMuted : AppColors.accent,
                                              fontSize: 10,
                                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (bodyText.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 36.0),
                                      child: Text(
                                        bodyText,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: textMuted,
                                          fontSize: 11.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Shell for Owner users - shows only GPS/Ops Mode (PropertyOpsDashboard)
/// with a simplified AppBar containing theme toggle, sync, notifications & logout.
class OwnerNavigationShell extends StatefulWidget {
  const OwnerNavigationShell({super.key});

  @override
  State<OwnerNavigationShell> createState() => _OwnerNavigationShellState();
}

class _OwnerNavigationShellState extends State<OwnerNavigationShell> {
  bool _showNotifications = false;
  List<OperationNotification> _notifications = [];
  StreamSubscription<List<AppNotification>>? _notifSubscription;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  void _initializeNotifications() {
    try {
      InstallmentReminderService().checkAndDispatchReminders();
    } catch (_) {}

    final notifRepo = FirestoreNotificationRepository();
    notifRepo.ensureInitialNotificationsFromDatabaseEntities();

    _notifSubscription?.cancel();
    _notifSubscription = notifRepo.streamAllNotifications().listen((firestoreNotifs) {
      if (!mounted) return;

      final sorted = List<AppNotification>.from(firestoreNotifs)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final user = AuthService.instance.currentProfile;

      final List<OperationNotification> list = [];

      for (final fn in sorted) {
        // Target user filter if notification is targeted
        if (user != null && fn.targetUserId.isNotEmpty && fn.targetUserId != 'ALL') {
          final target = fn.targetUserId.toLowerCase();
          final uid = user.id.toLowerCase();
          final uemail = user.email.toLowerCase();
          if (target != uid && target != uemail) {
            continue;
          }
        }

        final diff = DateTime.now().difference(fn.createdAt);
        final timeStr = diff.inSeconds < 45
            ? 'Just now'
            : diff.inMinutes < 60
                ? '${diff.inMinutes}m ago'
                : diff.inHours < 24
                    ? '${diff.inHours}h ago'
                    : '${diff.inDays}d ago';

        final typeStr = (fn.type ?? '').toLowerCase();
        final titleEn = fn.title.toLowerCase();
        final titleAr = fn.titleAr;

        final isPayment = typeStr == 'payment' ||
            typeStr == 'installment_reminder' ||
            typeStr.contains('payment') ||
            typeStr.contains('installment') ||
            titleEn.contains('payment') ||
            titleEn.contains('installment') ||
            titleEn.contains('reconciled') ||
            titleAr.contains('دفعة') ||
            titleAr.contains('قسط') ||
            titleAr.contains('سداد') ||
            titleAr.contains('تسوية') ||
            fn.installmentAmount != null;

        final isMaintenance = typeStr.startsWith('maintenance') ||
            typeStr.contains('ticket') ||
            titleEn.contains('maintenance') ||
            titleEn.contains('ticket') ||
            titleAr.contains('صيانة') ||
            titleAr.contains('تذكرة');

        final isDocument = typeStr.startsWith('document') ||
            typeStr.contains('document') ||
            titleEn.contains('document') ||
            titleEn.contains('contract') ||
            titleAr.contains('مستند') ||
            titleAr.contains('عقد');

        IconData icon;
        Color iconColor;

        if (isPayment) {
          icon = Icons.receipt_long_outlined;
          iconColor = Colors.green;
        } else if (fn.type == 'maintenance_created' || titleEn.contains('maintenance ticket') || titleAr.contains('صيانة')) {
          icon = Icons.build_circle_outlined;
          iconColor = Colors.blueAccent;
        } else if (fn.type == 'maintenance_updated' || fn.type == 'maintenance_comment') {
          icon = Icons.published_with_changes;
          iconColor = AppColors.accent;
        } else if (isDocument) {
          icon = Icons.description_outlined;
          iconColor = AppColors.accent;
        } else if (fn.priority == NotificationPriority.critical || fn.priority == NotificationPriority.emergency) {
          icon = Icons.warning_amber_rounded;
          iconColor = AppColors.error;
        } else {
          icon = Icons.notifications_active_rounded;
          iconColor = AppColors.accent;
        }

        late final OperationNotification opNotif;
        opNotif = OperationNotification(
          id: fn.id,
          title: fn.title,
          titleAr: fn.titleAr,
          subtitle: fn.body,
          subtitleAr: fn.bodyAr,
          time: timeStr,
          icon: icon,
          iconColor: iconColor,
          pdfUrl: fn.pdfUrl,
          pdfTitle: fn.pdfTitle,
          amount: fn.installmentAmount,
          dueDate: fn.dueDate,
          unitId: fn.unitId,
          installmentId: fn.installmentId,
          type: fn.type,
          isRead: fn.isRead,
          onTap: () async {
            try {
              await notifRepo.markAsRead(fn.id);
            } catch (_) {}

            if (!mounted) return;

            setState(() {
              _showNotifications = false;
            });

            if (fn.pdfUrl != null && fn.pdfUrl!.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentViewerScreen(
                    title: fn.pdfTitle ?? fn.title,
                    documentUrl: fn.pdfUrl!,
                  ),
                ),
              );
            } else if (isPayment) {
              _showRealPaymentReceiptDialog(context, opNotif);
            } else if (isMaintenance) {
              _showRealMaintenanceTicketDetailDialog(context, opNotif);
            } else if (isDocument) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentViewerScreen(
                    title: fn.pdfTitle ?? fn.title,
                    documentUrl: fn.pdfUrl ?? 'https://iliving.app/statement/${fn.unitId ?? "A01-207"}.pdf',
                  ),
                ),
              );
            }
          },
        );

        list.add(opNotif);
      }

      if (mounted) {
        setState(() {
          _notifications = list;
        });
      }
    });
  }

  Future<void> _handleLogout() async {
    await SyncScope.of(context).logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final user = AuthService.instance.currentProfile;
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            final leftLabel = isAr ? 'الإدارة' : 'ADMIN';
            final rightLabel = isAr ? 'العمليات' : 'OPS MODE';

            if (user != null && user.isStaff) {
              return Container(
                height: 36,
                width: 175,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: cardAltBg,
                  borderRadius: AppBorderRadius.pill,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final pillWidth = totalWidth / 2;

                    return Stack(
                      children: [
                        Positioned(
                          left: isAr ? null : pillWidth,
                          right: isAr ? pillWidth : null,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: pillWidth,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: AppBorderRadius.pill,
                              boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/admin');
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: Text(
                                      leftLabel,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: textMuted,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {},
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: Text(
                                      rightLabel,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                    borderRadius: AppBorderRadius.pill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gps_fixed_rounded, color: AppColors.accent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        l10n.ownerOpsModeHeader.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          _buildHeaderActionButtons(
            context: context,
            showNotifications: _showNotifications,
            notificationCount: _notifications.where((n) => !n.isRead).length,
            onToggleNotifications: () {
              setState(() {
                _showNotifications = !_showNotifications;
              });
            },
            onLogout: _handleLogout,
          ),
        ],
      ),
      body: Stack(
        children: [
          const PropertyOpsDashboard(),
          _buildNotificationSheetGrid3Column(),
        ],
      ),
    );
  }

  Widget _buildNotificationSheetGrid3Column() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      bottom: _showNotifications ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      child: Container(
        height: 480,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.realTimeSystemOperations,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (_notifications.any((n) => !n.isRead))
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      tooltip: Localizations.localeOf(context).languageCode == 'ar' ? 'تحديد الكل كمقروء' : 'Mark all as read',
                      icon: const Icon(Icons.done_all_rounded, color: AppColors.accent, size: 20),
                      onPressed: () async {
                        final user = AuthService.instance.currentProfile;
                        await FirestoreNotificationRepository().markAllAsRead(targetUserId: user?.id);
                      },
                    ),
                  if (_notifications.isNotEmpty)
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      tooltip: Localizations.localeOf(context).languageCode == 'ar' ? 'مسح الكل' : 'Clear All',
                      icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 20),
                      onPressed: () async {
                        final currentNotifs = List<OperationNotification>.from(_notifications);
                        setState(() {
                          _notifications.clear();
                        });
                        for (final n in currentNotifs) {
                          if (!n.id.startsWith('notif_')) {
                            try {
                              await FirestoreNotificationRepository().deleteNotification(n.id);
                            } catch (_) {}
                          }
                        }
                      },
                    ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    tooltip: l10n.signOut,
                    icon: Icon(Icons.logout_rounded, color: textMuted, size: 18),
                    onPressed: _handleLogout,
                  ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.close_rounded, color: textMuted, size: 20),
                    onPressed: () {
                      setState(() {
                        _showNotifications = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, color: textMuted.withAlpha(120), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              Localizations.localeOf(context).languageCode == 'ar'
                                  ? 'لا توجد إشعارات حالياً'
                                  : 'No notifications at this time',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final isAr = Localizations.localeOf(context).languageCode == 'ar';
                        final titleText = isAr && notif.titleAr.isNotEmpty ? notif.titleAr : notif.title;
                        final bodyText = isAr && notif.subtitleAr.isNotEmpty ? notif.subtitleAr : notif.subtitle;

                        return Dismissible(
                          key: Key(notif.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: AppBorderRadius.medium,
                            ),
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  isAr ? 'مسح الإشعار' : 'Delete',
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                          onDismissed: (direction) async {
                            final messenger = ScaffoldMessenger.of(context);
                            final removed = notif;
                            setState(() {
                              _notifications.removeWhere((n) => n.id == removed.id);
                            });

                            if (!removed.id.startsWith('notif_')) {
                              try {
                                await FirestoreNotificationRepository().deleteNotification(removed.id);
                              } catch (_) {}
                            }

                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr ? 'تم مسح الإشعار بنجاح' : 'Notification removed',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          child: InkWell(
                            onTap: notif.onTap,
                            borderRadius: AppBorderRadius.medium,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: AppBorderRadius.medium,
                                border: !notif.isRead
                                    ? Border.all(
                                        color: AppColors.accent.withAlpha(isDark ? 80 : 60),
                                        width: 1.2,
                                      )
                                    : null,
                                boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: notif.iconColor.withAlpha(isDark ? 35 : 18),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(notif.icon, color: notif.iconColor, size: 18),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                titleText,
                                                style: TextStyle(
                                                  fontFamily: AppTextStyles.fontFamily,
                                                  color: textColor,
                                                  fontSize: 13,
                                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!notif.isRead) ...[
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: AppColors.accent,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.accent.withAlpha(200),
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            notif.time,
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              color: notif.isRead ? textMuted : AppColors.accent,
                                              fontSize: 10,
                                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (bodyText.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 36.0),
                                      child: Text(
                                        bodyText,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: textMuted,
                                          fontSize: 11.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

