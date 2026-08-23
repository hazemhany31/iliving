import '../../models/project.dart';

abstract class ProjectRepository {
  Future<Project?> getProjectById(String id);
  Stream<Project?> streamProject(String id);
  Stream<List<Project>> streamAllProjects();
  Future<List<Project>> getProjects({
    String? searchQuery,
    int? limit,
    String? startAfterId,
  });
  Future<void> createProject(Project project);
  Future<void> updateProject(Project project);
  Future<void> deleteProject(String id);
}
