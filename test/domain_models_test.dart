import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/installment.dart';
import 'package:iliving/models/unit_model.dart';
import 'package:iliving/models/contract.dart';
import 'package:iliving/models/user_profile.dart';

void main() {
  group('Priority 1 Real Customer Data Model Tests', () {
    test('Installment parses semiAnnual, annual, and receiptNumber', () {
      final json = {
        'id': 'inst_001',
        'contractId': 'cnt_117',
        'unitId': 'unit_b404',
        'buyerUserId': 'user_144',
        'sequenceNumber': 3,
        'installmentType': 'semiAnnual',
        'dueDate': '2025-11-01T00:00:00.000',
        'gracePeriodEndDate': '2025-11-15T00:00:00.000',
        'principalAmount': 585200.0,
        'paidAmount': 0.0,
        'currency': 'EGP',
        'status': 'UNPAID',
        'receiptNumber': '38',
      };

      final inst = Installment.fromJson(json);
      expect(inst.installmentType, equals(InstallmentType.semiAnnual));
      expect(inst.receiptNumber, equals('38'));
      expect(inst.currency, equals('EGP'));
      expect(inst.toJson()['receiptNumber'], equals('38'));
      expect(inst.toJson()['installmentType'], equals('semiAnnual'));
    });

    test('UnitModel parses gardenArea, orientation, and block', () {
      final json = {
        'unitNumber': 'A01',
        'configuration': '2 Bed Apartment',
        'areaSqFt': 915.0,
        'priceEGP': 2675812.0,
        'isVacant': true,
        'assetClass': 'Residential',
        'furnishingStatus': 'Unfurnished',
        'pricePerSqFt': 2924.0,
        'parkingSpaces': 1,
        'constructionPhase': 'Under Construction',
        'parentCompoundId': 'cmp_skyhills',
        'areaSquareMeters': 85.0,
        'gardenArea': 50.0,
        'orientation': 'OWEST',
        'block': 'A',
      };

      final unit = UnitModel.fromJson(json);
      expect(unit.unitNumber, equals('A01'));
      expect(unit.gardenArea, equals(50.0));
      expect(unit.orientation, equals('OWEST'));
      expect(unit.block, equals('A'));
      expect(unit.toJson()['gardenArea'], equals(50.0));
      expect(unit.toJson()['orientation'], equals('OWEST'));
    });

    test('Contract parses clientCode and handoverPaymentAmount', () {
      final json = {
        'id': 'cnt_117',
        'contractNumber': '117',
        'unitId': 'unit_b404',
        'compoundId': 'cmp_skyhills',
        'buyerUserId': 'user_144',
        'salesAgentUserId': 'agent_01',
        'agreedTotalPrice': 2675812.0,
        'downPaymentAmount': 248500.0,
        'maintenanceDepositAmount': 0.0,
        'handoverPaymentAmount': 69891.0,
        'clientCode': '144',
        'installmentDurationYears': 8,
        'totalInstallmentsCount': 34,
        'startDate': '2025-01-01T00:00:00.000',
        'endDate': '2032-12-14T00:00:00.000',
        'deliveryDateExpected': '2032-12-14T00:00:00.000',
      };

      final contract = Contract.fromJson(json);
      expect(contract.contractNumber, equals('117'));
      expect(contract.clientCode, equals('144'));
      expect(contract.handoverPaymentAmount, equals(69891.0));
      expect(contract.toJson()['clientCode'], equals('144'));
    });

    test('UserProfile parses clientCode', () {
      final json = {
        'uid': 'user_144',
        'email': 'client144@example.com',
        'phoneNumber': '01000000144',
        'fullName': 'Fictional Client 144',
        'clientCode': '144',
        'role': 'CUSTOMER',
        'createdAt': '2025-01-01T00:00:00.000',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.fullName, equals('Fictional Client 144'));
      expect(profile.clientCode, equals('144'));
      expect(profile.toJson()['clientCode'], equals('144'));
    });
  });
}
