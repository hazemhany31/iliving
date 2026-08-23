import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/services/auth_service.dart';
import 'package:iliving/models/auth_model.dart';

void main() {
  group('AuthService Mock Login Tests', () {
    setUp(() {
      // Ensure service is in unauthenticated state before each test
      AuthService.instance.logout();
    });

    test('Login succeeds with name-based email (ahmed.shazly.abdelgawad@new-build-egypt.com) and master password', () async {
      final success = await AuthService.instance.login(
        'ahmed.shazly.abdelgawad@new-build-egypt.com',
        'iliving2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentState, AuthState.authenticated);
      expect(AuthService.instance.currentProfile?.clientId, 'client_87');
      expect(AuthService.instance.currentProfile?.displayName, 'أحمد شاذلي عبد الجواد');
    });

    test('Login succeeds with name-based email and unique password (iLiving872026!)', () async {
      final success = await AuthService.instance.login(
        'ahmed.shazly.abdelgawad@new-build-egypt.com',
        'iLiving872026!',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentState, AuthState.authenticated);
      expect(AuthService.instance.currentProfile?.clientId, 'client_87');
    });

    test('Login succeeds with phone email (01127633326@iliving.com) and master password', () async {
      final success = await AuthService.instance.login(
        '01127633326@iliving.com',
        'iliving2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentState, AuthState.authenticated);
      expect(AuthService.instance.currentProfile?.clientId, 'client_87');
    });

    test('Login succeeds with name-based email and code as password', () async {
      final success = await AuthService.instance.login(
        'mahmoud.ghanem.ibrahim@new-build-egypt.com',
        '89',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentState, AuthState.authenticated);
      expect(AuthService.instance.currentProfile?.clientId, 'client_89');
      expect(AuthService.instance.currentProfile?.displayName, 'محمود غانم إبراهيم');
    });

    test('Login fails with invalid email', () async {
      final success = await AuthService.instance.login(
        'nonexistent@new-build-egypt.com',
        'iliving2026',
      );
      expect(success, isFalse);
      expect(AuthService.instance.currentState, AuthState.unauthenticated);
    });

    test('Login fails with correct email but wrong password', () async {
      final success = await AuthService.instance.login(
        'ahmed.shazly.abdelgawad@new-build-egypt.com',
        'wrongpassword',
      );
      expect(success, isFalse);
      expect(AuthService.instance.currentState, AuthState.unauthenticated);
    });

    test('Login succeeds with name-based email under different domains and alternate password formats', () async {
      // client 87 under iHome domain with iHome password
      var success = await AuthService.instance.login(
        'ahmed.shazly.abdelgawad@ihome.com.eg',
        'IHome872026!',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_87');
      await AuthService.instance.logout();

      // client 87 under iLiving domain with generic ihome master password
      success = await AuthService.instance.login(
        'ahmed.shazly.abdelgawad@iliving.com.eg',
        'ihome2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_87');
      await AuthService.instance.logout();
    });

    test('Login succeeds with Demo credentials (both ihome and iliving domains)', () async {
      // demo@ihome.com.eg with ihome2026
      var success = await AuthService.instance.login(
        'demo@ihome.com.eg',
        'ihome2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_demo');
      expect(AuthService.instance.currentProfile?.displayName, 'أحمد عبد العظيم صدقي');
      await AuthService.instance.logout();

      // demo@iliving.com.eg with iliving2026
      success = await AuthService.instance.login(
        'demo@iliving.com.eg',
        'iliving2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_demo');
      await AuthService.instance.logout();
    });

    test('Login succeeds with Broker/Sterling credentials', () async {
      // sterling@ihome.com.eg with sterling2026
      var success = await AuthService.instance.login(
        'sterling@ihome.com.eg',
        'sterling2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_broker');
      expect(AuthService.instance.currentProfile?.displayName, 'Alistair Sterling');
      await AuthService.instance.logout();

      // sterling@iliving.com.eg with ihome2026
      success = await AuthService.instance.login(
        'sterling@iliving.com.eg',
        'ihome2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_broker');
      await AuthService.instance.logout();
    });

    test('Login succeeds with Admin credentials', () async {
      // admin@new-build-egypt.com with admin2026
      var success = await AuthService.instance.login(
        'admin@new-build-egypt.com',
        'admin2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_admin');
      expect(AuthService.instance.currentProfile?.displayName, 'iLiving Administrator');
      await AuthService.instance.logout();

      // admin@iliving.com.eg with iliving2026
      success = await AuthService.instance.login(
        'admin@iliving.com.eg',
        'iliving2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_admin');
      await AuthService.instance.logout();
    });

    test('All 55 client credentials specified by user log in successfully with their dedicated IHome{code}2026! password', () async {
      final clientCredentials = [
        {'email': 'ahmed.shazly.abdelgawad@new-build-egypt.com', 'password': 'IHome872026!', 'code': '87'},
        {'email': 'mahmoud.ghanem.ibrahim@new-build-egypt.com', 'password': 'IHome892026!', 'code': '89'},
        {'email': 'marrow.ali.mohamed@new-build-egypt.com', 'password': 'IHome902026!', 'code': '90'},
        {'email': 'basyouni.ibrahim.basyouni@new-build-egypt.com', 'password': 'IHome912026!', 'code': '91'},
        {'email': 'fictional.client.93@new-build-egypt.com', 'password': 'IHome932026!', 'code': '93'},
        {'email': 'ahmed.hussein.mohamed@new-build-egypt.com', 'password': 'IHome942026!', 'code': '94'},
        {'email': 'mhasn.mohamed.hasan@new-build-egypt.com', 'password': 'IHome952026!', 'code': '95'},
        {'email': 'abdallah.ibrahim.ibrahim@new-build-egypt.com', 'password': 'IHome982026!', 'code': '98'},
        {'email': 'fictional.client.100@new-build-egypt.com', 'password': 'IHome1002026!', 'code': '100'},
        {'email': 'awadallah.rashid.ahmed@new-build-egypt.com', 'password': 'IHome1022026!', 'code': '102'},
        {'email': 'dowlat.mohamed.elsayed@new-build-egypt.com', 'password': 'IHome1052026!', 'code': '105'},
        {'email': 'fictional.client.107@new-build-egypt.com', 'password': 'IHome1072026!', 'code': '107'},
        {'email': 'fictional.client.109@new-build-egypt.com', 'password': 'IHome1092026!', 'code': '109'},
        {'email': 'hasan.mohamed.hasan@new-build-egypt.com', 'password': 'IHome1112026!', 'code': '111'},
        {'email': 'fictional.client.113@new-build-egypt.com', 'password': 'IHome1132026!', 'code': '113'},
        {'email': 'mohamed.mousa.ali@new-build-egypt.com', 'password': 'IHome1142026!', 'code': '114'},
        {'email': 'khaled.mohamed.mohamed@new-build-egypt.com', 'password': 'IHome1162026!', 'code': '116'},
        {'email': 'sameh.abd.alsmd@new-build-egypt.com', 'password': 'IHome1212026!', 'code': '121'},
        {'email': 'amir.abd.alsmd@new-build-egypt.com', 'password': 'IHome1222026!', 'code': '122'},
        {'email': 'hanafy.ahmed.badawy@new-build-egypt.com', 'password': 'IHome1232026!', 'code': '123'},
        {'email': 'fictional.client.124@new-build-egypt.com', 'password': 'IHome1242026!', 'code': '124'},
        {'email': 'marwa.hasan.mohamed@new-build-egypt.com', 'password': 'IHome1252026!', 'code': '125'},
        {'email': 'mohamed.shaban.mohamed@new-build-egypt.com', 'password': 'IHome1272026!', 'code': '127'},
        {'email': 'ahmed.jalal.abd@new-build-egypt.com', 'password': 'IHome1302026!', 'code': '130'},
        {'email': 'samir.ghanem.ibrahim@new-build-egypt.com', 'password': 'IHome1342026!', 'code': '134'},
        {'email': 'mohamed.ahmed.mohamed@new-build-egypt.com', 'password': 'IHome1372026!', 'code': '137'},
        {'email': 'ahmed.ashraf.obeid@new-build-egypt.com', 'password': 'IHome1392026!', 'code': '139'},
        {'email': 'ahmed.abdelkhalek.ouf@new-build-egypt.com', 'password': 'IHome1422026!', 'code': '142'},
        {'email': 'ibrahim.ahmed.abdallah@new-build-egypt.com', 'password': 'IHome1442026!', 'code': '144'},
        {'email': 'mohamed.ahmed.abdallh@new-build-egypt.com', 'password': 'IHome1452026!', 'code': '145'},
        {'email': 'elsayed.abdallah.abdelhamid@new-build-egypt.com', 'password': 'IHome1462026!', 'code': '146'},
        {'email': 'ahmed.abd.alazym@new-build-egypt.com', 'password': 'IHome1472026!', 'code': '147'},
        {'email': 'fictional.client.150@new-build-egypt.com', 'password': 'IHome1502026!', 'code': '150'},
        {'email': 'fictional.client.151@new-build-egypt.com', 'password': 'IHome1512026!', 'code': '151'},
        {'email': 'ahmed.basyouni.atiya@new-build-egypt.com', 'password': 'IHome1522026!', 'code': '152'},
        {'email': 'fictional.client.154@new-build-egypt.com', 'password': 'IHome1542026!', 'code': '154'},
        {'email': 'mohamed.ali.zydan@new-build-egypt.com', 'password': 'IHome1552026!', 'code': '155'},
        {'email': 'fictional.client.161@new-build-egypt.com', 'password': 'IHome1612026!', 'code': '161'},
        {'email': 'mohamed.said.abdelalim@new-build-egypt.com', 'password': 'IHome1652026!', 'code': '165'},
        {'email': 'fictional.client.167@new-build-egypt.com', 'password': 'IHome1672026!', 'code': '167'},
        {'email': 'talaat.mohamed.adel@new-build-egypt.com', 'password': 'IHome1732026!', 'code': '173'},
        {'email': 'ahmed.sayed.ali@new-build-egypt.com', 'password': 'IHome1762026!', 'code': '176'},
        {'email': 'sahar.mahmoud.ibrahim@new-build-egypt.com', 'password': 'IHome1792026!', 'code': '179'},
        {'email': 'sameh.ibrahim.ywsf@new-build-egypt.com', 'password': 'IHome1802026!', 'code': '180'},
        {'email': 'amir.fadlelmawla@new-build-egypt.com', 'password': 'IHome1822026!', 'code': '182'},
        {'email': 'yasmin.abdelwahab.mahmoud@new-build-egypt.com', 'password': 'IHome1832026!', 'code': '183'},
        {'email': 'ahmed.sayed.ibrahim@new-build-egypt.com', 'password': 'IHome1852026!', 'code': '185'},
        {'email': 'mohamed.mohsen.mohamed@new-build-egypt.com', 'password': 'IHome1872026!', 'code': '187'},
        {'email': 'fictional.client.189@new-build-egypt.com', 'password': 'IHome1892026!', 'code': '189'},
        {'email': 'fictional.client.197@new-build-egypt.com', 'password': 'IHome1972026!', 'code': '197'},
        {'email': 'mostafa.mohamed.hsam@new-build-egypt.com', 'password': 'IHome1982026!', 'code': '198'},
        {'email': 'osama.ipad.ali@new-build-egypt.com', 'password': 'IHome2002026!', 'code': '200'},
        {'email': 'mohamed.ahmed.shehab@new-build-egypt.com', 'password': 'IHome2032026!', 'code': '203'},
        {'email': 'ramadan.salah.ramadan@new-build-egypt.com', 'password': 'IHome2052026!', 'code': '205'},
        {'email': 'fictional.client.207@new-build-egypt.com', 'password': 'IHome2072026!', 'code': '207'},
      ];

      for (final cred in clientCredentials) {
        final email = cred['email']!;
        final password = cred['password']!;
        final code = cred['code']!;

        final success = await AuthService.instance.login(email, password);
        expect(success, isTrue, reason: 'Failed to login with $email and $password');
        expect(AuthService.instance.currentState, AuthState.authenticated);
        expect(AuthService.instance.currentProfile?.clientId, 'client_$code');
        await AuthService.instance.logout();
      }
    });

    test('Login succeeds with pasted glued email, missing exclamation marks, or typos (e.g. min@new-build-egypt.comiliving2026 + IHome892026)', () async {
      // Glued email + password with password without exclamation mark
      var success = await AuthService.instance.login(
        'min@new-build-egypt.comiliving2026',
        'IHome892026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentState, AuthState.authenticated);
      expect(AuthService.instance.currentProfile?.clientId, 'client_admin');
      await AuthService.instance.logout();

      // Client 89 with password without exclamation mark
      success = await AuthService.instance.login(
        'mahmoud.ghanem.ibrahim@new-build-egypt.com',
        'IHome892026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentState, AuthState.authenticated);
      expect(AuthService.instance.currentProfile?.clientId, 'client_89');
      await AuthService.instance.logout();

      // Admin with clean email and client password
      success = await AuthService.instance.login(
        'admin@new-build-egypt.com',
        'IHome892026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_admin');
      await AuthService.instance.logout();
    });
  });
}
