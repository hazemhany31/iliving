import '../../models/building.dart';

abstract class BuildingRepository {
  Future<Building?> getBuildingById(String id);
  Stream<Building?> streamBuilding(String id);
  Stream<List<Building>> streamBuildingsForCompound(String compoundId);
  Future<List<Building>> getBuildingsForCompound(String compoundId);
  Future<void> createBuilding(Building building);
  Future<void> updateBuilding(Building building);
  Future<void> deleteBuilding(String id);
  Future<void> batchCreateBuildings(List<Building> buildings);
}
