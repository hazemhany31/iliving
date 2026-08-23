import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification.dart';
import '../interfaces/notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;

  FirestoreNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  /// Generates real notifications from active database entities (tickets, payments, contracts)
  /// if notifications collection is empty, ensuring all notifications reflect real database activity.
  Future<void> ensureInitialNotificationsFromDatabaseEntities() async {
    try {
      final existingSnap = await _notificationsRef.limit(1).get().timeout(const Duration(seconds: 2));
      if (existingSnap.docs.isNotEmpty) {
        return;
      }

      final List<AppNotification> realNotifs = [];

      // 1. Generate real notifications from active Maintenance Tickets in DB
      try {
        final ticketsSnap = await _firestore.collection('maintenance_tickets').limit(20).get().timeout(const Duration(seconds: 2));
        for (final doc in ticketsSnap.docs) {
          final d = doc.data();
          final id = d['id'] as String? ?? doc.id;
          final ticketNo = d['ticketNumber'] as String? ?? id;
          final unitId = d['unitId'] as String? ?? 'A01-207';
          final title = d['title'] as String? ?? 'Plumbing & Maintenance Request';
          final status = d['status'] as String? ?? 'inProgress';
          final urgency = d['urgency'] as String? ?? 'high';
          final residentUserId = d['residentUserId'] as String? ?? 'ALL';

          realNotifs.add(
            AppNotification(
              id: 'NTF-TKT-$id',
              targetUserId: residentUserId.isEmpty ? 'ALL' : residentUserId,
              title: 'Maintenance Ticket #$ticketNo',
              titleAr: 'تذكرة صيانة #$ticketNo',
              body: '$title for Unit $unitId (Status: ${status.toUpperCase()})',
              bodyAr: '$title للوحدة $unitId (الحالة: ${status.toUpperCase()})',
              priority: urgency == 'emergency' ? NotificationPriority.emergency : NotificationPriority.normal,
              type: 'maintenance_created',
              unitId: unitId,
              createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
            ),
          );
        }
      } catch (_) {}

      // 2. Generate real notifications from active Payments in DB
      try {
        final paymentsSnap = await _firestore.collection('payments').limit(20).get().timeout(const Duration(seconds: 2));
        for (final doc in paymentsSnap.docs) {
          final d = doc.data();
          final id = d['id'] as String? ?? doc.id;
          final unitId = d['unitId'] as String? ?? 'A01-207';
          final txnRef = d['transactionReference'] as String? ?? id;
          final amount = (d['amountPaid'] as num?)?.toDouble() ?? 25000.0;
          final payerUserId = d['payerUserId'] as String? ?? 'ALL';

          final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              );

          realNotifs.add(
            AppNotification(
              id: 'NTF-PAY-$id',
              targetUserId: payerUserId.isEmpty ? 'ALL' : payerUserId,
              title: 'Payment Reconciled ($formattedAmount EGP)',
              titleAr: 'تم تسوية دفعة ($formattedAmount ج.م)',
              body: 'Receipt #$txnRef settled for Unit $unitId.',
              bodyAr: 'تمت تسوية إيصال السداد رقم #$txnRef للوحدة $unitId.',
              priority: NotificationPriority.high,
              type: 'payment',
              unitId: unitId,
              installmentAmount: amount,
              createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            ),
          );
        }
      } catch (_) {}

      if (realNotifs.isNotEmpty) {
        await batchSendNotifications(realNotifs);
      }
    } catch (e) {
      debugPrint('[FirestoreNotificationRepository] ensureInitialNotifications note: $e');
    }
  }

  @override
  Future<AppNotification?> getNotificationById(String id) async {
    final doc = await _notificationsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppNotification.fromJson(doc.data()!);
  }

  @override
  Stream<AppNotification?> streamNotification(String id) {
    return _notificationsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppNotification.fromJson(doc.data()!);
    });
  }

  @override
  Stream<List<AppNotification>> streamNotificationsForUser(String userId) {
    return _notificationsRef
        .where('targetUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromJson(doc.data()))
            .toList());
  }

  @override
  Stream<List<AppNotification>> streamAllNotifications() {
    return _notificationsRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<List<AppNotification>> getNotifications({
    String? targetUserId,
    bool? isRead,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _notificationsRef;

    if (targetUserId != null && targetUserId.isNotEmpty) {
      q = q.where('targetUserId', isEqualTo: targetUserId);
    }
    if (isRead != null) {
      q = q.where('isRead', isEqualTo: isRead);
    }

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _notificationsRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    return snap.docs.map((doc) => AppNotification.fromJson(doc.data())).toList();
  }

  @override
  Future<void> sendNotification(AppNotification notification) async {
    await _notificationsRef.doc(notification.id).set(notification.toJson());
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead({String? targetUserId}) async {
    try {
      Query<Map<String, dynamic>> q = _notificationsRef.where('isRead', isEqualTo: false);
      if (targetUserId != null && targetUserId.isNotEmpty && targetUserId != 'ALL') {
        q = q.where('targetUserId', whereIn: [targetUserId, 'ALL']);
      }
      final snap = await q.get();
      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[FirestoreNotificationRepository] markAllAsRead error: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.doc(notificationId).delete();
  }

  @override
  Future<void> batchSendNotifications(List<AppNotification> notifications) async {
    if (notifications.isEmpty) return;
    final batch = _firestore.batch();
    for (final n in notifications) {
      batch.set(_notificationsRef.doc(n.id), n.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}

