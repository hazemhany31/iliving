import '../models/installment.dart';
import '../repositories/interfaces/ledger_repository.dart';

class LedgerService {
  final LedgerRepository _ledgerRepository;

  LedgerService({required LedgerRepository ledgerRepository})
      : _ledgerRepository = ledgerRepository;

  List<Installment> generateInstallmentSchedule({
    required String contractId,
    required String unitId,
    required String buyerUserId,
    required double totalUnitValue,
    required double downPayment,
    required double maintenanceFundPercentage, // e.g. 0.08 for 8%
    required int durationYears,
    required int frequencyPerYear, // e.g. 4 for quarterly
    required DateTime startDate,
  }) {
    final maintenanceDepositAmount = totalUnitValue * maintenanceFundPercentage;
    return generateInstallmentScheduleWithAmount(
      contractId: contractId,
      unitId: unitId,
      buyerUserId: buyerUserId,
      totalUnitValue: totalUnitValue,
      downPayment: downPayment,
      maintenanceDepositAmount: maintenanceDepositAmount,
      totalInstallmentsCount: durationYears * frequencyPerYear,
      startDate: startDate,
      maintenanceDueDate: DateTime(
        startDate.year + (durationYears > 0 ? durationYears - 1 : 2),
        startDate.month,
        startDate.day,
      ),
    );
  }

  List<Installment> generateInstallmentScheduleWithAmount({
    required String contractId,
    required String unitId,
    required String buyerUserId,
    required double totalUnitValue,
    required double downPayment,
    required double maintenanceDepositAmount,
    required int totalInstallmentsCount,
    required DateTime startDate,
    DateTime? maintenanceDueDate,
  }) {
    final remainingBalance = totalUnitValue - downPayment;
    final totalInstallments = totalInstallmentsCount > 0 ? totalInstallmentsCount : 12;
    final baseInstallmentAmount = remainingBalance > 0 ? (remainingBalance / totalInstallments) : 0.0;

    final List<Installment> schedule = [];

    // 1. Down payment installment
    if (downPayment > 0) {
      schedule.add(
        Installment(
          id: 'INS-$contractId-DP',
          contractId: contractId,
          unitId: unitId,
          buyerUserId: buyerUserId,
          sequenceNumber: 1,
          installmentType: InstallmentType.downPayment,
          dueDate: startDate,
          gracePeriodEndDate: startDate.add(const Duration(days: 14)),
          principalAmount: downPayment,
        ),
      );
    }

    // 2. Regular Installments
    int monthInterval = (12 * 30 / totalInstallments).round();
    if (monthInterval < 30) monthInterval = 30;
    for (int i = 1; i <= totalInstallments; i++) {
      final dueDate = DateTime(
        startDate.year,
        startDate.month + (i * 3),
        startDate.day,
      );
      schedule.add(
        Installment(
          id: 'INS-$contractId-${schedule.length + 1}',
          contractId: contractId,
          unitId: unitId,
          buyerUserId: buyerUserId,
          sequenceNumber: schedule.length + 1,
          installmentType: InstallmentType.regularQuarterly,
          dueDate: dueDate,
          gracePeriodEndDate: dueDate.add(const Duration(days: 14)),
          principalAmount: baseInstallmentAmount,
        ),
      );
    }

    // 3. Maintenance Fund Installment (وديعة الصيانة)
    if (maintenanceDepositAmount > 0) {
      final mntDueDate = maintenanceDueDate ??
          DateTime(
            startDate.year + 3,
            startDate.month,
            startDate.day,
          );
      schedule.add(
        Installment(
          id: 'INS-$contractId-MNT',
          contractId: contractId,
          unitId: unitId,
          buyerUserId: buyerUserId,
          sequenceNumber: schedule.length + 1,
          installmentType: InstallmentType.maintenanceFund,
          dueDate: mntDueDate,
          gracePeriodEndDate: mntDueDate.add(const Duration(days: 14)),
          principalAmount: maintenanceDepositAmount,
        ),
      );
    }

    return schedule;
  }

  double calculatePenalty({
    required double unpaidAmount,
    required int daysOverdue,
    double annualPenaltyRate = 0.12,
  }) {
    if (daysOverdue <= 0 || unpaidAmount <= 0) return 0.0;
    final dailyRate = annualPenaltyRate / 365.0;
    return unpaidAmount * dailyRate * daysOverdue;
  }

  Future<void> updateLedgerForInstallmentPayment(
      Installment installment, double paidAmount) async {
    final updatedPaidAmount = installment.paidAmount + paidAmount;
    final isFullyPaid = updatedPaidAmount >= installment.totalAmountDue;

    final updatedInstallment = installment.copyWith(
      paidAmount: updatedPaidAmount,
      status: isFullyPaid ? InstallmentStatus.paid : InstallmentStatus.partiallyPaid,
      paidAt: isFullyPaid ? DateTime.now() : installment.paidAt,
    );

    await _ledgerRepository.updateInstallment(updatedInstallment);
  }
}
