import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../repositories/firestore/firestore_project_repository.dart';
import '../../theme/luxury_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/admin/shared/admin_data_table.dart';
import '../../widgets/admin/shared/admin_form_dialog.dart';
import '../../widgets/admin/shared/admin_confirm_dialog.dart';

class ProjectsModuleScreen extends StatefulWidget {
  const ProjectsModuleScreen({super.key});

  @override
  State<ProjectsModuleScreen> createState() => _ProjectsModuleScreenState();
}

class _ProjectsModuleScreenState extends State<ProjectsModuleScreen> {
  final FirestoreProjectRepository _repository = FirestoreProjectRepository();
  late final Stream<List<Project>> _projectsStream;
  static List<Project>? _cachedProjects;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _projectsStream = _repository.streamAllProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return StreamBuilder<List<Project>>(
      stream: _projectsStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _cachedProjects = snapshot.data;
        }
        final projects = snapshot.data ?? _cachedProjects ?? [];
        final isLoading = projects.isEmpty && snapshot.connectionState == ConnectionState.waiting;
        final filteredProjects = projects.where((p) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return p.name.toLowerCase().contains(q) ||
              p.code.toLowerCase().contains(q) ||
              p.city.toLowerCase().contains(q) ||
              p.district.toLowerCase().contains(q);
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.projectsModule.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${l10n.projectsModule} (${projects.length} total projects)',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textMuted,
                            fontSize: 11.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                      ),
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: Text(
                        l10n.addProject,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () => _showProjectFormDialog(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                width: 320,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: textMuted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Filter projects...',
                          hintStyle: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textMuted,
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Table
              Expanded(
                child: AdminDataTable<Project>(
                  isLoading: isLoading,
                  items: filteredProjects,
                  emptyTitle: 'No Projects Found',
                  emptyMessage: _searchQuery.isEmpty
                      ? 'No project records exist in Firestore. Click "+ Create Project" to add one.'
                      : 'No projects match your filter query "$_searchQuery".',
                  columns: [
                    AdminTableColumn<Project>(
                      title: 'Project Code',
                      cellBuilder: (p) => Text(
                        p.code,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    AdminTableColumn<Project>(
                      title: 'Project Name',
                      cellBuilder: (p) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.name,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (p.nameAr.isNotEmpty)
                            Text(
                              p.nameAr,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AdminTableColumn<Project>(
                      title: 'Location',
                      cellBuilder: (p) => Text(
                        '${p.city}${p.district.isNotEmpty ? ', ${p.district}' : ''}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    AdminTableColumn<Project>(
                      title: 'Status',
                      cellBuilder: (p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (p.status.toUpperCase() == 'ACTIVE' ? AppColors.success : AppColors.warning).withAlpha(25),
                          borderRadius: AppBorderRadius.pill,
                        ),
                        child: Text(
                          p.status.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: p.status.toUpperCase() == 'ACTIVE' ? AppColors.success : AppColors.warning,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    AdminTableColumn<Project>(
                      title: 'Actions',
                      cellBuilder: (p) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 18),
                            tooltip: 'Edit Project',
                            onPressed: () => _showProjectFormDialog(context, project: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                            tooltip: 'Delete Project',
                            onPressed: () => _confirmDeleteProject(context, p),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProjectFormDialog(BuildContext context, {Project? project}) {
    final isEditing = project != null;
    final idController = TextEditingController(text: project?.id ?? 'PROJ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final codeController = TextEditingController(text: project?.code ?? 'PRJ-001');
    final nameController = TextEditingController(text: project?.name ?? '');
    final nameArController = TextEditingController(text: project?.nameAr ?? '');
    final cityController = TextEditingController(text: project?.city ?? 'Cairo');
    final districtController = TextEditingController(text: project?.district ?? 'New Cairo');
    final descController = TextEditingController(text: project?.description ?? '');
    String status = project?.status ?? 'ACTIVE';

    AdminFormDialog.show(
      context: context,
      title: isEditing ? 'Edit Project Details' : 'Create New Project',
      subtitle: isEditing ? 'Update project info in Firestore SSOT' : 'Add new development project to Master SSOT',
      icon: isEditing ? Icons.domain : Icons.add_business_rounded,
      body: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEditing)
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Project ID (Doc ID)', hintText: 'e.g. PROJ-001'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Project Code',
                hintText: 'e.g. PRJ-001',
                prefixIcon: Icon(Icons.qr_code_2, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.traffic, size: 20),
              ),
              items: const [
                DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'PLANNING', child: Text('PLANNING', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) {
                if (val != null) setModalState(() => status = val);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name (English) *',
                hintText: 'e.g. Grand Residence',
                prefixIcon: Icon(Icons.domain, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameArController,
              decoration: const InputDecoration(
                labelText: 'Project Name (Arabic)',
                hintText: 'e.g. المجمع السكني الكبير',
                prefixIcon: Icon(Icons.translate, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'e.g. Cairo',
                prefixIcon: Icon(Icons.location_city, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: districtController,
              decoration: const InputDecoration(
                labelText: 'District',
                hintText: 'e.g. New Cairo',
                prefixIcon: Icon(Icons.map_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.notes, size: 20),
              ),
            ),
          ],
        ),
      ),
      onSubmit: () async {
        if (nameController.text.trim().isEmpty) {
          throw Exception('Project name is required');
        }
        final p = Project(
          id: idController.text.trim(),
          developerId: project?.developerId ?? 'DEV-MASTER',
          code: codeController.text.trim(),
          name: nameController.text.trim(),
          nameAr: nameArController.text.trim(),
          description: descController.text.trim(),
          city: cityController.text.trim(),
          district: districtController.text.trim(),
          totalCompounds: project?.totalCompounds ?? 0,
          totalUnits: project?.totalUnits ?? 0,
          status: status,
          createdAt: project?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (isEditing) {
          setState(() {
            final idx = _cachedProjects?.indexWhere((proj) => proj.id == p.id) ?? -1;
            if (idx != -1) _cachedProjects?[idx] = p;
          });
          await _repository.updateProject(p);
        } else {
          setState(() {
            _cachedProjects?.insert(0, p);
          });
          await _repository.createProject(p);
        }
      },
    );
  }

  void _confirmDeleteProject(BuildContext context, Project p) {
    AdminConfirmDialog.show(
      context: context,
      title: 'Delete Project',
      message: 'Are you sure you want to permanently delete project "${p.name}" (${p.code})? This action cannot be undone.',
      confirmLabel: 'Delete Record',
      isDanger: true,
      onConfirm: () async {
        setState(() {
          _cachedProjects?.removeWhere((proj) => proj.id == p.id);
        });
        await _repository.deleteProject(p.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project "${p.name}" deleted successfully.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }
}
