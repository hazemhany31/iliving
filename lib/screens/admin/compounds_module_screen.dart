import 'package:flutter/material.dart';
import '../../models/compound_model.dart';
import '../../repositories/firestore/firestore_compound_repository.dart';
import '../../theme/luxury_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/admin/shared/admin_data_table.dart';
import '../../widgets/admin/shared/admin_form_dialog.dart';
import '../../widgets/admin/shared/admin_confirm_dialog.dart';

class CompoundsModuleScreen extends StatefulWidget {
  const CompoundsModuleScreen({super.key});

  @override
  State<CompoundsModuleScreen> createState() => _CompoundsModuleScreenState();
}

class _CompoundsModuleScreenState extends State<CompoundsModuleScreen> {
  final FirestoreCompoundRepository _repository = FirestoreCompoundRepository();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
      stream: _repository.streamAllCompounds(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final compounds = snapshot.data ?? [];
        final filteredCompounds = compounds.where((c) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return c.title.toLowerCase().contains(q) ||
              c.location.toLowerCase().contains(q) ||
              c.id.toLowerCase().contains(q);
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
                          l10n.compoundsModule.toUpperCase(),
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
                          '${l10n.compoundsModule} (${compounds.length} total compounds)',
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
                      icon: const Icon(Icons.holiday_village_outlined, size: 18),
                      label: Text(
                        l10n.addCompound,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () => _showCompoundFormDialog(context),
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
                          hintText: 'Filter compounds...',
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
                child: AdminDataTable<CompoundModel>(
                  isLoading: isLoading,
                  items: filteredCompounds,
                  emptyTitle: 'No Compounds Found',
                  emptyMessage: _searchQuery.isEmpty
                      ? 'No compound records exist in Firestore. Click "+ Create Compound" to add one.'
                      : 'No compounds match your filter query "$_searchQuery".',
                  columns: [
                    AdminTableColumn<CompoundModel>(
                      title: 'Compound ID',
                      cellBuilder: (c) => Text(
                        c.id,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    AdminTableColumn<CompoundModel>(
                      title: 'Title & Location',
                      cellBuilder: (c) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.title,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            c.location,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AdminTableColumn<CompoundModel>(
                      title: 'Base Price (EGP)',
                      cellBuilder: (c) => Text(
                        'EGP ${c.basePriceEGP.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AdminTableColumn<CompoundModel>(
                      title: 'Area / Completion',
                      cellBuilder: (c) => Text(
                        '${c.areaSqFt.toStringAsFixed(0)} sqft • ${c.completionPercentage.toStringAsFixed(0)}% Done',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    AdminTableColumn<CompoundModel>(
                      title: 'Actions',
                      cellBuilder: (c) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 18),
                            tooltip: 'Edit Compound',
                            onPressed: () => _showCompoundFormDialog(context, compound: c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                            tooltip: 'Delete Compound',
                            onPressed: () => _confirmDeleteCompound(context, c),
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

  void _showCompoundFormDialog(BuildContext context, {CompoundModel? compound}) {
    final isEditing = compound != null;
    final idController = TextEditingController(text: compound?.id ?? 'CMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final titleController = TextEditingController(text: compound?.title ?? '');
    final locationController = TextEditingController(text: compound?.location ?? 'New Cairo, Egypt');
    final categoryController = TextEditingController(text: compound?.category ?? 'Luxury Villa & Apartment Masterplan');
    final priceController = TextEditingController(text: compound != null ? compound.basePriceEGP.toStringAsFixed(0) : '4500000');
    final areaController = TextEditingController(text: compound != null ? compound.areaSqFt.toStringAsFixed(0) : '2200');
    final completionController = TextEditingController(text: compound != null ? compound.completionPercentage.toStringAsFixed(0) : '85');
    final descController = TextEditingController(text: compound?.description ?? '');

    AdminFormDialog.show(
      context: context,
      title: isEditing ? 'Edit Compound' : 'Create New Compound',
      subtitle: isEditing ? 'Update compound configuration in Firestore' : 'Add new compound to Master SSOT',
      icon: isEditing ? Icons.edit_location_alt : Icons.add_location_alt,
      body: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEditing)
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Compound ID (Doc ID)', hintText: 'e.g. COMPOUND-001'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Compound Title', hintText: 'e.g. Al Yasmine Heights'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Base Price (EGP)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: areaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Area (Sq Ft)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: completionController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Completion %'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
      onSubmit: () async {
        if (titleController.text.trim().isEmpty) {
          throw Exception('Compound title is required');
        }
        final c = CompoundModel(
          id: idController.text.trim(),
          title: titleController.text.trim(),
          location: locationController.text.trim(),
          category: categoryController.text.trim(),
          description: descController.text.trim(),
          basePriceEGP: double.tryParse(priceController.text) ?? 4500000.0,
          areaSqFt: double.tryParse(areaController.text) ?? 2200.0,
          completionPercentage: double.tryParse(completionController.text) ?? 85.0,
          heroImageUrl: compound?.heroImageUrl ?? 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
          cardImageUrl: compound?.cardImageUrl ?? 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
          primaryView: compound?.primaryView ?? 'Main Garden View',
        );

        if (isEditing) {
          await _repository.updateCompound(c);
        } else {
          await _repository.createCompound(c);
        }
      },
    );
  }

  void _confirmDeleteCompound(BuildContext context, CompoundModel c) {
    AdminConfirmDialog.show(
      context: context,
      title: 'Delete Compound',
      message: 'Are you sure you want to delete compound "${c.title}" (${c.id})? This action cannot be undone.',
      confirmLabel: 'Delete Record',
      isDanger: true,
      onConfirm: () async {
        await _repository.deleteCompound(c.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Compound "${c.title}" deleted successfully.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }
}
