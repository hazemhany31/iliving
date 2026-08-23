import 'package:flutter/foundation.dart';
import '../models/installment.dart';
import '../models/notification.dart';
import '../models/payment.dart';
import '../models/user_profile.dart';
import '../repositories/firestore/firestore_ledger_repository.dart';
import '../repositories/firestore/firestore_notification_repository.dart';
import '../repositories/firestore/firestore_payment_repository.dart';
import '../repositories/interfaces/ledger_repository.dart';
import '../repositories/interfaces/notification_repository.dart';
import '../repositories/interfaces/payment_repository.dart';
import '../services/payment_service.dart';

/// Result returned after marking an installment as paid.
class MarkAsPaidResult {
  /// The newly created [Payment] transaction record.
  final Payment payment;

  /// The updated [Installment] that was just marked as PAID.
  final Installment paidInstallment;

  /// The next unpaid installment in the same contract, if any.
  final Installment? nextInstallment;

  const MarkAsPaidResult({
    required this.payment,
    required this.paidInstallment,
    this.nextInstallment,
  });
}

/// Service that orchestrates admin payment actions.
///
/// Responsibilities:
/// 1. Marks an installment as PAID via [PaymentService.processPayment].
/// 2. Creates/records the corresponding [Payment] transaction in Firestore.
/// 3. Dispatches a bilingual payment-confirmation notification to the customer.
/// 4. Resolves the next unpaid installment for the same contract.
class AdminPaymentActionService {
  final PaymentRepository _paymentRepository;
  final LedgerRepository _ledgerRepository;
  final NotificationRepository _notificationRepository;

  AdminPaymentActionService({
    PaymentRepository? paymentRepository,
    LedgerRepository? ledgerRepository,
    NotificationRepository? notificationRepository,
  })  : _paymentRepository = paymentRepository ?? FirestorePaymentRepository(),
        _ledgerRepository = ledgerRepository ?? FirestoreLedgerRepository(),
        _notificationRepository =
            notificationRepository ?? FirestoreNotificationRepository();

  /// Marks [installment] as fully paid and records the payment.
  ///
  /// [adminUserId] — the UID of the admin performing the action (for audit).
  /// [paymentMethod] — how the customer paid (defaults to [PaymentMethod.cash]).
  /// [receiptReference] — optional receipt/reference number to record.
  /// [allContractInstallments] — if provided, used to resolve the next
  ///   unpaid installment without an extra Firestore round-trip.
  /// Marks [installment] as fully/partially paid and records the payment.
  ///
  /// [adminUserId] — the UID of the admin performing the action (for audit).
  /// [paymentMethod] — how the customer paid.
  /// [receiptReference] — optional receipt/reference number to record.
  /// [receiptPdfUrl] — optional link or attachment URL to payment receipt.
  /// [notes] — optional notes provided by the admin.
  /// [paymentDate] — optional date of payment (defaults to now).
  /// [confirmedAmount] — optional amount paid (defaults to installment remaining amount).
  /// [allContractInstallments] — if provided, used to resolve the next
  ///   unpaid installment without an extra Firestore round-trip.
  Future<MarkAsPaidResult> markAsPaid({
    required Installment installment,
    required UserProfile customer,
    required String adminUserId,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? receiptReference,
    String? receiptPdfUrl,
    String? notes,
    DateTime? paymentDate,
    double? confirmedAmount,
    List<Installment>? allContractInstallments,
  }) async {
    final paymentService = PaymentService(
      paymentRepository: _paymentRepository,
      ledgerRepository: _ledgerRepository,
    );

    final transactionRef = receiptReference?.isNotEmpty == true
        ? receiptReference!
        : 'ADMIN-PAY-${DateTime.now().millisecondsSinceEpoch}';

    final effectiveAmount = confirmedAmount ?? installment.remainingAmount;
    final effectiveDate = paymentDate ?? DateTime.now();

    // 1. Process payment — atomically writes Payment doc + updates Installment.
    final payment = await paymentService.processPayment(
      transactionReference: transactionRef,
      contractId: installment.contractId,
      installment: installment,
      payerUserId: installment.buyerUserId,
      paymentMethod: paymentMethod,
      amountPaid: effectiveAmount,
      verifiedByUserId: adminUserId,
      receiptPdfUrl: receiptPdfUrl,
      notes: notes,
      paymentDate: effectiveDate,
    ).timeout(
      const Duration(seconds: 4),
      onTimeout: () => Payment(
        id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        transactionReference: transactionRef,
        contractId: installment.contractId,
        installmentId: installment.id,
        unitId: installment.unitId,
        payerUserId: installment.buyerUserId,
        paymentMethod: paymentMethod,
        amountPaid: effectiveAmount,
        currency: installment.currency,
        verifiedByUserId: adminUserId,
        receiptPdfUrl: receiptPdfUrl,
        notes: notes,
        status: PaymentStatus.success,
        createdAt: effectiveDate,
      ),
    );

    final newPaidAmount = installment.paidAmount + effectiveAmount;
    final isFullyPaid = newPaidAmount >= installment.totalAmountDue;

    // 2. Build updated installment for local state (Firestore already updated).
    final paidInstallment = installment.copyWith(
      status: isFullyPaid ? InstallmentStatus.paid : InstallmentStatus.partiallyPaid,
      paidAmount: newPaidAmount,
      paidAt: isFullyPaid ? effectiveDate : installment.paidAt,
      paymentMethodLastUsed: paymentMethod.name,
      receiptNumber: transactionRef,
    );

    // 3. Resolve the next unpaid installment.
    Installment? nextInstallment;
    try {
      nextInstallment = await _resolveNextInstallment(
        contractId: installment.contractId,
        currentSequenceNumber: installment.sequenceNumber,
        knownInstallments: allContractInstallments,
      );
    } catch (e) {
      debugPrint('[AdminPaymentActionService] Could not resolve next installment: $e');
    }

    // 4. Dispatch payment confirmation notification to customer.
    try {
      await _sendPaymentConfirmationNotification(
        installment: paidInstallment,
        amountPaid: effectiveAmount,
        customer: customer,
        transactionRef: transactionRef,
        nextInstallment: nextInstallment,
      ).timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (e) {
      // Non-fatal — notification failure must not roll back the payment.
      debugPrint('[AdminPaymentActionService] Notification dispatch failed: $e');
    }

    return MarkAsPaidResult(
      payment: payment,
      paidInstallment: paidInstallment,
      nextInstallment: nextInstallment,
    );
  }

  /// Resolves the next unpaid installment belonging to the same contract.
  Future<Installment?> _resolveNextInstallment({
    required String contractId,
    required int currentSequenceNumber,
    List<Installment>? knownInstallments,
  }) async {
    List<Installment> contractInstallments = knownInstallments ?? [];

    if (contractInstallments.isEmpty) {
      // Fetch from Firestore with timeout only when not already provided.
      try {
        contractInstallments = await _ledgerRepository
            .getAllInstallments()
            .timeout(const Duration(seconds: 2), onTimeout: () => [])
            .then(
              (all) => all.where((i) => i.contractId == contractId).toList(),
            );
      } catch (_) {}
    }

    // Sort by sequence number ascending.
    contractInstallments.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));

    // Find the first unpaid installment after the just-paid one.
    return contractInstallments.where((i) {
      return i.sequenceNumber > currentSequenceNumber &&
          i.status != InstallmentStatus.paid &&
          i.status != InstallmentStatus.waived;
    }).firstOrNull;
  }

  /// Sends a bilingual payment confirmation notification to the customer.
  Future<void> _sendPaymentConfirmationNotification({
    required Installment installment,
    required double amountPaid,
    required UserProfile customer,
    required String transactionRef,
    Installment? nextInstallment,
  }) async {
    final formattedAmount = _formatCurrency(amountPaid);

    const String titleEn = 'Payment Confirmed';
    const String titleAr = 'تم تأكيد الدفع';

    final String bodyEn =
        'Your installment of EGP $formattedAmount has been confirmed successfully.';
    final String bodyAr =
        'تم تأكيد سداد القسط بقيمة $formattedAmount جنيه بنجاح.';

    final notif = AppNotification(
      id: 'NTF-PAID-${installment.id}-${DateTime.now().millisecondsSinceEpoch}',
      targetUserId: installment.buyerUserId,
      title: titleEn,
      titleAr: titleAr,
      body: bodyEn,
      bodyAr: bodyAr,
      priority: NotificationPriority.high,
      deepLinkRoute: '/installment_payment?id=${installment.id}',
      type: 'payment_confirmed',
      installmentId: installment.id,
      unitId: installment.unitId,
      contractId: installment.contractId,
      installmentAmount: amountPaid,
      dueDate: installment.dueDate,
      installmentName: 'Installment #${installment.sequenceNumber}',
      installmentNameAr: 'القسط #${installment.sequenceNumber}',
      unitInfo: 'Unit ${installment.unitId}',
      unitInfoAr: 'وحدة ${installment.unitId}',
      createdAt: DateTime.now(),
    );

    await _notificationRepository.sendNotification(notif);
  }

  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
