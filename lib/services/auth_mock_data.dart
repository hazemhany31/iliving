import '../models/auth_model.dart';

/// Separates the hardcoded user database from the authentication logical service layer.
class AuthMockData {
  /// The global fallback developer access password.
  static const String defaultMasterPassword = 'ihome2026';

  /// A pre-populated list of simulated Egyptian client records and unit mappings.
  static const List<Map<String, dynamic>> mockUsers = [
    {'name': 'أحمد عبد العظيم صدقي', 'phone': '01000197979', 'code': '147', 'unit': 'B01B202'},
    {'name': 'سامح إبراهيم يوسف رمضان', 'phone': '01000995004', 'code': '180', 'unit': 'A103B202'},
    {'name': 'ياسمين عبد الوهاب محمود', 'phone': '31642789908', 'code': '183', 'unit': 'B101B202'},
    {'name': 'عبد الله إبراهيم إبراهيم', 'phone': '01011101209', 'code': '98', 'unit': 'A01B202'},
    {'name': 'عوض الله رشيد أحمد', 'phone': '01156695555', 'code': '102', 'unit': 'B401B202'},
    {'name': 'خالد محمد محمد علي', 'phone': '01000364262', 'code': '116', 'unit': 'A301B202'},
    {'name': 'سامح عبد الصمد البنا', 'phone': '01098733072', 'code': '121', 'unit': 'B302B202'},
    {'name': 'أمير عبد الصمد البنا', 'phone': '01060294554', 'code': '122', 'unit': 'B202B202'},
    {'name': 'حنفي أحمد بدوي', 'phone': '01060290080', 'code': '123', 'unit': 'A203B202'},
    {'name': 'محمد شعبان محمد', 'phone': '01002710135', 'code': '127', 'unit': 'B201B202'},
    {'name': 'أحمد سيد علي', 'phone': '01285696491', 'code': '176', 'unit': 'B501B409'},
    {'name': 'إبراهيم احمد عبد الله', 'phone': '00966656943790', 'code': '144', 'unit': 'A301B404', 'units': ['A301B404', 'C303B404', 'C302B404']},
    {'name': 'أحمد شاذلي عبد الجواد', 'phone': '01127633326', 'code': '87', 'unit': 'A301B208'},
    {'name': 'أحمد سيد إبراهيم', 'phone': '010118999890', 'code': '185', 'unit': 'A01B203'},
    {'name': 'احمد حسين محمد', 'phone': '01003635780', 'code': '94', 'unit': 'A01B208'},
    {'name': 'احمد جلال عبد العزيز', 'phone': '01009090425', 'code': '130', 'unit': 'A01-207'},
    {'name': 'احمد بسيوني عطيه', 'phone': '01099990363', 'code': '152', 'unit': 'A103B208'},
    {'name': 'سمير غانم إبراهيم', 'phone': '01011572317', 'code': '134', 'unit': 'B104B203'},
    {'name': 'احمد عبد الخالق عوف', 'phone': '01012342359', 'code': '142', 'unit': 'C301B409'},
    {'name': 'اسامه ipad علي', 'phone': '01025666033', 'code': '200', 'unit': 'A502B310'},
    {'name': 'السيد عبد الله عبد الحميد', 'phone': '01010791172', 'code': '146', 'unit': 'C203B404', 'units': ['C203B404', 'C202B404']},
    {'name': 'امير فضل المولى', 'phone': '00966500593093', 'code': '182', 'unit': 'A101B409'},
    {'name': 'بسيوني إبراهيم بسيوني أبو الغيط', 'phone': '01026673378', 'code': '91', 'unit': 'B102B409'},
    {'name': 'مصطفى محمد حسام الدين', 'phone': '01152526666', 'code': '198', 'unit': 'C201B409'},
    {'name': 'حسن محمد حسن', 'phone': '01000055047', 'code': '111', 'unit': 'B403B208'},
    {'name': 'محمد علي زيدان', 'phone': '00966597115149', 'code': '155', 'unit': 'A201B409'},
    {'name': 'محمد احمد شهاب', 'phone': '01005471111', 'code': '203', 'unit': 'B302B208'},
    {'name': 'محمد احمد عبدالله', 'phone': '01060815450', 'code': '145', 'unit': 'A201B404'},
    {'name': 'محمد احمد محمد مكي', 'phone': '01026443490', 'code': '137', 'unit': 'C303B409'},
    {'name': 'محمد سعيد عبد العليم', 'phone': '01060815450', 'code': '165', 'unit': 'A01B409'},
    {'name': 'محمد محسن محمد', 'phone': '01012400812', 'code': '187', 'unit': 'C103B409'},
    {'name': 'محمد موسى علي عطيه', 'phone': '01224899336', 'code': '114', 'unit': 'B303B208'},
    {'name': 'محمود غانم إبراهيم', 'phone': '032465795140', 'code': '89', 'unit': 'B101B409'},
    {'name': 'مروة حسن محمد', 'phone': '01027773311', 'code': '125', 'unit': 'B402B409'},
    {'name': 'marrow علي محمد', 'phone': '01008102068', 'code': '90', 'unit': 'C102B409'},
    {'name': 'دولت محمد السيد', 'phone': '01144456446', 'code': '105', 'unit': 'B02B409'},
    {'name': 'رمضان صلاح رمضان', 'phone': '01092150776', 'code': '205', 'unit': 'B01B409'},
    {'name': 'طلعت محمد عادل', 'phone': '01288133533', 'code': '173', 'unit': 'C401B409'},
    {'name': 'احمد اشرف عبيد', 'phone': '01010101140', 'code': '139', 'unit': 'B01-207'},
    {'name': 'سحر محمود إبراهيم', 'phone': '01009730394', 'code': '179', 'unit': 'A401B409', 'units': ['A401B409', 'B401B208']},
    {'name': 'محاسن محمد حسن', 'phone': '01005788266', 'code': '95', 'unit': 'C203B409', 'units': ['C203B409', 'C202B409']},
  ];

  /// Checks if the cleaned input phone matches any registered user profiles.
  static Map<String, dynamic>? findProfile(String cleanInput) {
    if (cleanInput.isEmpty) return null;
    for (final u in mockUsers) {
      final cleanPhone = (u['phone'] as String).replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanInput.endsWith(cleanPhone) || cleanPhone.endsWith(cleanInput)) {
        return u;
      }
    }
    return null;
  }
}
