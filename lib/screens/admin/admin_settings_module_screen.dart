import 'package:flutter/material.dart';
import '../../models/admin_settings.dart';
import '../../repositories/firestore/firestore_admin_settings_repository.dart';
import '../../repositories/interfaces/admin_settings_repository.dart';
import '../../services/installment_reminder_service.dart';
import '../../theme/luxury_theme.dart';
import '../../l10n/app_localizations.dart';

class AdminSettingsModuleScreen extends StatefulWidget {
  const AdminSettingsModuleScreen({super.key});

  @override
  State<AdminSettingsModuleScreen> createState() => _AdminSettingsModuleScreenState();
}

class _AdminSettingsModuleScreenState extends State<AdminSettingsModuleScreen> {
  final AdminSettingsRepository _repository = FirestoreAdminSettingsRepository();
  final InstallmentReminderService _reminderService = InstallmentReminderService();
  final TextEditingController _daysController = TextEditingController();

  InstallmentReminderSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEngineRunning = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _repository.getInstallmentReminderSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;
    setState(() => _isSaving = true);
    await _repository.saveInstallmentReminderSettings(_settings!);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Installment reminder settings saved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _addReminderDay(int day) {
    if (_settings == null || day <= 0) return;
    if (_settings!.reminderDays.contains(day)) return;

    final updatedDays = List<int>.from(_settings!.reminderDays)..add(day);
    updatedDays.sort((a, b) => b.compareTo(a));

    setState(() {
      _settings = _settings!.copyWith(reminderDays: updatedDays);
    });
  }

  void _removeReminderDay(int day) {
    if (_settings == null) return;
    final updatedDays = List<int>.from(_settings!.reminderDays)..remove(day);
    setState(() {
      _settings = _settings!.copyWith(reminderDays: updatedDays);
    });
  }

  Future<void> _triggerReminderEngine() async {
    setState(() => _isEngineRunning = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
        content: const Row(
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Running Installment Reminder Engine...',
                style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    int dispatchedCount = 0;
    try {
      dispatchedCount = await _reminderService
          .checkAndDispatchReminders()
          .timeout(const Duration(seconds: 5), onTimeout: () => 0);
    } catch (e) {
      debugPrint('[AdminSettings] Error triggering reminder engine: $e');
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isEngineRunning = false);
      }
    }

    if (!mounted) return;
    await _loadSettings();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.medium,
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppColors.accent),
              SizedBox(width: 10),
              Text(
                'Reminder Engine Execution',
                style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Successfully scanned installments against configured settings.\n\nDispatched $dispatchedCount push notification(s) to targeted customers.',
            style: const TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
              ),
              child: const Text('OK', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final Color textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final Color textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    if (_isLoading || _settings == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    final reminderDays = _settings!.reminderDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SYSTEM & REMINDER SETTINGS',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Configure push notification reminder intervals & installment policies',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                label: Text(
                  _isSaving ? 'Saving...' : l10n.save.toUpperCase(),
                  style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Card: Installment Reminder Configuration
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppBorderRadius.medium,
              boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.accent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Installment Reminder Settings',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'إعدادات تنبيهات استحقاق الأقساط والمواعيد المسبقة',
                            style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    // Toggle Switch
                    Row(
                      children: [
                        Text(
                          _settings!.autoRemindersEnabled ? 'Enabled' : 'Disabled',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: _settings!.autoRemindersEnabled ? AppColors.success : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _settings!.autoRemindersEnabled,
                          activeThumbColor: AppColors.accent,
                          onChanged: (val) {
                            setState(() {
                              _settings = _settings!.copyWith(autoRemindersEnabled: val);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(height: 32, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

                // Reminder Days Configurator
                Text(
                  'Reminder Days Before Due Date',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set how many days before an installment due date to trigger an automatic push notification.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // Active Days Chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...reminderDays.map((day) {
                      return Chip(
                        backgroundColor: AppColors.accent.withAlpha(25),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                        avatar: const Icon(Icons.alarm_rounded, color: AppColors.accent, size: 16),
                        label: Text(
                          '$day Days Before (${day == 1 ? '1 يوم' : '$day أيام'})',
                          style: const TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                        onDeleted: () => _removeReminderDay(day),
                      );
                    }),
                    if (reminderDays.isEmpty)
                      const Text(
                        'No reminder days configured. Click below to add days.',
                        style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.error, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick Add Presets
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Quick Add Presets: ',
                      style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 12),
                    ),
                    ...[14, 7, 3, 1].map((preset) {
                      final isAdded = reminderDays.contains(preset);
                      return ActionChip(
                        backgroundColor: isAdded ? (isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt) : AppColors.accent.withAlpha(20),
                        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                        side: BorderSide.none,
                        label: Text(
                          '+ $preset Days',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: isAdded ? textMuted : AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: isAdded ? null : () => _addReminderDay(preset),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Custom Input Add
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 170,
                      child: TextField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textColor, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Enter days (e.g. 30)',
                          hintStyle: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                          isDense: true,
                          filled: true,
                          fillColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                          border: OutlineInputBorder(borderRadius: AppBorderRadius.pill, borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        final val = int.tryParse(_daysController.text.trim());
                        if (val != null && val > 0) {
                          _addReminderDay(val);
                          _daysController.clear();
                        }
                      },
                      icon: const Icon(Icons.add, color: AppColors.accent, size: 16),
                      label: const Text('Add Reminder Day', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: AppColors.accent, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent),
                        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Manual Engine Action Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppBorderRadius.medium,
              boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, color: AppColors.accent, size: 32),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Run Reminder Engine Now',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _settings!.lastRunTimestamp != null
                              ? 'Last executed: ${_settings!.lastRunTimestamp!.toLocal().toIso8601String().replaceAll('T', ' ').split('.').first}'
                              : 'Engine has not been executed manually yet.',
                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isEngineRunning ? null : _triggerReminderEngine,
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text(
                    'Execute Now',
                    style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
