import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../services/sync_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await SyncScope.of(context)
        .login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid credentials. Please check your email and password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxuryTheme.backgroundBlack,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackgroundDecoration(),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildLogoHeader(),
                  const SizedBox(height: 52),
                  _buildLoginForm(),
                  const SizedBox(height: 32),
                  _buildDemoCredentialsGrid(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            if (_isLoading) _buildBiometricOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned(
      top: -100,
      right: -80,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              LuxuryTheme.primaryGold.withAlpha(25),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _pulseAnimation.value,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: LuxuryTheme.primaryGold,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: LuxuryTheme.primaryGold.withAlpha(80),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.domain_rounded,
                  color: LuxuryTheme.backgroundBlack,
                  size: 28,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'iHOME',
          style: TextStyle(
            color: LuxuryTheme.primaryGold,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 6.0,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'LUXURY CLIENT PORTAL',
          style: TextStyle(
            color: LuxuryTheme.textMuted,
            fontSize: 10,
            letterSpacing: 3.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 48,
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [LuxuryTheme.primaryGold, LuxuryTheme.darkGold],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SECURE ACCESS',
            style: TextStyle(
              color: LuxuryTheme.primaryGold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            id: 'login_email_field',
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email is required';
              if (!val.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            id: 'login_password_field',
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: LuxuryTheme.textMuted,
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Password is required';
              if (val.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withAlpha(80), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              key: const Key('login_submit_btn'),
              onPressed: _isLoading ? null : _attemptLogin,
              child: const Text(
                'SECURE SIGN IN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String id,
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
      style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: LuxuryTheme.primaryGold, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: LuxuryTheme.surfaceBrown,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LuxuryTheme.cardBrown, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LuxuryTheme.primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        labelStyle: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 13),
      ),
      validator: validator,
    );
  }

  Widget _buildDemoCredentialsGrid() {
    final accounts = [
      {'email': 'demo@ihome.com.eg', 'pass': 'ihome2026', 'role': 'DEMO'},
      {'email': 'sterling@ihome.com.eg', 'pass': 'sterling2026', 'role': 'BROKER'},
      {'email': 'admin@new-build-egypt.com', 'pass': 'admin2026', 'role': 'ADMIN'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 20, height: 1, color: LuxuryTheme.cardBrown),
            const SizedBox(width: 8),
            const Text(
              'DEMO ACCESS CREDENTIALS',
              style: TextStyle(
                color: LuxuryTheme.textMuted,
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: LuxuryTheme.cardBrown)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: accounts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final acc = accounts[index];
            return GestureDetector(
              onTap: () {
                _emailController.text = acc['email']!;
                _passwordController.text = acc['pass']!;
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LuxuryTheme.surfaceBrown,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: LuxuryTheme.primaryGold.withAlpha(30),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        acc['role']!,
                        style: const TextStyle(
                          color: LuxuryTheme.primaryGold,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      acc['email']!.split('@').first,
                      style: const TextStyle(
                        color: LuxuryTheme.textWhite,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'TAP TO FILL',
                      style: TextStyle(
                        color: LuxuryTheme.textMuted,
                        fontSize: 7,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBiometricOverlay() {
    return Container(
      color: LuxuryTheme.backgroundBlack.withAlpha(230),
      child: Center(
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
                    onEnd: () => setState(() {}),
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
}
