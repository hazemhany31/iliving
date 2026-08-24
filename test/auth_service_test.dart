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
      // client 87 under iLiving domain with iLiving password
      var success = await AuthService.instance.login(
        'ahmed.shazly.abdelgawad@iliving.com.eg',
        'iLiving872026!',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_87');
      await AuthService.instance.logout();

      // client 87 under iLiving domain with generic iliving master password
      success = await AuthService.instance.login(
        'ahmed.shazly.abdelgawad@iliving.com.eg',
        'iliving2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_87');
      await AuthService.instance.logout();
    });

    test('Login succeeds with Demo credentials (both iliving and iliving domains)', () async {
      // demo@iliving.com.eg with iliving2026
      var success = await AuthService.instance.login(
        'demo@iliving.com.eg',
        'iliving2026',
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
      // sterling@iliving.com.eg with sterling2026
      var success = await AuthService.instance.login(
        'sterling@iliving.com.eg',
        'sterling2026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_broker');
      expect(AuthService.instance.currentProfile?.displayName, 'Alistair Sterling');
      await AuthService.instance.logout();

      // sterling@iliving.com.eg with iliving2026
      success = await AuthService.instance.login(
        'sterling@iliving.com.eg',
        'iliving2026',
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

    test('All 55 client credentials specified by user log in successfully with their dedicated iLiving{code}2026! password', () async {
      final clientCredentials = [
        {'email': 'ahmed.shazly.abdelgawad@new-build-egypt.com', 'password': 'iLiving872026!', 'code': '87'},
        {'email': 'mahmoud.ghanem.ibrahim@new-build-egypt.com', 'password': 'iLiving892026!', 'code': '89'},
        {'email': 'marrow.ali.mohamed@new-build-egypt.com', 'password': 'iLiving902026!', 'code': '90'},
        {'email': 'basyouni.ibrahim.basyouni@new-build-egypt.com', 'password': 'iLiving912026!', 'code': '91'},
        {'email': 'fictional.client.93@new-build-egypt.com', 'password': 'iLiving932026!', 'code': '93'},
        {'email': 'ahmed.hussein.mohamed@new-build-egypt.com', 'password': 'iLiving942026!', 'code': '94'},
        {'email': 'mhasn.mohamed.hasan@new-build-egypt.com', 'password': 'iLiving952026!', 'code': '95'},
        {'email': 'abdallah.ibrahim.ibrahim@new-build-egypt.com', 'password': 'iLiving982026!', 'code': '98'},
        {'email': 'fictional.client.100@new-build-egypt.com', 'password': 'iLiving1002026!', 'code': '100'},
        {'email': 'awadallah.rashid.ahmed@new-build-egypt.com', 'password': 'iLiving1022026!', 'code': '102'},
        {'email': 'dowlat.mohamed.elsayed@new-build-egypt.com', 'password': 'iLiving1052026!', 'code': '105'},
        {'email': 'fictional.client.107@new-build-egypt.com', 'password': 'iLiving1072026!', 'code': '107'},
        {'email': 'fictional.client.109@new-build-egypt.com', 'password': 'iLiving1092026!', 'code': '109'},
        {'email': 'hasan.mohamed.hasan@new-build-egypt.com', 'password': 'iLiving1112026!', 'code': '111'},
        {'email': 'fictional.client.113@new-build-egypt.com', 'password': 'iLiving1132026!', 'code': '113'},
        {'email': 'mohamed.mousa.ali@new-build-egypt.com', 'password': 'iLiving1142026!', 'code': '114'},
        {'email': 'khaled.mohamed.mohamed@new-build-egypt.com', 'password': 'iLiving1162026!', 'code': '116'},
        {'email': 'sameh.abd.alsmd@new-build-egypt.com', 'password': 'iLiving1212026!', 'code': '121'},
        {'email': 'amir.abd.alsmd@new-build-egypt.com', 'password': 'iLiving1222026!', 'code': '122'},
        {'email': 'hanafy.ahmed.badawy@new-build-egypt.com', 'password': 'iLiving1232026!', 'code': '123'},
        {'email': 'fictional.client.124@new-build-egypt.com', 'password': 'iLiving1242026!', 'code': '124'},
        {'email': 'marwa.hasan.mohamed@new-build-egypt.com', 'password': 'iLiving1252026!', 'code': '125'},
        {'email': 'mohamed.shaban.mohamed@new-build-egypt.com', 'password': 'iLiving1272026!', 'code': '127'},
        {'email': 'ahmed.jalal.abd@new-build-egypt.com', 'password': 'iLiving1302026!', 'code': '130'},
        {'email': 'samir.ghanem.ibrahim@new-build-egypt.com', 'password': 'iLiving1342026!', 'code': '134'},
        {'email': 'mohamed.ahmed.mohamed@new-build-egypt.com', 'password': 'iLiving1372026!', 'code': '137'},
        {'email': 'ahmed.ashraf.obeid@new-build-egypt.com', 'password': 'iLiving1392026!', 'code': '139'},
        {'email': 'ahmed.abdelkhalek.ouf@new-build-egypt.com', 'password': 'iLiving1422026!', 'code': '142'},
        {'email': 'ibrahim.ahmed.abdallah@new-build-egypt.com', 'password': 'iLiving1442026!', 'code': '144'},
        {'email': 'mohamed.ahmed.abdallh@new-build-egypt.com', 'password': 'iLiving1452026!', 'code': '145'},
        {'email': 'elsayed.abdallah.abdelhamid@new-build-egypt.com', 'password': 'iLiving1462026!', 'code': '146'},
        {'email': 'ahmed.abd.alazym@new-build-egypt.com', 'password': 'iLiving1472026!', 'code': '147'},
        {'email': 'fictional.client.150@new-build-egypt.com', 'password': 'iLiving1502026!', 'code': '150'},
        {'email': 'fictional.client.151@new-build-egypt.com', 'password': 'iLiving1512026!', 'code': '151'},
        {'email': 'ahmed.basyouni.atiya@new-build-egypt.com', 'password': 'iLiving1522026!', 'code': '152'},
        {'email': 'fictional.client.154@new-build-egypt.com', 'password': 'iLiving1542026!', 'code': '154'},
        {'email': 'mohamed.ali.zydan@new-build-egypt.com', 'password': 'iLiving1552026!', 'code': '155'},
        {'email': 'fictional.client.161@new-build-egypt.com', 'password': 'iLiving1612026!', 'code': '161'},
        {'email': 'mohamed.said.abdelalim@new-build-egypt.com', 'password': 'iLiving1652026!', 'code': '165'},
        {'email': 'fictional.client.167@new-build-egypt.com', 'password': 'iLiving1672026!', 'code': '167'},
        {'email': 'talaat.mohamed.adel@new-build-egypt.com', 'password': 'iLiving1732026!', 'code': '173'},
        {'email': 'ahmed.sayed.ali@new-build-egypt.com', 'password': 'iLiving1762026!', 'code': '176'},
        {'email': 'sahar.mahmoud.ibrahim@new-build-egypt.com', 'password': 'iLiving1792026!', 'code': '179'},
        {'email': 'sameh.ibrahim.ywsf@new-build-egypt.com', 'password': 'iLiving1802026!', 'code': '180'},
        {'email': 'amir.fadlelmawla@new-build-egypt.com', 'password': 'iLiving1822026!', 'code': '182'},
        {'email': 'yasmin.abdelwahab.mahmoud@new-build-egypt.com', 'password': 'iLiving1832026!', 'code': '183'},
        {'email': 'ahmed.sayed.ibrahim@new-build-egypt.com', 'password': 'iLiving1852026!', 'code': '185'},
        {'email': 'mohamed.mohsen.mohamed@new-build-egypt.com', 'password': 'iLiving1872026!', 'code': '187'},
        {'email': 'fictional.client.189@new-build-egypt.com', 'password': 'iLiving1892026!', 'code': '189'},
        {'email': 'fictional.client.197@new-build-egypt.com', 'password': 'iLiving1972026!', 'code': '197'},
        {'email': 'mostafa.mohamed.hsam@new-build-egypt.com', 'password': 'iLiving1982026!', 'code': '198'},
        {'email': 'osama.ipad.ali@new-build-egypt.com', 'password': 'iLiving2002026!', 'code': '200'},
        {'email': 'mohamed.ahmed.shehab@new-build-egypt.com', 'password': 'iLiving2032026!', 'code': '203'},
        {'email': 'ramadan.salah.ramadan@new-build-egypt.com', 'password': 'iLiving2052026!', 'code': '205'},
        {'email': 'fictional.client.207@new-build-egypt.com', 'password': 'iLiving2072026!', 'code': '207'},
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

    test('Login succeeds with pasted glued email, missing exclamation marks, or typos (e.g. min@new-build-egypt.comiliving2026 + iLiving892026)', () async {
      // Glued email + password with password without exclamation mark
      var success = await AuthService.instance.login(
        'min@new-build-egypt.comiliving2026',
        'iLiving892026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentState, AuthState.authenticated);
      expect(AuthService.instance.currentProfile?.clientId, 'client_admin');
      await AuthService.instance.logout();

      // Client 89 with password without exclamation mark
      success = await AuthService.instance.login(
        'mahmoud.ghanem.ibrahim@new-build-egypt.com',
        'iLiving892026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentState, AuthState.authenticated);
      expect(AuthService.instance.currentProfile?.clientId, 'client_89');
      await AuthService.instance.logout();

      // Admin with clean email and client password
      success = await AuthService.instance.login(
        'admin@new-build-egypt.com',
        'iLiving892026',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentProfile?.clientId, 'client_admin');
      await AuthService.instance.logout();
    });

    test('createCustomerAccount generates working credentials that can immediately log in and are deleted on remove', () async {
      // 1. Create a brand new customer
      final created = await AuthService.instance.createCustomerAccount(
        fullName: 'خالد عبد الرحمن السعيد',
        email: 'khaled.saeed@iliving.com.eg',
        password: 'iLiving999!2026',
        phoneNumber: '+201099998888',
        clientCode: 'CLI-999',
        nationalIdOrPassport: '29812120109999',
      );

      expect(created.profile.fullName, 'خالد عبد الرحمن السعيد');
      expect(created.profile.email, 'khaled.saeed@iliving.com.eg');
      expect(created.generatedPassword, 'iLiving999!2026');

      // 2. Attempt login with generated credentials
      final loginSuccess = await AuthService.instance.login(
        'khaled.saeed@iliving.com.eg',
        'iLiving999!2026',
      );
      expect(loginSuccess, isTrue);
      expect(AuthService.instance.currentState, AuthState.authenticated);
      expect(AuthService.instance.currentUserProfile?.fullName, 'خالد عبد الرحمن السعيد');
      await AuthService.instance.logout();

      // 3. Delete customer account
      await AuthService.instance.deleteCustomerAccount(created.profile);

      // 4. Verify login no longer works
      final loginAfterDelete = await AuthService.instance.login(
        'khaled.saeed@iliving.com.eg',
        'iLiving999!2026',
      );
      expect(loginAfterDelete, isFalse);
      expect(AuthService.instance.currentState, AuthState.unauthenticated);
    });

    test('createCustomerAccount with custom Gmail (hazemhany@gmail.com) logs in successfully', () async {
      final created = await AuthService.instance.createCustomerAccount(
        fullName: 'Hazem Hany',
        email: 'hazemhany@gmail.com',
        password: 'iLiving101!2026',
        phoneNumber: '+201001234567',
        clientCode: 'CLI-101',
        nationalIdOrPassport: '29901010101010',
      );

      expect(created.profile.email, 'hazemhany@gmail.com');

      // Login with exact password
      var success = await AuthService.instance.login('hazemhany@gmail.com', 'iLiving101!2026');
      expect(success, isTrue);
      expect(AuthService.instance.currentUserProfile?.email, 'hazemhany@gmail.com');
      await AuthService.instance.logout();

      // Login with master password
      success = await AuthService.instance.login('hazemhany@gmail.com', 'iliving2026');
      expect(success, isTrue);
      await AuthService.instance.logout();
    });
  });
}
