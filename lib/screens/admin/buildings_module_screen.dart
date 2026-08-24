import 'package:flutter/material.dart';
import '../../models/building.dart';
import '../../models/compound_model.dart';
import '../../repositories/firestore/firestore_building_repository.dart';
import '../../repositories/firestore/firestore_compound_repository.dart';
import '../../theme/luxury_theme.dart';
import '../../widgets/admin/shared/admin_data_table.dart';
import '../../widgets/admin/shared/admin_form_dialog.dart';
import '../../widgets/admin/shared/admin_confirm_dialog.dart';

class BuildingsModuleScreen extends StatefulWidget {
  const BuildingsModuleScreen({super.key});

  @override
  State<BuildingsModuleScreen> createState() => _BuildingsModuleScreenState();
}

class _BuildingsModuleScreenState extends State<BuildingsModuleScreen> {
  final FirestoreBuildingRepository _buildingRepository = FirestoreBuildingRepository();
  final FirestoreCompoundRepository _compoundRepository = FirestoreCompoundRepository();
  late final Stream<List<CompoundModel>> _compoundsStream;
  static final Map<String, List<Building>> _cachedBuildings = {};
  String? _selectedCompoundId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _compoundsStream = _compoundRepository.streamAllCompounds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return StreamBuilder<List<CompoundModel>>(
      stream: _compoundsStream,
      builder: (context, compoundSnap) {
        final compounds = compoundSnap.data ?? [];
        if (_selectedCompoundId == null && compounds.isNotEmpty) {
          _selectedCompoundId = compounds.first.id;
        }

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
                          'BUILDINGS MANAGEMENT',
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
                          'Manage structures, floors, and unit capacity across compounds',
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
                      icon: const Icon(Icons.apartment_outlined, size: 18),
                      label: const Text(
                        'Create Building',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: _selectedCompoundId == null
                          ? null
                          : () => _showBuildingFormDialog(context, defaultCompoundId: _selectedCompoundId!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Row: Compound Picker & Search Bar
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Container(
                    width: 240,
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                      borderRadius: AppBorderRadius.pill,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCompoundId,
                        isExpanded: true,
                        hint: Text('Select Compound', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12)),
                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        items: compounds.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.title, style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCompoundId = val);
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 280,
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
                              hintText: 'Filter buildings...',
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
                ],
              ),
              const SizedBox(height: 16),

              // Table
              Expanded(
                child: _selectedCompoundId == null
                    ? const Center(child: Text('Please select or create a compound first.', style: TextStyle(color: AppColors.accent)))
                    : StreamBuilder<List<Building>>(
                        stream: _buildingRepository.streamBuildingsForCompound(_selectedCompoundId!),
                        builder: (context, buildingSnap) {
                          if (buildingSnap.hasData) {
                            _cachedBuildings[_selectedCompoundId!] = buildingSnap.data!;
                          }
                          final buildings = buildingSnap.data ?? _cachedBuildings[_selectedCompoundId!] ?? [];
                          final isLoading = buildings.isEmpty && buildingSnap.connectionState == ConnectionState.waiting;
                          final filteredBuildings = buildings.where((b) {
                            if (_searchQuery.isEmpty) return true;
                            final q = _searchQuery.toLowerCase();
                            return b.name.toLowerCase().contains(q) ||
                                b.code.toLowerCase().contains(q) ||
                                b.id.toLowerCase().contains(q);
                          }).toList();

                          return AdminDataTable<Building>(
                            isLoading: isLoading,
                            items: filteredBuildings,
                            emptyTitle: 'No Buildings Found',
                            emptyMessage: _searchQuery.isEmpty
                                ? 'No buildings registered for this compound. Click "+ Create Building" to add one.'
                                : 'No buildings match your filter query "$_searchQuery".',
                            columns: [
                              AdminTableColumn<Building>(
                                title: 'Building Code',
                                cellBuilder: (b) => Text(
                                  b.code,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              AdminTableColumn<Building>(
                                title: 'Building Name',
                                cellBuilder: (b) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      b.name,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    if (b.nameAr.isNotEmpty)
                                      Text(
                                        b.nameAr,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 11,
                                          color: textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              AdminTableColumn<Building>(
                                title: 'Floors / Units',
                                cellBuilder: (b) => Text(
                                  '${b.totalFloors} Floors • ${b.totalUnits} Units',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              AdminTableColumn<Building>(
                                title: 'Compound ID',
                                cellBuilder: (b) => Text(
                                  b.compoundId,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              AdminTableColumn<Building>(
                                title: 'Actions',
                                cellBuilder: (b) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 18),
                                      tooltip: 'Edit Building',
                                      onPressed: () => _showBuildingFormDialog(context, building: b, defaultCompoundId: b.compoundId),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                      tooltip: 'Delete Building',
                                      onPressed: () => _confirmDeleteBuilding(context, b),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBuildingFormDialog(BuildContext context, {Building? building, required String defaultCompoundId}) {
    final isEditing = building != null;
    final idController = TextEditingController(text: building?.id ?? 'BLD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final codeController = TextEditingController(text: building?.code ?? 'B-01');
    final nameController = TextEditingController(text: building?.name ?? '');
    final nameArController = TextEditingController(text: building?.nameAr ?? '');
    final floorsController = TextEditingController(text: building != null ? building.totalFloors.toString() : '6');
    final unitsController = TextEditingController(text: building != null ? building.totalUnits.toString() : '24');

    AdminFormDialog.show(
      context: context,
      title: isEditing ? 'Edit Building' : 'Create New Building',
      subtitle: isEditing ? 'Update building details in Firestore' : 'Add new building to compound "$defaultCompoundId"',
      icon: isEditing ? Icons.edit_location : Icons.add_location,
      body: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEditing)
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Building ID (Doc ID)', hintText: 'e.g. BLD-001'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Building Code *',
                hintText: 'e.g. B-01',
                prefixIcon: Icon(Icons.qr_code_2, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: floorsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Floors *',
                hintText: 'e.g. 6',
                prefixIcon: Icon(Icons.layers_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: unitsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Units *',
                hintText: 'e.g. 24',
                prefixIcon: Icon(Icons.door_front_door_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Building Name (English) *',
                hintText: 'e.g. Building A1',
                prefixIcon: Icon(Icons.domain, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameArController,
              decoration: const InputDecoration(
                labelText: 'Building Name (Arabic)',
                hintText: 'e.g. مبنى أ١',
                prefixIcon: Icon(Icons.translate, size: 20),
              ),
            ),
          ],
        ),
      ),
      onSubmit: () async {
        if (nameController.text.trim().isEmpty) {
          throw Exception('Building name is required');
        }
        final b = Building(
          id: idController.text.trim(),
          compoundId: defaultCompoundId,
          code: codeController.text.trim(),
          name: nameController.text.trim(),
          nameAr: nameArController.text.trim(),
          totalFloors: int.tryParse(floorsController.text) ?? 6,
          totalUnits: int.tryParse(unitsController.text) ?? 24,
          createdAt: building?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (isEditing) {
          setState(() {
            final list = _cachedBuildings[defaultCompoundId];
            final idx = list?.indexWhere((item) => item.id == b.id) ?? -1;
            if (idx != -1) list?[idx] = b;
          });
          await _buildingRepository.updateBuilding(b);
        } else {
          setState(() {
            _cachedBuildings[defaultCompoundId] ??= [];
            _cachedBuildings[defaultCompoundId]?.insert(0, b);
          });
          await _buildingRepository.createBuilding(b);
        }
      },
    );
  }

  void _confirmDeleteBuilding(BuildContext context, Building b) {
    AdminConfirmDialog.show(
      context: context,
      title: 'Delete Building',
      message: 'Are you sure you want to delete building "${b.name}" (${b.code})? This action cannot be undone.',
      confirmLabel: 'Delete Record',
      isDanger: true,
      onConfirm: () async {
        setState(() {
          _cachedBuildings[b.compoundId]?.removeWhere((item) => item.id == b.id);
        });
        await _buildingRepository.deleteBuilding(b.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Building "${b.name}" deleted successfully.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }
}
