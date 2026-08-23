import '../../models/compound_model.dart';

abstract class CompoundRepository {
  Future<CompoundModel?> getCompoundById(String id);
  Stream<CompoundModel?> streamCompound(String id);
  Stream<List<CompoundModel>> streamAllCompounds();
  Future<List<CompoundModel>> getCompounds({
    String? projectId,
    String? searchQuery,
    int? limit,
    String? startAfterId,
  });
  Future<void> createCompound(CompoundModel compound);
  Future<void> updateCompound(CompoundModel compound);
  Future<void> deleteCompound(String id);
}
