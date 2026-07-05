import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../screens/document_viewer_screen.dart';
import '../screens/eoi_capture_screen.dart';
import '../screens/prypco_hub_screen.dart';
import '../screens/yield_analytics_screen.dart';
import '../screens/property_ops_dashboard.dart';

class LuxurySidebar extends StatelessWidget {
  const LuxurySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: LuxuryTheme.backgroundBlack,
      elevation: 16,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: LuxuryTheme.surfaceBrown,
                border: Border(
                  bottom: BorderSide(
                    color: LuxuryTheme.primaryGold,
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: LuxuryTheme.primaryGold, width: 2),
                          image: DecorationImage(
                            image: const NetworkImage(
                                'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=200'),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {},
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alistair Sterling',
                              style: TextStyle(
                                color: LuxuryTheme.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Text(
                              'Elite Relationship Manager',
                              style: TextStyle(
                                color: LuxuryTheme.primaryGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: LuxuryTheme.cardBrown,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LIC# EG-iH-9942',
                                style: TextStyle(
                                  color: LuxuryTheme.textSilver,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                children: [
                  _buildSectionTitle('OPERATIONAL UTILITIES'),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.82,
                    children: [
                      _buildGridItem(
                        context,
                        Icons.verified_user_outlined,
                        'Licensing',
                        () => _viewSecureDocument(
                          context,
                          'Company Licensing & Governance',
                          'https://gateway.ihome.com.eg/governance/license_v9.pdf',
                        ),
                      ),
                      _buildGridItem(
                        context,
                        Icons.monetization_on_outlined,
                        'EOI Form',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EoiCaptureScreen(),
                            ),
                          );
                        },
                      ),
                      _buildGridItem(
                        context,
                        Icons.pie_chart_outline_rounded,
                        'PRYPCO',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrypcoHubScreen(),
                            ),
                          );
                        },
                      ),
                      _buildGridItem(
                        context,
                        Icons.analytics_outlined,
                        'Analytics',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const YieldAnalyticsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildGridItem(
                        context,
                        Icons.calculate_outlined,
                        'Yield Calc',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const YieldAnalyticsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildGridItem(
                        context,
                        Icons.folder_shared_outlined,
                        'Marketing',
                        () => _viewSecureDocument(
                          context,
                          'Luxury Brochure Hub',
                          'https://gateway.ihome.com.eg/brochures/sky_hills_brochure.pdf',
                        ),
                      ),
                      _buildGridItem(
                        context,
                        Icons.domain_outlined,
                        'Property Ops',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PropertyOpsDashboard(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('EOI LEADERBOARD'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LuxuryTheme.surfaceBrown,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _buildLeaderboardRow('1', 'Maximilian V.', '24M EGP'),
                        const Divider(color: LuxuryTheme.cardBrown, height: 12),
                        _buildLeaderboardRow('2', 'Seraphina L.', '18.5M EGP'),
                        const Divider(color: LuxuryTheme.cardBrown, height: 12),
                        _buildLeaderboardRow(
                            '3', 'Alistair S. (You)', '15.2M EGP'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              color: LuxuryTheme.surfaceBrown,
              child: Row(
                children: [
                  const Icon(Icons.logout, color: LuxuryTheme.primaryGold),
                  const SizedBox(width: 12),
                  const Text(
                    'Logout Broker Session',
                    style: TextStyle(
                      color: LuxuryTheme.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Active',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: LuxuryTheme.primaryGold,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildGridItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: LuxuryTheme.surfaceBrown,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: LuxuryTheme.cardBrown,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: LuxuryTheme.primaryGold,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: LuxuryTheme.textWhite,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(String rank, String name, String volume) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                rank == '1' ? LuxuryTheme.primaryGold : LuxuryTheme.cardBrown,
            shape: BoxShape.circle,
          ),
          child: Text(
            rank,
            style: TextStyle(
              color: rank == '1'
                  ? LuxuryTheme.backgroundBlack
                  : LuxuryTheme.textWhite,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: const TextStyle(
            color: LuxuryTheme.textWhite,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          volume,
          style: const TextStyle(
            color: LuxuryTheme.primaryGold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _viewSecureDocument(
      BuildContext context, String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerScreen(
          title: title,
          documentUrl: url,
        ),
      ),
    );
  }
}
