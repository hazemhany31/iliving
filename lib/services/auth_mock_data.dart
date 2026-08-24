import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthMockData {
  static const String defaultMasterPassword = 'iliving2026';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _dynamicUsersKey = 'persisted_dynamic_mock_users';
  static bool _hasLoadedStorage = false;

  static const List<Map<String, dynamic>> mockUsers = [
    {'name': 'أحمد شاذلي عبد الجواد', 'phone': '01127633326', 'code': '87', 'unit': 'A301B208', 'email': 'ahmed.shazly.abdelgawad@new-build-egypt.com'},
    {'name': 'محمود غانم إبراهيم', 'phone': '032465795140', 'code': '89', 'unit': 'B101B409', 'email': 'mahmoud.ghanem.ibrahim@new-build-egypt.com'},
    {'name': 'marrow علي محمد', 'phone': '01008102068', 'code': '90', 'unit': 'C102B409', 'email': 'marrow.ali.mohamed@new-build-egypt.com'},
    {'name': 'بسيوني إبراهيم بسيوني أبو الغيط', 'phone': '01026673378', 'code': '91', 'unit': 'B102B409', 'email': 'basyouni.ibrahim.basyouni@new-build-egypt.com'},
    {'name': 'Fictional Client 93', 'phone': '01000000093', 'code': '93', 'unit': 'B203', 'email': 'fictional.client.93@new-build-egypt.com'},
    {'name': 'احمد حسين محمد', 'phone': '01003635780', 'code': '94', 'unit': 'A01B208', 'email': 'ahmed.hussein.mohamed@new-build-egypt.com'},
    {'name': 'محاسن محمد حسن', 'phone': '01005788266', 'code': '95', 'unit': 'C203B409', 'email': 'mhasn.mohamed.hasan@new-build-egypt.com', 'units': ['C203B409', 'C202B409']},
    {'name': 'عبد الله إبراهيم إبراهيم', 'phone': '01011101209', 'code': '98', 'unit': 'A01B202', 'email': 'abdallah.ibrahim.ibrahim@new-build-egypt.com'},
    {'name': 'Fictional Client 100', 'phone': '01000000100', 'code': '100', 'unit': 'B404', 'email': 'fictional.client.100@new-build-egypt.com'},
    {'name': 'عوض الله رشيد أحمد', 'phone': '01156695555', 'code': '102', 'unit': 'B401B202', 'email': 'awadallah.rashid.ahmed@new-build-egypt.com'},
    {'name': 'دولت محمد السيد', 'phone': '01144456446', 'code': '105', 'unit': 'B02B409', 'email': 'dowlat.mohamed.elsayed@new-build-egypt.com'},
    {'name': 'Fictional Client 107', 'phone': '01000000107', 'code': '107', 'unit': 'B203', 'email': 'fictional.client.107@new-build-egypt.com'},
    {'name': 'Fictional Client 109', 'phone': '01000000109', 'code': '109', 'unit': 'B203', 'email': 'fictional.client.109@new-build-egypt.com'},
    {'name': 'حسن محمد حسن', 'phone': '01000055047', 'code': '111', 'unit': 'B403B208', 'email': 'hasan.mohamed.hasan@new-build-egypt.com'},
    {'name': 'Fictional Client 113', 'phone': '01000000113', 'code': '113', 'unit': 'B208', 'email': 'fictional.client.113@new-build-egypt.com'},
    {'name': 'محمد موسى علي عطيه', 'phone': '01224899336', 'code': '114', 'unit': 'B303B208', 'email': 'mohamed.mousa.ali@new-build-egypt.com'},
    {'name': 'خالد محمد محمد علي', 'phone': '01000364262', 'code': '116', 'unit': 'A301B202', 'email': 'khaled.mohamed.mohamed@new-build-egypt.com'},
    {'name': 'سامح عبد الصمد البنا', 'phone': '01098733072', 'code': '121', 'unit': 'B302B202', 'email': 'sameh.abd.alsmd@new-build-egypt.com'},
    {'name': 'أمير عبد الصمد البنا', 'phone': '01060294554', 'code': '122', 'unit': 'B202B202', 'email': 'amir.abd.alsmd@new-build-egypt.com'},
    {'name': 'حنفي أحمد بدوي', 'phone': '01060290080', 'code': '123', 'unit': 'A203B202', 'email': 'hanafy.ahmed.badawy@new-build-egypt.com'},
    {'name': 'Fictional Client 124', 'phone': '01000000124', 'code': '124', 'unit': 'B409', 'email': 'fictional.client.124@new-build-egypt.com'},
    {'name': 'مروة حسن محمد', 'phone': '01027773311', 'code': '125', 'unit': 'B402B409', 'email': 'marwa.hasan.mohamed@new-build-egypt.com'},
    {'name': 'محمد شعبان محمد', 'phone': '01002710135', 'code': '127', 'unit': 'B201B202', 'email': 'mohamed.shaban.mohamed@new-build-egypt.com'},
    {'name': 'احمد جلال عبد العزيز', 'phone': '01009090425', 'code': '130', 'unit': 'A01-207', 'email': 'ahmed.jalal.abd@new-build-egypt.com'},
    {'name': 'سمير غانم إبراهيم', 'phone': '01011572317', 'code': '134', 'unit': 'B104B203', 'email': 'samir.ghanem.ibrahim@new-build-egypt.com'},
    {'name': 'محمد احمد محمد مكي', 'phone': '01026443490', 'code': '137', 'unit': 'C303B409', 'email': 'mohamed.ahmed.mohamed@new-build-egypt.com'},
    {'name': 'احمد اشرف عبيد', 'phone': '01010101140', 'code': '139', 'unit': 'B01-207', 'email': 'ahmed.ashraf.obeid@new-build-egypt.com'},
    {'name': 'احمد عبد الخالق عوف', 'phone': '01012342359', 'code': '142', 'unit': 'C301B409', 'email': 'ahmed.abdelkhalek.ouf@new-build-egypt.com'},
    {'name': 'إبراهيم احمد عبد الله', 'phone': '00966656943790', 'code': '144', 'unit': 'A301B404', 'email': 'ibrahim.ahmed.abdallah@new-build-egypt.com', 'units': ['A301B404', 'C303B404', 'C302B404']},
    {'name': 'محمد احمد عبدالله', 'phone': '01060815450', 'code': '145', 'unit': 'A201B404', 'email': 'mohamed.ahmed.abdallh@new-build-egypt.com'},
    {'name': 'السيد عبد الله عبد الحميد', 'phone': '01010791172', 'code': '146', 'unit': 'C203B404', 'email': 'elsayed.abdallah.abdelhamid@new-build-egypt.com', 'units': ['C203B404', 'C202B404']},
    {'name': 'أحمد عبد العظيم صدقي', 'phone': '01000197979', 'code': '147', 'unit': 'B01B202', 'email': 'ahmed.abd.alazym@new-build-egypt.com'},
    {'name': 'Fictional Client 150', 'phone': '01000000150', 'code': '150', 'unit': 'B409', 'email': 'fictional.client.150@new-build-egypt.com'},
    {'name': 'Fictional Client 151', 'phone': '01000000151', 'code': '151', 'unit': 'B409', 'email': 'fictional.client.151@new-build-egypt.com'},
    {'name': 'احمد بسيوني عطيه', 'phone': '01099990363', 'code': '152', 'unit': 'A103B208', 'email': 'ahmed.basyouni.atiya@new-build-egypt.com'},
    {'name': 'Fictional Client 154', 'phone': '01000000154', 'code': '154', 'unit': 'B409', 'email': 'fictional.client.154@new-build-egypt.com'},
    {'name': 'محمد علي زيدان', 'phone': '00966597115149', 'code': '155', 'unit': 'A201B409', 'email': 'mohamed.ali.zydan@new-build-egypt.com', 'units': ['B409', 'B409', 'B409']},
    {'name': 'Fictional Client 161', 'phone': '01000000161', 'code': '161', 'unit': 'B203', 'email': 'fictional.client.161@new-build-egypt.com'},
    {'name': 'محمد سعيد عبد العليم', 'phone': '01060815450', 'code': '165', 'unit': 'A01B409', 'email': 'mohamed.said.abdelalim@new-build-egypt.com'},
    {'name': 'Fictional Client 167', 'phone': '01000000167', 'code': '167', 'unit': 'B409', 'email': 'fictional.client.167@new-build-egypt.com'},
    {'name': 'طلعت محمد عادل', 'phone': '01288133533', 'code': '173', 'unit': 'C401B409', 'email': 'talaat.mohamed.adel@new-build-egypt.com'},
    {'name': 'أحمد سيد علي', 'phone': '01285696491', 'code': '176', 'unit': 'B501B409', 'email': 'ahmed.sayed.ali@new-build-egypt.com'},
    {'name': 'سحر محمود إبراهيم', 'phone': '01009730394', 'code': '179', 'unit': 'A401B409', 'email': 'sahar.mahmoud.ibrahim@new-build-egypt.com', 'units': ['A401B409', 'B401B208']},
    {'name': 'سامح إبراهيم يوسف رمضان', 'phone': '01000995004', 'code': '180', 'unit': 'A103B202', 'email': 'sameh.ibrahim.ywsf@new-build-egypt.com'},
    {'name': 'امير فضل المولى', 'phone': '00966500593093', 'code': '182', 'unit': 'A101B409', 'email': 'amir.fadlelmawla@new-build-egypt.com'},
    {'name': 'ياسمين عبد الوهاب محمود', 'phone': '31642789908', 'code': '183', 'unit': 'B101B202', 'email': 'yasmin.abdelwahab.mahmoud@new-build-egypt.com'},
    {'name': 'أحمد سيد إبراهيم', 'phone': '010118999890', 'code': '185', 'unit': 'A01B203', 'email': 'ahmed.sayed.ibrahim@new-build-egypt.com'},
    {'name': 'محمد محسن محمد', 'phone': '01012400812', 'code': '187', 'unit': 'C103B409', 'email': 'mohamed.mohsen.mohamed@new-build-egypt.com'},
    {'name': 'Fictional Client 189', 'phone': '01000000189', 'code': '189', 'unit': 'B202', 'email': 'fictional.client.189@new-build-egypt.com'},
    {'name': 'Fictional Client 197', 'phone': '01000000197', 'code': '197', 'unit': 'B202', 'email': 'fictional.client.197@new-build-egypt.com'},
    {'name': 'مصطفى محمد حسام الدين', 'phone': '01152526666', 'code': '198', 'unit': 'C201B409', 'email': 'mostafa.mohamed.hsam@new-build-egypt.com'},
    {'name': 'اسامه ipad علي', 'phone': '01025666033', 'code': '200', 'unit': 'A502B310', 'email': 'osama.ipad.ali@new-build-egypt.com'},
    {'name': 'محمد احمد شهاب', 'phone': '01005471111', 'code': '203', 'unit': 'B302B208', 'email': 'mohamed.ahmed.shehab@new-build-egypt.com'},
    {'name': 'رمضان صلاح رمضان', 'phone': '01092150776', 'code': '205', 'unit': 'B01B409', 'email': 'ramadan.salah.ramadan@new-build-egypt.com'},
    {'name': 'Fictional Client 207', 'phone': '01000000207', 'code': '207', 'unit': 'B202', 'email': 'fictional.client.207@new-build-egypt.com'},
  ];

  /// Sanitizes email by stripping accidentally pasted passwords or fixing common prefixes.
  static String sanitizeEmail(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.isEmpty) return s;

    // Common typo fixes: min@ -> admin@
    if (s.startsWith('min@')) {
      s = 'ad$s';
    }

    // Only strip glued passwords if domain is followed by known password suffix (e.g. .comiliving2026 -> .com)
    final gluedMatch = RegExp(r'(\.(?:com|eg|net|org|io|me|app))(iliving\d*|ihome\d*|admin\d*|\d{4,})$', caseSensitive: false);
    if (gluedMatch.hasMatch(s)) {
      s = s.replaceFirstMapped(gluedMatch, (m) => m.group(1)!);
    }

    return s;
  }

  static final List<Map<String, dynamic>> _dynamicUsers = [];

  static Future<void> ensureLoaded() async {
    if (_hasLoadedStorage) return;
    _hasLoadedStorage = true;
    try {
      final jsonStr = await _storage.read(key: _dynamicUsersKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final email = (item['email'] as String? ?? '').toLowerCase();
            final code = (item['code'] as String? ?? '').toLowerCase();
            if (!_dynamicUsers.any((u) => (u['email'] as String? ?? '').toLowerCase() == email && (u['code'] as String? ?? '').toLowerCase() == code)) {
              _dynamicUsers.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> _persistDynamicUsers() async {
    try {
      final jsonStr = jsonEncode(_dynamicUsers);
      await _storage.write(key: _dynamicUsersKey, value: jsonStr);
    } catch (_) {}
  }

  static void registerDynamicUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String code,
    List<String>? units,
  }) {
    final clean = sanitizeEmail(email);
    final cleanCode = code.trim().toLowerCase();
    _dynamicUsers.removeWhere((u) {
      final uEmail = (u['email'] as String? ?? '').toLowerCase();
      final uCode = (u['code'] as String? ?? '').toLowerCase();
      return (clean.isNotEmpty && uEmail == clean) || (cleanCode.isNotEmpty && uCode == cleanCode);
    });
    _dynamicUsers.add({
      'name': name,
      'phone': phone,
      'code': code,
      'email': clean.isNotEmpty ? clean : '$cleanCode@iliving.com.eg',
      'password': password.trim(),
      'units': units ?? [],
    });
    _persistDynamicUsers();
  }

  static void removeDynamicUser(String emailOrCode) {
    final clean = sanitizeEmail(emailOrCode);
    final cleanCode = emailOrCode.trim().toLowerCase();
    _dynamicUsers.removeWhere((u) {
      final uEmail = (u['email'] as String? ?? '').toLowerCase();
      final uCode = (u['code'] as String? ?? '').toLowerCase();
      return (clean.isNotEmpty && uEmail == clean) || (cleanCode.isNotEmpty && uCode == cleanCode);
    });
    _persistDynamicUsers();
  }

  static Map<String, dynamic>? findProfile(String emailOrPhone) {
    final cleanInput = sanitizeEmail(emailOrPhone);
    if (cleanInput.isEmpty) return null;

    // 0. Match dynamically registered users first
    for (final u in _dynamicUsers) {
      if (u['email'] != null && (u['email'] as String).toLowerCase() == cleanInput) {
        return u;
      }
    }

    // 1. Match by exact email string
    for (final u in mockUsers) {
      if (u['email'] != null && (u['email'] as String).toLowerCase() == cleanInput) {
        return u;
      }
    }

    // 2. Match by email prefix or client code in email
    if (cleanInput.contains('@')) {
      final prefix = cleanInput.split('@')[0];
      for (final u in [..._dynamicUsers, ...mockUsers]) {
        if (u['email'] != null) {
          final mockEmail = (u['email'] as String).toLowerCase();
          final mockPrefix = mockEmail.split('@')[0];
          if (prefix == mockPrefix) {
            return u;
          }
        }
        final code = (u['code'] as String? ?? '').toLowerCase();
        if (code.isNotEmpty && (prefix == 'client$code' ||
            prefix == 'client_$code' ||
            prefix == 'client-$code' ||
            prefix == code)) {
          return u;
        }
      }

      // Check if digits in email prefix match a user code
      final pDigits = prefix.replaceAll(RegExp(r'[^0-9]'), '');
      if (pDigits.isNotEmpty) {
        for (final u in [..._dynamicUsers, ...mockUsers]) {
          if ((u['code'] as String? ?? '').toLowerCase() == pDigits) {
            return u;
          }
        }
      }
    }

    // 3. Match by client code or phone digits
    final digits = cleanInput.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      for (final u in [..._dynamicUsers, ...mockUsers]) {
        final code = (u['code'] as String? ?? '').toLowerCase();
        final cleanPhone = (u['phone'] as String? ?? '').replaceAll(RegExp(r'[^0-9]'), '');
        if ((code.isNotEmpty && digits == code) ||
            (cleanPhone.isNotEmpty && (digits.endsWith(cleanPhone) || cleanPhone.endsWith(digits)))) {
          return u;
        }
      }
    }

    return null;
  }

  /// Validates password for mock/demo accounts and client logins.
  static bool verifyPassword(String emailOrPhone, String password) {
    final cleanInput = sanitizeEmail(emailOrPhone);
    final cleanPass = password.trim();
    if (cleanInput.isEmpty || cleanPass.isEmpty) return false;
    final passLower = cleanPass.toLowerCase();

    // 1. Admin accounts
    if (cleanInput.startsWith('admin@') || cleanInput == 'admin' || cleanInput.contains('admin')) {
      return true;
    }

    // 2. Broker / Sterling accounts
    if (cleanInput.startsWith('sterling@') || cleanInput == 'sterling') {
      return true;
    }

    // 3. Demo accounts
    if (cleanInput.startsWith('demo@') || cleanInput == 'demo') {
      return true;
    }

    // 4. Look up client profile in dynamic & mock registry
    final mockData = findProfile(cleanInput);
    if (mockData != null) {
      // Universal master passwords for registered clients
      if (passLower == 'iliving2026' ||
          passLower == 'ihome2026' ||
          passLower == 'iliving2026!' ||
          passLower == 'ihome2026!' ||
          passLower == '123456') {
        return true;
      }

      // Explicit custom password if present in map
      if (mockData['password'] != null) {
        final storedPass = (mockData['password'] as String).trim();
        if (storedPass == cleanPass || storedPass.toLowerCase() == passLower) {
          return true;
        }
      }

      final code = (mockData['code'] as String? ?? '').toLowerCase();
      // Standard client pattern: iLiving<code>2026! / iLiving<code>2026 / <code>
      if (code.isNotEmpty) {
        if (passLower == 'ihome${code}2026!' ||
            passLower == 'ihome${code}2026' ||
            passLower == 'iliving${code}2026!' ||
            passLower == 'iliving${code}2026' ||
            cleanPass == code) {
          return true;
        }
      }

      // If code was custom or generated
      final passCodeMatch = RegExp(r'^(?:ihome|iliving)(\d+)2026!?$', caseSensitive: false).firstMatch(cleanPass);
      if (passCodeMatch != null) {
        return true;
      }
      return false;
    }

    return false;
  }
}
