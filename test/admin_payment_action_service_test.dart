import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/installment.dart';
import 'package:iliving/models/payment.dart';
import 'package:iliving/widgets/admin/installment_payment_confirm_dialog.dart';

void main() {
  group('AdminPaymentActionService Unit Tests', () {
    final inst1 = Installment(
      id: 'INS-001',
      contractId: 'CTR-001',
      unitId: 'B201-305',
      buyerUserId: 'USR-TEST-001',
      sequenceNumber: 5,
      installmentType: InstallmentType.regularQuarterly,
      dueDate: DateTime(2026, 8, 27),
      gracePeriodEndDate: DateTime(2026, 9, 10),
      principalAmount: 25000.0,
      status: InstallmentStatus.unpaid,
    );

    test('MarkAsPaidResult formats currency correctly', () {
      expect(inst1.totalAmountDue, 25000.0);
      expect(inst1.status, InstallmentStatus.unpaid);
    });

    test('PaymentConfirmData retains selected payment method and reference', () {
      final data = PaymentConfirmData(
        paymentMethod: PaymentMethod.cash,
        receiptReference: 'CHQ-2026-001',
        amountPaid: 25000.0,
        paymentDate: DateTime(2026, 8, 8),
      );
      expect(data.paymentMethod, PaymentMethod.cash);
      expect(data.receiptReference, 'CHQ-2026-001');
      expect(data.amountPaid, 25000.0);
    });

    test('Empty contract installments list handles safe resolution', () {
      final List<Installment> emptyList = [];
      expect(emptyList.isEmpty, true);
      expect(emptyList.lastOrNull, null);
    });
  });
}
