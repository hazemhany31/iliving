import '../../models/unit_model.dart';

abstract class UnitRepository {
  Future<Unit?> getUnitById(String id);
  Stream<Unit?> streamUnit(String id);
  Stream<List<Unit>> streamUnitsForCompound(String compoundId);
  Stream<List<Unit>> streamUnitsForUser(String userId);
  Stream<List<Unit>> streamAllUnits();
  Future<List<Unit>> getUnits({
    String? compoundId,
    String? buildingId,
    UnitStatus? status,
    String? orientation,
    String? block,
    bool? hasGarden,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  });
  Future<void> createUnit(Unit unit);
  Future<void> updateUnit(Unit unit);
  Future<void> deleteUnit(String id);
  Future<void> updateUnitStatus(String unitId, UnitStatus status, {String? ownerId});
  Future<void> updateUnitPrice(String unitId, double newPricePerSqm, String reason, String changedByUserId);
  Future<void> batchCreateUnits(List<Unit> units);
  Future<void> batchUpdateUnits(List<Unit> units);
}
