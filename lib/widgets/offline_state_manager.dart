import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';

class OfflineStateManager extends StatefulWidget {
  final Widget child;
  final void Function(bool isOffline)? onConnectivityChanged;

  static final ValueNotifier<bool> forceOnline = ValueNotifier(true);

  const OfflineStateManager({
    super.key,
    required this.child,
    this.onConnectivityChanged,
  });

  @override
  State<OfflineStateManager> createState() => _OfflineStateManagerState();
}

class _OfflineStateManagerState extends State<OfflineStateManager>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  Timer? _connectivityTimer;
  late final AnimationController _bannerController;
  late final Animation<Offset> _bannerSlide;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.fastOutSlowIn,
    ));
    _startMonitoring();
    OfflineStateManager.forceOnline.addListener(_onForceOnlineChanged);
  }

  void _onForceOnlineChanged() {
    _checkConnectivity();
  }

  void _startMonitoring() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkConnectivity();
    });
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    if (OfflineStateManager.forceOnline.value) {
      _updateState(false);
      return;
    }
    // Primary check: use a reliable public host to verify actual internet
    for (final host in ['google.com', '1.1.1.1', 'gateway.iliving.com.eg']) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          _updateState(false); // We're online
          return;
        }
      } catch (_) {
        // Try next host
      }
    }
    // All hosts failed — truly offline
    _updateState(true);
  }

  void _updateState(bool isOffline) {
    if (!mounted) return;
    if (_isOffline == isOffline) return;
    setState(() {
      _isOffline = isOffline;
    });
    widget.onConnectivityChanged?.call(isOffline);
    if (isOffline) {
      _bannerController.forward();
    } else {
      _bannerController.reverse();
    }
  }

  @override
  void dispose() {
    OfflineStateManager.forceOnline.removeListener(_onForceOnlineChanged);
    _connectivityTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        SlideTransition(
          position: _bannerSlide,
          child: _buildOfflineBanner(),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1007), Color(0xFF2B1D04)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              bottom: BorderSide(color: LuxuryTheme.primaryGold, width: 1.5),
            ),
          ),
          child: Row(
            children: [
              _PulsingOfflineIcon(),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وضع عدم الاتصال  —  OFFLINE MODE',
                      style: TextStyle(
                        color: LuxuryTheme.primaryGold,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Displaying cached registry assets in read-only mode',
                      style: TextStyle(
                        color: LuxuryTheme.textMuted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: LuxuryTheme.primaryGold.withAlpha(28),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: LuxuryTheme.primaryGold, width: 1),
                ),
                child: const Text(
                  'READ-ONLY',
                  style: TextStyle(
                    color: LuxuryTheme.primaryGold,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingOfflineIcon extends StatefulWidget {
  @override
  State<_PulsingOfflineIcon> createState() => _PulsingOfflineIconState();
}

class _PulsingOfflineIconState extends State<_PulsingOfflineIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Icon(
          Icons.wifi_off_rounded,
          color: LuxuryTheme.primaryGold.withValues(alpha: _pulseAnim.value),
          size: 18,
        );
      },
    );
  }
}

class OfflineAwareWrapper extends StatefulWidget {
  final Widget Function(bool isOffline) builder;
  final String checkHost;

  const OfflineAwareWrapper({
    super.key,
    required this.builder,
    this.checkHost = 'gateway.iliving.com.eg',
  });

  @override
  State<OfflineAwareWrapper> createState() => _OfflineAwareWrapperState();
}

class _OfflineAwareWrapperState extends State<OfflineAwareWrapper> {
  bool _isOffline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
    _check();
    OfflineStateManager.forceOnline.addListener(_onForceOnlineChanged);
  }

  void _onForceOnlineChanged() {
    _check();
  }

  Future<void> _check() async {
    if (OfflineStateManager.forceOnline.value) {
      if (mounted && _isOffline) setState(() => _isOffline = false);
      return;
    }
    for (final host in ['google.com', '1.1.1.1', widget.checkHost]) {
      try {
        final r = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 3));
        final ok = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
        if (ok) {
          if (mounted && _isOffline) setState(() => _isOffline = false);
          return;
        }
      } catch (_) {
        // Try next host
      }
    }
    // All hosts failed — truly offline
    if (mounted && !_isOffline) setState(() => _isOffline = true);
  }

  @override
  void dispose() {
    OfflineStateManager.forceOnline.removeListener(_onForceOnlineChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_isOffline);
}
