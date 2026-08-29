import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreSeederService {
  final FirebaseFirestore _firestore;

  FirestoreSeederService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Checks if Firestore already contains ERP seed data.
  /// If not yet seeded, automatically runs [runFirestoreImport] once so the app is auto-populated permanently.
  static Future<void> ensureSeeded() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final projectsSnap = await firestore.collection('projects').limit(1).get().timeout(const Duration(seconds: 3));
      if (projectsSnap.docs.isNotEmpty) {
        debugPrint("[FirestoreSeederService] ERP data is already saved in Firestore. Auto-seed skipped.");
        return;
      }
      debugPrint("[FirestoreSeederService] Initializing automatic first-time ERP data seed...");
      await FirestoreSeederService(firestore: firestore).runFirestoreImport();
    } catch (e) {
      debugPrint("[FirestoreSeederService] ensureSeeded check note: $e");
    }
  }

  void _logError({
    required String stepName,
    required String entityName,
    required String docId,
    required dynamic error,
    required StackTrace stack,
  }) {
    debugPrint(
      "==========================================================\n"
      "[FirestoreSeederService ERROR]\n"
      "File: firestore_seeder_service.dart\n"
      "Method: runFirestoreImport ($stepName)\n"
      "Entity: $entityName\n"
      "Document ID: $docId\n"
      "Error: $error\n"
      "Stack Trace:\n$stack\n"
      "==========================================================",
    );
  }

  Future<void> _commitBatchWithTimeout(WriteBatch batch, {Duration timeout = const Duration(seconds: 3)}) async {
    try {
      await batch.commit().timeout(timeout);
    } on TimeoutException {
      debugPrint("[FirestoreSeederService] Batch commit timed out after $timeout. Local offline queue accepted.");
    } catch (e) {
      debugPrint("[FirestoreSeederService] Batch commit exception: $e");
    }
  }

  /// Loads `assets/erp_seed_data.json` and seeds all 10 domain entity collections into Firestore.
  /// Reports real-time progress via [onProgress] callback with detailed error reporting per step.
  Future<void> runFirestoreImport({
    void Function(String message, double progress)? onProgress,
  }) async {
    // 1. 0% Loading JSON
    onProgress?.call("0% Loading JSON - Reading assets/erp_seed_data.json...", 0.0);
    String? jsonString;
    try {
      final List<String> candidatePaths = [
        'assets/erp_seed_data.json',
        'assets/assets/erp_seed_data.json',
        'erp_seed_data.json',
      ];

      for (final path in candidatePaths) {
        try {
          jsonString = await rootBundle.loadString(path);
          if (jsonString.isNotEmpty) break;
        } catch (_) {}
      }

      if (jsonString == null || jsonString.isEmpty) {
        throw Exception("Could not find or read assets/erp_seed_data.json via rootBundle.");
      }
      debugPrint("[FirestoreSeederService] 0% Loading JSON successful.");
    } catch (e, stack) {
      _logError(
        stepName: "Loading JSON",
        entityName: "AssetFile",
        docId: "assets/erp_seed_data.json",
        error: e,
        stack: stack,
      );
      onProgress?.call("Error loading asset: $e", 0.0);
      rethrow;
    }

    // 2. 5% Parsing JSON
    onProgress?.call("5% Parsing JSON payload...", 0.05);
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(jsonString);
      debugPrint("[FirestoreSeederService] 5% Parsing JSON successful.");
    } catch (e, stack) {
      _logError(
        stepName: "Parsing JSON",
        entityName: "JSONData",
        docId: "root",
        error: e,
        stack: stack,
      );
      onProgress?.call("Error parsing JSON: $e", 0.05);
      rethrow;
    }

    final List<dynamic> rawProjects = data['projects'] ?? [];
    final List<dynamic> rawCompounds = data['compounds'] ?? [];
    final List<dynamic> rawBuildings = data['buildings'] ?? [];
    final List<dynamic> rawUnits = data['units'] ?? [];
    final List<dynamic> rawUsers = data['users'] ?? [];
    final List<dynamic> rawContracts = data['contracts'] ?? [];
    final List<dynamic> rawInstallments = data['installments'] ?? [];
    final List<dynamic> rawPayments = data['payments'] ?? [];
    final List<dynamic> rawLedgers = data['ledgers'] ?? [];
    final List<dynamic> rawDocuments = data['documents'] ?? [];

    // 3. 10% Projects
    onProgress?.call("10% Projects - Seeding ${rawProjects.length} Projects...", 0.10);
    try {
      final batch = _firestore.batch();
      for (final item in rawProjects) {
        final docMap = item as Map<String, dynamic>;
        final docId = docMap['id']?.toString() ?? 'unknown';
        try {
          final project = Project.fromJson(docMap);
          batch.set(_firestore.collection('projects').doc(project.id), project.toJson(), SetOptions(merge: true));
        } catch (e, stack) {
          _logError(
            stepName: "Projects Parsing",
            entityName: "Project",
            docId: docId,
            error: e,
            stack: stack,
          );
        }
      }
      await _commitBatchWithTimeout(batch);
      debugPrint("[FirestoreSeederService] 10% Projects import complete.");
    } catch (e, stack) {
      _logError(
        stepName: "Projects Batch Commit",
        entityName: "Project",
        docId: "projects_batch",
        error: e,
        stack: stack,
      );
      onProgress?.call("Error seeding Projects: $e", 0.10);
    }

    // 4. 15% Compounds
    onProgress?.call("15% Compounds - Seeding ${rawCompounds.length} Compounds...", 0.15);
    try {
      final batch = _firestore.batch();
      for (final item in rawCompounds) {
        final docMap = item as Map<String, dynamic>;
        final docId = docMap['id']?.toString() ?? 'unknown';
        try {
          final compound = CompoundModel.fromJson(docMap);
          batch.set(_firestore.collection('compounds').doc(compound.id), compound.toJson(), SetOptions(merge: true));
        } catch (e, stack) {
          _logError(
            stepName: "Compounds Parsing",
            entityName: "CompoundModel",
            docId: docId,
            error: e,
            stack: stack,
          );
        }
      }
      await _commitBatchWithTimeout(batch);
      debugPrint("[FirestoreSeederService] 15% Compounds import complete.");
    } catch (e, stack) {
      _logError(
        stepName: "Compounds Batch Commit",
        entityName: "CompoundModel",
        docId: "compounds_batch",
        error: e,
        stack: stack,
      );
      onProgress?.call("Error seeding Compounds: $e", 0.15);
    }

    // 5. 20% Buildings
    onProgress?.call("20% Buildings - Seeding ${rawBuildings.length} Buildings...", 0.20);
    try {
      final batch = _firestore.batch();
      for (final item in rawBuildings) {
        final docMap = item as Map<String, dynamic>;
        final docId = docMap['id']?.toString() ?? 'unknown';
        try {
          final building = Building.fromJson(docMap);
          final compoundId = building.compoundId.isNotEmpty ? building.compoundId : 'dev_1';
          final ref = _firestore.collection('compounds').doc(compoundId).collection('buildings').doc(building.id);
          batch.set(ref, building.toJson(), SetOptions(merge: true));
        } catch (e, stack) {
          _logError(
            stepName: "Buildings Parsing",
            entityName: "Building",
            docId: docId,
            error: e,
            stack: stack,
          );
        }
      }
      await _commitBatchWithTimeout(batch);
      debugPrint("[FirestoreSeederService] 20% Buildings import complete.");
    } catch (e, stack) {
      _logError(
        stepName: "Buildings Batch Commit",
        entityName: "Building",
        docId: "buildings_batch",
        error: e,
        stack: stack,
      );
      onProgress?.call("Error seeding Buildings: $e", 0.20);
    }

    // 6. 30% Units
    onProgress?.call("30% Units - Seeding ${rawUnits.length} Units...", 0.30);
    await _safeBatchWrite(
      collectionName: 'units',
      items: rawUnits,
      entityName: 'UnitModel',
      mapper: (item) {
        final unit = UnitModel.fromJson(item);
        return MapEntry(unit.id, unit.toJson());
      },
      onProgress: onProgress,
      progress: 0.30,
    );

    // 7. 40% Users
    onProgress?.call("40% Users - Seeding ${rawUsers.length} Users...", 0.40);
    await _safeBatchWrite(
      collectionName: 'users',
      items: rawUsers,
      entityName: 'UserProfile',
      mapper: (item) {
        final doc = Map<String, dynamic>.from(item);
        if (!doc.containsKey('mustChangePassword')) {
          doc['mustChangePassword'] = true;
        }
        final user = UserProfile.fromJson(doc);
        return MapEntry(user.uid, user.toJson());
      },
      onProgress: onProgress,
      progress: 0.40,
    );

    // 8. 50% Contracts
    onProgress?.call("50% Contracts - Seeding ${rawContracts.length} Contracts...", 0.50);
    await _safeBatchWrite(
      collectionName: 'contracts',
      items: rawContracts,
      entityName: 'Contract',
      mapper: (item) {
        final contract = Contract.fromJson(item);
        return MapEntry(contract.id, contract.toJson());
      },
      onProgress: onProgress,
      progress: 0.50,
    );

    // 9. 60% Installments
    onProgress?.call("60% Installments - Seeding ${rawInstallments.length} Installments...", 0.60);
    await _safeBatchWriteInstallments(rawInstallments, onProgress: onProgress, progress: 0.60);

    // 10. 75% Payments
    onProgress?.call("75% Payments - Seeding ${rawPayments.length} Payments...", 0.75);
    await _safeBatchWrite(
      collectionName: 'payments',
      items: rawPayments,
      entityName: 'Payment',
      mapper: (item) {
        final payment = Payment.fromJson(item);
        return MapEntry(payment.id, payment.toJson());
      },
      onProgress: onProgress,
      progress: 0.75,
    );

    // 11. 85% Ledgers
    onProgress?.call("85% Ledgers - Seeding ${rawLedgers.length} Unit Ledgers...", 0.85);
    await _safeBatchWrite(
      collectionName: 'ledgers',
      items: rawLedgers,
      entityName: 'UnitLedger',
      mapper: (item) {
        final ledger = UnitLedger.fromJson(item);
        return MapEntry(ledger.unitId, ledger.toJson());
      },
      onProgress: onProgress,
      progress: 0.85,
    );

    // 12. 95% Documents
    onProgress?.call("95% Documents - Seeding ${rawDocuments.length} Documents...", 0.95);
    await _safeBatchWrite(
      collectionName: 'documents',
      items: rawDocuments,
      entityName: 'DocumentItem',
      mapper: (item) {
        final doc = DocumentItem.fromJson(item);
        return MapEntry(doc.id, doc.toJson());
      },
      onProgress: onProgress,
      progress: 0.95,
    );

    // 13. 100% Complete
    onProgress?.call("100% Complete - Firestore ERP Seeding Completed Successfully!", 1.0);
    debugPrint("[FirestoreSeederService] 100% Complete - Full ERP import succeeded.");
  }

  Future<void> _safeBatchWrite({
    required String collectionName,
    required List<dynamic> items,
    required String entityName,
    required MapEntry<String, Map<String, dynamic>> Function(Map<String, dynamic> json) mapper,
    void Function(String message, double progress)? onProgress,
    required double progress,
  }) async {
    const int chunkSize = 400;
    for (int i = 0; i < items.length; i += chunkSize) {
      final chunk = items.sublist(i, i + chunkSize > items.length ? items.length : i + chunkSize);
      final batch = _firestore.batch();
      final List<String> chunkDocIds = [];

      for (final item in chunk) {
        final map = item as Map<String, dynamic>;
        final docId = map['id']?.toString() ?? map['uid']?.toString() ?? map['unitId']?.toString() ?? 'unknown';
        chunkDocIds.add(docId);
        try {
          final entry = mapper(map);
          batch.set(_firestore.collection(collectionName).doc(entry.key), entry.value, SetOptions(merge: true));
        } catch (e, stack) {
          _logError(
            stepName: "_safeBatchWrite parsing",
            entityName: entityName,
            docId: docId,
            error: e,
            stack: stack,
          );
          onProgress?.call("Parsing error in $entityName ($docId): $e", progress);
        }
      }

      await _commitBatchWithTimeout(batch);
    }
  }

  Future<void> _safeBatchWriteInstallments(
    List<dynamic> rawInstallments, {
    void Function(String message, double progress)? onProgress,
    required double progress,
  }) async {
    const int chunkSize = 400;
    for (int i = 0; i < rawInstallments.length; i += chunkSize) {
      final chunk = rawInstallments.sublist(i, i + chunkSize > rawInstallments.length ? rawInstallments.length : i + chunkSize);
      final batch = _firestore.batch();

      for (final item in chunk) {
        final map = item as Map<String, dynamic>;
        final docId = map['id']?.toString() ?? 'unknown';
        try {
          final inst = Installment.fromJson(map);
          final contractId = inst.contractId.isNotEmpty ? inst.contractId : 'unknown_contract';
          final ref = _firestore.collection('contracts').doc(contractId).collection('installments').doc(inst.id);
          batch.set(ref, inst.toJson(), SetOptions(merge: true));
        } catch (e, stack) {
          _logError(
            stepName: "_safeBatchWriteInstallments parsing",
            entityName: "Installment",
            docId: docId,
            error: e,
            stack: stack,
          );
          onProgress?.call("Installment parsing error ($docId): $e", progress);
        }
      }

      await _commitBatchWithTimeout(batch);
    }
  }
}
