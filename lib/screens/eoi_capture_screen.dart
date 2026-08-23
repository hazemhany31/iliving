import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../models/compound_model.dart';
import '../repositories/compound_repository.dart';
import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';
import '../widgets/image_loader.dart';
import '../l10n/app_localizations.dart';

class EoiCaptureScreen extends StatefulWidget {
  const EoiCaptureScreen({super.key});

  @override
  State<EoiCaptureScreen> createState() => _EoiCaptureScreenState();
}

class _EoiCaptureScreenState extends State<EoiCaptureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  int _selectedDevelopmentIndex = 0;
  String _selectedUnitType = '2 BR';
  bool _isLoading = true;
  bool _isSubmitting = false;

  final CompoundRepository _repository = CompoundRepository();
  List<CompoundModel> _compounds = [];

  final List<String> _unitTypes = ['1 BR', '2 BR', '3 BR', 'Penthouse', 'Duplex', 'Villa'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final compounds = await _repository.fetchCompounds();
    if (mounted) {
      setState(() {
        _compounds = compounds;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final iconColor = isDark ? AppColors.textLight : AppColors.textDark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        title: Text(
          l10n.eoiTitle.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView(isDark)
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectDeveloperPortfolio.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _compounds.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.82,
                        ),
                        itemBuilder: (context, index) {
                          final compound = _compounds[index];
                          final isSelected = _selectedDevelopmentIndex == index;

                          return InteractiveTapBounce(
                            onTap: () {
                              setState(() {
                                _selectedDevelopmentIndex = index;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppColors.accent : AppColors.primary)
                                    : cardBg,
                                borderRadius: AppBorderRadius.medium,
                                boxShadow: isSelected
                                    ? (isDark ? AppShadows.darkElevated : AppShadows.elevated)
                                    : (isDark ? AppShadows.darkSoft : AppShadows.soft),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: ImageLoader(
                                        imageUrl: compound.cardImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      compound.title,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: isSelected
                                            ? Colors.white
                                            : textColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.selectUnitSpecification.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _unitTypes.map((type) {
                          final isSelected = _selectedUnitType == type;

                          return InteractiveTapBounce(
                            onTap: () {
                              setState(() {
                                _selectedUnitType = type;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppColors.accent : AppColors.primary)
                                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                                borderRadius: AppBorderRadius.pill,
                                boxShadow: isSelected
                                    ? (isDark ? AppShadows.darkSoft : AppShadows.soft)
                                    : null,
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: isSelected
                                      ? Colors.white
                                      : textColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.prospectClientDossier.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildModernTextField(
                        controller: _nameController,
                        label: l10n.clientLegalName,
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.clientLegalName;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildModernTextField(
                        controller: _emailController,
                        label: l10n.clientEmail,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.clientEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildModernTextField(
                        controller: _phoneController,
                        label: l10n.verifiedMobile,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.verifiedMobile;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildModernTextField(
                        controller: _amountController,
                        label: 'EOI Deposit Value (EGP)',
                        icon: Icons.monetization_on_outlined,
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Financial allocation is mandatory';
                          }
                          final amt = double.tryParse(value);
                          if (amt == null || amt < 50000) {
                            return 'Minimum VIP tier allocation is 50,000 EGP';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isSubmitting = true;
                                    });
                                    final selectedCompound = _compounds[_selectedDevelopmentIndex];
                                    try {
                                      await _repository.submitEOI(
                                        clientName: _nameController.text,
                                        clientEmail: _emailController.text,
                                        clientPhone: _phoneController.text,
                                        amount: _amountController.text,
                                        compoundId: selectedCompound.id,
                                        compoundTitle: selectedCompound.title,
                                        unitType: _selectedUnitType,
                                      );
                                    } catch (e) {
                                      debugPrint("Error submitting EOI: $e");
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isSubmitting = false;
                                        });
                                      }
                                    }

                                    if (!context.mounted) return;
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
                                        return Container(
                                          padding: const EdgeInsets.all(28),
                                          decoration: BoxDecoration(
                                            color: surfaceBg,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                            boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success.withAlpha(25),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.verified_rounded,
                                                  color: AppColors.success,
                                                  size: 44,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'EOI CAPTURED SUCCESSFULLY',
                                                style: TextStyle(
                                                  fontFamily: AppTextStyles.fontFamily,
                                                  color: textColor,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Client ${_nameController.text} has been successfully locked for the ${selectedCompound.title} $_selectedUnitType allocation.',
                                                style: TextStyle(
                                                  fontFamily: AppTextStyles.fontFamily,
                                                  color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                                                  fontSize: 12,
                                                  height: 1.4,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 24),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 48,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    Navigator.pop(context);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: AppBorderRadius.pill,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'DONE',
                                                    style: TextStyle(
                                                      fontFamily: AppTextStyles.fontFamily,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppBorderRadius.pill,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  l10n.commitEoi.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppBorderRadius.medium,
        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: textColor,
          fontSize: 13,
        ),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: textMuted,
            fontSize: 12,
          ),
          prefixIcon: Icon(icon, color: AppColors.accent, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLoadingView(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LuxuryShimmer(width: 160, height: 16),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppBorderRadius.medium,
              ),
              child: const LuxuryShimmer(width: double.infinity, height: 100),
            ),
          ),
        ],
      ),
    );
  }
}
