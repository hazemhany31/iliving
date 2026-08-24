import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_settings.dart';
import '../interfaces/admin_settings_repository.dart';

class FirestoreAdminSettingsRepository implements AdminSettingsRepository {
  final FirebaseFirestore _firestore;
  static InstallmentReminderSettings _fallbackSettings = InstallmentReminderSettings.defaultSettings();

  FirestoreAdminSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _firestore.collection('settings').doc('installment_reminder');

  @override
  Future<InstallmentReminderSettings> getInstallmentReminderSettings() async {
    try {
      final doc = await _settingsDoc.get().timeout(const Duration(seconds: 4));
      final data = doc.data();
      if (doc.exists && data != null) {
        final settings = InstallmentReminderSettings.fromJson(data);
        _fallbackSettings = settings;
        return settings;
      }
    } catch (_) {}
    return _fallbackSettings;
  }

  @override
  Stream<InstallmentReminderSettings> streamInstallmentReminderSettings() {
    final controller = StreamController<InstallmentReminderSettings>();
    try {
      _settingsDoc.snapshots().listen((snap) {
        final data = snap.data();
        if (snap.exists && data != null) {
          final settings = InstallmentReminderSettings.fromJson(data);
          _fallbackSettings = settings;
          controller.add(settings);
        } else {
          controller.add(_fallbackSettings);
        }
      }, onError: (_) {
        controller.add(_fallbackSettings);
      });
    } catch (_) {
      controller.add(_fallbackSettings);
    }
    return controller.stream;
  }

  @override
  Future<void> saveInstallmentReminderSettings(InstallmentReminderSettings settings) async {
    _fallbackSettings = settings;
    try {
      await _settingsDoc
          .set(settings.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}
