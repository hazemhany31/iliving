import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../services/auth_mock_data.dart';
import '../repositories/operations_mock_data.dart';
import '../models/unit_ledger_model.dart';
import '../services/auth_service.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String title;
  final String documentUrl;

  const DocumentViewerScreen({
    super.key,
    required this.title,
    required this.documentUrl,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isRefreshing = false;

  void _refreshDocument() {
    setState(() {
      _isRefreshing = true;
    });
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    });
  }

  String _formatCommas(String val) {
    try {
      final doubleValue = double.tryParse(val);
      if (doubleValue == null) return val;
      final parts = doubleValue.toStringAsFixed(0).split('.');
      final whole = parts[0];
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return whole.replaceAllMapped(reg, (Match m) => '${m[1]},');
    } catch (_) {
      return val;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final iconColor = isDark ? AppColors.textLight : AppColors.textDark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    final String url = widget.documentUrl;
    final bool isBill = url.contains('bill') || url.contains('elec') || widget.title.toLowerCase().contains('bill');
    final bool isInvoice = (url.contains('invoice') || url.contains('receipt') || widget.title.contains('Invoice') || widget.title.toLowerCase().contains('receipt') || url.contains('pay')) && !isBill;
    final bool isContract = url.contains('contract') || widget.title.contains('SPA') || url.contains('spa');

    String clientName = 'iLiving Client';
    String unitId = 'B01B202';
    String baseAmount = '15,200,000';
    String vat = '760,000';
    String netTotal = '15,960,000';
    String docRef = 'REF: EGP-INV-2026-889';

    String development = 'Zayed Lagoons';
    String assetClass = 'Luxury Penthouse';
    String location = 'West Cairo';
    String areaSqft = '4,800 SQFT';
    String rmAssigned = 'iLiving Advisor';
    String dpStatus = 'PAID (10%)';

    String metricType = 'Electricity';
    String compound = 'Sky Hills';
    String billDue = '05 June 2026';
    String billAmount = '4,500 EGP';
    String billStatus = 'Outstanding';

    final user = AuthService.instance.currentProfile;
    if (user != null) {
      clientName = user.displayName;
      if (user.ownedUnitIds.isNotEmpty) {
        unitId = user.ownedUnitIds.first;
      }
    }

    final receiptMatch = RegExp(r'receipt_([a-zA-Z0-9_]+)').firstMatch(url);
    if (receiptMatch != null) {
      final codeSegment = receiptMatch.group(1) ?? '';
      final parts = codeSegment.split('_');
      final code = parts.first;
      final typeKey = parts.last;
      String? targetUnitId;
      if (parts.length > 2) {
        targetUnitId = parts[1];
      }

      final mockUser = AuthMockData.mockUsers.firstWhere(
        (u) => u['code'] == code,
        orElse: () => {'name': 'iLiving Client', 'unit': 'B01B202'},
      );
      clientName = mockUser['name'] ?? 'iLiving Client';
      unitId = targetUnitId ?? mockUser['unit'] ?? 'B01B202';

      UnitLedger? ledger;
      try {
        if (targetUnitId != null) {
          ledger = OperationsMockData.dummyLedgers.firstWhere(
            (l) => l.clientId == 'client_$code' && l.unitId == targetUnitId,
          );
        } else {
          ledger = OperationsMockData.dummyLedgers.firstWhere(
            (l) => l.clientId == 'client_$code',
          );
        }
      } catch (_) {}

      if (ledger != null) {
        double amt = 0.0;
        if (typeKey == 'DP') {
          amt = ledger.downPayment.amountEGP;
        } else if (typeKey == 'MAINT') {
          amt = ledger.maintenance.balanceEGP;
        } else {
          for (final inst in ledger.installments) {
            final instKey = inst.id.split('-').last;
            if (instKey == typeKey) {
              amt = inst.amountEGP;
              break;
            }
          }
          if (amt == 0.0 && ledger.installments.isNotEmpty) {
            amt = ledger.installments.first.amountEGP;
          }
        }
        baseAmount = _formatCommas(amt.toStringAsFixed(0));
        vat = _formatCommas((amt * 0.05).toStringAsFixed(0));
        netTotal = _formatCommas((amt * 1.05).toStringAsFixed(0));
      }
      docRef = 'REF: REC-${code.toUpperCase()}-EGP';
    }

    if (isContract) {
      development = 'Zayed Lagoons';
      assetClass = 'Luxury Penthouse';
      location = 'West Cairo';
      areaSqft = '3,200 SQFT';
      rmAssigned = 'iLiving Relations';
      dpStatus = 'PAID (10%)';

      final uri = Uri.tryParse(url);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final filename = uri.pathSegments.last.replaceAll('.pdf', '').replaceAll('_', ' ');
        if (filename.toLowerCase().contains('zayed lagoons')) {
          development = 'Zayed Lagoons';
          location = 'West Cairo';
        } else if (filename.toLowerCase().contains('sky hills')) {
          development = 'Sky Hills';
          location = 'New October';
        }
        final unitMatch = RegExp(r'\d+').firstMatch(filename);
        if (unitMatch != null) {
          unitId = 'UNIT ${unitMatch.group(0)}';
        }
      }
      docRef = 'SPA-${unitId.replaceAll(' ', '')}-2026';
    }

    if (isBill) {
      metricType = url.contains('elec') ? 'Electricity' : (url.contains('water') ? 'Water' : 'Utility');
      compound = url.contains('lm') ? 'Lamar Compound' : (url.contains('sh') ? 'Sky Hills' : 'Lamar Compound');
      unitId = url.contains('1204') ? 'SH/12/1204' : (url.contains('801') ? 'ZL/08/801' : unitId);
      billDue = '05 June 2026';
      billAmount = url.contains('elec') ? '4,500 EGP' : (url.contains('water') ? '1,200 EGP' : '3,500 EGP');
      billStatus = 'Outstanding';
      docRef = 'BILL-${compound.substring(0, 2).toUpperCase()}-2026';
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        title: Text(
          widget.title.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Color(0xFFFF5F56), size: 9),
                    const SizedBox(width: 5),
                    const Icon(Icons.circle, color: Color(0xFFFFBD2E), size: 9),
                    const SizedBox(width: 5),
                    const Icon(Icons.circle, color: Color(0xFF27C93F), size: 9),
                    const SizedBox(width: 14),
                    Icon(Icons.arrow_back_rounded, color: textMuted, size: 16),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: textMuted, size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : Colors.white,
                          borderRadius: AppBorderRadius.pill,
                          boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 12),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.documentUrl,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 10,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.accent,
                              ),
                            )
                          : Icon(Icons.refresh_rounded, color: textMuted, size: 18),
                      onPressed: _refreshDocument,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
                  ),
                  child: _isRefreshing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isInvoice
                                            ? 'OFFICIAL PAYMENT RECEIPT'
                                            : isContract
                                                ? 'VIP SPA CONTRACT'
                                                : 'DIGITAL UTILITY BILL',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        docRef,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withAlpha(25),
                                      borderRadius: AppBorderRadius.pill,
                                    ),
                                    child: const Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: AppColors.success,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 24),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.25,
                                children: isInvoice
                                    ? [
                                        _buildGridCard('CLIENT NAME', clientName, isDark),
                                        _buildGridCard('UNIT ID', unitId, isDark),
                                        _buildGridCard('CURRENCY', 'EGP (ج.م)', isDark),
                                        _buildGridCard('BASE AMOUNT', baseAmount, isDark),
                                        _buildGridCard('VAT (5%)', vat, isDark),
                                        _buildGridCard('NET TOTAL', netTotal, isDark),
                                      ]
                                    : isContract
                                        ? [
                                            _buildGridCard('DEVELOPMENT', development, isDark),
                                            _buildGridCard('ASSET CLASS', assetClass, isDark),
                                            _buildGridCard('LOCATION', location, isDark),
                                            _buildGridCard('AREA SQFT', areaSqft, isDark),
                                            _buildGridCard('RM ASSIGNED', rmAssigned, isDark),
                                            _buildGridCard('DOWN PAYMENT', dpStatus, isDark),
                                          ]
                                        : [
                                            _buildGridCard('METRIC TYPE', metricType, isDark),
                                            _buildGridCard('COMPOUND', compound, isDark),
                                            _buildGridCard('UNIT ID', unitId, isDark),
                                            _buildGridCard('DUE DATE', billDue, isDark),
                                            _buildGridCard('AMOUNT DUE', billAmount, isDark),
                                            _buildGridCard('BILL STATUS', billStatus, isDark),
                                          ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'LEGAL DISCLAIMER & COMPLIANCE',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'This secure document representation is verified under regulatory frameworks of West Cairo Authority and is dynamically synced with iLiving Developer Core Services. IPFS hash audit verification can be inspected dynamically under secondary key layers.',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 9.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                                  borderRadius: AppBorderRadius.medium,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'E-SIGNATURE DOCK STATUS',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: textColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      isContract ? 'PENDING USER COUNTER-SIGN' : 'SECURED & RECONCILED',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: isContract ? AppColors.warning : AppColors.success,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('E-Signature verified. Contract locks in transaction ledger.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppBorderRadius.pill,
                            ),
                          ),
                          child: Text(
                            'CO-SIGN SECURELY',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reconciliation statement exported to client files.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
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
                            'EXPORT STATUS',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(String label, String value, bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
        borderRadius: AppBorderRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textMuted,
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
