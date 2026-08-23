import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sync_state.dart';
import '../services/locale_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/ihome_button.dart';

class OnboardingSlide {
  final String image;
  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;

  const OnboardingSlide({
    required this.image,
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
  });
}

/// Onboarding & Login Screen matching Screen 1 of the Abu Hossain Dribbble reference.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  bool _isFormVisible = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      image: 'images/lamar/lamar-1.jpg',
      titleEn: 'Buy, Sell, Rent Every\nProperty Easily',
      titleAr: 'بيع، شراء، وتأجير\nالعقارات بكل سهولة',
      subtitleEn: 'Discover, list, and manage homes, offices, and\nproperties effortlessly today.',
      subtitleAr: 'اكتشف وأدر المنازل، المكاتب، والعقارات\nالمتميزة بسلاسة ومرونة.',
    ),
    OnboardingSlide(
      image: 'images/zayed_lagoons/zayed-lahogons1.jpg',
      titleEn: 'Explore Modern Living\nSpaces Near You',
      titleAr: 'استكشف مساحات\nالمعيشة العصرية بالقرب منك',
      subtitleEn: 'Experience smart amenities, lagoon views, and\nworld-class luxury communities.',
      subtitleAr: 'عش تجربة المرافق الذكية والإطلالات الخلابة\nفي مجتمعات سكنية متكاملة.',
    ),
    OnboardingSlide(
      image: 'images/skyhills/ski-hills.jpg',
      titleEn: 'Premium Real Estate\nat Your Fingertips',
      titleAr: 'عقارات استثنائية\nبين يديك مباشرة',
      subtitleEn: 'Track installments, manage smart gate passes,\nand book prime units in seconds.',
      subtitleAr: 'تابع الأقساط، تصاريح البوابات الذكية،\nواحجز وحدتك في ثوانٍ معدودة.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlideTimer();
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _isFormVisible) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await SyncScope.of(context)
        .login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.invalidCredentials;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = LocaleService.instance.isArabic;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Natural native PageView with Image + Gradient + Text per slide
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final slide = _slides[index];
              final title = isAr ? slide.titleAr : slide.titleEn;
              final subtitle = isAr ? slide.subtitleAr : slide.subtitleEn;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full-bleed background image
                  Image.asset(
                    slide.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),

                  // Gradient scrim
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.35, 0.65, 1.0],
                          colors: [
                            Colors.black.withAlpha(80),
                            Colors.transparent,
                            Colors.black.withAlpha(200),
                            Colors.black.withAlpha(245),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Text content for this slide (moves naturally with page scroll)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: bottomInset + 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withAlpha(200),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Fixed Top bar (Brand + Language pill)
          _buildTopBar(isDark),

          // 3. Fixed Bottom controls (Dots + Get Started button + Sign In link)
          if (!_isFormVisible)
            Positioned(
              left: 24,
              right: 24,
              bottom: bottomInset + 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clean standard animated dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_slides.length, (index) {
                      final isSelected = index == _currentPage;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(right: 6),
                          width: isSelected ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withAlpha(100),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Big White Pill "Get Started" CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      key: const Key('get_started_btn'),
                      onPressed: () {
                        setState(() {
                          _isFormVisible = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A1A2E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorderRadius.pill,
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Direct Sign In Text Button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isFormVisible = true;
                        });
                      },
                      child: Text(
                        '${AppLocalizations.of(context).signIn} with account',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(210),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 4. Slide-up clean white login sheet when activated
          if (_isFormVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildLoginFormSheet(isDark),
            ),

          // 5. Biometric scanning overlay if loading
          if (_isLoading) _buildBiometricOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final isAr = LocaleService.instance.isArabic;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: AppSpacing.pageHorizontal,
      right: AppSpacing.pageHorizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: AppBorderRadius.pill,
              border: Border.all(color: Colors.white.withAlpha(30), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.domain_rounded,
                    color: Color(0xFF1A1A2E),
                    size: 13,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'iHOME',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),

          // Language Switcher Pill
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => LocaleService.instance.toggleLocale(),
              borderRadius: AppBorderRadius.pill,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  borderRadius: AppBorderRadius.pill,
                  border: Border.all(color: Colors.white.withAlpha(30), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? l10n.english : l10n.arabic,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Slide-up white card for Email/Password Sign-In
  Widget _buildLoginFormSheet(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24.0,
        20.0,
        24.0,
        MediaQuery.of(context).padding.bottom + 20.0,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header row with back / close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.signIn,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.loginSubtitle,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: textMuted,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFormVisible = false;
                      _errorMessage = null;
                    });
                    _startAutoSlideTimer();
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Email pill input
            _buildPillTextField(
              id: 'login_email_field',
              controller: _emailController,
              label: l10n.email,
              hint: 'name@example.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return l10n.email;
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Password pill input
            _buildPillTextField(
              id: 'login_password_field',
              controller: _passwordController,
              label: l10n.password,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              isDark: isDark,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return l10n.password;
                return null;
              },
            ),

            // Error banner
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(isDark ? 30 : 15),
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Debug Demo User Quick Selectors
            if (kDebugMode) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('demo_user_a_btn'),
                      onPressed: () {
                        setState(() {
                          _emailController.text = 'ahmed.shazly.abdelgawad@new-build-egypt.com';
                          _passwordController.text = 'iliving2026';
                          _errorMessage = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      child: const Text('User A (Ahmed)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('demo_user_b_btn'),
                      onPressed: () {
                        setState(() {
                          _emailController.text = 'mahmoud.ghanem.ibrahim@new-build-egypt.com';
                          _passwordController.text = 'iliving2026';
                          _errorMessage = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      child: const Text('User B (Mahmoud)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Primary Pill Submit Button
            IHomeButton(
              key: const Key('login_submit_btn'),
              text: l10n.signIn,
              onPressed: _isLoading ? null : _attemptLogin,
              isLoading: _isLoading,
              height: 52,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTextField({
    required String id,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: Key(id),
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        color: isDark ? AppColors.textLight : AppColors.textDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
          size: 18,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.pill,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.pill,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
          fontSize: 13,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildBiometricOverlay(bool isDark) {
    return Container(
      color: Colors.black.withAlpha(220),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(25),
                border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SIGNING IN...',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Connecting to iHome network',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.white.withAlpha(180),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
