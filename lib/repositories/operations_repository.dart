import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/app_secrets.dart';
import '../models/operation_ticket_model.dart';
import '../models/unit_ledger_model.dart';
import '../models/gate_utility_model.dart';
import '../services/auth_service.dart';
import 'operations_mock_data.dart';
import '../models/invoice_model.dart';
import '../services/notification_service.dart';
import 'firestore/firestore_notification_repository.dart';


class OperationsRepository {
  Future<List<Map<String, dynamic>>> fetchCompoundOpsData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('compounds').get().timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        final filtered = _filterAndDeduplicateCompounds(snapshot.docs.map((doc) => doc.data()).toList());
        if (filtered.isNotEmpty) return filtered;
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
          .map((snapshot) => _filterAndDeduplicateCompounds(snapshot.docs.map((doc) => doc.data()).toList()))
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

  String _normalizeUnitId(String unitId, [String? clientId]) {
    final effectiveClientId = clientId ?? AuthService.instance.currentProfile?.clientId ?? '';
    final cleanClient = effectiveClientId.trim();
    final cleanCode = cleanClient.replaceAll(RegExp(r'[^0-9]'), '');
    const fictionalCodes = {'93', '100', '107', '109', '124', '150', '151', '154', '161', '167', '189', '197', '207'};
    if (fictionalCodes.contains(cleanCode)) {
      if (unitId == 'B203' || unitId == 'B404' || unitId == 'B409' || unitId == 'B202') {
        return 'UNIT$cleanCode';
      }
    }
    return unitId;
  }

  List<Map<String, dynamic>> _filterAndDeduplicateCompounds(List<Map<String, dynamic>> rawList) {
    final user = AuthService.instance.currentProfile;
    if (user == null) {
      return _deduplicateCompounds(rawList);
    }

    final clientId = user.clientId;
    final ownedUnits = user.ownedUnitIds.map((u) => _normalizeUnitId(u, clientId)).toList();

    List<Map<String, dynamic>> filtered = [];
    if (ownedUnits.isNotEmpty) {
      filtered = rawList.where((c) {
        final unitStr = (c['unit'] ?? c['unitId'] ?? '').toString();
        final normalizedUnit = _normalizeUnitId(unitStr, clientId);
        final itemClientId = (c['clientId'] ?? c['clientCode'] ?? '').toString();
        return ownedUnits.contains(unitStr) ||
            ownedUnits.contains(normalizedUnit) ||
            (itemClientId.isNotEmpty && itemClientId == clientId);
      }).toList();
    }

    if (filtered.isEmpty && clientId.isNotEmpty) {
      filtered = rawList.where((c) {
        final itemClientId = (c['clientId'] ?? c['clientCode'] ?? '').toString();
        return itemClientId == clientId;
      }).toList();
    }

    if (filtered.isEmpty) {
      if (rawList.isNotEmpty) {
        final firstComp = Map<String, dynamic>.from(rawList.first);
        if (ownedUnits.isNotEmpty) {
          firstComp['unit'] = ownedUnits.first;
        }
        return [firstComp];
      }
      return [];
    }

    return _deduplicateCompounds(filtered);
  }

  List<Map<String, dynamic>> _deduplicateCompounds(List<Map<String, dynamic>> list) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final item in list) {
      final unit = (item['unit'] ?? item['unitId'] ?? '').toString();
      final title = (item['title'] ?? '').toString();
      final id = (item['id'] ?? '').toString();
      final key = '${id}_${title}_$unit';
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(item);
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _getFallbackOpsData() {
    return _filterAndDeduplicateCompounds(OperationsMockData.dummyOpsCompounds);
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
    final targetUnitId = _normalizeUnitId(unitId, clientId);
    final controller = StreamController<UnitLedger>();

    UnitLedger getFallback() {
      try {
        return OperationsMockData.dummyLedgers.firstWhere(
          (l) => l.clientId == clientId && l.unitId == targetUnitId,
          orElse: () => OperationsMockData.dummyLedgers.firstWhere(
            (l) => l.clientId == clientId,
            orElse: () => OperationsMockData.dummyLedgers.firstWhere(
              (l) => l.unitId == targetUnitId,
              orElse: () => OperationsMockData.dummyLedgers.first.copyWith(
                clientId: clientId,
                unitId: targetUnitId,
              ),
            ),
          ),
        );
      } catch (_) {
        return OperationsMockData.dummyLedgers.first.copyWith(
          clientId: clientId,
          unitId: targetUnitId,
        );
      }
    }

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
              controller.add(getFallback());
            },
          );
    } catch (_) {
      controller.add(getFallback());
    }
    return controller.stream;
  }

  Future<List<GateAccessCode>> fetchActiveGateCodes({
    required String compoundId,
    required String unitId,
  }) async {
    final targetUnitId = _normalizeUnitId(unitId);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('gateAccessCodes')
          .where('compoundId', isEqualTo: compoundId)
          .where('unitId', isEqualTo: targetUnitId)
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
        .where((c) => c.compoundId == compoundId && c.unitId == targetUnitId && c.isActive)
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
    if (segments.length != 5 || segments[0] != 'ILIVING-GATE') {
      throw ArgumentError('Invalid QR payload format or missing signature');
    }
    final codeId = segments[1];
    final compoundId = segments[2];
    final epochMsStr = segments[3];
    final signature = segments[4];
    final message = 'ILIVING-GATE:$codeId:$compoundId:$epochMsStr';
    final expectedSignature = GateAccessCode.hmacSha256(message, AppSecrets.instance.gateSigningKey);
    if (signature != expectedSignature) {
      throw StateError('Cryptographic signature verification failed');
    }
    final epochMs = int.tryParse(epochMsStr) ?? 0;
    final now = DateTime.now().toUtc();
    final expiration = DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true);
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
    var result = GateAccessLog.evaluateScan(code);
    if (result == GateScanResult.granted && now.isAfter(expiration)) {
      result = GateScanResult.deniedExpired;
    }
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
    OperationTicketModel result = ticket;
    try {
      final ref = await FirebaseFirestore.instance.collection('tickets').add(ticket.toJson());
      result = ticket.copyWith(id: ref.id);
    } catch (_) {
      OperationsMockData.dummyTickets.add(ticket);
    }

    try {
      final notifService = NotificationService(notificationRepository: FirestoreNotificationRepository());
      await notifService.notifyTicketCreated(
        residentUserId: ticket.clientId,
        unitId: ticket.unitId,
        ticketNumber: ticket.id,
        title: ticket.description,
        urgency: ticket.priority.name,
      );
    } catch (_) {}

    return result;
  }

  Future<OperationTicketModel> updateTicketStatus({
    required String ticketId,
    required TicketStatus newStatus,
    required String changedByName,
    required String changedByRole,
    String? note,
  }) async {
    OperationTicketModel updated;
    try {
      final docRef = FirebaseFirestore.instance.collection('tickets').doc(ticketId);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final ticket = OperationTicketModel.fromJson(snapshot.data()!);
        updated = ticket.withStatusTransition(
          newStatus: newStatus,
          changedByName: changedByName,
          changedByRole: changedByRole,
          note: note,
        );
        await docRef.set(updated.toJson());
      } else {
        final index = OperationsMockData.dummyTickets.indexWhere((t) => t.id == ticketId);
        if (index == -1) throw StateError('Ticket not found: $ticketId');
        updated = OperationsMockData.dummyTickets[index].withStatusTransition(
          newStatus: newStatus,
          changedByName: changedByName,
          changedByRole: changedByRole,
          note: note,
        );
        OperationsMockData.dummyTickets[index] = updated;
      }
    } catch (_) {
      final index = OperationsMockData.dummyTickets.indexWhere((t) => t.id == ticketId);
      if (index == -1) throw StateError('Ticket not found: $ticketId');
      updated = OperationsMockData.dummyTickets[index].withStatusTransition(
        newStatus: newStatus,
        changedByName: changedByName,
        changedByRole: changedByRole,
        note: note,
      );
      OperationsMockData.dummyTickets[index] = updated;
    }

    try {
      final notifService = NotificationService(notificationRepository: FirestoreNotificationRepository());
      if (note != null && note.isNotEmpty) {
        await notifService.notifyTicketCommentAdded(
          targetUserId: updated.clientId,
          ticketNumber: updated.id,
          authorName: changedByName,
          message: note,
        );
      } else {
        await notifService.notifyTicketUpdated(
          residentUserId: updated.clientId,
          unitId: updated.unitId,
          ticketNumber: updated.id,
          title: updated.description,
          status: newStatus.name,
        );
      }
    } catch (_) {}

    return updated;
  }

}
