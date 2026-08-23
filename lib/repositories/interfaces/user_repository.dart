import '../../models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getUserById(String uid);
  Future<UserProfile?> getUserByEmail(String email);
  Stream<UserProfile?> streamUser(String uid);
  Stream<List<UserProfile>> streamAllUsers();
  Stream<List<UserProfile>> streamUsersByRole(UserRole role);
  Future<List<UserProfile>> getUsers({
    UserRole? role,
    KycStatus? status,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  });
  Future<void> createUser(UserProfile user);
  Future<void> updateUser(UserProfile user);
  Future<void> deleteUser(String uid);
  Future<void> updateKycStatus(String uid, KycStatus status);
  Future<void> addFcmToken(String uid, String token);
  Future<List<UserProfile>> queryUsersByRole(UserRole role);
  Future<void> batchUpdateUsers(List<UserProfile> users);
}
