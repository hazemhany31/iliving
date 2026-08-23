import '../../models/admin_settings.dart';

abstract class AdminSettingsRepository {
  Future<InstallmentReminderSettings> getInstallmentReminderSettings();
  Stream<InstallmentReminderSettings> streamInstallmentReminderSettings();
  Future<void> saveInstallmentReminderSettings(InstallmentReminderSettings settings);
}
