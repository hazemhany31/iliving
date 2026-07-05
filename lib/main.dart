import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/luxury_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/property_ops_dashboard.dart';
import 'screens/eoi_capture_screen.dart';
import 'screens/prypco_hub_screen.dart';
import 'screens/document_viewer_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/luxury_shimmer.dart';
import 'widgets/interactive_tap_bounce.dart';
import 'services/auth_service.dart';
import 'services/sync_state.dart';
import 'repositories/price_sync_repository.dart';
import 'models/auth_model.dart';

final ValueNotifier<ThemeMode> luxuryThemeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  try {
    await Firebase.initializeApp();
    debugPrint("[Firebase] Core platform initialization successful.");
  } catch (e) {
    debugPrint("[Firebase] Core platform initialization bypassed or failed (missing files): $e");
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
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _syncManager.initialize();
    } catch (e) {
      debugPrint("Bootstrap initialization error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _initialized = true;
          _authenticated = _syncManager.authState == AuthState.authenticated;
        });
      }
      AuthService.instance.stateNotifier.addListener(_onAuthChanged);
    }
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {
      _authenticated = AuthService.instance.currentState == AuthState.authenticated;
    });
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
          return MaterialApp(
            title: 'iHome Luxury Client Portal',
            debugShowCheckedModeBanner: false,
            theme: LuxuryTheme.lightTheme,
            darkTheme: LuxuryTheme.darkTheme,
            themeMode: themeMode,
            routes: {
              '/home': (context) => const MainNavigationShell(),
              '/login': (context) => const LoginScreen(),
            },
            home: _buildInitialRoute(),
          );
        },
      ),
    );
  }

  Widget _buildInitialRoute() {
    if (!_initialized) {
      return _buildSplashScreen();
    }
    if (!_authenticated) {
      return const LoginScreen();
    }
    return const MainNavigationShell();
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: LuxuryTheme.backgroundBlack,
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
                  child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
                );
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: LuxuryTheme.primaryGold,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: LuxuryTheme.primaryGold.withAlpha(100),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.domain_rounded, color: LuxuryTheme.backgroundBlack, size: 32),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'iHOME',
              style: TextStyle(
                color: LuxuryTheme.primaryGold,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 6.0,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'LUXURY CLIENT PORTAL',
              style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 9, letterSpacing: 3.0),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: LuxuryTheme.cardBrown,
                valueColor: const AlwaysStoppedAnimation<Color>(LuxuryTheme.primaryGold),
                borderRadius: BorderRadius.circular(2),
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
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const OperationNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with TickerProviderStateMixin {
  AppMode _appMode = AppMode.brokerage;
  int _currentIndex = 0;
  final bool _isTransitioning = false;
  bool _showNotifications = false;
  final bool _isFaceIdChecking = false;
  final Set<AppModule> _activeModules = {};
  late List<OperationNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _updateActiveModules(AppMode.brokerage);
    _initializeNotifications();
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
    _notifications = [
      OperationNotification(
        id: 'notif_1',
        title: 'SPA Document Ready',
        subtitle: 'Secure counter-sign required for Zayed Lagoons Unit ZL/08/801.',
        time: '2m ago',
        icon: Icons.border_color,
        iconColor: LuxuryTheme.primaryGold,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DocumentViewerScreen(
                title: 'SPA Zayed Lagoons',
                documentUrl: 'https://gateway.ihome.com.eg/contracts/spa_zayed_lagoons_801.pdf',
              ),
            ),
          );
        },
      ),
      OperationNotification(
        id: 'notif_2',
        title: 'Maintenance Ticket #881',
        subtitle: 'Sky Hills plumbing calibration ticket status set to In Progress.',
        time: '12m ago',
        icon: Icons.build_circle_outlined,
        iconColor: Colors.blueAccent,
        onTap: () {
          _switchMode(AppMode.operations);
        },
      ),
      OperationNotification(
        id: 'notif_3',
        title: 'Utility Bill Reconciled',
        subtitle: 'Lamar Compound electricity card dues settled: 2,100.00 EGP.',
        time: '1h ago',
        icon: Icons.receipt_long_outlined,
        iconColor: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DocumentViewerScreen(
                title: 'Electricity Receipt',
                documentUrl: 'https://gateway.ihome.com.eg/pay/invoice_lm_bill_elec.html',
              ),
            ),
          );
        },
      ),
    ];
  }

  void _switchMode(AppMode mode) {
    if (_appMode == mode) return;
    setState(() {
      _appMode = mode;
      _updateActiveModules(mode);
      _currentIndex = 0;
    });
  }

  List<Widget> _getScreens() {
    if (_appMode == AppMode.brokerage) {
      return const [
        DashboardScreen(),
        BookingHistoryScreen(),
        EoiCaptureScreen(),
        PrypcoHubScreen(),
      ];
    } else {
      return const [
        PropertyOpsDashboard(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavigationItems() {
    if (_appMode == AppMode.brokerage) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'DISCOVERY',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'CRM & LEDGER',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'EOI CAPTURE',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart_outline_rounded),
          activeIcon: Icon(Icons.pie_chart),
          label: 'PRYPCO HUB',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.domain_outlined),
          activeIcon: Icon(Icons.domain),
          label: 'OPERATIONS',
        ),
      ];
    }
  }

  Future<void> _handleLogout() async {
    await SyncScope.of(context).logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isFaceIdChecking) {
      return Scaffold(
        backgroundColor: LuxuryTheme.backgroundBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: LuxuryTheme.primaryGold, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.face_retouching_natural, color: LuxuryTheme.primaryGold, size: 44),
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
                              color: LuxuryTheme.primaryGold,
                              boxShadow: [
                                BoxShadow(
                                  color: LuxuryTheme.primaryGold.withAlpha(200),
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
                  color: LuxuryTheme.primaryGold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Connecting to secure registry assets...',
                style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 8.5),
              ),
            ],
          ),
        ),
      );
    }

    if (_isTransitioning) {
      return Scaffold(
        backgroundColor: LuxuryTheme.backgroundBlack,
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

    final screens = _getScreens();
    final items = _getNavigationItems();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: LuxuryTheme.backgroundBlack,
        automaticallyImplyLeading: false,
        title: _buildExecutiveToggle(),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: luxuryThemeNotifier,
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: IconButton(
                  key: ValueKey(isDark),
                  icon: Icon(
                    isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                    color: LuxuryTheme.primaryGold,
                    size: 24,
                  ),
                  tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  onPressed: () {
                    luxuryThemeNotifier.value =
                        isDark ? ThemeMode.light : ThemeMode.dark;
                  },
                ),
              );
            },
          ),
          _buildLiveSyncIndicator(),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: LuxuryTheme.primaryGold, size: 28),
                  onPressed: () {
                    setState(() {
                      _showNotifications = !_showNotifications;
                    });
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: LuxuryTheme.primaryGold,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_notifications.length}',
                      style: const TextStyle(
                        color: LuxuryTheme.backgroundBlack,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),
          _buildNotificationSheetGrid3Column(),
        ],
      ),
      bottomNavigationBar: items.length > 1
          ? Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: LuxuryTheme.cardBrown, width: 1.5)),
              ),
              child: BottomNavigationBar(
                backgroundColor: LuxuryTheme.surfaceBrown,
                currentIndex: _currentIndex,
                selectedItemColor: LuxuryTheme.primaryGold,
                unselectedItemColor: LuxuryTheme.textMuted,
                selectedFontSize: 9,
                unselectedFontSize: 9,
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

  Widget _buildLiveSyncIndicator() {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: PriceSyncRepository.instance.statusNotifier,
      builder: (context, status, _) {
        final color = status == SyncStatus.live
            ? Colors.green
            : status == SyncStatus.syncing
                ? LuxuryTheme.primaryGold
                : status == SyncStatus.offline
                    ? Colors.red
                    : Colors.orange;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Tooltip(
            message: 'Price Sync: ${status.name.toUpperCase()}',
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withAlpha(120), blurRadius: 6, spreadRadius: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExecutiveToggle() {
    return Container(
      height: 40,
      width: 280,
      decoration: BoxDecoration(
        color: LuxuryTheme.cardBrown,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LuxuryTheme.primaryGold, width: 1.5),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _appMode == AppMode.brokerage ? 2 : 138,
            top: 2,
            child: Container(
              height: 32,
              width: 136,
              decoration: BoxDecoration(
                color: LuxuryTheme.primaryGold,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchMode(AppMode.brokerage),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'SALES MODE',
                      style: TextStyle(
                        color: _appMode == AppMode.brokerage
                            ? LuxuryTheme.backgroundBlack
                            : LuxuryTheme.textWhite,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchMode(AppMode.operations),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'OWNER/OPS MODE',
                      style: TextStyle(
                        color: _appMode == AppMode.operations
                            ? LuxuryTheme.backgroundBlack
                            : LuxuryTheme.textWhite,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSheetGrid3Column() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      bottom: _showNotifications ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      child: Container(
        height: 480,
        decoration: BoxDecoration(
          color: LuxuryTheme.surfaceBrown,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(color: LuxuryTheme.primaryGold, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(200), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, color: LuxuryTheme.primaryGold, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'REAL-TIME SYSTEM OPERATIONS',
                        style: TextStyle(
                          color: LuxuryTheme.primaryGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _handleLogout,
                        child: const Text(
                          'SIGN OUT',
                          style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 9),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: LuxuryTheme.primaryGold),
                        onPressed: () {
                          setState(() {
                            _showNotifications = false;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: LuxuryTheme.cardBrown),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  return InteractiveTapBounce(
                    onTap: () {
                      setState(() {
                        _showNotifications = false;
                      });
                      notif.onTap();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LuxuryTheme.cardBrown,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: notif.iconColor.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(notif.icon, color: notif.iconColor, size: 18),
                              ),
                              Text(
                                notif.time,
                                style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            notif.title,
                            style: const TextStyle(
                              color: LuxuryTheme.textWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              notif.subtitle,
                              style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 8.5),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}


