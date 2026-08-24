import '../utils/date_time_util.dart';

enum AuthState {
  unauthenticated,
  authenticating,
  authenticated,
  sessionExpired,
  error,
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final String clientId;
  final String displayName;
  final String? avatarUrl;
  final DateTime expiresAt;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.clientId,
    required this.displayName,
    this.avatarUrl,
    required this.expiresAt,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      clientId: json['client_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      expiresAt: DateTimeUtil.parse(json['expires_at']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class ClientProfile {
  final String clientId;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final List<String> ownedUnitIds;
  final String? assignedLedgerId;

  const ClientProfile({
    required this.clientId,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    required this.ownedUnitIds,
    this.assignedLedgerId,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      clientId: json['client_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      ownedUnitIds: (json['owned_unit_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      assignedLedgerId: json['assigned_ledger_id'] as String?,
    );
  }

  static ClientProfile get fallback => const ClientProfile(
        clientId: 'client_147',
        displayName: 'أحمد عبد العظيم صدقي',
        email: '01000197979@new-build-egypt.com',
        ownedUnitIds: ['B01B202'],
        assignedLedgerId: 'ledger_147',
      );
}
