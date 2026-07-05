import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final bool isInvoice = widget.documentUrl.contains('invoice') || widget.title.contains('Invoice') || widget.documentUrl.contains('pay');
    final bool isContract = widget.documentUrl.contains('contract') || widget.title.contains('SPA') || widget.documentUrl.contains('spa');

    return Scaffold(
      backgroundColor: LuxuryTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          widget.title.toUpperCase(),
          style: const TextStyle(
            color: LuxuryTheme.primaryGold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: LuxuryTheme.primaryGold, size: 18),
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
                decoration: const BoxDecoration(
                  color: LuxuryTheme.surfaceBrown,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(color: LuxuryTheme.primaryGold, width: 1),
                    left: BorderSide(color: LuxuryTheme.primaryGold, width: 1),
                    right: BorderSide(color: LuxuryTheme.primaryGold, width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.red, size: 8),
                    const SizedBox(width: 4),
                    const Icon(Icons.circle, color: Colors.orange, size: 8),
                    const SizedBox(width: 4),
                    const Icon(Icons.circle, color: Colors.green, size: 8),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_back, color: LuxuryTheme.textMuted, size: 16),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: LuxuryTheme.textMuted, size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: LuxuryTheme.backgroundBlack,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, color: LuxuryTheme.primaryGold, size: 12),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.documentUrl,
                                style: const TextStyle(
                                  color: LuxuryTheme.textMuted,
                                  fontSize: 10,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: LuxuryTheme.primaryGold,
                              ),
                            )
                          : const Icon(Icons.refresh, color: LuxuryTheme.primaryGold, size: 18),
                      onPressed: _refreshDocument,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(color: LuxuryTheme.primaryGold, width: 1),
                  ),
                  child: _isRefreshing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: LuxuryTheme.primaryGold,
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
                                        style: const TextStyle(
                                          color: LuxuryTheme.surfaceBrown,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isInvoice
                                            ? 'REF: EGP-INV-2026-889'
                                            : isContract
                                                ? 'SPA-ZL-2026-801'
                                                : 'BILL-SH-EL-1204',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: LuxuryTheme.darkGold,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(height: 1.5, color: LuxuryTheme.primaryGold),
                              const SizedBox(height: 16),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.25,
                                children: isInvoice
                                    ? [
                                        _buildGridCard('CLIENT NAME', 'A. Sterling'),
                                        _buildGridCard('UNIT ID', 'ZL/08/801'),
                                        _buildGridCard('CURRENCY', 'EGP (ج.م)'),
                                        _buildGridCard('BASE AMOUNT', '15,200,000'),
                                        _buildGridCard('VAT (5%)', '760,000'),
                                        _buildGridCard('NET TOTAL', '15,960,000'),
                                      ]
                                    : isContract
                                        ? [
                                            _buildGridCard('DEVELOPMENT', 'Zayed Lagoons'),
                                            _buildGridCard('ASSET CLASS', 'Luxury Villa'),
                                            _buildGridCard('LOCATION', 'West Cairo'),
                                            _buildGridCard('AREA SQFT', '4,800 SQFT'),
                                            _buildGridCard('RM ASSIGNED', 'A. Sterling'),
                                            _buildGridCard('DOWN PAYMENT', 'PAID (10%)'),
                                          ]
                                        : [
                                            _buildGridCard('METRIC TYPE', 'Electricity'),
                                            _buildGridCard('COMPOUND', 'Sky Hills'),
                                            _buildGridCard('UNIT ID', 'SH/12/1204'),
                                            _buildGridCard('DUE DATE', '05 June 2026'),
                                            _buildGridCard('AMOUNT DUE', '4,500 EGP'),
                                            _buildGridCard('BILL STATUS', 'Outstanding'),
                                          ],
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'LEGAL DISCLAIMER & COMPLIANCE',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'This secure document representation is verified under regulatory frameworks of West Cairo Authority and is dynamically synced with iHome Developer Core Services. IPFS hash audit verification can be inspected dynamically under secondary key layers.',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 9,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'E-SIGNATURE DOCK STATUS',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          isContract ? 'PENDING USER COUNTER-SIGN' : 'SECURED & RECONCILED',
                                          style: TextStyle(
                                            color: isContract ? LuxuryTheme.deepGold : Colors.green,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('E-Signature verified. Contract locks in transaction ledger.'),
                              backgroundColor: LuxuryTheme.primaryGold,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: LuxuryTheme.primaryGold, width: 1.5),
                        ),
                        child: const Text(
                          'CO-SIGN SECURELY',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reconciliation statement exported to client files.'),
                              backgroundColor: LuxuryTheme.primaryGold,
                            ),
                          );
                        },
                        child: const Text(
                          'EXPORT STATUS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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

  Widget _buildGridCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
