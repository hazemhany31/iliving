import 'package:flutter/material.dart';
import '../../models/unit_model.dart';
import '../../models/compound_model.dart';
import '../../repositories/firestore/firestore_unit_repository.dart';
import '../../repositories/firestore/firestore_compound_repository.dart';
import '../../theme/luxury_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/admin/shared/admin_data_table.dart';
import '../../widgets/admin/shared/admin_form_dialog.dart';
import '../../widgets/admin/shared/admin_confirm_dialog.dart';

class UnitInventoryModuleScreen extends StatefulWidget {
  const UnitInventoryModuleScreen({super.key});

  @override
  State<UnitInventoryModuleScreen> createState() => _UnitInventoryModuleScreenState();
}

class _UnitInventoryModuleScreenState extends State<UnitInventoryModuleScreen> {
  final FirestoreUnitRepository _unitRepository = FirestoreUnitRepository();
  final FirestoreCompoundRepository _compoundRepository = FirestoreCompoundRepository();

  late final Stream<List<CompoundModel>> _compoundsStream;
  late final Stream<List<Unit>> _unitsStream;

  String? _selectedCompoundId;
  UnitStatus? _selectedStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static List<CompoundModel>? _cachedCompounds;
  static List<Unit>? _cachedUnits;

  @override
  void initState() {
    super.initState();
    _compoundsStream = _compoundRepository.streamAllCompounds();
    _unitsStream = _unitRepository.streamAllUnits();
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

    return StreamBuilder<List<CompoundModel>>(
      stream: _compoundsStream,
      builder: (context, compoundSnap) {
        if (compoundSnap.hasData) {
          _cachedCompounds = compoundSnap.data;
        }
        final compounds = compoundSnap.data ?? _cachedCompounds ?? [];

        return StreamBuilder<List<Unit>>(
          stream: _unitsStream,
          builder: (context, unitSnap) {
            if (unitSnap.hasData) {
              _cachedUnits = unitSnap.data;
            }
            final units = unitSnap.data ?? _cachedUnits ?? [];
            final isLoading = units.isEmpty && unitSnap.connectionState == ConnectionState.waiting;

            final filteredUnits = units.where((u) {
              if (_selectedCompoundId != null && u.compoundId != _selectedCompoundId) {
                return false;
              }
              if (_selectedStatus != null && u.status != _selectedStatus) {
                return false;
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                return u.unitNumber.toLowerCase().contains(q) ||
                    u.compoundId.toLowerCase().contains(q) ||
                    u.configuration.toLowerCase().contains(q);
              }
              return true;
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
                              l10n.unitInventoryModule.toUpperCase(),
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
                              '${l10n.unitInventoryModule} (${units.length} total units)',
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
                          icon: const Icon(Icons.add_home_outlined, size: 18),
                          label: Text(
                            l10n.addUnit,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () => _showUnitFormDialog(context, compounds: compounds),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filters Bar
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Filter Compound
                      Container(
                        width: 220,
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                          borderRadius: AppBorderRadius.pill,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedCompoundId,
                            isExpanded: true,
                            hint: Text('All Compounds', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12)),
                            dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Compounds', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12)),
                              ),
                              ...compounds.map((c) {
                                return DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Text(c.title, style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12)),
                                );
                              }),
                            ],
                            onChanged: (val) => setState(() => _selectedCompoundId = val),
                          ),
                        ),
                      ),

                      // Filter Status
                      Container(
                        width: 180,
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                          borderRadius: AppBorderRadius.pill,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<UnitStatus?>(
                            value: _selectedStatus,
                            isExpanded: true,
                            hint: Text('All Statuses', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12)),
                            dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            items: [
                              DropdownMenuItem<UnitStatus?>(
                                value: null,
                                child: Text('All Statuses', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12)),
                              ),
                              ...UnitStatus.values.map((s) {
                                return DropdownMenuItem<UnitStatus?>(
                                  value: s,
                                  child: Text(s.nameString, style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12)),
                                );
                              }),
                            ],
                            onChanged: (val) => setState(() => _selectedStatus = val),
                          ),
                        ),
                      ),

                      // Search
                      Container(
                        width: 240,
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
                                style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Search unit...',
                                  hintStyle: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
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

                  // Data Table
                  Expanded(
                    child: AdminDataTable<Unit>(
                      isLoading: isLoading,
                      items: filteredUnits,
                      emptyTitle: 'No Units Found',
                      emptyMessage: _searchQuery.isEmpty
                          ? 'No unit records exist. Click "+ Create Unit" to add one.'
                          : 'No units match your filter parameters.',
                      columns: [
                        AdminTableColumn<Unit>(
                          title: 'Unit Number',
                          cellBuilder: (u) => Text(
                            u.unitNumber,
                            style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, color: AppColors.accent),
                          ),
                        ),
                        AdminTableColumn<Unit>(
                          title: 'Compound / Config',
                          cellBuilder: (u) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(u.configuration, style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold, color: textColor)),
                              Text('Compound: ${u.compoundId}', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, color: textMuted)),
                            ],
                          ),
                        ),
                        AdminTableColumn<Unit>(
                          title: 'Area (sqft / sqm)',
                          cellBuilder: (u) => Text(
                            '${u.areaSqFt.toStringAsFixed(0)} sqft (${u.areaSquareMeters.toStringAsFixed(0)} m²)',
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
                          ),
                        ),
                        AdminTableColumn<Unit>(
                          title: 'Total Price (EGP)',
                          cellBuilder: (u) => Text(
                            'EGP ${u.priceEGP.toStringAsFixed(2)}',
                            style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                        ),
                        AdminTableColumn<Unit>(
                          title: 'Status',
                          cellBuilder: (u) {
                            Color badgeColor;
                            switch (u.status) {
                              case UnitStatus.available:
                                badgeColor = AppColors.success;
                                break;
                              case UnitStatus.reserved:
                                badgeColor = AppColors.warning;
                                break;
                              case UnitStatus.contracted:
                              case UnitStatus.delivered:
                                badgeColor = AppColors.info;
                                break;
                              default:
                                badgeColor = textMuted;
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withAlpha(25),
                                borderRadius: AppBorderRadius.pill,
                              ),
                              child: Text(
                                u.status.nameString,
                                style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: badgeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                        AdminTableColumn<Unit>(
                          title: 'Actions',
                          cellBuilder: (u) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 18),
                                tooltip: 'Edit Unit Details',
                                onPressed: () => _showUnitFormDialog(context, unit: u, compounds: compounds),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                tooltip: 'Delete Unit',
                                onPressed: () => _confirmDeleteUnit(context, u),
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
      },
    );
  }

  void _showUnitFormDialog(BuildContext context, {Unit? unit, required List<CompoundModel> compounds}) {
    final isEditing = unit != null;
    final formKey = GlobalKey<FormState>();

    final unitNumberController = TextEditingController(text: unit?.unitNumber ?? '');
    final buildingIdController = TextEditingController(text: unit?.buildingId ?? '');
    final floorTierController = TextEditingController(text: unit?.floorTier ?? 'Ground Floor');
    final areaSqFtController = TextEditingController(text: unit?.areaSqFt.toString() ?? '2000');
    final pricePerSqFtController = TextEditingController(text: unit?.pricePerSqFt.toString() ?? '5000');
    final configurationController = TextEditingController(text: unit?.configuration ?? 'Penthouse Suite');
    final assetClassController = TextEditingController(text: unit?.assetClass ?? 'Luxury Apartment');
    final furnishingController = TextEditingController(text: unit?.furnishingStatus ?? 'Fully Furnished');
    final parkingController = TextEditingController(text: unit?.parkingSpaces.toString() ?? '1');
    final phaseController = TextEditingController(text: unit?.constructionPhase ?? 'Phase 1');
    final orientationController = TextEditingController(text: unit?.orientation ?? 'North-East');
    final blockController = TextEditingController(text: unit?.block ?? 'Block A');

    String selectedCompound = unit?.parentCompoundId ?? (compounds.isNotEmpty ? compounds.first.id : 'COMPOUND-001');
    UnitStatus selectedStatus = unit?.status ?? UnitStatus.available;

    AdminFormDialog.show(
      context: context,
      title: isEditing ? 'Edit Unit "${unit.unitNumber}"' : 'Create New Unit Record',
      subtitle: 'Synchronize unit attributes directly to Firestore Master Catalog',
      icon: isEditing ? Icons.edit_note : Icons.add_home,
      submitLabel: isEditing ? 'Save Changes' : 'Create Unit',
      body: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: compounds.any((c) => c.id == selectedCompound) ? selectedCompound : null,
                decoration: const InputDecoration(
                  labelText: 'Compound Development *',
                  prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                ),
                items: compounds.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(c.title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedCompound = val;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: unitNumberController,
                enabled: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'Unit Number (e.g. U-101) *',
                  prefixIcon: Icon(Icons.home_outlined, size: 20),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: buildingIdController,
                decoration: const InputDecoration(
                  labelText: 'Building Code / Name *',
                  prefixIcon: Icon(Icons.domain_outlined, size: 20),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: floorTierController,
                decoration: const InputDecoration(
                  labelText: 'Floor Tier *',
                  prefixIcon: Icon(Icons.layers_outlined, size: 20),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<UnitStatus>(
                isExpanded: true,
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Unit Status *',
                  prefixIcon: Icon(Icons.verified_outlined, size: 20),
                ),
                items: UnitStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.nameString, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedStatus = val;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: areaSqFtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Area (SqFt) *',
                  prefixIcon: Icon(Icons.square_foot_outlined, size: 20),
                ),
                validator: (val) => double.tryParse(val ?? '') == null ? 'Valid number required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: pricePerSqFtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price per SqFt (EGP) *',
                  prefixIcon: Icon(Icons.payments_outlined, size: 20),
                ),
                validator: (val) => double.tryParse(val ?? '') == null ? 'Valid number required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: assetClassController,
                decoration: const InputDecoration(
                  labelText: 'Asset Class *',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: furnishingController,
                decoration: const InputDecoration(
                  labelText: 'Furnishing Status',
                  prefixIcon: Icon(Icons.chair_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: parkingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Parking Spaces',
                  prefixIcon: Icon(Icons.local_parking_outlined, size: 20),
                ),
                validator: (val) => int.tryParse(val ?? '') == null ? 'Integer required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phaseController,
                decoration: const InputDecoration(
                  labelText: 'Construction Phase',
                  prefixIcon: Icon(Icons.engineering_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: orientationController,
                decoration: const InputDecoration(
                  labelText: 'Orientation',
                  prefixIcon: Icon(Icons.explore_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: blockController,
                decoration: const InputDecoration(
                  labelText: 'Block / Zone',
                  prefixIcon: Icon(Icons.grid_view_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: configurationController,
                decoration: const InputDecoration(
                  labelText: 'Unit Configuration / Layout *',
                  prefixIcon: Icon(Icons.architecture_outlined, size: 20),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      onSubmit: () async {
        if (!formKey.currentState!.validate()) throw Exception('Please fill all required fields');

        final area = double.parse(areaSqFtController.text);
        final pricePerSqFt = double.parse(pricePerSqFtController.text);
        final priceEGP = area * pricePerSqFt;
        final parking = int.parse(parkingController.text);

        final newUnit = Unit(
          unitNumber: unitNumberController.text.trim(),
          parentCompoundId: selectedCompound,
          buildingId: buildingIdController.text.trim(),
          floorTier: floorTierController.text.trim(),
          areaSqFt: area,
          pricePerSqFt: pricePerSqFt,
          priceEGP: priceEGP,
          isVacant: selectedStatus == UnitStatus.available,
          assetClass: assetClassController.text.trim(),
          furnishingStatus: furnishingController.text.trim(),
          parkingSpaces: parking,
          constructionPhase: phaseController.text.trim(),
          configuration: configurationController.text.trim(),
          orientation: orientationController.text.trim(),
          block: blockController.text.trim(),
          status: selectedStatus,
          paymentMilestones: unit?.paymentMilestones ?? [],
          areaSquareMeters: area / 10.764,
          gardenArea: unit?.gardenArea,
          currentOwnerId: unit?.currentOwnerId,
        );

        if (isEditing) {
          setState(() {
            final idx = _cachedUnits?.indexWhere((u) => u.unitNumber == newUnit.unitNumber) ?? -1;
            if (idx != -1) {
              _cachedUnits?[idx] = newUnit;
            }
          });
          await _unitRepository.updateUnit(newUnit);
        } else {
          setState(() {
            _cachedUnits?.insert(0, newUnit);
          });
          await _unitRepository.createUnit(newUnit);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unit "${newUnit.unitNumber}" saved successfully to SSOT.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _confirmDeleteUnit(BuildContext context, Unit unit) {
    AdminConfirmDialog.show(
      context: context,
      title: 'Delete Unit Record',
      message: 'Are you sure you want to permanently delete unit "${unit.unitNumber}" from the inventory master catalog?',
      detailText: 'Unit: ${unit.unitNumber} • Compound: ${unit.compoundId} • Valuation: EGP ${unit.priceEGP.toStringAsFixed(2)}',
      confirmLabel: 'Delete Unit',
      isDanger: true,
      onConfirm: () async {
        setState(() {
          _cachedUnits?.removeWhere((u) => u.unitNumber == unit.unitNumber);
        });
        await _unitRepository.deleteUnit(unit.unitNumber);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unit "${unit.unitNumber}" deleted from Firestore.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }
}
