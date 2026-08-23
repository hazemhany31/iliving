import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/services/auth_service.dart';

void main() {
  group('Profile Picture Management & UserProfile Avatar Tests', () {
    setUp(() {
      AuthService.instance.logout();
    });

    test('UserProfile parses and serializes avatarUrl correctly', () {
      final userWithAvatar = UserProfile.fromJson(const {
        'uid': 'test_user_1',
        'email': 'test@iliving.com',
        'fullName': 'Test User',
        'role': 'CUSTOMER',
        'createdAt': '2026-08-02T00:00:00.000',
        'avatarUrl': 'https://example.com/avatar.jpg',
      });

      expect(userWithAvatar.avatarUrl, 'https://example.com/avatar.jpg');
      final json = userWithAvatar.toJson();
      expect(json['avatarUrl'], 'https://example.com/avatar.jpg');
    });

    test('UserProfile copyWith handles updating and clearing avatarUrl', () {
      final baseUser = UserProfile(
        uid: 'test_user_2',
        email: 'test2@iliving.com',
        phoneNumber: '01000000000',
        fullName: 'Test User 2',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        avatarUrl: 'https://example.com/old_avatar.jpg',
      );

      expect(baseUser.avatarUrl, 'https://example.com/old_avatar.jpg');

      final updatedUser = baseUser.copyWith(
        avatarUrl: 'https://example.com/new_avatar.jpg',
      );
      expect(updatedUser.avatarUrl, 'https://example.com/new_avatar.jpg');

      final clearedUser = updatedUser.copyWith(clearAvatar: true);
      expect(clearedUser.avatarUrl, isNull);
    });

    test('AuthService updates and removes profile picture in real-time', () async {
      await AuthService.instance.login('demo@iliving.com.eg', 'iliving2026');
      expect(AuthService.instance.currentUserProfile, isNotNull);

      // Update avatar
      const newUrl = 'https://images.unsplash.com/photo-1560250097-0b93528c311a';
      await AuthService.instance.updateProfilePicture(newUrl);
      expect(AuthService.instance.currentUserProfile?.avatarUrl, newUrl);

      // Remove avatar
      await AuthService.instance.removeProfilePicture();
      expect(AuthService.instance.currentUserProfile?.avatarUrl, isNull);
    });
  });
}
