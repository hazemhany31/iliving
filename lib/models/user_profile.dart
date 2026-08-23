import 'package:flutter/foundation.dart';

enum UserRole {
  superAdmin,
  salesManager,
  broker,
  finance,
  facilityManager,
  security,
  customer,
}

extension UserRoleX on UserRole {
  String get nameString {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.salesManager:
        return 'SALES_MANAGER';
      case UserRole.broker:
        return 'BROKER';
      case UserRole.finance:
        return 'FINANCE';
      case UserRole.facilityManager:
        return 'FACILITY_MANAGER';
      case UserRole.security:
        return 'SECURITY';
      case UserRole.customer:
        return 'CUSTOMER';
    }
  }

  static UserRole fromString(String? roleStr) {
    switch (roleStr?.toUpperCase()) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'SALES_MANAGER':
        return UserRole.salesManager;
      case 'BROKER':
      case 'SALES_AGENT':
        return UserRole.broker;
      case 'FINANCE':
      case 'FINANCE_OFFICER':
        return UserRole.finance;
      case 'FACILITY_MANAGER':
      case 'PROPERTY_MANAGER':
        return UserRole.facilityManager;
      case 'SECURITY':
        return UserRole.security;
      case 'CUSTOMER':
      default:
        return UserRole.customer;
    }
  }
}

enum KycStatus { pending, verified, rejected }

enum AccountStatus { active, suspended, deleted }

@immutable
class UserProfile {
  final String uid;
  final String email;
  final String phoneNumber;
  final String fullName;
  final String nationalIdOrPassport;
  final String nationality;
  final String? clientCode;
  final UserRole role;
  final KycStatus kycStatus;
  final List<String> associatedUnitIds;
  final List<String> fcmTokens;
  final String preferredLanguage;
  final AccountStatus accountStatus;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? avatarUrl;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    required this.fullName,
    this.nationalIdOrPassport = '',
    this.nationality = 'Egyptian',
    this.clientCode,
    required this.role,
    this.kycStatus = KycStatus.pending,
    this.associatedUnitIds = const [],
    this.fcmTokens = const [],
    this.preferredLanguage = 'ar',
    this.accountStatus = AccountStatus.active,
    required this.createdAt,
    this.lastLoginAt,
    this.avatarUrl,
  });

  bool get isVerified => kycStatus == KycStatus.verified;
  bool get isActive => accountStatus == AccountStatus.active;
  bool get isAdmin =>
      role == UserRole.superAdmin ||
      email.toLowerCase().contains('admin') ||
      clientId == 'client_admin';
  bool get isStaff =>
      isAdmin ||
      role == UserRole.salesManager ||
      role == UserRole.broker ||
      role == UserRole.finance ||
      role == UserRole.facilityManager ||
      role == UserRole.security;
  bool get isOwner =>
      role == UserRole.customer && associatedUnitIds.isNotEmpty;
  String get id => uid;
  String get clientId => clientCode ?? uid;
  String get displayName => fullName;
  List<String> get ownedUnitIds => associatedUnitIds;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? json['phone_number'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['display_name'] as String? ?? '',
      nationalIdOrPassport: json['nationalIdOrPassport'] as String? ?? '',
      nationality: json['nationality'] as String? ?? 'Egyptian',
      clientCode: json['clientCode'] as String?,
      role: UserRoleX.fromString(json['role'] as String?),
      kycStatus: KycStatus.values.firstWhere(
        (e) => e.name == json['kycStatus'],
        orElse: () => KycStatus.pending,
      ),
      associatedUnitIds: (json['associatedUnitIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      fcmTokens: (json['fcmTokens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      preferredLanguage: json['preferredLanguage'] as String? ?? 'ar',
      accountStatus: AccountStatus.values.firstWhere(
        (e) => e.name == json['accountStatus'],
        orElse: () => AccountStatus.active,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'nationalIdOrPassport': nationalIdOrPassport,
      'nationality': nationality,
      'clientCode': clientCode,
      'role': role.nameString,
      'kycStatus': kycStatus.name,
      'associatedUnitIds': associatedUnitIds,
      'fcmTokens': fcmTokens,
      'preferredLanguage': preferredLanguage,
      'accountStatus': accountStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'avatarUrl': avatarUrl,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? fullName,
    String? nationalIdOrPassport,
    String? nationality,
    String? clientCode,
    UserRole? role,
    KycStatus? kycStatus,
    List<String>? associatedUnitIds,
    List<String>? fcmTokens,
    String? preferredLanguage,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      nationalIdOrPassport: nationalIdOrPassport ?? this.nationalIdOrPassport,
      nationality: nationality ?? this.nationality,
      clientCode: clientCode ?? this.clientCode,
      role: role ?? this.role,
      kycStatus: kycStatus ?? this.kycStatus,
      associatedUnitIds: associatedUnitIds ?? this.associatedUnitIds,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
