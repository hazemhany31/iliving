import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';

class CachedGatePassWidget extends StatelessWidget {
  final String compoundTitle;

  const CachedGatePassWidget({super.key, required this.compoundTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LuxuryTheme.surfaceBrown,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReadOnlyCacheRibbon(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: LuxuryTheme.primaryGold, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CACHED GATE ACCESS QR',
                      style: TextStyle(color: LuxuryTheme.textWhite, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      compoundTitle,
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
            children: const [
              _CachedAccessCard(title: 'Courier QR', icon: Icons.delivery_dining),
              _CachedAccessCard(title: 'Visitor QR', icon: Icons.group),
              _CachedAccessCard(title: 'Service QR', icon: Icons.build),
            ],
          ),
        ],
      ),
    );
  }
}

class _CachedAccessCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _CachedAccessCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LuxuryTheme.cardBrown,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
      ),
      padding: const EdgeInsets.all(6),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: LuxuryTheme.primaryGold.withAlpha(120), size: 16),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 8.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: LuxuryTheme.textMuted, size: 8),
                  SizedBox(width: 2),
                  Text('CACHED', style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 6, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CachedInvoiceWidget extends StatelessWidget {
  final String label;
  final String invoiceId;
  final String amount;
  final String date;

  const CachedInvoiceWidget({
    super.key,
    required this.label,
    required this.invoiceId,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LuxuryTheme.surfaceBrown,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReadOnlyCacheRibbon(compact: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: LuxuryTheme.primaryGold.withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined, color: LuxuryTheme.primaryGold, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: LuxuryTheme.textWhite, fontSize: 9.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: $invoiceId',
            style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 7.5),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: const TextStyle(color: LuxuryTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: const TextStyle(color: LuxuryTheme.textMuted, fontSize: 7),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: LuxuryTheme.cardBrown,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: LuxuryTheme.primaryGold.withAlpha(60), width: 1),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: LuxuryTheme.textMuted, size: 9),
                SizedBox(width: 4),
                Text(
                  'CACHED — RECONNECT TO VIEW',
                  style: TextStyle(color: LuxuryTheme.textMuted, fontSize: 6, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyCacheRibbon extends StatelessWidget {
  final bool compact;

  const _ReadOnlyCacheRibbon({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: LuxuryTheme.primaryGold.withAlpha(22),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: LuxuryTheme.primaryGold.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: LuxuryTheme.primaryGold, size: 9),
          const SizedBox(width: 4),
          Text(
            'OFFLINE CACHE — READ ONLY',
            style: TextStyle(
              color: LuxuryTheme.primaryGold,
              fontSize: compact ? 6 : 7,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
