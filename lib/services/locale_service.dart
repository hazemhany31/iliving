import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleService {
  LocaleService._privateConstructor();
  static final LocaleService instance = LocaleService._privateConstructor();

  static const String _storageKey = 'app_locale';
  final _storage = const FlutterSecureStorage();

  final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(const Locale('en'));

  Locale get locale => localeNotifier.value;
  bool get isArabic => localeNotifier.value.languageCode == 'ar';

  Future<void> initialize() async {
    try {
      final savedCode = await _storage.read(key: _storageKey);
      if (savedCode != null && (savedCode == 'ar' || savedCode == 'en')) {
        localeNotifier.value = Locale(savedCode);
      }
    } catch (e) {
      debugPrint('[LocaleService] Failed to read saved locale: $e');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (newLocale.languageCode != 'en' && newLocale.languageCode != 'ar') return;
    if (localeNotifier.value == newLocale) return;

    localeNotifier.value = newLocale;
    try {
      await _storage.write(key: _storageKey, value: newLocale.languageCode);
    } catch (e) {
      debugPrint('[LocaleService] Failed to write saved locale: $e');
    }
  }

  Future<void> toggleLocale() async {
    final nextLocale = isArabic ? const Locale('en') : const Locale('ar');
    await setLocale(nextLocale);
  }
}
