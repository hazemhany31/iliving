import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/models/unit_model.dart';
import 'package:iliving/models/contract.dart';
import 'package:iliving/models/installment.dart';
import 'package:iliving/models/payment.dart';
import 'package:iliving/screens/admin/customers_module_screen.dart';

void main() {
  group('Customer Financial SSOT Audit & ERP Reconciliation Tests', () {
    late Map<String, dynamic> erpData;
    late List<UserProfile> allUsers;
    late List<Unit> allUnits;
    late List<Contract> allContracts;
    late List<Installment> allInstallments;
    late List<Payment> allPayments;

    setUpAll(() {
      final file = File('assets/erp_seed_data.json');
      expect(file.existsSync(), isTrue, reason: 'assets/erp_seed_data.json must exist');
      final jsonString = file.readAsStringSync();
      erpData = jsonDecode(jsonString);

      allUsers = (erpData['users'] as List)
          .map((u) => UserProfile.fromJson(u as Map<String, dynamic>))
          .toList();
      allUnits = (erpData['units'] as List)
          .map((u) => Unit.fromJson(u as Map<String, dynamic>))
          .toList();
      allContracts = (erpData['contracts'] as List)
          .map((c) => Contract.fromJson(c as Map<String, dynamic>))
          .toList();
      allInstallments = (erpData['installments'] as List)
          .map((i) => Installment.fromJson(i as Map<String, dynamic>))
          .toList();
      allPayments = (erpData['payments'] as List)
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();
    });

    test('Audit record totals from ERP dataset', () {
      expect(allUsers.length, equals(48));
      expect(allContracts.length, equals(54));
      expect(allInstallments.length, equals(1533));
      expect(allPayments.length, equals(235));
    });

    test('Verify CustomerAggregateData financial metrics for EVERY customer', () {
      int checkedCustomers = 0;
      int checkedContracts = 0;
      int checkedInstallments = 0;
      int checkedPayments = 0;
      final List<String> flaggedDiscrepancyUsers = [];

      for (final user in allUsers) {
        final userUnits = allUnits.where((unit) {
          return unit.currentOwnerId == user.uid ||
              (user.clientCode != null &&
                  user.clientCode!.isNotEmpty &&
                  unit.currentOwnerId == user.clientCode);
        }).toList();

        final userContracts = allContracts.where((c) {
          return c.buyerUserId == user.uid ||
              (user.clientCode != null &&
                  user.clientCode!.isNotEmpty &&
                  (c.buyerUserId == user.clientCode || c.clientCode == user.clientCode));
        }).toList();

        final userContractIds = userContracts.map((c) => c.id).toSet();

        final userInstallments = allInstallments.where((inst) {
          return inst.buyerUserId == user.uid ||
              (user.clientCode != null &&
                  user.clientCode!.isNotEmpty &&
                  inst.buyerUserId == user.clientCode) ||
              userContractIds.contains(inst.contractId);
        }).toList();

        final userPayments = allPayments.where((p) {
          return p.payerUserId == user.uid ||
              (user.clientCode != null &&
                  user.clientCode!.isNotEmpty &&
                  p.payerUserId == user.clientCode);
        }).toList();

        final agg = CustomerAggregateData(
          user: user,
          units: userUnits,
          contracts: userContracts,
          installments: userInstallments,
          payments: userPayments,
        );

        checkedCustomers++;
        checkedContracts += userContracts.length;
        checkedInstallments += userInstallments.length;
        checkedPayments += userPayments.length;

        // Verify calculations non-negative
        expect(agg.totalContractValue, greaterThanOrEqualTo(0.0));
        expect(agg.totalAmountPaid, greaterThanOrEqualTo(0.0));
        expect(agg.totalAmountRemaining, greaterThanOrEqualTo(0.0));
        expect(agg.paidInstallmentsCount, greaterThanOrEqualTo(0));
        expect(agg.remainingInstallmentsCount, greaterThanOrEqualTo(0));
        expect(agg.overdueAmount, greaterThanOrEqualTo(0.0));
        expect(agg.nextInstallmentAmount, greaterThanOrEqualTo(0.0));

        // Total contract value should equal remaining + paid (within rounding precision) if no discrepancy
        if (!agg.hasDiscrepancy && userContracts.isNotEmpty) {
          expect(
            (agg.totalContractValue - (agg.totalAmountPaid + agg.totalAmountRemaining)).abs(),
            lessThanOrEqualTo(1.0),
          );
        }

        if (agg.hasDiscrepancy) {
          flaggedDiscrepancyUsers.add(user.fullName);
          expect(agg.paymentStatusDisplay, equals('DISCREPANCY DETECTED'));
          expect(agg.discrepancyMessage, isNotEmpty);
        }
      }

      expect(checkedCustomers, equals(48));
      expect(checkedContracts, equals(54));
      expect(checkedInstallments, equals(1533));
      expect(checkedPayments, equals(235));
      // Verify exact count of users with inconsistent data flagged (User 165: محمد سعيد عبد العليم)
      expect(flaggedDiscrepancyUsers.length, equals(1));
      expect(flaggedDiscrepancyUsers, contains('محمد سعيد عبد العليم'));
    });

    test('Verify Customer 87 exact financial values', () {
      final user87 = allUsers.firstWhere((u) => u.clientCode == '87');
      final userContracts = allContracts.where((c) => c.clientCode == '87' || c.buyerUserId == user87.uid).toList();
      final userContractIds = userContracts.map((c) => c.id).toSet();
      final userInstallments = allInstallments.where((i) => userContractIds.contains(i.contractId)).toList();
      final userPayments = allPayments.where((p) => p.payerUserId == user87.uid || p.payerUserId == '87').toList();

      final agg = CustomerAggregateData(
        user: user87,
        units: [],
        contracts: userContracts,
        installments: userInstallments,
        payments: userPayments,
      );

      expect(agg.totalContractValue, equals(2538000.0));
      expect(agg.totalAmountPaid, equals(367200.0));
      expect(agg.totalAmountRemaining, equals(2170800.0));
      expect(agg.totalInstallmentsCount, equals(34));
      expect(agg.paidInstallmentsCount, equals(3));
      expect(agg.remainingInstallmentsCount, equals(31));
      expect(agg.hasDiscrepancy, isFalse);
    });
  });
}
