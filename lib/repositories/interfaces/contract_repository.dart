import '../../models/contract.dart';

abstract class ContractRepository {
  Future<Contract?> getContractById(String id);
  Stream<Contract?> streamContract(String id);
  Stream<List<Contract>> streamContractsForUser(String userId);
  Stream<List<Contract>> streamAllContracts();
  Future<List<Contract>> getContracts({
    String? buyerUserId,
    String? compoundId,
    String? clientCode,
    SignatureStatus? status,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  });
  Future<void> createContract(Contract contract);
  Future<void> updateContract(Contract contract);
  Future<void> deleteContract(String id);
  Future<void> batchSaveContracts(List<Contract> contracts);
}
