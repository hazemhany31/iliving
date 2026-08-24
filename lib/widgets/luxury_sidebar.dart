import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/luxury_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../screens/document_viewer_screen.dart';
import '../screens/eoi_capture_screen.dart';
import '../screens/prypco_hub_screen.dart';
import '../screens/yield_analytics_screen.dart';
import '../screens/property_ops_dashboard.dart';
import '../screens/admin/admin_portal_shell.dart';
import '../screens/change_password_screen.dart';
import '../services/auth_service.dart';
import 'user_avatar.dart';
import 'profile_picture_dialog.dart';

class LuxurySidebar extends StatelessWidget {
  const LuxurySidebar({super.key});

  static Stream<QuerySnapshot?>? _cachedEoisStream;
  static Stream<QuerySnapshot?> get _eoisStream =>
      _cachedEoisStream ??= (Firebase.apps.isNotEmpty
          ? FirebaseFirestore.instance.collection('eois').snapshots().asBroadcastStream()
          : const Stream.empty());

  String _getUserRole(BuildContext context) {
    final profile = AuthService.instance.currentProfile;
    if (profile == null) return '';
    if (profile.email.contains('sterling') || profile.clientId == 'client_broker') {
      return 'Elite Relationship Manager';
    }
    if (profile.email.contains('admin')) {
      return 'System Administrator';
    }
    return 'VIP Client';
  }

  String _getUserSubText() {
    final profile = AuthService.instance.currentProfile;
    if (profile == null) return '';
    if (profile.email.contains('sterling') || profile.clientId == 'client_broker') {
      return 'LIC# EG-iH-9942';
    }
    if (profile.email.contains('admin')) {
      return 'ROOT ACCESS';
    }
    final code = profile.clientId.replaceAll('client_', '');
    return 'CLIENT CODE: $code';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                      UserAvatar(
                        radius: 30,
                        showEditBadge: true,
                        onTap: () => ProfilePictureDialog.show(context),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AuthService.instance.currentProfile?.displayName ?? 'Alistair Sterling',
                              style: const TextStyle(
                                color: LuxuryTheme.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _getUserRole(context),
                              style: const TextStyle(
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
                              child: Text(
                                _getUserSubText(),
                                style: const TextStyle(
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
                  // Language Switcher Tile
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: LuxuryTheme.surfaceBrown,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LuxuryTheme.primaryGold, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.language, color: LuxuryTheme.primaryGold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.switchLanguage,
                              style: const TextStyle(
                                color: LuxuryTheme.textWhite,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => LocaleService.instance.toggleLocale(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: LuxuryTheme.primaryGold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              LocaleService.instance.isArabic ? l10n.english : l10n.arabic,
                              style: const TextStyle(
                                color: LuxuryTheme.backgroundBlack,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSectionTitle(l10n.quickActions.toUpperCase()),
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
                        l10n.docTitle,
                        () => _viewSecureDocument(
                          context,
                          l10n.docTitle,
                          'https://gateway.iliving.com.eg/governance/license_v9.pdf',
                        ),
                      ),
                      _buildGridItem(
                        context,
                        Icons.monetization_on_outlined,
                        l10n.navEoi,
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
                        l10n.navPrypco,
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
                        l10n.navYield,
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
                        l10n.investmentCalculator,
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
                        l10n.navDocuments,
                        () => _viewSecureDocument(
                          context,
                          l10n.navDocuments,
                          'https://gateway.iliving.com.eg/brochures/sky_hills_brochure.pdf',
                        ),
                      ),
                      _buildGridItem(
                        context,
                        Icons.domain_outlined,
                        l10n.navPropertyOps,
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
                      if (AuthService.instance.currentProfile?.isAdmin ?? false)
                        _buildGridItem(
                          context,
                          Icons.dashboard_customize_outlined,
                          l10n.navAdminPortal,
                          () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminPortalShell(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(l10n.eoiTitle.toUpperCase()),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot?>(
                    stream: _eoisStream,
                    builder: (context, snapshot) {
                      List<Map<String, dynamic>> leaderboardItems = [];

                      if (snapshot.hasData && snapshot.data != null) {
                        final docs = snapshot.data!.docs;
                        final Map<String, double> groupedClients = {};

                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>? ?? {};
                          final name = data['clientName'] ?? data['name'] ?? '';
                          final amtDouble = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
                          if (name.isNotEmpty && amtDouble > 0) {
                            groupedClients[name] = (groupedClients[name] ?? 0.0) + amtDouble;
                          }
                        }

                        groupedClients.forEach((name, amount) {
                          leaderboardItems.add({
                            'name': name,
                            'amount': amount,
                          });
                        });

                        leaderboardItems.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
                      }

                      // Fallback real clients if we have less than 3
                      final List<Map<String, dynamic>> fallbacks = [
                        {'name': 'أحمد شاذلي عبد الجواد', 'amount': 24000000.0},
                        {'name': 'محمود غانم إبراهيم', 'amount': 18500000.0},
                        {'name': 'marrow علي محمد', 'amount': 15200000.0},
                      ];

                      for (var fallback in fallbacks) {
                        if (leaderboardItems.length >= 3) break;
                        // Avoid duplicates if already submitted in Firestore
                        final fallbackShortName = fallback['name'].toString().split(' ')[0];
                        if (!leaderboardItems.any((item) => item['name'].toString().contains(fallbackShortName))) {
                          leaderboardItems.add(fallback);
                        }
                      }

                      // Keep top 3
                      if (leaderboardItems.length > 3) {
                        leaderboardItems = leaderboardItems.sublist(0, 3);
                      }

                      final currentProfile = AuthService.instance.currentProfile;
                      final currentName = currentProfile?.displayName ?? '';

                      // Ensure current user is on the leaderboard at rank 3 if not in top 2
                      if (currentName.isNotEmpty) {
                        int myIndex = -1;
                        for (int i = 0; i < leaderboardItems.length; i++) {
                          final name = leaderboardItems[i]['name']?.toString() ?? '';
                          if (name == currentName || currentName.contains(name) || name.contains(currentName)) {
                            myIndex = i;
                            break;
                          }
                        }
                        if (myIndex == -1) {
                          // Not found in top 3, replace the 3rd item with current user
                          const myAmt = 15200000.0; // default volume
                          if (leaderboardItems.length >= 3) {
                            leaderboardItems[2] = {'name': currentName, 'amount': myAmt};
                          } else {
                            leaderboardItems.add({'name': currentName, 'amount': myAmt});
                          }
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LuxuryTheme.surfaceBrown,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: LuxuryTheme.cardBrown, width: 1.5),
                        ),
                        child: Column(
                          children: List.generate(leaderboardItems.length * 2 - 1, (index) {
                            if (index.isOdd) {
                              return const Divider(color: LuxuryTheme.cardBrown, height: 12);
                            }
                            final itemIndex = index ~/ 2;
                            final item = leaderboardItems[itemIndex];
                            final String rank = (itemIndex + 1).toString();
                            
                            String displayName = item['name'] ?? '';
                            if (currentName.isNotEmpty &&
                                (displayName == currentName ||
                                 currentName.contains(displayName) ||
                                 displayName.contains(currentName))) {
                              displayName = '$displayName (You)';
                            }

                            // Truncate name beautifully if too long (especially for Arabic names)
                            if (displayName.length > 25) {
                              displayName = '${displayName.substring(0, 23)}...';
                            }
                            
                            final double amount = item['amount'] as double;
                            String formattedAmt = '';
                            if (amount >= 1000000) {
                              formattedAmt = '${(amount / 1000000).toStringAsFixed(1)}M EGP';
                            } else if (amount >= 1000) {
                              formattedAmt = '${(amount / 1000).toStringAsFixed(0)}K EGP';
                            } else {
                              formattedAmt = '${amount.toStringAsFixed(0)} EGP';
                            }

                            return _buildLeaderboardRow(rank, displayName, formattedAmt);
                          }),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: LuxuryTheme.surfaceBrown,
                border: Border(
                  top: BorderSide(color: LuxuryTheme.cardBrown, width: 1.5),
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset_rounded, color: LuxuryTheme.primaryGold, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              color: LuxuryTheme.textWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.chevron_right_rounded, color: LuxuryTheme.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: LuxuryTheme.cardBrown, height: 1),
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await AuthService.instance.logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            l10n.navLogout,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                          Text(
                            l10n.active,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: LuxuryTheme.textWhite,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
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
