import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../models/compound_model.dart';
import '../repositories/compound_repository.dart';
import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';

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
  String _selectedPaymentMethod = 'Bank Transfer';
  bool _isLoading = true;

  final CompoundRepository _repository = CompoundRepository();
  List<CompoundModel> _compounds = [];

  final List<String> _unitTypes = ['1 BR', '2 BR', '3 BR', 'Penthouse', 'Duplex', 'Villa'];
  final List<String> _paymentMethods = ['Bank Transfer', 'Credit Card (Stripe)', 'Crypto Escrow', 'Cheque Deposit'];

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
    return Scaffold(
      backgroundColor: LuxuryTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text(
          'EXPRESSION OF INTEREST (EOI)',
          style: TextStyle(
            color: LuxuryTheme.primaryGold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: LuxuryTheme.primaryGold, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELECT DEVELOPER PORTFOLIO',
                        style: TextStyle(
                          color: LuxuryTheme.primaryGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _compounds.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.85,
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
                                color: LuxuryTheme.surfaceBrown,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.cardBrown,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          topRight: Radius.circular(6),
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(compound.cardImageUrl),
                                          fit: BoxFit.cover,
                                          onError: (e, s) {},
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      compound.title,
                                      style: TextStyle(
                                        color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.textWhite,
                                        fontSize: 8.5,
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
                      const Text(
                        'SELECT UNIT SPECIFICATION',
                        style: TextStyle(
                          color: LuxuryTheme.primaryGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _unitTypes.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.2,
                        ),
                        itemBuilder: (context, index) {
                          final type = _unitTypes[index];
                          final isSelected = _selectedUnitType == type;

                          return InteractiveTapBounce(
                            onTap: () {
                              setState(() {
                                _selectedUnitType = type;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? LuxuryTheme.cardBrown : LuxuryTheme.surfaceBrown,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.cardBrown,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.textWhite,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'PROSPECT CLIENT DOSSIER',
                        style: TextStyle(
                          color: LuxuryTheme.primaryGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Client Legal Entity / Individual Name',
                          prefixIcon: Icon(Icons.person_outline, color: LuxuryTheme.primaryGold),
                        ),
                        style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 13),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Legal identifier is mandatory';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Client Secure Contact Email',
                          prefixIcon: Icon(Icons.email_outlined, color: LuxuryTheme.primaryGold),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 13),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Secure contact point is mandatory';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Verified Mobile (Including CC)',
                          prefixIcon: Icon(Icons.phone_outlined, color: LuxuryTheme.primaryGold),
                        ),
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 13),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Verification protocol number required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'EOI Deposit Value (EGP)',
                          prefixIcon: Icon(Icons.monetization_on_outlined, color: LuxuryTheme.primaryGold),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 13),
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
                      const SizedBox(height: 24),
                      const Text(
                        'ESCROW FUNDING METHOD',
                        style: TextStyle(
                          color: LuxuryTheme.primaryGold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _paymentMethods.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.1,
                        ),
                        itemBuilder: (context, index) {
                          final method = _paymentMethods[index];
                          final isSelected = _selectedPaymentMethod == method;

                          return InteractiveTapBounce(
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = method;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? LuxuryTheme.cardBrown : LuxuryTheme.surfaceBrown,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.cardBrown,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                method,
                                style: TextStyle(
                                  color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.textWhite,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      InteractiveTapBounce(
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            final selectedCompound = _compounds[_selectedDevelopmentIndex];
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: false,
                              barrierColor: Colors.black.withAlpha(204),
                              transitionDuration: const Duration(milliseconds: 500),
                              pageBuilder: (context, anim1, anim2) {
                                return Center(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      margin: const EdgeInsets.all(24),
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: LuxuryTheme.surfaceBrown,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: LuxuryTheme.primaryGold, width: 2),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_sharp,
                                            color: LuxuryTheme.primaryGold,
                                            size: 50,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'EOI CAPTURED SUCCESSFULLY',
                                            style: TextStyle(
                                              color: LuxuryTheme.primaryGold,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Client ${_nameController.text} has been successfully locked for the ${selectedCompound.title} $_selectedUnitType allocation. EOI Certificate has been pushed to registration ledger.',
                                            style: const TextStyle(color: LuxuryTheme.textSilver, fontSize: 11, height: 1.4),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 24),
                                          InteractiveTapBounce(
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: LuxuryTheme.primaryGold,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'CLOSE PROTOCOL',
                                                style: TextStyle(
                                                  color: LuxuryTheme.backgroundBlack,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                LuxuryTheme.deepGold,
                                LuxuryTheme.primaryGold,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: LuxuryTheme.primaryGold, width: 1),
                          ),
                          child: const Text(
                            'COMMIT SECURE EOI CAPTURE',
                            style: TextStyle(
                              color: LuxuryTheme.backgroundBlack,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.0,
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

  Widget _buildLoadingView() {
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
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) => const LuxuryShimmer(width: double.infinity, height: 100),
          ),
        ],
      ),
    );
  }
}
