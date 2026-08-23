import '../../models/unit_ledger_model.dart';
import '../../models/installment.dart';

abstract class LedgerRepository {
  Future<UnitLedger?> getLedgerByUnitId(String unitId);
  Stream<UnitLedger?> streamLedgerForUnit(String unitId);
  Stream<List<UnitLedger>> streamAllLedgers();
  Stream<List<Installment>> streamInstallmentsForUser(String userId);
  Stream<List<Installment>> streamAllInstallments();
  Future<List<Installment>> getAllInstallments();
  Future<List<UnitLedger>> getLedgers({
    String? compoundId,
    String? clientId,
    int? limit,
    String? startAfterId,
  });
  Future<void> saveLedger(UnitLedger ledger);
  Future<void> createInstallment(Installment installment);
  Future<void> updateInstallment(Installment installment);
  Future<void> deleteInstallment(String contractId, String installmentId);
  Future<void> deleteLedger(String unitId);
  Future<void> batchUpdateInstallments(List<Installment> installments);
}

