import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../repositories/operations_repository.dart';
import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';
import '../widgets/offline_state_manager.dart';
import '../widgets/cached_gate_pass_widget.dart';
import 'document_viewer_screen.dart';

class PropertyOpsDashboard extends StatefulWidget {
  const PropertyOpsDashboard({super.key});

  @override
  State<PropertyOpsDashboard> createState() => _PropertyOpsDashboardState();
}

class _PropertyOpsDashboardState extends State<PropertyOpsDashboard> with TickerProviderStateMixin {
  int _selectedCompoundIndex = 0;
  bool _isWhatsAppSharing = false;
  bool _isNfcScanning = false;
  double _nfcBalance = 2400.00;

  bool _showCheckout = false;
  bool _isCheckoutBiometric = false;
  bool _isReceiptPrinted = false;
  bool _isReceiptTorn = false;
  String _checkoutTitle = '';
  String _checkoutUnit = '';
  double _checkoutAmount = 0.0;
  VoidCallback? _onCheckoutSuccess;

  List<Map<String, dynamic>> _compoundsList = [];
  bool _isLoading = true;
  bool _isOffline = false;
  final OperationsRepository _repository = OperationsRepository();
  StreamSubscription? _compoundsSubscription;

  @override
  void initState() {
    super.initState();
    _compoundsSubscription = _repository.streamCompoundOpsData().listen((data) {
      if (mounted) {
        setState(() {
          _compoundsList = data;
          _isLoading = false;
        });
      }
    }, onError: (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _compoundsSubscription?.cancel();
    super.dispose();
  }

  void _triggerNfcScan() {
    setState(() {
      _isNfcScanning = true;
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _isNfcScanning = false;
          _nfcBalance += 1000.00;
        });
        _showSuccessDialog(
          'NFC Top-Up Success',
          'Successfully re-charged 1,000.00 EGP to iHome Smart Pass. New Balance: $_nfcBalance EGP.',
        );
      }
    });
  }

  void _shareGatePassWhatsApp(String label) {
    setState(() {
      _isWhatsAppSharing = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isWhatsAppSharing = false;
        });
        _showSuccessDialog(
          'WhatsApp Dispatched',
          'Temporary QR credentials for $label successfully compiled and shared to visitor mobile.',
        );
      }
    });
  }

  void _startCheckoutFlow(String title, String unit, double amount, VoidCallback onSuccess) {
    setState(() {
      _checkoutTitle = title;
      _checkoutUnit = unit;
      _checkoutAmount = amount;
      _onCheckoutSuccess = onSuccess;
      _showCheckout = true;
      _isCheckoutBiometric = true;
      _isReceiptPrinted = false;
      _isReceiptTorn = false;
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isCheckoutBiometric = false;
        });
      }
    });
  }

  void _confirmCheckoutPayment() {
    setState(() {
      _isReceiptPrinted = true;
    });
  }

  void _executeReceiptTear() {
    setState(() {
      _isReceiptTorn = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showCheckout = false;
          _isReceiptPrinted = false;
          _isReceiptTorn = false;
        });
        if (_onCheckoutSuccess != null) {
          _onCheckoutSuccess!();
        }
        _showSuccessDialog('Payment Reconciled', 'Transacted asset secured via digital registry escrow protocol.');
      }
    });
  }

  void _showSuccessDialog(String title, String subtitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: LuxuryTheme.surfaceBrown,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: LuxuryTheme.primaryGold, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.verified_outlined, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            subtitle,
            style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 10.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DISMISS', style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showMaintenanceRequestSheet(String trade) {
    final active = _compoundsList[_selectedCompoundIndex];
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController();
    String priority = 'Medium';
    bool isSubmitting = false;
    final shakeKey = GlobalKey<_AnimatedShakeFieldState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: LuxuryTheme.surfaceBrown,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: LuxuryTheme.primaryGold, width: 2),
                ),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REQUEST $trade SERVICE'.toUpperCase(),
                      style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Filing work ticket under asset: ${active['title']} (${active['unit']})',
                      style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 8.5),
                    ),
                    const SizedBox(height: 16),
                    _AnimatedShakeField(
                      key: shakeKey,
                      child: TextFormField(
                        controller: descController,
                        style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 12.5),
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Describe service requirements & urgency detail',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 5) {
                            return 'Verification requirement: minimum 5 characters details';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TICKET URGENCY PRIORITY',
                      style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Low', 'Medium', 'High'].map((p) {
                        final isSelected = priority == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                priority = p;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.cardBrown,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.cardBrown),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                p.toUpperCase(),
                                style: TextStyle(
                                  color: isSelected ? LuxuryTheme.backgroundBlack : LuxuryTheme.textWhite,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    InteractiveTapBounce(
                      onTap: isSubmitting
                          ? null
                          : () {
                              final isValid = formKey.currentState!.validate();
                              if (!isValid) {
                                shakeKey.currentState?.shake();
                                return;
                              }
                              setSheetState(() {
                                isSubmitting = true;
                              });
                              Future.delayed(const Duration(milliseconds: 1000), () {
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                if (mounted) {
                                  setState(() {
                                    final tickets = active['activeTickets'] as List;
                                    tickets.insert(0, {
                                      'id': 'T-${884 + tickets.length}',
                                      'trade': trade,
                                      'desc': descController.text.trim(),
                                      'status': 'Requested',
                                    });
                                  });
                                  _showSuccessDialog(
                                    'Ticket Formulated',
                                    'Service request successfully registered in registry backlog.',
                                  );
                                }
                              });
                            },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: LuxuryTheme.primaryGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: LuxuryTheme.backgroundBlack, strokeWidth: 2),
                              )
                            : const Text(
                                'FILE SERVICE REQUEST',
                                style: TextStyle(color: LuxuryTheme.backgroundBlack, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  String _getReceiptUrl(String unit, String typeKey) {
    final cleanUnit = unit.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final codes = {
      'B01B202': '147',
      'A103B202': '180',
      'B101B202': '183',
      'A01B202': '98',
      'B401B202': '102',
      'A301B202': '116',
      'B302B202': '121',
      'B202B202': '122',
      'A203B202': '123',
      'B201B202': '127',
      'B501B409': '176',
      'A301B404': '144_A301B404',
      'C303B404': '144_C303B404',
      'C302B404': '144_C302B404',
      'A301B208': '87',
      'A01B203': '185',
      'A01B208': '94',
      'A01207': '130',
      'A103B208': '152',
      'B104B203': '134',
      'C301B409': '142',
      'A502B310': '200',
      'C203B404': '146_C203B404',
      'C202B404': '146_C202B404',
      'A101B409': '182',
      'B102B409': '91',
      'C201B409': '198',
      'B403B208': '111',
      'A201B409': '155',
      'B302B208': '203',
      'A201B404': '145',
      'C303B409': '137',
      'A01B409': '165',
      'C103B409': '187',
      'B303B208': '114',
      'B101B409': '89',
      'B402B409': '125',
      'C102B409': '90',
    };
    final code = codes[cleanUnit] ?? 'fallback';
    return 'https://new-build-egypt.com/assets/receipts/receipt_${code}_$typeKey.pdf';
  }

  void _openInvoiceBrowser(String title, String billId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerScreen(
          title: title,
          documentUrl: 'https://gateway.ihome.com.eg/pay/invoice_$billId.html',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: LuxuryTheme.backgroundBlack,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                LuxuryShimmerGrid(itemCount: 3, crossAxisCount: 3, childAspectRatio: 1.35),
                SizedBox(height: 20),
                LuxuryShimmerGrid(itemCount: 3, crossAxisCount: 3, childAspectRatio: 0.60),
              ],
            ),
          ),
        ),
      );
    }

    final active = _compoundsList[_selectedCompoundIndex];

    return Scaffold(
      backgroundColor: LuxuryTheme.backgroundBlack,
      body: OfflineStateManager(
        onConnectivityChanged: (offline) {
          if (mounted) setState(() => _isOffline = offline);
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 24, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'SELECT PORTFOLIO ASSET',
                      style: TextStyle(
                        color: LuxuryTheme.primaryGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCompoundsSelectorGrid(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('CLIENT FINANCIAL LEDGER'),
                  _buildFinancialBalancesSheet(active),
                  const SizedBox(height: 24),
                  _buildSectionHeader('NFC INTEGRATIONS & PASS SERVICES'),
                  _buildNfcTopUpSection(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('GRANULAR MAINTENANCE TICKET PIPELINE'),
                  _buildGranularServiceRequestHub(active),
                  const SizedBox(height: 24),
                  _buildSectionHeader('DYNAMIC DEVELOPER RELEASES & UP-SELLING'),
                  _buildDeveloperLaunchUpsellFeed(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('VIP GUEST GATE ACCESS QR'),
                  _isOffline
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: CachedGatePassWidget(compoundTitle: active['title'] ?? ''),
                        )
                      : _buildDynamicGuestPassSection(active),
                ],
              ),
            ),
            if (_isWhatsAppSharing) _buildWhatsAppSharingOverlay(),
            if (_isNfcScanning) _buildNfcScanningOverlay(),
            if (_showCheckout) _buildCheckoutOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: LuxuryTheme.primaryGold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
            ),
          ),
          Container(width: 60, height: 1.5, color: LuxuryTheme.cardBrown),
        ],
      ),
    );
  }

  Widget _buildCompoundsSelectorGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _compoundsList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          final comp = _compoundsList[index];
          final isSelected = _selectedCompoundIndex == index;

          return InteractiveTapBounce(
            onTap: () {
              setState(() {
                _selectedCompoundIndex = index;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.surfaceBrown,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? LuxuryTheme.primaryGold : LuxuryTheme.cardBrown,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.domain,
                    color: isSelected ? LuxuryTheme.backgroundBlack : LuxuryTheme.primaryGold,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      comp['title'].split(' ')[0],
                      style: TextStyle(
                        color: isSelected ? LuxuryTheme.backgroundBlack : LuxuryTheme.textWhite,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialBalancesSheet(Map<String, dynamic> active) {
    final downPayment = active['downPayment'] as Map<String, dynamic>;
    final installments = active['installments'] as List;
    final maintenance = active['maintenance'] as Map<String, dynamic>;

    final bool dpPaid = downPayment['isPaid'] ?? false;
    final double dpAmt = downPayment['amount'] ?? 0.0;
    final bool maintPaid = maintenance['isPaid'] ?? false;
    final double maintAmt = maintenance['balance'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.60,
        children: [
          Container(
            decoration: BoxDecoration(
              color: LuxuryTheme.surfaceBrown,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(dpPaid ? Icons.verified : Icons.error_outline, color: dpPaid ? Colors.green : Colors.red, size: 20),
                    const SizedBox(height: 10),
                    const Text('المقدم', style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold)),
                    const Text('DOWN PAYMENT', style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 7, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${(dpAmt / 1000000).toStringAsFixed(1)}M EGP', style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 11, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    dpPaid
                        ? InteractiveTapBounce(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DocumentViewerScreen(
                                    title: 'Down Payment Receipt',
                                    documentUrl: _getReceiptUrl(active['unit'], 'DP'),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'VIEW RECEIPT',
                                  style: TextStyle(color: Colors.green, fontSize: 7, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          )
                        : InteractiveTapBounce(
                            onTap: () {
                              _startCheckoutFlow('Down Payment Settlement', active['unit'], dpAmt, () {
                                setState(() {
                                  downPayment['isPaid'] = true;
                                  downPayment['status'] = 'PAID (10%)';
                                  downPayment['timestamp'] = '2026-05-26 15:15:00';
                                });
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'SETTLE DUES',
                                  style: TextStyle(color: LuxuryTheme.textWhite, fontSize: 7, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: LuxuryTheme.surfaceBrown,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.calendar_month, color: LuxuryTheme.primaryGold, size: 20),
                    SizedBox(height: 10),
                    Text('الأقساط', style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('INSTALLMENTS', style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 7, fontWeight: FontWeight.bold)),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: installments.map((instItem) {
                        final inst = instItem as Map<String, dynamic>;
                        final isPaid = inst['isPaid'] ?? false;
                        final String cleanAmount = inst['amount'].split(' ')[0];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: InteractiveTapBounce(
                            onTap: isPaid
                                ? () {
                                    final String typeKey = inst['title'].contains('1') ? 'I1' : (inst['title'].contains('2') ? 'I2' : 'I3');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DocumentViewerScreen(
                                          title: '${inst['title']} Receipt',
                                          documentUrl: _getReceiptUrl(active['unit'], typeKey),
                                        ),
                                      ),
                                    );
                                  }
                                : () {
                                    _startCheckoutFlow(inst['title'], active['unit'], 2250000.0, () {
                                      setState(() {
                                        inst['isPaid'] = true;
                                        inst['due'] = 'Paid';
                                        inst['date'] = '2026-05-26';
                                      });
                                    });
                                  },
                            child: Row(
                              children: [
                                Icon(isPaid ? Icons.check_circle : Icons.error_outline, color: isPaid ? Colors.green : Colors.red, size: 8),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${inst['title'].split(' ')[1]}: $cleanAmount',
                                    style: TextStyle(
                                      color: isPaid ? Colors.green : Colors.red,
                                      fontSize: 6.5,
                                      fontWeight: FontWeight.bold,
                                      decoration: isPaid ? TextDecoration.none : TextDecoration.underline,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: LuxuryTheme.surfaceBrown,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(maintPaid ? Icons.account_balance_wallet : Icons.error_outline, color: maintPaid ? Colors.green : Colors.red, size: 20),
                    const SizedBox(height: 10),
                    const Text('وديعة الصيانة', style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold)),
                    const Text('MAINTENANCE', style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 7, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${(maintAmt / 1000000).toStringAsFixed(1)}M EGP', style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 11, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    maintPaid
                        ? InteractiveTapBounce(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DocumentViewerScreen(
                                    title: 'Maintenance Receipt',
                                    documentUrl: _getReceiptUrl(active['unit'], 'MAINT'),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green, width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'VIEW RECEIPT',
                                  style: TextStyle(color: Colors.green, fontSize: 7, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          )
                        : InteractiveTapBounce(
                            onTap: () {
                              _startCheckoutFlow('Maintenance Fund Escrow', active['unit'], maintAmt, () {
                                setState(() {
                                  maintenance['isPaid'] = true;
                                  maintenance['status'] = 'Escrow Secured';
                                });
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: LuxuryTheme.primaryGold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'SETTLE DUES',
                                  style: TextStyle(color: LuxuryTheme.backgroundBlack, fontSize: 7, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNfcTopUpSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: LuxuryTheme.surfaceBrown,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.nfc, color: LuxuryTheme.primaryGold, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RFID NFC ACCESS KEYCARD',
                    style: TextStyle(color: LuxuryTheme.textWhite, fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Balance: ${_nfcBalance.toStringAsFixed(2)} EGP — Connected smart gateway registry',
                    style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 8.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InteractiveTapBounce(
              onTap: _triggerNfcScan,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: LuxuryTheme.primaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TOP UP CARD',
                  style: TextStyle(color: LuxuryTheme.backgroundBlack, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGranularServiceRequestHub(Map<String, dynamic> active) {
    final tickets = active['activeTickets'] as List;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.25,
            children: [
              _buildTradeRequestCard('صيانة المياه', 'PLUMBING & WATER', Icons.water_drop, () => _showMaintenanceRequestSheet('Plumbing')),
              _buildTradeRequestCard('الصرف الصحي', 'SEWAGE SYSTEMS', Icons.waves, () => _showMaintenanceRequestSheet('Drainage')),
              _buildTradeRequestCard('صيانة الكهرباء', 'ELECTRICAL GRID', Icons.electric_bolt, () => _showMaintenanceRequestSheet('Electrical')),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'ACTIVE TICKETS HISTORY (3-COLUMN)',
            style: TextStyle(color: LuxuryTheme.textSilver, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tickets.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final tickItem = tickets[index];
              final tick = tickItem as Map<String, dynamic>;
              return Container(
                decoration: BoxDecoration(
                  color: LuxuryTheme.surfaceBrown,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tick['id'], style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 8, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: tick['status'] == 'Resolved' ? Colors.green.withAlpha(40) : LuxuryTheme.primaryGold.withAlpha(40),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            tick['status'].toUpperCase(),
                            style: TextStyle(
                              color: tick['status'] == 'Resolved' ? Colors.green : LuxuryTheme.primaryGold,
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      tick['desc'],
                      style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 8, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    InteractiveTapBounce(
                      onTap: () => _openInvoiceBrowser('Service Ticket ${tick['id']}', tick['id']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: LuxuryTheme.cardBrown,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: LuxuryTheme.primaryGold.withAlpha(80), width: 1),
                        ),
                        child: const Center(
                          child: Text(
                            'VIEW INVOICE',
                            style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 6.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTradeRequestCard(String ar, String en, IconData icon, VoidCallback onTap) {
    return InteractiveTapBounce(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: LuxuryTheme.surfaceBrown,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: LuxuryTheme.primaryGold, size: 18),
            const SizedBox(height: 6),
            Text(
              ar,
              style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
            Text(
              en,
              style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 6, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperLaunchUpsellFeed() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Transform.scale(
        scale: 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LuxuryTheme.cardBrown, LuxuryTheme.surfaceBrown],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LuxuryTheme.primaryGold, width: 1.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: LuxuryTheme.primaryGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VIP PORTFOLIO UPSELL',
                        style: TextStyle(color: LuxuryTheme.backgroundBlack, fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'EXCLUSIVE PHASE LAUNCH: SKY HILLS',
                      style: TextStyle(color: LuxuryTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Secure high-altitude allocations in New October with priority premium registry.',
                      style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InteractiveTapBounce(
                onTap: () {
                  _startCheckoutFlow('VVIP Premium Placement Deposit', 'Sky Hills VIP Unit', 500000.0, () {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: LuxuryTheme.primaryGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'INQUIRE',
                    style: TextStyle(color: LuxuryTheme.backgroundBlack, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicGuestPassSection(Map<String, dynamic> active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: LuxuryTheme.surfaceBrown,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: LuxuryTheme.primaryGold, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DYNAMIC GUEST ACCESS QR',
                        style: TextStyle(color: LuxuryTheme.textWhite, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Smart Gate Access for compound gate ${active['title']}',
                        style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 8.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.35,
              children: [
                _buildAccessActionCard('Courier QR', Icons.delivery_dining, () => _shareGatePassWhatsApp('Courier')),
                _buildAccessActionCard('Visitor QR', Icons.group, () => _shareGatePassWhatsApp('Visitor')),
                _buildAccessActionCard('Service QR', Icons.build, () => _shareGatePassWhatsApp('Maintenance Crew')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessActionCard(String title, IconData icon, VoidCallback onTap) {
    return InteractiveTapBounce(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: LuxuryTheme.cardBrown,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: LuxuryTheme.primaryGold, size: 16),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share, color: Colors.green, size: 8),
                SizedBox(width: 2),
                Text('WHATSAPP', style: TextStyle(color: Colors.green, fontSize: 6, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppSharingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(200),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(color: Colors.green, strokeWidth: 4),
              ),
              SizedBox(height: 24),
              Icon(Icons.share, color: Colors.green, size: 40),
              SizedBox(height: 16),
              Text(
                'DISPATCHING VIA WHATSAPP API',
                style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              SizedBox(height: 6),
              Text(
                'Securing temporary guest gate pass tokens...',
                style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNfcScanningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(200),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.6),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: LuxuryTheme.primaryGold.withValues(alpha: 2.0 - value), width: 3),
                    ),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
                child: const Icon(Icons.nfc, color: LuxuryTheme.primaryGold, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'RFID NFC PASS READ TRIGGERED',
                style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hold smart token card near device contact point...',
                style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(220),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isCheckoutBiometric) ...[
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
                            const Icon(Icons.face_retouching_natural, color: LuxuryTheme.primaryGold, size: 40),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: -35, end: 35),
                              duration: const Duration(seconds: 1),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, value),
                                  child: Container(
                                    width: 70,
                                    height: 2,
                                    color: LuxuryTheme.primaryGold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'BIOMETRIC FACE ID CHECK',
                        style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const Text(
                        'Authenticating secure payment gateway...',
                        style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 8.5),
                      ),
                    ] else if (!_isReceiptPrinted) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: LuxuryTheme.surfaceBrown,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: LuxuryTheme.primaryGold, width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'iHOME PAYMENT TERMINAL',
                              style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: LuxuryTheme.cardBrown),
                            const SizedBox(height: 8),
                            Text('TRANSACTION: $_checkoutTitle', style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            Text('UNIT ID: $_checkoutUnit', style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 9.5)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL DUE:', style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('${(_checkoutAmount / 1000000).toStringAsFixed(2)}M EGP', style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _showCheckout = false;
                                      });
                                    },
                                    child: const Text('CANCEL', style: TextStyle(fontSize: 10)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _confirmCheckoutPayment,
                                    child: const Text('PAY NOW', style: TextStyle(fontSize: 10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.fastOutSlowIn,
                        height: _isReceiptTorn ? 0 : 380,
                        child: ClipPath(
                          clipper: JaggedEdgeClipper(),
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('iHOME LUXURY REGISTRY', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(height: 1, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                _buildReceiptRow('TRANSACTION ID', 'TX-99420-EGP'),
                                _buildReceiptRow('CLIENT ASSIGNED', 'Lord Harrington'),
                                _buildReceiptRow('UNIT ALLOCATION', _checkoutUnit),
                                _buildReceiptRow('SETTLEMENT FUND', _checkoutTitle),
                                _buildReceiptRow('NET PAID IN ESCROW', '${(_checkoutAmount / 1000000).toStringAsFixed(2)}M EGP'),
                                _buildReceiptRow('REGISTRY HASH', '0x9E7E...A41D'),
                                const Spacer(),
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: CustomPaint(
                                    size: const Size(double.infinity, 1),
                                    painter: DottedTearPainter(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InteractiveTapBounce(
                                  onTap: _executeReceiptTear,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: LuxuryTheme.surfaceBrown,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'TEAR & SECURE RECEIPT',
                                      style: TextStyle(color: LuxuryTheme.primaryGold, fontSize: 10.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 8, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class JaggedEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 10);
    double x = 0;
    double y = size.height - 10;
    double increment = 10;
    bool up = true;
    while (x < size.width) {
      x += increment;
      y = up ? (size.height - 18) : (size.height - 10);
      path.lineTo(x, y);
      up = !up;
    }
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DottedTearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    double max = size.width;
    double dashWidth = 5.0;
    double dashSpace = 4.0;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedShakeField extends StatefulWidget {
  final Widget child;

  const _AnimatedShakeField({super.key, required this.child});

  @override
  State<_AnimatedShakeField> createState() => _AnimatedShakeFieldState();
}

class _AnimatedShakeFieldState extends State<_AnimatedShakeField> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });
  }

  void shake() {
    setState(() {
      _hasError = true;
    });
    _shakeController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _hasError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _hasError
                        ? const Color(0xFFE57373)
                        : LuxuryTheme.surfaceBrown,
                    width: _hasError ? 1.5 : 1.0,
                  ),
                ),
                child: child!,
              ),
              AnimatedOpacity(
                opacity: _hasError ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Color(0xFFE57373), size: 11),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Verification requirement: minimum 5 characters details',
                          style: TextStyle(
                            color: Color(0xFFE57373),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

