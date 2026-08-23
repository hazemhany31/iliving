import '../models/payment.dart';
import '../models/installment.dart';
import '../repositories/interfaces/payment_repository.dart';
import '../repositories/interfaces/ledger_repository.dart';

class PaymentService {
  final PaymentRepository _paymentRepository;
  final LedgerRepository _ledgerRepository;

  PaymentService({
    required PaymentRepository paymentRepository,
    required LedgerRepository ledgerRepository,
  })  : _paymentRepository = paymentRepository,
        _ledgerRepository = ledgerRepository;

  Future<Payment> processPayment({
    required String transactionReference,
    required String contractId,
    required Installment installment,
    required String payerUserId,
    required PaymentMethod paymentMethod,
    required double amountPaid,
    String? verifiedByUserId,
    String? receiptPdfUrl,
    String? notes,
    DateTime? paymentDate,
  }) async {
    final effectiveDate = paymentDate ?? DateTime.now();

    final payment = Payment(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      transactionReference: transactionReference,
      contractId: contractId,
      installmentId: installment.id,
      unitId: installment.unitId,
      payerUserId: payerUserId,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      currency: installment.currency,
      verifiedByUserId: verifiedByUserId,
      receiptPdfUrl: receiptPdfUrl,
      notes: notes,
      status: PaymentStatus.success,
      createdAt: effectiveDate,
    );

    try {
      await _paymentRepository.logPayment(payment).timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
    } catch (_) {}

    final newPaidAmount = installment.paidAmount + amountPaid;
    final isFullyPaid = newPaidAmount >= installment.totalAmountDue;

    final updatedInstallment = installment.copyWith(
      paidAmount: newPaidAmount,
      status: isFullyPaid ? InstallmentStatus.paid : InstallmentStatus.partiallyPaid,
      paidAt: isFullyPaid ? effectiveDate : installment.paidAt,
      paymentMethodLastUsed: paymentMethod.name,
      receiptNumber: transactionReference,
    );

    try {
      await _ledgerRepository.updateInstallment(updatedInstallment).timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
    } catch (_) {}

    return payment;
  }
}
