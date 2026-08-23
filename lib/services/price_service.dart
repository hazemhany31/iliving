import '../repositories/interfaces/unit_repository.dart';

class PriceService {
  final UnitRepository _unitRepository;

  PriceService({required UnitRepository unitRepository})
      : _unitRepository = unitRepository;

  Future<void> updateUnitPrice({
    required String unitId,
    required double newPricePerSqm,
    required String reason,
    required String changedByUserId,
  }) async {
    await _unitRepository.updateUnitPrice(
      unitId,
      newPricePerSqm,
      reason,
      changedByUserId,
    );
  }
}
