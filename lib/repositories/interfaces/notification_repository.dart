import '../../models/notification.dart';

abstract class NotificationRepository {
  Future<AppNotification?> getNotificationById(String id);
  Stream<AppNotification?> streamNotification(String id);
  Stream<List<AppNotification>> streamNotificationsForUser(String userId);
  Stream<List<AppNotification>> streamAllNotifications();
  Future<List<AppNotification>> getNotifications({
    String? targetUserId,
    bool? isRead,
    int? limit,
    String? startAfterId,
  });
  Future<void> sendNotification(AppNotification notification);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead({String? targetUserId});
  Future<void> deleteNotification(String notificationId);
  Future<void> batchSendNotifications(List<AppNotification> notifications);
}

