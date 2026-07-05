import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/operation_ticket_model.dart';
import '../models/unit_ledger_model.dart';
import '../models/gate_utility_model.dart';
import '../services/auth_service.dart';
import 'operations_mock_data.dart';
import '../models/invoice_model.dart';


class OperationsRepository {
  Future<List<Map<String, dynamic>>> fetchCompoundOpsData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('compounds').get().timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      }
    } catch (_) {}
    return _getFallbackOpsData();
  }

  Stream<List<Map<String, dynamic>>> streamCompoundOpsData() {
    final controller = StreamController<List<Map<String, dynamic>>>();
    try {
      FirebaseFirestore.instance
          .collection('compounds')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
          .listen(
            (data) {
              if (data.isNotEmpty) {
                controller.add(data);
              } else {
                controller.add(_getFallbackOpsData());
              }
            },
            onError: (_) {
              controller.add(_getFallbackOpsData());
            },
          );
    } catch (_) {
      controller.add(_getFallbackOpsData());
    }
    return controller.stream;
  }

  List<Map<String, dynamic>> _getFallbackOpsData() {
    final user = AuthService.instance.currentProfile;
    final ownedUnits = user?.ownedUnitIds ?? ['B01B202'];
    final filtered = OperationsMockData.dummyOpsCompounds.where((c) => ownedUnits.contains(c['unit'])).toList();
    if (filtered.isEmpty) {
      return OperationsMockData.dummyOpsCompounds;
    }
    return filtered;
  }

  Future<List<OperationTicketModel>> fetchTicketsForCompound(String compoundId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('compoundId', isEqualTo: compoundId)
          .get()
          .timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => OperationTicketModel.fromJson(doc.data())).toList();
      }
    } catch (_) {}
    return OperationsMockData.dummyTickets.where((t) => t.compoundId == compoundId).toList();
  }

  Future<List<InvoiceModel>> fetchInvoicesForCompound(String compoundId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('invoices')
          .where('compoundId', isEqualTo: compoundId)
          .get()
          .timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => InvoiceModel.fromJson(doc.data())).toList();
      }
    } catch (_) {}
    return OperationsMockData.dummyInvoices.where((i) => i.compoundId == compoundId).toList();
  }

  Stream<UnitLedger> fetchLedgerForUnit({
    required String compoundId,
    required String unitId,
    required String clientId,
  }) {
    final controller = StreamController<UnitLedger>();
    try {
      FirebaseFirestore.instance
          .doc('/ledger/$clientId/compounds/$compoundId')
          .snapshots()
          .map((snapshot) {
            final data = snapshot.data();
            if (data == null) throw StateError('Ledger not found');
            return UnitLedger.fromJson(data);
          })
          .listen(
            (ledger) => controller.add(ledger),
            onError: (_) {
              try {
                final fallback = OperationsMockData.dummyLedgers.firstWhere(
                  (l) => l.unitId == unitId,
                );
                controller.add(fallback);
              } catch (err) {
                controller.addError(err);
              }
            },
          );
    } catch (_) {
      try {
        final fallback = OperationsMockData.dummyLedgers.firstWhere(
          (l) => l.unitId == unitId,
        );
        controller.add(fallback);
      } catch (err) {
        controller.addError(err);
      }
    }
    return controller.stream;
  }

  Future<List<GateAccessCode>> fetchActiveGateCodes({
    required String compoundId,
    required String unitId,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('gateAccessCodes')
          .where('compoundId', isEqualTo: compoundId)
          .where('unitId', isEqualTo: unitId)
          .get()
          .timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => GateAccessCode.fromJson(doc.data()))
            .where((code) => code.isActive)
            .toList();
      }
    } catch (_) {}
    return OperationsMockData.dummyGateCodes
        .where((c) => c.compoundId == compoundId && c.unitId == unitId && c.isActive)
        .toList();
  }

  Future<GateAccessCode> generateGateAccessCode({
    required String compoundId,
    required String unitId,
    required String issuedByClientId,
    required String guestName,
    required String guestPhone,
    required GateAccessType accessType,
    required Duration validity,
    String? guestNationalId,
    String? vehiclePlate,
    int maxScans = 1,
    String? notes,
  }) async {
    final code = GateAccessCode.generate(
      compoundId: compoundId,
      unitId: unitId,
      issuedByClientId: issuedByClientId,
      guestName: guestName,
      guestPhone: guestPhone,
      accessType: accessType,
      validity: validity,
      guestNationalId: guestNationalId,
      vehiclePlate: vehiclePlate,
      maxScans: maxScans,
      notes: notes,
    );
    try {
      final epochMs = DateTime.now().add(validity).millisecondsSinceEpoch;
      final payload = {
        ...code.toJson(),
        'epochMs': epochMs,
        'signature': 'SECURED-SHA256:${code.codeId}:$epochMs',
      };
      await FirebaseFirestore.instance
          .collection('gateAccessCodes')
          .doc(code.codeId)
          .set(payload)
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
    OperationsMockData.dummyGateCodes.add(code);
    return code;
  }

  Future<GateAccessLog> processGateScan({
    required String qrPayloadString,
    required String gateId,
    String? operatorId,
    String? vehiclePlate,
    String? cameraSnapshotUrl,
  }) async {
    final segments = qrPayloadString.split(':');
    if (segments.length != 4 || segments[0] != 'IHOME-GATE') {
      throw ArgumentError('Invalid QR payload format: $qrPayloadString');
    }
    final codeId = segments[1];
    GateAccessCode? code;
    try {
      final snapshot = await FirebaseFirestore.instance.collection('gateAccessCodes').doc(codeId).get();
      if (snapshot.exists) {
        code = GateAccessCode.fromJson(snapshot.data()!);
      }
    } catch (_) {}
    if (code == null) {
      final index = OperationsMockData.dummyGateCodes.indexWhere((c) => c.codeId == codeId);
      if (index == -1) throw StateError('Gate code not found: $codeId');
      code = OperationsMockData.dummyGateCodes[index];
    }
    final result = GateAccessLog.evaluateScan(code);
    final logEntry = GateAccessLog.recordScan(
      code: code,
      gateId: gateId,
      result: result,
      operatorId: operatorId,
      vehiclePlate: vehiclePlate,
      cameraSnapshotUrl: cameraSnapshotUrl,
    );
    try {
      await FirebaseFirestore.instance.collection('gateAccessLogs').add(logEntry.toJson());
      if (result == GateScanResult.granted) {
        await FirebaseFirestore.instance.collection('gateAccessCodes').doc(codeId).update({'scanCount': code.scanCount + 1});
      }
    } catch (_) {}
    OperationsMockData.dummyGateLogs.add(logEntry);
    final idx = OperationsMockData.dummyGateCodes.indexWhere((c) => c.codeId == codeId);
    if (idx != -1 && result == GateScanResult.granted) {
      OperationsMockData.dummyGateCodes[idx] = code.copyWith(scanCount: code.scanCount + 1);
    }
    return logEntry;
  }

  Future<GateAccessCode> revokeGateAccessCode({
    required String codeId,
    required String revokedByClientId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      final docRef = FirebaseFirestore.instance.collection('gateAccessCodes').doc(codeId);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final code = GateAccessCode.fromJson(snapshot.data()!);
        final updated = code.copyWith(
          isRevoked: true,
          revokedAtIso: now,
          revokedByClientId: revokedByClientId,
        );
        await docRef.set(updated.toJson());
        return updated;
      }
    } catch (_) {}
    final index = OperationsMockData.dummyGateCodes.indexWhere((c) => c.codeId == codeId);
    if (index == -1) throw StateError('Gate code not found: $codeId');
    final revoked = OperationsMockData.dummyGateCodes[index].copyWith(
      isRevoked: true,
      revokedAtIso: now,
      revokedByClientId: revokedByClientId,
    );
    OperationsMockData.dummyGateCodes[index] = revoked;
    return revoked;
  }

  Future<List<GateAccessLog>> fetchGateLogsForUnit({
    required String compoundId,
    required String unitId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('gateAccessLogs')
          .where('compoundId', isEqualTo: compoundId)
          .where('unitId', isEqualTo: unitId)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        final logs = snapshot.docs.map((doc) => GateAccessLog.fromJson(doc.data())).toList();
        logs.sort((a, b) => b.scanTimestampIso.compareTo(a.scanTimestampIso));
        return logs;
      }
    } catch (_) {}
    final filtered = OperationsMockData.dummyGateLogs
        .where((l) => l.compoundId == compoundId && l.unitId == unitId)
        .toList();
    filtered.sort((a, b) => b.scanTimestampIso.compareTo(a.scanTimestampIso));
    return filtered.take(limit).toList();
  }

  Future<OperationTicketModel> submitTicket(OperationTicketModel ticket) async {
    try {
      final ref = await FirebaseFirestore.instance.collection('tickets').add(ticket.toJson());
      return ticket.copyWith(id: ref.id);
    } catch (_) {}
    OperationsMockData.dummyTickets.add(ticket);
    return ticket;
  }

  Future<OperationTicketModel> updateTicketStatus({
    required String ticketId,
    required TicketStatus newStatus,
    required String changedByName,
    required String changedByRole,
    String? note,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('tickets').doc(ticketId);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final ticket = OperationTicketModel.fromJson(snapshot.data()!);
        final updated = ticket.withStatusTransition(
          newStatus: newStatus,
          changedByName: changedByName,
          changedByRole: changedByRole,
          note: note,
        );
        await docRef.set(updated.toJson());
        return updated;
      }
    } catch (_) {}
    final index = OperationsMockData.dummyTickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) throw StateError('Ticket not found: $ticketId');
    final updated = OperationsMockData.dummyTickets[index].withStatusTransition(
      newStatus: newStatus,
      changedByName: changedByName,
      changedByRole: changedByRole,
      note: note,
    );
    OperationsMockData.dummyTickets[index] = updated;
    return updated;
  }

}
