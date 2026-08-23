import '../models/notification.dart';
import '../repositories/interfaces/notification_repository.dart';

class NotificationService {
  final NotificationRepository _notificationRepository;

  NotificationService({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository;

  Future<void> dispatchNotification({
    required String targetUserId,
    required String title,
    String titleAr = '',
    required String body,
    String bodyAr = '',
    NotificationPriority priority = NotificationPriority.normal,
    String? deepLinkRoute,
    String? type,
    String? unitId,
    double? installmentAmount,
  }) async {
    final notification = AppNotification(
      id: 'NTF-${DateTime.now().millisecondsSinceEpoch}',
      targetUserId: targetUserId.isEmpty ? 'ALL' : targetUserId,
      title: title,
      titleAr: titleAr,
      body: body,
      bodyAr: bodyAr,
      priority: priority,
      deepLinkRoute: deepLinkRoute,
      type: type,
      unitId: unitId,
      installmentAmount: installmentAmount,
      createdAt: DateTime.now(),
    );

    await _notificationRepository.sendNotification(notification);
  }

  /// Send a real-time notification when a payment is logged or received
  Future<void> notifyPaymentReceived({
    required String payerUserId,
    required String unitId,
    required double amount,
    required String transactionReference,
  }) async {
    final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    final notification = AppNotification(
      id: 'NTF-PAY-${DateTime.now().millisecondsSinceEpoch}',
      targetUserId: payerUserId.isEmpty ? 'ALL' : payerUserId,
      title: 'Payment Received ($formattedAmount EGP)',
      titleAr: 'تم استلام دفعة مالية ($formattedAmount ج.م)',
      body: 'Payment recorded for Unit $unitId. Ref: $transactionReference',
      bodyAr: 'تم تسجيل دفع مبلغ $formattedAmount ج.م للوحدة $unitId. رقم مرجعي: $transactionReference',
      priority: NotificationPriority.high,
      type: 'payment',
      unitId: unitId,
      installmentAmount: amount,
      createdAt: DateTime.now(),
    );

    await _notificationRepository.sendNotification(notification);
  }

  /// Send a real-time notification when a new maintenance ticket is created
  Future<void> notifyTicketCreated({
    required String residentUserId,
    required String unitId,
    required String ticketNumber,
    required String title,
    String urgency = 'normal',
  }) async {
    final priority = urgency.toLowerCase() == 'emergency'
        ? NotificationPriority.emergency
        : urgency.toLowerCase() == 'high'
            ? NotificationPriority.high
            : NotificationPriority.normal;

    final notification = AppNotification(
      id: 'NTF-TKT-NEW-${DateTime.now().millisecondsSinceEpoch}',
      targetUserId: residentUserId.isEmpty ? 'ALL' : residentUserId,
      title: 'Maintenance Ticket #$ticketNumber Filed',
      titleAr: 'تذكرة صيانة جديدة #$ticketNumber',
      body: 'New maintenance ticket filed for Unit $unitId: $title',
      bodyAr: 'تم تقديم تذكرة صيانة جديدة للوحدة $unitId: $title',
      priority: priority,
      type: 'maintenance_created',
      unitId: unitId,
      createdAt: DateTime.now(),
    );

    await _notificationRepository.sendNotification(notification);
  }

  /// Send a real-time notification when a maintenance ticket status or detail is updated
  Future<void> notifyTicketUpdated({
    required String residentUserId,
    required String unitId,
    required String ticketNumber,
    required String title,
    required String status,
  }) async {
    final notification = AppNotification(
      id: 'NTF-TKT-UPD-${DateTime.now().millisecondsSinceEpoch}',
      targetUserId: residentUserId.isEmpty ? 'ALL' : residentUserId,
      title: 'Maintenance Ticket #$ticketNumber Updated',
      titleAr: 'تحديث تذكرة الصيانة #$ticketNumber',
      body: 'Ticket status for Unit $unitId set to ${status.toUpperCase()}.',
      bodyAr: 'تم تغيير حالة تذكرة الصيانة للوحدة $unitId إلى $status.',
      priority: NotificationPriority.normal,
      type: 'maintenance_updated',
      unitId: unitId,
      createdAt: DateTime.now(),
    );

    await _notificationRepository.sendNotification(notification);
  }

  /// Send a real-time notification when a comment or update is added to a maintenance ticket
  Future<void> notifyTicketCommentAdded({
    required String targetUserId,
    required String ticketNumber,
    required String authorName,
    required String message,
  }) async {
    final notification = AppNotification(
      id: 'NTF-TKT-CMT-${DateTime.now().millisecondsSinceEpoch}',
      targetUserId: targetUserId.isEmpty ? 'ALL' : targetUserId,
      title: 'New Comment on Ticket #$ticketNumber',
      titleAr: 'تحديث جديد على التذكرة #$ticketNumber',
      body: '$authorName: $message',
      bodyAr: '$authorName: $message',
      priority: NotificationPriority.normal,
      type: 'maintenance_comment',
      createdAt: DateTime.now(),
    );

    await _notificationRepository.sendNotification(notification);
  }
}

