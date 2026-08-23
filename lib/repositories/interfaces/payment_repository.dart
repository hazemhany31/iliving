import '../../models/payment.dart';

abstract class PaymentRepository {
  Future<Payment?> getPaymentById(String id);
  Stream<Payment?> streamPayment(String id);
  Stream<List<Payment>> streamPaymentsForUser(String userId);
  Stream<List<Payment>> streamAllPayments();
  Future<List<Payment>> getPayments({
    String? payerUserId,
    String? unitId,
    String? receiptNumber,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    String? startAfterId,
  });
  Future<void> logPayment(Payment payment);
  Future<void> updatePayment(Payment payment);
  Future<void> deletePayment(String id);
  Future<void> batchLogPayments(List<Payment> payments);
}
