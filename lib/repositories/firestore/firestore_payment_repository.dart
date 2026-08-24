import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/payment.dart';
import '../../services/notification_service.dart';
import '../interfaces/payment_repository.dart';
import 'firestore_notification_repository.dart';

class FirestorePaymentRepository implements PaymentRepository {
  final FirebaseFirestore _firestore;

  FirestorePaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _firestore.collection('payments');

  @override
  Future<Payment?> getPaymentById(String id) async {
    final doc = await _paymentsRef.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return Payment.fromJson(data);
  }

  @override
  Stream<Payment?> streamPayment(String id) {
    return _paymentsRef.doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return Payment.fromJson(data);
    });
  }

  @override
  Stream<List<Payment>> streamPaymentsForUser(String userId) {
    return _paymentsRef
        .where('payerUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromJson(doc.data())).toList());
  }

  @override
  Stream<List<Payment>> streamAllPayments() {
    return _paymentsRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Payment.fromJson(doc.data())).toList(),
        );
  }

  /// A bandwidth-capped variant for admin list screens.
  Stream<List<Payment>> streamAllPaymentsLimited({int limit = 500}) {
    return _paymentsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromJson(doc.data())).toList());
  }

  @override
  Future<List<Payment>> getPayments({
    String? payerUserId,
    String? unitId,
    String? receiptNumber,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _paymentsRef;

    if (payerUserId != null && payerUserId.isNotEmpty) {
      q = q.where('payerUserId', isEqualTo: payerUserId);
    }
    if (unitId != null && unitId.isNotEmpty) {
      q = q.where('unitId', isEqualTo: unitId);
    }
    if (receiptNumber != null && receiptNumber.isNotEmpty) {
      q = q.where('receiptNumber', isEqualTo: receiptNumber);
    }
    if (status != null) {
      q = q.where('status', isEqualTo: status.name);
    }

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _paymentsRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    var list = snap.docs.map((doc) => Payment.fromJson(doc.data())).toList();

    if (startDate != null) {
      list = list.where((p) => p.paymentTimestamp.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      list = list.where((p) => p.paymentTimestamp.isBefore(endDate)).toList();
    }

    return list;
  }

  @override
  Future<void> logPayment(Payment payment) async {
    await _paymentsRef.doc(payment.id).set(payment.toJson());
    try {
      final notifService = NotificationService(
        notificationRepository: FirestoreNotificationRepository(firestore: _firestore),
      );
      await notifService.notifyPaymentReceived(
        payerUserId: payment.payerUserId,
        unitId: payment.unitId,
        amount: payment.amountPaid,
        transactionReference: payment.transactionReference,
      );
    } catch (_) {}
  }

  @override
  Future<void> updatePayment(Payment payment) async {
    await _paymentsRef.doc(payment.id).update(payment.toJson());
  }

  @override
  Future<void> deletePayment(String id) async {
    await _paymentsRef.doc(id).delete();
  }

  @override
  Future<void> batchLogPayments(List<Payment> payments) async {
    if (payments.isEmpty) return;
    final batch = _firestore.batch();
    for (final p in payments) {
      batch.set(_paymentsRef.doc(p.id), p.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
