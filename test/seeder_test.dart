import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ERP Seed Data Verification', () {
    test('assets/erp_seed_data.json exists, is non-empty and valid JSON', () {
      final file = File('assets/erp_seed_data.json');
      expect(file.existsSync(), isTrue, reason: 'assets/erp_seed_data.json must exist');

      final content = file.readAsStringSync();
      expect(content.isNotEmpty, isTrue, reason: 'assets/erp_seed_data.json must not be empty');

      final Map<String, dynamic> data = jsonDecode(content);
      expect(data.containsKey('projects'), isTrue);
      expect(data.containsKey('compounds'), isTrue);
      expect(data.containsKey('buildings'), isTrue);
      expect(data.containsKey('units'), isTrue);
      expect(data.containsKey('users'), isTrue);
      expect(data.containsKey('contracts'), isTrue);
      expect(data.containsKey('installments'), isTrue);
      expect(data.containsKey('payments'), isTrue);
      expect(data.containsKey('ledgers'), isTrue);
      expect(data.containsKey('documents'), isTrue);

      expect((data['projects'] as List).length, equals(1));
      expect((data['compounds'] as List).length, equals(1));
      expect((data['buildings'] as List).length, greaterThanOrEqualTo(9));
      expect((data['units'] as List).length, greaterThanOrEqualTo(185));
      expect((data['users'] as List).length, greaterThanOrEqualTo(48));
      expect((data['contracts'] as List).length, equals(54));
      expect((data['installments'] as List).length, greaterThanOrEqualTo(1500));
      expect((data['payments'] as List).length, greaterThanOrEqualTo(200));
      expect((data['ledgers'] as List).length, equals(54));
      expect((data['documents'] as List).length, equals(54));
    });

    test('Parses all seed data records into domain models without exceptions', () {
      final file = File('assets/erp_seed_data.json');
      final Map<String, dynamic> data = jsonDecode(file.readAsStringSync());

      final projects = (data['projects'] as List).map((e) => Project.fromJson(e)).toList();
      final compounds = (data['compounds'] as List).map((e) => CompoundModel.fromJson(e)).toList();
      final buildings = (data['buildings'] as List).map((e) => Building.fromJson(e)).toList();
      final units = (data['units'] as List).map((e) => UnitModel.fromJson(e)).toList();
      final users = (data['users'] as List).map((e) => UserProfile.fromJson(e)).toList();
      final contracts = (data['contracts'] as List).map((e) => Contract.fromJson(e)).toList();
      final installments = (data['installments'] as List).map((e) => Installment.fromJson(e)).toList();
      final payments = (data['payments'] as List).map((e) => Payment.fromJson(e)).toList();
      final ledgers = (data['ledgers'] as List).map((e) => UnitLedger.fromJson(e)).toList();
      final documents = (data['documents'] as List).map((e) => DocumentItem.fromJson(e)).toList();

      expect(projects.length, equals(1));
      expect(compounds.length, equals(1));
      expect(buildings.length, equals(9));
      expect(units.length, equals(185));
      expect(users.length, equals(48));
      expect(contracts.length, equals(54));
      expect(installments.length, equals(1533));
      expect(payments.length, equals(235));
      expect(ledgers.length, equals(54));
      expect(documents.length, equals(54));
    });
  });
}
