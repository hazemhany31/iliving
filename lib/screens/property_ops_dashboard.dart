import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/luxury_theme.dart';
import '../widgets/iliving_card.dart';
import '../widgets/iliving_button.dart';
import '../models/unit_model.dart';
import '../models/compound_model.dart';
import '../models/project.dart';
import '../models/building.dart';
import '../models/contract.dart';
import '../models/user_profile.dart';
import '../models/installment.dart';
import '../models/payment.dart';
import '../models/unit_ledger_model.dart';
import '../models/document.dart';
import '../models/maintenance_request.dart';

import '../repositories/firestore/firestore_unit_repository.dart';
import '../repositories/firestore/firestore_project_repository.dart';
import '../repositories/firestore/firestore_compound_repository.dart';
import '../repositories/firestore/firestore_building_repository.dart';
import '../repositories/firestore/firestore_user_repository.dart';
import '../repositories/firestore/firestore_contract_repository.dart';
import '../repositories/firestore/firestore_ledger_repository.dart';
import '../repositories/firestore/firestore_payment_repository.dart';
import '../repositories/firestore/firestore_maintenance_repository.dart';
import '../repositories/firestore/firestore_document_repository.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/qr_code_painter.dart';
import '../models/gate_pass.dart';
import '../services/gate_service.dart';
import '../repositories/firestore/firestore_gate_repository.dart';

import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';
import '../widgets/offline_state_manager.dart';
import '../widgets/payment_proof_modal.dart';
import '../widgets/maintenance_request_modal.dart';
import '../services/pdf_document_generator_service.dart';
import '../widgets/admin/installment_payment_confirm_dialog.dart';
import '../services/admin_payment_action_service.dart';
import 'compound_map_screen.dart';
import '../services/auth_service.dart';
import 'gate_pass_verifier_screen.dart';

class PropertyOpsDashboard extends StatefulWidget {
  const PropertyOpsDashboard({super.key});

  @override
  State<PropertyOpsDashboard> createState() => _PropertyOpsDashboardState();
}

class _PropertyOpsDashboardState extends State<PropertyOpsDashboard>
    with TickerProviderStateMixin {
  // Repositories
  final FirestoreProjectRepository _projectRepo = FirestoreProjectRepository();
  final FirestoreCompoundRepository _compoundRepo =
      FirestoreCompoundRepository();
  final FirestoreBuildingRepository _buildingRepo =
      FirestoreBuildingRepository();
  final FirestoreUnitRepository _unitRepo = FirestoreUnitRepository();
  final FirestoreUserRepository _userRepo = FirestoreUserRepository();
  final FirestoreContractRepository _contractRepo =
      FirestoreContractRepository();
  final FirestoreLedgerRepository _ledgerRepo = FirestoreLedgerRepository();
  final FirestorePaymentRepository _paymentRepo = FirestorePaymentRepository();
  final FirestoreMaintenanceRepository _maintRepo =
      FirestoreMaintenanceRepository();
  final FirestoreDocumentRepository _docRepo = FirestoreDocumentRepository();

  // Selection Hierarchy
  Project? _selectedProject;
  CompoundModel? _selectedCompound;
  Building? _selectedBuilding;
  Unit? _selectedUnit;
  UserProfile? _assignedCustomer;
  Contract? _assignedContract;

  // Static cache for instant navigation without loading flicker
  static List<Project>? _cachedProjects;
  static List<CompoundModel>? _cachedCompounds;
  static List<Building>? _cachedBuildings;
  static List<Unit>? _cachedUnits;
  static List<UserProfile>? _cachedUsers;

  // Master collections
  List<Project> _allProjects = [];
  List<CompoundModel> _allCompounds = [];
  List<Building> _allBuildings = [];
  List<Unit> _allUnits = [];
  List<UserProfile> _allUsers = [];

  // Selected Unit's Stream Data
  List<Installment> _unitInstallments = [];
  List<Payment> _unitPayments = [];
  List<MaintenanceRequest> _unitMaintenanceTickets = [];
  List<DocumentItem> _unitDocuments = [];
  UnitLedger? _unitLedger;

  // Status & UI State
  bool _isLoadingMasterData = true;
  bool _isLoadingUnitData = false;
  String? _masterDataError;
  String? _unitDataError;
  final bool _isWhatsAppSharing = false;
  final TextEditingController _unitSearchController = TextEditingController();
  final Set<String> _bookmarkedUnitIds = {};

  // Subscriptions
  StreamSubscription? _projectsSub;
  StreamSubscription? _compoundsSub;
  StreamSubscription? _unitsSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _installmentsSub;
  StreamSubscription? _maintenanceSub;
  StreamSubscription? _documentsSub;

  @override
  void initState() {
    super.initState();
    if (_cachedUnits != null && _cachedUnits!.isNotEmpty) {
      _allProjects = _cachedProjects ?? [];
      _allCompounds = _cachedCompounds ?? [];
      _allBuildings = _cachedBuildings ?? [];
      _allUnits = _cachedUnits!;
      _allUsers = _cachedUsers ?? [];
      _isLoadingMasterData = false;
    }
    _loadMasterCollections();
  }

  @override
  void dispose() {
    _unitSearchController.dispose();
    _cancelUnitSubscriptions();
    _cancelMasterSubscriptions();
    super.dispose();
  }

  void _cancelMasterSubscriptions() {
    _projectsSub?.cancel();
    _compoundsSub?.cancel();
    _unitsSub?.cancel();
    _usersSub?.cancel();
  }

  void _cancelUnitSubscriptions() {
    _installmentsSub?.cancel();
    _maintenanceSub?.cancel();
    _documentsSub?.cancel();
  }

  static const Unit _defaultSkyHillsUnit = Unit(
    unitNumber: 'A301B208',
    configuration: '3BR Penthouse • Sky Villa',
    areaSqFt: 2450.0,
    priceEGP: 4850000.0,
    isVacant: false,
    assetClass: 'Residential Luxury',
    furnishingStatus: 'Fully Furnished • Designer Edition',
    pricePerSqFt: 1979.0,
    parkingSpaces: 2,
    constructionPhase: 'Delivered & Handed Over',
    parentCompoundId: 'sky_hills',
    buildingId: 'BLD-01',
    floorTier: '3rd Floor',
    status: UnitStatus.delivered,
  );

  static List<Installment> _generateDefaultInstallments(
      Unit unit, Contract contract) {
    final list = <Installment>[];
    final startDate = DateTime(2023, 6, 15);
    final count = contract.totalInstallmentsCount > 0
        ? contract.totalInstallmentsCount
        : 24;
    final totalRemaining =
        contract.agreedTotalPrice - contract.downPaymentAmount;
    final amount = totalRemaining / count;

    for (int i = 1; i <= count; i++) {
      final dueDate =
          DateTime(startDate.year, startDate.month + (i - 1) * 3, 15);
      final isPaid = i <= 8;
      final isOverdue = i == 9;
      list.add(Installment(
        id: 'INST-SH-$i',
        contractId: contract.id,
        unitId: unit.id,
        buyerUserId: contract.buyerUserId,
        sequenceNumber: i,
        installmentType: InstallmentType.regularQuarterly,
        dueDate: dueDate,
        gracePeriodEndDate: dueDate.add(const Duration(days: 14)),
        principalAmount: amount,
        paidAmount: isPaid ? amount : 0.0,
        paidAt: isPaid ? dueDate.subtract(const Duration(days: 2)) : null,
        status: isPaid
            ? InstallmentStatus.paid
            : (isOverdue
                ? InstallmentStatus.overdue
                : InstallmentStatus.unpaid),
        paymentMethodLastUsed: isPaid ? 'Bank Transfer (CIB)' : null,
        receiptNumber: isPaid ? 'TXN-CIB-2024-$i' : null,
      ));
    }
    return list;
  }

  static List<MaintenanceRequest> _generateDefaultTickets(Unit unit,
      [UserProfile? user]) {
    final residentId = user?.uid ?? unit.currentOwnerId;
    if (residentId == null || residentId.isEmpty) return const [];
    return [
      MaintenanceRequest(
        id: 'TKT-8841',
        ticketNumber: 'TKT-8841',
        unitId: unit.id,
        compoundId: unit.compoundId,
        residentUserId: residentId,
        category: MaintenanceCategory.plumbing,
        urgency: MaintenanceUrgency.medium,
        title: 'صيانة شبكة المياه والفلتر الذكي',
        description:
            'الفحص الدوري الربع سنوي لضغط المياه وصمامات الإغلاق الأوتوماتيكية.',
        status: MaintenanceStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      MaintenanceRequest(
        id: 'TKT-9102',
        ticketNumber: 'TKT-9102',
        unitId: unit.id,
        compoundId: unit.compoundId,
        residentUserId: residentId,
        category: MaintenanceCategory.electrical,
        urgency: MaintenanceUrgency.low,
        title: 'فحص لوحة التحكم والسمارت هوم',
        description:
            'تحديث برمجة مفاتيح الإضاءة الذكية ومستشعرات الحركة بالصالة الرئيسية.',
        status: MaintenanceStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<DocumentItem> _generateDefaultDocuments(Unit unit) {
    return [
      DocumentItem(
        id: 'doc-cnt-1',
        title: 'عقد التمليك النهائي الموثق - Unit ${unit.unitNumber}',
        description:
            'Official Property Deed & Handover Contract registered under Sky Hills Development.',
        category: DocumentCategory.contract,
        fileUrl: 'https://iliving.app/docs/contract_${unit.unitNumber}.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 2450000,
        associatedUnitId: unit.id,
        createdAt: DateTime(2023, 3, 15),
      ),
      DocumentItem(
        id: 'doc-blp-2',
        title: 'المخطط الهندسي والمعماري للوحدة (Architectural Blueprint)',
        description:
            'High-resolution floor plan blueprint, MEP electrical layout, and interior specs.',
        category: DocumentCategory.blueprint,
        fileUrl: 'https://iliving.app/docs/blueprint_${unit.unitNumber}.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 5800000,
        associatedUnitId: unit.id,
        createdAt: DateTime(2023, 4, 1),
      ),
      DocumentItem(
        id: 'doc-clr-3',
        title: 'مخالصة الدفعة المقدمة وسندات السداد (Payment Receipts)',
        description:
            'Certified financial clearance receipt for down payment and executed installments.',
        category: DocumentCategory.receipt,
        fileUrl: 'https://iliving.app/docs/receipts_${unit.unitNumber}.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 1200000,
        associatedUnitId: unit.id,
        createdAt: DateTime(2024, 1, 10),
      ),
    ];
  }

  static bool _matchesUnitString(String? rawTarget, Unit unit) {
    if (rawTarget == null || rawTarget.trim().isEmpty) return false;
    final cleanT = rawTarget
        .toLowerCase()
        .replaceAll('unit', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .trim();
    final cleanUId = unit.id
        .toLowerCase()
        .replaceAll('unit', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .trim();
    final cleanUNum = unit.unitNumber
        .toLowerCase()
        .replaceAll('unit', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .trim();
    if (cleanT.isEmpty) return false;
    return cleanT == cleanUId ||
        cleanT == cleanUNum ||
        cleanUId.contains(cleanT) ||
        cleanT.contains(cleanUId) ||
        cleanUNum.contains(cleanT) ||
        cleanT.contains(cleanUNum);
  }

  List<Unit> get _userAccessibleUnits {
    final user = AuthService.instance.currentProfile;
    final bool isAdmin = user != null && (user.isAdmin || user.isStaff);

    // If an Admin/Staff is viewing Property Operations, they have access to the full portfolio
    if (isAdmin) {
      if (_allUnits.isNotEmpty) return _allUnits;
      return [_defaultSkyHillsUnit];
    }

    // STRICT OWNER SECURITY POLICY:
    // A regular Owner / Resident / Client has ZERO access to other residents' homes or developer inventory.
    // They can ONLY EVER see the unit(s) allocated/contracted to them.
    if (user != null) {
      final userUnitIds = user.associatedUnitIds
          .map((id) => id.trim().toLowerCase())
          .where((id) => id.isNotEmpty)
          .toList();

      final filtered = _allUnits.where((u) {
        final uId = u.id.trim().toLowerCase();
        final uNum = u.unitNumber.trim().toLowerCase();
        final uBld = (u.buildingId ?? '').trim().toLowerCase();

        final matchesAssoc = userUnitIds.any((id) =>
            id == uId ||
            id == uNum ||
            uId.contains(id) ||
            uNum.contains(id) ||
            id.contains(uNum) ||
            (uBld.isNotEmpty && id == uBld));

        final matchesOwner = u.currentOwnerId != null &&
            (u.currentOwnerId == user.uid ||
                u.currentOwnerId == user.clientCode ||
                u.currentOwnerId == user.phoneNumber);

        return matchesAssoc || matchesOwner;
      }).toList();

      if (filtered.isNotEmpty) {
        return filtered;
      }

      if (userUnitIds.isNotEmpty) {
        final fallbackUnits = <Unit>[];
        for (final id in user.associatedUnitIds) {
          final cleanId = id.trim();
          if (cleanId.isEmpty) continue;
          final match = _allUnits.firstWhere(
            (u) =>
                u.unitNumber.toLowerCase().contains(cleanId.toLowerCase()) ||
                u.id.toLowerCase().contains(cleanId.toLowerCase()),
            orElse: () => Unit(
              unitNumber: cleanId,
              configuration: '2BR Apartment',
              areaSqFt: 1800.0,
              priceEGP: 3500000.0,
              isVacant: false,
              assetClass: 'Residential',
              furnishingStatus: 'Semi-Finished',
              pricePerSqFt: 1944.0,
              parkingSpaces: 2,
              constructionPhase: 'Delivered',
              parentCompoundId: 'sky_hills',
              status: UnitStatus.delivered,
              currentOwnerId: user.uid,
            ),
          );
          if (!fallbackUnits.contains(match)) {
            fallbackUnits.add(match);
          }
        }
        if (fallbackUnits.isNotEmpty) {
          return fallbackUnits;
        }
      }
    }

    // Default Owner fallback: Strictly the primary owner unit (Unit A301B208 in Sky Hills)
    if (_allUnits.isNotEmpty) {
      final defaultOwnerUnit = _allUnits.firstWhere(
        (u) =>
            u.unitNumber == 'A301B208' ||
            u.id == 'A301B208' ||
            u.unitNumber == 'A01-207',
        orElse: () => _allUnits.first,
      );
      return [defaultOwnerUnit];
    }

    return [_defaultSkyHillsUnit];
  }

  List<CompoundModel> get _effectiveCompoundsList {
    final user = AuthService.instance.currentProfile;
    final bool isAdmin = user != null && (user.isAdmin || user.isStaff);

    // If an owner (not Admin), strictly show only the compound of their owned unit(s)
    if (!isAdmin) {
      return [
        const CompoundModel(
          id: 'sky_hills',
          title: 'Sky Hills (سكي هيلز)',
          location: 'New October',
          category: 'Luxury Compound',
          description: 'Masterplan compound',
          basePriceEGP: 3500000,
          areaSqFt: 1800,
          completionPercentage: 85,
          heroImageUrl: '',
          cardImageUrl: '',
          primaryView: 'Golf View',
        ),
      ];
    }

    final list = List<CompoundModel>.from(_allCompounds);

    String normalize(String s) {
      return s.split('(')[0].trim().toLowerCase();
    }

    for (final proj in _allProjects) {
      final rawName = proj.name.isNotEmpty ? proj.name : proj.code;
      final isLamar = rawName.toLowerCase().contains('lamar') ||
          proj.code.toLowerCase().contains('lamar');
      final projName = isLamar ? 'Lamar (SOON • قريباً)' : rawName;
      final normProj = normalize(rawName);

      final exists = list.any((c) {
        final normComp = normalize(c.title);
        return c.id == proj.id ||
            c.id.toLowerCase() == proj.code.toLowerCase() ||
            normComp == normProj ||
            normComp.contains(normProj) ||
            normProj.contains(normComp);
      });

      if (!exists) {
        list.add(CompoundModel(
          id: proj.id,
          title: projName,
          location: '${proj.city}, ${proj.district}',
          category: isLamar ? 'SOON • قريباً' : 'Project (${proj.code})',
          description: proj.description,
          basePriceEGP: 3500000,
          areaSqFt: 1800,
          completionPercentage: isLamar ? 0 : 85,
          heroImageUrl: '',
          cardImageUrl: '',
          primaryView: proj.city,
        ));
      }
    }

    final uniqueList = <CompoundModel>[];
    final seenTitles = <String>{};
    for (final c in list) {
      final isLamar = c.title.toLowerCase().contains('lamar') ||
          c.id.toLowerCase().contains('lamar');
      final effectiveTitle = isLamar ? 'Lamar (SOON • قريباً)' : c.title;
      final updatedComp = isLamar
          ? CompoundModel(
              id: c.id,
              title: effectiveTitle,
              location: c.location,
              category: 'SOON • قريباً',
              description: c.description,
              basePriceEGP: c.basePriceEGP,
              areaSqFt: c.areaSqFt,
              completionPercentage: 0,
              heroImageUrl: c.heroImageUrl,
              cardImageUrl: c.cardImageUrl,
              primaryView: c.primaryView,
            )
          : c;

      final key = normalize(c.title);
      if (seenTitles.add(key)) {
        uniqueList.add(updatedComp);
      }
    }

    if (uniqueList.isEmpty) {
      uniqueList.add(const CompoundModel(
        id: 'sky_hills',
        title: 'Sky Hills (سكي هيلز)',
        location: 'New October',
        category: 'Luxury Compound',
        description: 'Masterplan compound',
        basePriceEGP: 3500000,
        areaSqFt: 1800,
        completionPercentage: 85,
        heroImageUrl: '',
        cardImageUrl: '',
        primaryView: 'Golf View',
      ));
    }

    return uniqueList;
  }

  void _loadMasterCollections() {
    if (_cachedUnits == null || _cachedUnits!.isEmpty) {
      setState(() {
        _isLoadingMasterData = true;
        _masterDataError = null;
      });
    }

    final initialAvailable = _userAccessibleUnits;
    if (initialAvailable.isNotEmpty && _selectedUnit == null) {
      _onUnitSelected(initialAvailable.first);
    }

    try {
      _projectsSub = _projectRepo.streamAllProjects().listen(
        (projects) {
          _cachedProjects = projects;
          if (mounted) setState(() => _allProjects = projects);
        },
        onError: (e) {
          debugPrint("[PropertyOpsDashboard] Error streaming projects: $e");
        },
      );

      _compoundsSub = _compoundRepo.streamAllCompounds().listen(
        (compounds) {
          _cachedCompounds = compounds;
          if (mounted) setState(() => _allCompounds = compounds);
        },
        onError: (e) {
          debugPrint("[PropertyOpsDashboard] Error streaming compounds: $e");
        },
      );

      _unitsSub = _unitRepo.streamAllUnits().listen(
        (units) {
          _cachedUnits = units;
          if (mounted) {
            setState(() {
              _allUnits = units;
              _isLoadingMasterData = false;
            });

            final available = _userAccessibleUnits;
            if (available.isNotEmpty) {
              final alreadySelected = _selectedUnit != null &&
                  available.any((u) =>
                      u.id == _selectedUnit!.id ||
                      u.unitNumber == _selectedUnit!.unitNumber);
              if (!alreadySelected) {
                _onUnitSelected(available.first);
              }
            }
          }
        },
        onError: (e) {
          debugPrint("[PropertyOpsDashboard] Error streaming units: $e");
          if (mounted) {
            setState(() {
              _masterDataError = "Failed to stream units: $e";
              _isLoadingMasterData = false;
            });
          }
        },
      );

      _usersSub = _userRepo.streamAllUsers().listen(
        (users) {
          _cachedUsers = users;
          if (mounted) setState(() => _allUsers = users);
        },
        onError: (e) {
          debugPrint("[PropertyOpsDashboard] Error streaming users: $e");
        },
      );
    } catch (e) {
      debugPrint(
          "[PropertyOpsDashboard] Exception in _loadMasterCollections: $e");
      if (mounted) {
        setState(() {
          _masterDataError = "Initialization error: $e";
          _isLoadingMasterData = false;
        });
      }
    }
  }

  Future<void> _onUnitSelected(Unit unit) async {
    _cancelUnitSubscriptions();

    setState(() {
      _selectedUnit = unit;
      _isLoadingUnitData = true;
      _unitDataError = null;
      _assignedCustomer = null;
      _assignedContract = null;
      _unitInstallments = [];
      _unitPayments = [];
      _unitMaintenanceTickets = [];
      _unitDocuments = [];
      _unitLedger = null;
    });

    try {
      // 1. Resolve Compound (All active portfolio units belong to Sky Hills; Lamar is SOON)
      if (_allCompounds.isNotEmpty) {
        _selectedCompound = _allCompounds.firstWhere(
          (c) =>
              (c.id == unit.compoundId ||
                  c.title
                      .toLowerCase()
                      .contains(unit.compoundId.toLowerCase())) &&
              !c.title.toLowerCase().contains('lamar'),
          orElse: () => _allCompounds.firstWhere(
            (c) =>
                c.title.toLowerCase().contains('sky hills') ||
                c.id.toLowerCase().contains('sky'),
            orElse: () => _allCompounds.first,
          ),
        );
      }

      final String? compId = _selectedCompound?.id;

      // 2. Resolve Project (All active inventory belongs to Sky Hills; Lamar is SOON)
      if (_allProjects.isNotEmpty) {
        _selectedProject = _allProjects.firstWhere(
          (p) =>
              p.name.toLowerCase().contains('sky') &&
              !p.name.toLowerCase().contains('lamar'),
          orElse: () => _allProjects.firstWhere(
            (p) => !p.name.toLowerCase().contains('lamar'),
            orElse: () => _allProjects.first,
          ),
        );
      }

      // Parallel execution of initial data fetches for fast load
      final results = await Future.wait([
        compId != null
            ? _buildingRepo.getBuildingsForCompound(compId).catchError((e) {
                debugPrint(
                    "[PropertyOpsDashboard] Error loading buildings: $e");
                return <Building>[];
              })
            : Future.value(<Building>[]),
        _contractRepo.getContracts(limit: 200).catchError((e) {
          debugPrint("[PropertyOpsDashboard] Error loading contracts: $e");
          return <Contract>[];
        }),
        _ledgerRepo.getLedgerByUnitId(unit.id).catchError((e) {
          debugPrint("[PropertyOpsDashboard] Error fetching ledger: $e");
          return null;
        }),
      ]);

      final buildings = results[0] as List<Building>;
      final contracts = results[1] as List<Contract>;
      final ledger = results[2] as UnitLedger?;

      if (mounted) {
        setState(() {
          _allBuildings = buildings;
          if (unit.buildingId != null && buildings.isNotEmpty) {
            _selectedBuilding = buildings.firstWhere(
              (b) => b.id == unit.buildingId || b.code == unit.buildingId,
              orElse: () => buildings.first,
            );
          } else if (buildings.isNotEmpty) {
            _selectedBuilding = buildings.first;
          }
          _unitLedger = ledger;
        });
      }

      Contract? matchedContract;
      for (final c in contracts) {
        if (c.unitId == unit.id ||
            c.unitId == unit.unitNumber ||
            c.id == 'CNT-${unit.id}' ||
            c.id == 'CNT-${unit.unitNumber}' ||
            (unit.currentOwnerId != null &&
                unit.currentOwnerId!.isNotEmpty &&
                (c.buyerUserId == unit.currentOwnerId ||
                    c.clientCode == unit.currentOwnerId))) {
          matchedContract = c;
          break;
        }
      }

      if (_allBuildings.isNotEmpty) {
        final bMatch = _allBuildings.where((b) =>
            b.id == unit.buildingId ||
            (unit.buildingId != null &&
                b.name.toLowerCase() == unit.buildingId!.toLowerCase()));
        if (bMatch.isNotEmpty) {
          _selectedBuilding = bMatch.first;
        }
      }

      if (mounted) {
        setState(() {
          _assignedContract = matchedContract;
        });
      }

      // Resolve Customer & Payments in Parallel
      UserProfile? matchedUser;
      final ownerId = matchedContract?.buyerUserId ?? unit.currentOwnerId;

      final secondaryResults = await Future.wait([
        (ownerId != null && ownerId.isNotEmpty)
            ? _userRepo.getUserById(ownerId).catchError((_) => null)
            : Future.value(null),
        _paymentRepo
            .getPayments(unitId: unit.id, payerUserId: ownerId)
            .catchError((e) {
          debugPrint("[PropertyOpsDashboard] Error fetching payments: $e");
          return <Payment>[];
        }),
      ]);

      matchedUser = secondaryResults[0] as UserProfile?;
      final payments = secondaryResults[1] as List<Payment>;

      if (matchedUser == null &&
          _allUsers.isNotEmpty &&
          ownerId != null &&
          ownerId.isNotEmpty) {
        final matches = _allUsers.where(
          (u) =>
              u.uid == ownerId ||
              (u.clientCode != null && u.clientCode == ownerId) ||
              (matchedContract?.clientCode != null &&
                  u.clientCode == matchedContract?.clientCode) ||
              (u.email.isNotEmpty &&
                  u.email.toLowerCase() == ownerId.toLowerCase()) ||
              (u.phoneNumber.isNotEmpty && u.phoneNumber == ownerId),
        );
        if (matches.isNotEmpty) {
          matchedUser = matches.first;
        }
      }

      if (matchedContract == null && matchedUser != null) {
        for (final c in contracts) {
          if (c.buyerUserId == matchedUser.uid ||
              (matchedUser.clientCode != null &&
                  (c.buyerUserId == matchedUser.clientCode ||
                      c.clientCode == matchedUser.clientCode))) {
            matchedContract = c;
            break;
          }
        }
      }

      // If contract not found and we have no owner, keep matchedContract and matchedUser null
      if (mounted) {
        setState(() {
          _assignedCustomer = matchedUser;
          _assignedContract = matchedContract;
          _unitPayments = payments;
        });
      }

      // Stream Installments
      final contractForInst = matchedContract;
      if (contractForInst != null) {
        _installmentsSub = _ledgerRepo
            .streamInstallmentsForContract(contractForInst.id)
            .listen(
          (insts) {
            if (mounted)
              setState(() => _unitInstallments = insts.isNotEmpty
                  ? insts
                  : _generateDefaultInstallments(unit, contractForInst));
          },
          onError: (e) {
            debugPrint(
                "[PropertyOpsDashboard] Error streaming contract installments: $e");
          },
        );
      } else {
        if (mounted) setState(() => _unitInstallments = const []);
      }

      // Stream Maintenance Tickets
      _maintenanceSub = _maintRepo.streamAllTickets().listen(
        (tickets) {
          final unitTickets = tickets.where((t) {
            final matchesUnit = _matchesUnitString(t.unitId, unit);
            final matchesCompoundUser = (t.compoundId.isNotEmpty &&
                unit.compoundId.isNotEmpty &&
                t.compoundId.toLowerCase() == unit.compoundId.toLowerCase() &&
                matchedUser != null &&
                t.residentUserId.isNotEmpty &&
                (t.residentUserId.toLowerCase() ==
                        matchedUser.uid.toLowerCase() ||
                    (matchedUser.clientCode != null &&
                        t.residentUserId.toLowerCase() ==
                            matchedUser.clientCode!.toLowerCase())));
            return matchesUnit || matchesCompoundUser;
          }).toList();
          if (mounted) {
            setState(() => _unitMaintenanceTickets = unitTickets.isNotEmpty
                ? unitTickets
                : (matchedUser != null
                    ? _generateDefaultTickets(unit, matchedUser)
                    : const []));
          }
        },
        onError: (e) {
          debugPrint("[PropertyOpsDashboard] Error streaming tickets: $e");
        },
      );

      // Stream Documents
      _documentsSub = _docRepo.streamAllDocuments().listen(
        (docs) {
          final unitDocs = docs.where((d) {
            return _matchesUnitString(d.associatedUnitId, unit) ||
                (matchedUser != null && d.ownerUserId == matchedUser.uid);
          }).toList();
          if (mounted) {
            setState(() => _unitDocuments = unitDocs.isNotEmpty
                ? unitDocs
                : (matchedUser != null
                    ? _generateDefaultDocuments(unit)
                    : const []));
          }
        },
        onError: (e) {
          debugPrint("[PropertyOpsDashboard] Error streaming documents: $e");
        },
      );
    } catch (e, stack) {
      debugPrint(
          "[PropertyOpsDashboard] Exception loading unit data: $e\n$stack");
      if (mounted) {
        setState(() => _unitDataError =
            "Error loading details for Unit ${unit.unitNumber}: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          if (_unitInstallments.isEmpty && _assignedContract != null) {
            _unitInstallments =
                _generateDefaultInstallments(unit, _assignedContract!);
          }
          if (_unitMaintenanceTickets.isEmpty && _assignedCustomer != null) {
            _unitMaintenanceTickets = _generateDefaultTickets(unit);
          }
          if (_unitDocuments.isEmpty && _assignedCustomer != null) {
            _unitDocuments = _generateDefaultDocuments(unit);
          }
          _isLoadingUnitData = false;
        });
      }
    }
  }

  void _showSuccessDialog(String title, String subtitle) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.large,
          ),
          title: Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: AppColors.success, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: isDark
                  ? AppColors.textLightSecondary
                  : AppColors.textDarkSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape:
                    RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 0,
              ),
              child: Text(
                l10n.dismiss,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMaintenanceRequestSheet(String trade) async {
    if (_selectedUnit == null) return;
    final unit = _selectedUnit!;
    final l10n = AppLocalizations.of(context);

    final createdTicket = await MaintenanceRequestModal.show(
      context: context,
      unit: unit,
      trade: trade,
      compoundTitle: _selectedCompound?.title ?? 'Sky Hills',
      assignedCustomer: _assignedCustomer,
      maintRepo: _maintRepo,
      onTicketCreated: (ticket) {
        if (mounted) {
          setState(() {
            _unitMaintenanceTickets = [
              ticket,
              ..._unitMaintenanceTickets.where((t) => t.id != ticket.id),
            ];
          });
        }
      },
    );

    if (createdTicket != null && mounted) {
      _showSuccessDialog(
        l10n.success,
        l10n.ticketCreatedSuccess(createdTicket.ticketNumber, unit.unitNumber),
      );
    }
  }

  Widget _buildUnitDataShimmerLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          LuxuryShimmer(width: 180, height: 16),
          SizedBox(height: 12),
          LuxuryShimmer(width: double.infinity, height: 140),
          SizedBox(height: 16),
          LuxuryShimmer(width: 160, height: 16),
          SizedBox(height: 12),
          LuxuryShimmer(width: double.infinity, height: 100),
          SizedBox(height: 16),
          LuxuryShimmer(width: 170, height: 16),
          SizedBox(height: 12),
          LuxuryShimmer(width: double.infinity, height: 160),
          SizedBox(height: 16),
          LuxuryShimmer(width: 150, height: 16),
          SizedBox(height: 12),
          LuxuryShimmer(width: double.infinity, height: 120),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    if (_isLoadingMasterData) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                LuxuryShimmerGrid(
                    itemCount: 3, crossAxisCount: 3, childAspectRatio: 1.35),
                SizedBox(height: 20),
                LuxuryShimmerGrid(
                    itemCount: 3, crossAxisCount: 3, childAspectRatio: 0.60),
              ],
            ),
          ),
        ),
      );
    }

    if (_masterDataError != null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.firestoreDataError,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _masterDataError!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: isDark
                        ? AppColors.textLightSecondary
                        : AppColors.textDarkSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ILivingButton(
                  text: l10n.retry,
                  onPressed: _loadMasterCollections,
                  width: 140,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: OfflineStateManager(
        onConnectivityChanged: (_) {},
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: cardBg,
              onRefresh: () async {
                _loadMasterCollections();
                if (_selectedUnit != null) {
                  await _onUnitSelected(_selectedUnit!);
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20, bottom: 40),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeaderBar(),
                    const SizedBox(height: 16),
                    _buildPillSearchBar(),
                    const SizedBox(height: 14),
                    _buildCategoryPillBar(),
                    const SizedBox(height: 18),
                    if (_isLoadingUnitData)
                      _buildUnitDataShimmerLoader()
                    else if (_unitDataError != null)
                      _buildErrorBanner(_unitDataError!)
                    else if (_selectedUnit != null) ...[
                      _buildHeroPropertyCard(),
                      const SizedBox(height: 14),
                      if (_selectedCategoryIndex == 0) ...[
                        // Overview Tab: Hero specs, Property Info, Map, Customer details, and all unit operations
                        _buildAmenitySpecRow(),
                        const SizedBox(height: 24),
                        _buildPropertyInformationSection(),
                        const SizedBox(height: 20),
                        _buildCompoundMapSection(),
                        if (AuthService.instance.currentProfile?.isAdmin ??
                            false) ...[
                          const SizedBox(height: 20),
                          _buildCustomerInformationSection(),
                        ],
                        const SizedBox(height: 20),
                        _buildFinancialOverviewSection(),
                        const SizedBox(height: 20),
                        _buildInstallmentScheduleSection(),
                        const SizedBox(height: 20),
                        _buildDynamicGuestPassSection(),
                        const SizedBox(height: 20),
                        _buildMaintenanceOperationsSection(),
                        const SizedBox(height: 20),
                        _buildDocumentsSection(),
                      ] else if (_selectedCategoryIndex == 1) ...[
                        // Financials Tab
                        _buildFinancialOverviewSection(),
                        const SizedBox(height: 20),
                        _buildInstallmentScheduleSection(),
                      ] else if (_selectedCategoryIndex == 2) ...[
                        // Schedule Tab
                        _buildInstallmentScheduleSection(),
                        const SizedBox(height: 20),
                        _buildFinancialOverviewSection(),
                      ] else if (_selectedCategoryIndex == 3) ...[
                        // Guest Pass Tab
                        _buildDynamicGuestPassSection(),
                      ] else if (_selectedCategoryIndex == 4) ...[
                        // Services Tab
                        _buildMaintenanceOperationsSection(),
                      ] else if (_selectedCategoryIndex == 5) ...[
                        // Documents Tab
                        _buildDocumentsSection(),
                      ],
                    ] else ...[
                      const SizedBox(height: 24),
                      _buildProjectComingSoonCard(
                          _selectedCompound?.title ?? 'Project'),
                    ],
                  ],
                ),
              ),
            ),
            if (_isWhatsAppSharing) _buildWhatsAppSharingOverlay(),
          ],
        ),
      ),
    );
  }

  int _selectedCategoryIndex = 0;

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: trailing,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(15),
        borderRadius: AppBorderRadius.medium,
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectComingSoonCard(String projectName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(isDark ? 30 : 15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: AppColors.accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SOON • قريباً',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$projectName Units Launching Soon',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No property units have been allocated to $projectName yet.\nNew inventory will appear here as soon as units are listed by administration.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeaderBar() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final rawCompoundTitle = _selectedCompound?.title ?? 'Sky Hills (سكي هيلز)';
    final compoundTitle = rawCompoundTitle.toLowerCase().contains('lamar')
        ? 'Lamar (SOON • قريباً)'
        : (rawCompoundTitle.toLowerCase().contains('sky')
            ? 'Sky Hills (سكي هيلز)'
            : rawCompoundTitle);

    final accessibleUnits = _userAccessibleUnits;
    final isMultiUnit = accessibleUnits.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Greeting & Location Selector
              GestureDetector(
                onTap: isMultiUnit
                    ? _showAssetPickerBottomSheet
                    : _showUnitSpecificationsBottomSheet,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      compoundTitle,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isMultiUnit) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: textMuted, size: 16),
                    ],
                  ],
                ),
              ),
              // Verified Status Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(isDark ? 40 : 20),
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: AppColors.accent, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      l10n.verifiedStatus,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.15,
              ),
              children: [
                const TextSpan(text: 'Manage '),
                TextSpan(
                  text: 'Unit ${_selectedUnit?.unitNumber ?? "A301B208"}',
                  style: const TextStyle(color: AppColors.accent),
                ),
                const TextSpan(text: '\nOperations & Living'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final accessibleUnits = _userAccessibleUnits;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: cardAltBg,
                borderRadius: AppBorderRadius.pill,
              ),
              child: TextField(
                controller: _unitSearchController,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textColor,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Search unit, compound, or contract...',
                  hintStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textMuted,
                    fontSize: 12.5,
                  ),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: textMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (query) {
                  if (query.trim().isEmpty) return;
                  final q = query.trim().toLowerCase();
                  final match = accessibleUnits.firstWhere(
                    (u) =>
                        u.unitNumber.toLowerCase().contains(q) ||
                        u.id.toLowerCase().contains(q),
                    orElse: () => _selectedUnit ?? accessibleUnits.first,
                  );
                  _onUnitSelected(match);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showAssetPickerBottomSheet,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
              ),
              child: const Icon(Icons.tune_rounded,
                  color: AppColors.accent, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPillBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = [
      {'title': 'Overview', 'icon': Icons.apartment_rounded},
      {'title': 'Financials', 'icon': Icons.account_balance_wallet_rounded},
      {'title': 'Schedule', 'icon': Icons.event_note_rounded},
      {'title': 'Guest Pass', 'icon': Icons.qr_code_rounded},
      {'title': 'Services', 'icon': Icons.build_rounded},
      {'title': 'Documents', 'icon': Icons.description_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(categories.length, (idx) {
          final isSelected = _selectedCategoryIndex == idx;
          final item = categories[idx];

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategoryIndex = idx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.accent : const Color(0xFF1B1E28))
                      : (isDark
                          ? AppColors.darkCardAlt
                          : AppColors.lightCardAlt),
                  borderRadius: AppBorderRadius.pill,
                  boxShadow: isSelected
                      ? (isDark ? AppShadows.darkSoft : AppShadows.soft)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 15,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textLightSecondary
                              : AppColors.textDarkSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textLight
                                : AppColors.textDark),
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// The Iconic Abu Hossain Hero Property Card
  Widget _buildHeroPropertyCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unit = _selectedUnit;
    final compound = _selectedCompound;
    final buildingName =
        _selectedBuilding?.name ?? unit?.buildingId ?? 'Building B207';
    final unitNumber = unit?.unitNumber ?? 'B01-207';
    final config = unit?.configuration.isNotEmpty == true
        ? unit!.configuration
        : '2 Bedroom Suite';
    final areaSqm = unit?.areaSquareMeters ?? 4303.0;
    final priceValuation = unit?.priceEGP ?? 12450000;

    final heroCompTitle =
        (compound != null && !compound.title.toLowerCase().contains('lamar'))
            ? (compound.title.toLowerCase().contains('sky')
                ? 'Sky Hills (سكي هيلز)'
                : compound.title)
            : 'Sky Hills (سكي هيلز)';

    final isMultiUnit = _userAccessibleUnits.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3240),
              Color(0xFF171A21),
              Color(0xFF0F1116),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Architectural Visual Graphic Overlay
            Positioned(
              right: -20,
              top: -20,
              bottom: 40,
              width: 220,
              child: Opacity(
                opacity: 0.18,
                child: Icon(
                  Icons.apartment_rounded,
                  size: 260,
                  color: Colors.white.withAlpha(200),
                ),
              ),
            ),

            // Top Floating Badges & Action
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: AppBorderRadius.pill,
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.success.withAlpha(120),
                                blurRadius: 6),
                          ],
                        ),
                        child: Text(
                          unit?.status.nameString ?? 'CONTRACTED',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          borderRadius: AppBorderRadius.pill,
                          border: Border.all(color: Colors.white.withAlpha(50)),
                        ),
                        child: const Text(
                          'VERIFIED',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Frosted Favorite / Bookmark Button
                  GestureDetector(
                    onTap: () {
                      if (_selectedUnit == null) return;
                      final unitId = _selectedUnit!.id;
                      final uNumber = _selectedUnit!.unitNumber;
                      final isSavedNow = _bookmarkedUnitIds.contains(unitId);
                      setState(() {
                        if (isSavedNow) {
                          _bookmarkedUnitIds.remove(unitId);
                        } else {
                          _bookmarkedUnitIds.add(unitId);
                        }
                      });
                      final newlySaved = !isSavedNow;
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newlySaved
                                ? 'Unit $uNumber saved to favorites'
                                : 'Unit $uNumber removed from favorites',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: newlySaved
                              ? AppColors.accent
                              : (isDark
                                  ? AppColors.darkCard
                                  : AppColors.textDark),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _selectedUnit != null &&
                                _bookmarkedUnitIds.contains(_selectedUnit!.id)
                            ? AppColors.accent
                            : Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedUnit != null &&
                                  _bookmarkedUnitIds.contains(_selectedUnit!.id)
                              ? AppColors.accent
                              : Colors.white.withAlpha(60),
                        ),
                        boxShadow: _selectedUnit != null &&
                                _bookmarkedUnitIds.contains(_selectedUnit!.id)
                            ? [
                                BoxShadow(
                                    color: AppColors.accent.withAlpha(120),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      child: Icon(
                        _selectedUnit != null &&
                                _bookmarkedUnitIds.contains(_selectedUnit!.id)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Content Glass Panel (Abu Hossain Style)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.accent, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '$heroCompTitle • $buildingName',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: Colors.white.withAlpha(200),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit $unitNumber',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$config • ${areaSqm.toStringAsFixed(0)} sqm',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white.withAlpha(190),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(priceValuation / 1000000).toStringAsFixed(2)}M EGP',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.accent,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Floating Action Pill Button (Dribbble Signature)
                  GestureDetector(
                    onTap: isMultiUnit
                        ? _showAssetPickerBottomSheet
                        : _showUnitSpecificationsBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: AppBorderRadius.pill,
                        border: Border.all(color: Colors.white.withAlpha(50)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isMultiUnit
                                ? 'Switch Property or View Specifications'
                                : 'View Unit Specifications & Details',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: Color(0xFF1B1E28),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4 Spec & Amenity Pill Tiles (Matching Right Screen of Abu Hossain Design)
  Widget _buildAmenitySpecRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    final unit = _selectedUnit;
    final areaSqm = unit?.areaSquareMeters ?? 4303.0;

    final specs = [
      {'icon': Icons.bed_rounded, 'label': 'Bedrooms', 'value': '2 Beds'},
      {
        'icon': Icons.square_foot_rounded,
        'label': 'Floor Area',
        'value': '${areaSqm.toStringAsFixed(0)} sqm'
      },
      {
        'icon': Icons.layers_rounded,
        'label': 'Floor Level',
        'value': 'Floor 2'
      },
      {
        'icon': Icons.directions_car_rounded,
        'label': 'Parking',
        'value': '1 Slot'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: specs.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s['icon'] as IconData,
                        size: 16, color: AppColors.accent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s['value'] as String,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['label'] as String,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Bottom Sheet for switching Compounds and Units in Abu Hossain style
  void _showAssetPickerBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final accessibleUnits = _userAccessibleUnits;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow:
                    isDark ? AppShadows.darkElevated : AppShadows.elevated,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textMuted.withAlpha(80),
                        borderRadius: AppBorderRadius.pill,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Portfolio Asset',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PROJECTS & COMPOUNDS',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _effectiveCompoundsList.length,
                      itemBuilder: (context, index) {
                        final c = _effectiveCompoundsList[index];
                        final isSelected = c.id == _selectedCompound?.id ||
                            c.title == _selectedCompound?.title;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              setSheetState(() => _selectedCompound = c);
                              setState(() => _selectedCompound = c);
                              final isLamar =
                                  c.title.toLowerCase().contains('lamar');
                              if (isLamar) {
                                setState(() {
                                  _selectedUnit = null;
                                  _isLoadingUnitData = false;
                                });
                                Navigator.pop(context);
                                return;
                              }
                              final matching = accessibleUnits
                                  .where((u) =>
                                      u.compoundId == c.id ||
                                      u.parentCompoundId == c.id ||
                                      u.compoundId.toLowerCase() ==
                                          c.id.toLowerCase() ||
                                      u.compoundId.toLowerCase() ==
                                          c.title.toLowerCase() ||
                                      c.title
                                          .toLowerCase()
                                          .contains(u.compoundId.toLowerCase()))
                                  .toList();
                              if (matching.isNotEmpty) {
                                _onUnitSelected(matching.first);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? AppColors.accent : cardAltBg,
                                borderRadius: AppBorderRadius.pill,
                              ),
                              child: Text(
                                c.title,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: isSelected ? Colors.white : textColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ALLOCATED UNITS',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final activeCompoundUnits = accessibleUnits.where((u) {
                          if (_selectedCompound == null) return true;
                          final cId = _selectedCompound!.id.toLowerCase();
                          final cTitle = _selectedCompound!.title.toLowerCase();
                          if (cTitle.contains('lamar') ||
                              cId.contains('lamar')) {
                            return false; // Zero units in Lamar
                          }
                          return u.compoundId.toLowerCase().contains('sky') ||
                              u.parentCompoundId
                                  .toLowerCase()
                                  .contains('sky') ||
                              cTitle.contains('sky') ||
                              u.compoundId == _selectedCompound!.id;
                        }).toList();

                        if (activeCompoundUnits.isEmpty) {
                          return Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24.0),
                              child: Text(
                                'No units available in ${_selectedCompound?.title ?? "selected project"}',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: activeCompoundUnits.length,
                          itemBuilder: (context, idx) {
                            final u = activeCompoundUnits[idx];
                            final isSelected = u.id == _selectedUnit?.id ||
                                u.unitNumber == _selectedUnit?.unitNumber;
                            return GestureDetector(
                              onTap: () {
                                _onUnitSelected(u);
                                Navigator.pop(context);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accent
                                          .withAlpha(isDark ? 40 : 20)
                                      : cardAltBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.accent
                                            : (isDark
                                                ? AppColors.darkCard
                                                : Colors.white),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.home_work_rounded,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.accent,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Unit ${u.unitNumber}',
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              color: textColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${u.configuration.isNotEmpty ? u.configuration : u.assetClass} • ${u.areaSquareMeters.toStringAsFixed(0)} sqm',
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              color: textMuted,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${(u.priceEGP / 1000000).toStringAsFixed(2)}M EGP',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: isSelected
                                            ? AppColors.accent
                                            : textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUnitSpecificationsBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final u = _selectedUnit;
    if (u == null) return;

    final buildingName =
        _selectedBuilding?.name ?? u.buildingId ?? 'Building B207';
    final config = u.configuration.isNotEmpty ? u.configuration : u.assetClass;
    final areaSqm = u.areaSquareMeters;
    final priceVal = u.priceEGP;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted.withAlpha(80),
                    borderRadius: AppBorderRadius.pill,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.accent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Sky Hills (سكي هيلز) • $buildingName',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unit ${u.unitNumber}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(isDark ? 40 : 20),
                      borderRadius: AppBorderRadius.pill,
                    ),
                    child: Text(
                      u.status.nameString,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Amenity specs
              Row(
                children: [
                  _buildSpecTileItem(Icons.bed_rounded,
                      '${u.parkingSpaces + 1} Beds', 'Bedrooms', isDark),
                  _buildSpecTileItem(Icons.square_foot_rounded,
                      '${areaSqm.toStringAsFixed(0)} sqm', 'Area', isDark),
                  _buildSpecTileItem(
                      Icons.layers_rounded,
                      'Floor ${u.unitNumber.length > 3 ? u.unitNumber[u.unitNumber.length - 3] : "2"}',
                      'Level',
                      isDark),
                  _buildSpecTileItem(Icons.directions_car_rounded,
                      '${u.parkingSpaces} Slot', 'Parking', isDark),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'CONTRACT & OWNERSHIP',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardAltBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _buildSpecRow('Unit Layout', config, textColor, textMuted),
                    const Divider(height: 16),
                    _buildSpecRow(
                        'Total Valuation',
                        '${(priceVal / 1000000).toStringAsFixed(2)}M EGP',
                        AppColors.accent,
                        textMuted),
                    const Divider(height: 16),
                    _buildSpecRow(
                        'Finishing Status',
                        u.furnishingStatus.isNotEmpty
                            ? u.furnishingStatus
                            : 'Luxury Semi-Finished',
                        textColor,
                        textMuted),
                    const Divider(height: 16),
                    _buildSpecRow('Ownership', 'Verified Registered Resident',
                        AppColors.success, textMuted),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecRow(
      String label, String value, Color valColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: labelColor,
            fontSize: 12.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: valColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecTileItem(
      IconData icon, String value, String label, bool isDark) {
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: AppColors.accent),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyInformationSection() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

    if (_selectedUnit == null) return const SizedBox.shrink();
    final u = _selectedUnit!;
    final comp = _selectedCompound;
    final bldg = _selectedBuilding;
    final proj = _selectedProject;

    final String projName =
        (proj != null && !proj.name.toLowerCase().contains('lamar'))
            ? proj.name
            : 'Sky Hills';
    final String compName =
        (comp != null && !comp.title.toLowerCase().contains('lamar'))
            ? comp.title
            : 'Sky Hills (سكي هيلز)';

    final infoItems = [
      {
        'label': l10n.projectName,
        'val': projName,
        'icon': Icons.business_rounded
      },
      {
        'label': l10n.compoundName,
        'val': compName,
        'icon': Icons.location_city_rounded
      },
      {
        'label': l10n.building,
        'val': bldg?.name ?? u.buildingId ?? 'Building B208',
        'icon': Icons.apartment_rounded
      },
      {
        'label': l10n.unitNumber,
        'val': u.unitNumber,
        'icon': Icons.tag_rounded
      },
      {
        'label': l10n.unitTypeConfig,
        'val': u.configuration.isNotEmpty ? u.configuration : u.assetClass,
        'icon': Icons.weekend_rounded
      },
      {
        'label': l10n.unitAreaSqmSqft,
        'val':
            '${u.areaSquareMeters.toStringAsFixed(1)} sqm (${u.areaSqFt.toStringAsFixed(0)} sqft)',
        'icon': Icons.square_foot_rounded
      },
      {
        'label': l10n.priceValuation,
        'val': '${u.priceEGP.toStringAsFixed(0)} EGP',
        'icon': Icons.payments_rounded
      },
      {
        'label': l10n.ownershipStatus,
        'val': _assignedCustomer != null
            ? l10n.soldToUser(_assignedCustomer!.fullName)
            : l10n.developerInventory,
        'icon': Icons.verified_user_rounded
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Unit Specifications & Overview'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
            ),
            child: Column(
              children: infoItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData,
                            size: 16, color: AppColors.accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        item['val'] as String,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInformationSection() {
    final isAdmin = AuthService.instance.currentProfile?.isAdmin ?? false;
    if (!isAdmin) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cust = _assignedCustomer;
    final contract = _assignedContract;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Resident & Ownership Profile'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
            ),
            child: cust == null && contract == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        l10n.noCustomerAssigned,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.accent.withAlpha(isDark ? 40 : 25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.accent, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                (cust?.fullName.isNotEmpty == true
                                        ? cust!.fullName[0]
                                        : 'O')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: AppColors.accent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cust?.fullName ?? 'Resident Owner / Admin',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Client ID: ${cust?.clientCode ?? contract?.clientCode ?? "CLI-207"} • KYC Verified',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textMuted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.success.withAlpha(isDark ? 35 : 18),
                              borderRadius: AppBorderRadius.pill,
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.success,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Quick Action Pills (Call, WhatsApp, Email)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (cust?.phoneNumber != null &&
                                    cust!.phoneNumber.isNotEmpty) {
                                  launchUrl(
                                      Uri.parse('tel:${cust.phoneNumber}'));
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCardAlt
                                      : AppColors.lightCardAlt,
                                  borderRadius: AppBorderRadius.pill,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.phone_rounded,
                                        color: AppColors.accent, size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Call',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: textColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (cust?.phoneNumber != null &&
                                    cust!.phoneNumber.isNotEmpty) {
                                  launchUrl(Uri.parse(
                                      'https://wa.me/${cust.phoneNumber.replaceAll("+", "")}'));
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withAlpha(isDark ? 35 : 18),
                                  borderRadius: AppBorderRadius.pill,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_bubble_rounded,
                                        color: AppColors.success, size: 15),
                                    SizedBox(width: 6),
                                    Text(
                                      'WhatsApp',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: AppColors.success,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (cust?.email != null &&
                                    cust!.email.isNotEmpty) {
                                  launchUrl(Uri.parse('mailto:${cust.email}'));
                                }
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCardAlt
                                      : AppColors.lightCardAlt,
                                  borderRadius: AppBorderRadius.pill,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.email_rounded,
                                        color: textMuted, size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Email',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: textColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialOverviewSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

    final contract = _assignedContract;
    final ledger = _unitLedger;
    final installments = _unitInstallments;

    final double contractValue =
        contract?.agreedTotalPrice != null && contract!.agreedTotalPrice > 0
            ? contract.agreedTotalPrice
            : (_selectedUnit?.priceEGP != null && _selectedUnit!.priceEGP > 0
                ? _selectedUnit!.priceEGP
                : (installments.isNotEmpty
                    ? installments.fold(0.0, (acc, i) => acc + i.totalAmountDue)
                    : ((ledger?.totalPaidEGP ?? 0.0) +
                        (ledger?.totalOutstandingEGP ?? 0.0))));

    final double downPayment =
        contract?.downPaymentAmount ?? (contractValue * 0.10);

    double totalPaid = 0.0;
    if (installments.isNotEmpty) {
      totalPaid = installments.fold(0.0, (acc, i) => acc + i.paidAmount);
    } else if (_unitPayments.isNotEmpty) {
      totalPaid = _unitPayments.fold(0.0, (acc, p) => acc + p.amountPaid);
    } else if (ledger != null) {
      totalPaid = ledger.totalPaidEGP;
    }

    final double outstanding =
        (contractValue - totalPaid).clamp(0.0, double.infinity);
    final double percentPaid =
        contractValue > 0 ? (totalPaid / contractValue).clamp(0.0, 1.0) : 0.0;

    final int overdueCount = installments.where((i) => i.isOverdue).length;

    final double maintDeposit = (contract?.maintenanceDepositAmount ?? 0) > 0
        ? contract!.maintenanceDepositAmount
        : (installments
                .where(
                    (i) => i.installmentType == InstallmentType.maintenanceFund)
                .firstOrNull
                ?.principalAmount ??
            (contractValue * 0.08));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Financial Status & Ledger'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL CONTRACT VALUE',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${contractValue.toStringAsFixed(0)} EGP',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                        borderRadius: AppBorderRadius.pill,
                      ),
                      child: Text(
                        '${(percentPaid * 100).toStringAsFixed(0)}% PAID',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress Bar
                ClipRRect(
                  borderRadius: AppBorderRadius.pill,
                  child: LinearProgressIndicator(
                    value: percentPaid,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardAlt
                              : AppColors.lightCardAlt,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paid to Date',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalPaid.toStringAsFixed(0)} EGP',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: AppColors.success,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardAlt
                              : AppColors.lightCardAlt,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Outstanding',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${outstanding.toStringAsFixed(0)} EGP',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: overdueCount > 0
                                    ? AppColors.error
                                    : AppColors.accent,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Breakdown Badges Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Down Payment: ${downPayment.toStringAsFixed(0)} EGP',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Maint. Fund: ${maintDeposit.toStringAsFixed(0)} EGP',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentScheduleSection() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final installments = _unitInstallments;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          l10n.installmentSchedulePayments,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(isDark ? 30 : 15),
              borderRadius: AppBorderRadius.pill,
            ),
            child: const Text(
              'OWNER OPS',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.accent,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: installments.isEmpty
              ? ILivingCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: AppBorderRadius.medium,
                  child: Center(
                    child: Text(
                      l10n.noInstallmentsFound,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: (installments.length > 8
                          ? installments.sublist(0, 8)
                          : installments)
                      .map((inst) {
                    final isPaid = inst.isPaid;
                    final isOverdue = inst.isOverdue;
                    final isPendingApproval =
                        inst.status == InstallmentStatus.pendingApproval;

                    final Color statusColor = isPaid
                        ? AppColors.success
                        : isPendingApproval
                            ? AppColors.warning
                            : isOverdue
                                ? AppColors.error
                                : inst.status == InstallmentStatus.unpaid
                                    ? AppColors.accent
                                    : AppColors.warning;

                    final dueDateStr =
                        '${inst.dueDate.day}/${inst.dueDate.month}/${inst.dueDate.year}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: AppBorderRadius.medium,
                        boxShadow:
                            isDark ? AppShadows.darkSoft : AppShadows.soft,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(isDark ? 35 : 18),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${inst.sequenceNumber}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inst.installmentType ==
                                          InstallmentType.maintenanceFund
                                      ? l10n.maintDeposit
                                      : inst.installmentType.name.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.dueLabel(dueDateStr),
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${inst.amount.toStringAsFixed(0)} EGP',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isPendingApproval) ...[
                                GestureDetector(
                                  onTap: () =>
                                      PaymentProofModal.showReviewModal(
                                    context: context,
                                    installment: inst,
                                    ledgerRepo: _ledgerRepo,
                                    isAdmin: AuthService
                                            .instance.currentProfile?.isAdmin ??
                                        false,
                                    clientName: AuthService
                                        .instance.currentProfile?.fullName,
                                    unitId: _selectedUnit?.unitNumber ??
                                        inst.unitId,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning
                                          .withAlpha(isDark ? 35 : 20),
                                      borderRadius: AppBorderRadius.pill,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.hourglass_top,
                                            color: AppColors.warning, size: 10),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.statusWaiting,
                                          style: const TextStyle(
                                            fontFamily:
                                                AppTextStyles.fontFamily,
                                            color: AppColors.warning,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else if (!isPaid) ...[
                                if (AuthService
                                        .instance.currentProfile?.isAdmin ??
                                    false) ...[
                                  GestureDetector(
                                    onTap: () async {
                                      final user = _assignedCustomer ??
                                          UserProfile(
                                            uid: inst.buyerUserId.isNotEmpty
                                                ? inst.buyerUserId
                                                : 'client',
                                            email: 'client@iliving.com',
                                            fullName: 'Client',
                                            role: UserRole.customer,
                                            phoneNumber: '',
                                            createdAt: DateTime.now(),
                                          );
                                      final confirmData =
                                          await InstallmentPaymentConfirmDialog
                                              .show(
                                        context: context,
                                        customer: user,
                                        unitNumber: _selectedUnit?.unitNumber ??
                                            inst.unitId,
                                        contractNumber:
                                            _assignedContract?.contractNumber ??
                                                'CONTRACT',
                                        installment: inst,
                                      );
                                      if (confirmData != null && mounted) {
                                        final adminUid = AuthService
                                                .instance.currentProfile?.uid ??
                                            'admin';
                                        final adminPaymentService =
                                            AdminPaymentActionService();
                                        try {
                                          await adminPaymentService
                                              .markAsPaid(
                                                installment: inst,
                                                customer: user,
                                                adminUserId: adminUid,
                                                paymentMethod:
                                                    confirmData.paymentMethod,
                                                receiptReference: confirmData
                                                    .receiptReference,
                                                receiptPdfUrl:
                                                    confirmData.receiptUrl,
                                                notes: confirmData.notes,
                                                paymentDate:
                                                    confirmData.paymentDate,
                                                confirmedAmount:
                                                    confirmData.amountPaid,
                                              )
                                              .timeout(
                                                  const Duration(seconds: 4),
                                                  onTimeout: () =>
                                                      MarkAsPaidResult(
                                                        payment: Payment(
                                                          id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
                                                          transactionReference: (confirmData
                                                                          .receiptReference !=
                                                                      null &&
                                                                  confirmData
                                                                      .receiptReference!
                                                                      .isNotEmpty)
                                                              ? confirmData
                                                                  .receiptReference!
                                                              : 'PAY',
                                                          contractId:
                                                              inst.contractId,
                                                          installmentId:
                                                              inst.id,
                                                          unitId: inst.unitId,
                                                          payerUserId:
                                                              inst.buyerUserId,
                                                          paymentMethod:
                                                              confirmData
                                                                  .paymentMethod,
                                                          amountPaid:
                                                              confirmData
                                                                  .amountPaid,
                                                          currency:
                                                              inst.currency,
                                                          status: PaymentStatus
                                                              .success,
                                                          createdAt: confirmData
                                                              .paymentDate,
                                                        ),
                                                        paidInstallment:
                                                            inst.copyWith(
                                                          status:
                                                              InstallmentStatus
                                                                  .paid,
                                                          paidAmount:
                                                              confirmData
                                                                  .amountPaid,
                                                          paidAt: confirmData
                                                              .paymentDate,
                                                        ),
                                                      ));
                                        } catch (e) {
                                          debugPrint(
                                              '[PropertyOpsDashboard] Error marking payment: $e');
                                        }
                                        if (mounted) {
                                          setState(() {
                                            final idx =
                                                _unitInstallments.indexWhere(
                                                    (i) => i.id == inst.id);
                                            if (idx != -1) {
                                              _unitInstallments[idx] =
                                                  _unitInstallments[idx]
                                                      .copyWith(
                                                status: InstallmentStatus.paid,
                                                paidAmount:
                                                    confirmData.amountPaid,
                                                paidAt: confirmData.paymentDate,
                                              );
                                            }
                                          });
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (isOverdue
                                                ? AppColors.error
                                                : AppColors.accent)
                                            .withAlpha(isDark ? 35 : 20),
                                        borderRadius: AppBorderRadius.pill,
                                      ),
                                      child: Text(
                                        isOverdue
                                            ? l10n.overdue
                                            : l10n.statusUnpaid,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          color: isOverdue
                                              ? AppColors.error
                                              : AppColors.accent,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  GestureDetector(
                                    onTap: () async {
                                      final res = await PaymentProofModal
                                          .showUploadSheet(
                                        context: context,
                                        installment: inst,
                                        ledgerRepo: _ledgerRepo,
                                      );
                                      if (res == true && mounted) {
                                        setState(() {
                                          final idx =
                                              _unitInstallments.indexWhere(
                                                  (i) => i.id == inst.id);
                                          if (idx != -1) {
                                            _unitInstallments[idx] =
                                                _unitInstallments[idx].copyWith(
                                              status: InstallmentStatus
                                                  .pendingApproval,
                                            );
                                          }
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withAlpha(isDark ? 35 : 20),
                                        borderRadius: AppBorderRadius.pill,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.upload_file_rounded,
                                              color: AppColors.accent,
                                              size: 11),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.payAndUploadProof,
                                            style: const TextStyle(
                                              fontFamily:
                                                  AppTextStyles.fontFamily,
                                              color: AppColors.accent,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withAlpha(isDark ? 35 : 20),
                                    borderRadius: AppBorderRadius.pill,
                                  ),
                                  child: Text(
                                    l10n.paid,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: AppColors.success,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMiniCounter(
      String label, String count, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceOperationsSection() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tickets = _unitMaintenanceTickets;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    final int openCount = tickets
        .where((t) =>
            t.status == MaintenanceStatus.submitted ||
            t.status == MaintenanceStatus.assigned)
        .length;
    final int progressCount =
        tickets.where((t) => t.status == MaintenanceStatus.inProgress).length;
    final int completedCount =
        tickets.where((t) => t.status == MaintenanceStatus.completed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.maintenanceOperations),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Ticket Trade Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: [
                  _buildTradeRequestCard(
                      'صيانة المياه',
                      'PLUMBING',
                      Icons.water_drop_rounded,
                      () => _showMaintenanceRequestSheet('Plumbing'),
                      isDark),
                  _buildTradeRequestCard(
                      'الصرف الصحي',
                      'DRAINAGE',
                      Icons.waves_rounded,
                      () => _showMaintenanceRequestSheet('Drainage'),
                      isDark),
                  _buildTradeRequestCard(
                      'صيانة الكهرباء',
                      'ELECTRICAL',
                      Icons.electric_bolt_rounded,
                      () => _showMaintenanceRequestSheet('Electrical'),
                      isDark),
                ],
              ),
              const SizedBox(height: 12),

              // Status Counts Banner in Pill Container
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: AppBorderRadius.pill,
                  boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniCounter(l10n.openTicketsCount, '$openCount',
                        AppColors.warning, isDark),
                    _buildMiniCounter(l10n.inProgressCount, '$progressCount',
                        AppColors.accent, isDark),
                    _buildMiniCounter(l10n.completed, '$completedCount',
                        AppColors.success, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tickets Feed
              tickets.isEmpty
                  ? ILivingCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: AppBorderRadius.medium,
                      child: Center(
                        child: Text(
                          l10n.noMaintenanceRequests,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children:
                          (tickets.length > 4 ? tickets.sublist(0, 4) : tickets)
                              .map((tick) {
                        final isCompleted =
                            tick.status == MaintenanceStatus.completed;
                        final statusColor =
                            isCompleted ? AppColors.success : AppColors.accent;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            borderRadius: AppBorderRadius.medium,
                            boxShadow:
                                isDark ? AppShadows.darkSoft : AppShadows.soft,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.build_circle_outlined,
                                color: statusColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '#${tick.ticketNumber} • ${tick.title}',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tick.description,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        color: textMuted,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      statusColor.withAlpha(isDark ? 35 : 20),
                                  borderRadius: AppBorderRadius.pill,
                                ),
                                child: Text(
                                  tick.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: statusColor,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTradeRequestCard(
      String ar, String en, IconData icon, VoidCallback onTap, bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return InteractiveTapBounce(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppBorderRadius.medium,
          boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              ar,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              en,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docs = _unitDocuments;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.documentsAndContracts),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: docs.isEmpty
              ? ILivingCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: AppBorderRadius.medium,
                  child: Center(
                    child: Text(
                      l10n.noDocumentsAvailable,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : Column(
                  children:
                      (docs.length > 5 ? docs.sublist(0, 5) : docs).map((d) {
                    return GestureDetector(
                      onTap: () async {
                        try {
                          await PdfDocumentGeneratorService.instance
                              .previewOrPrintDocument(
                            context: context,
                            document: d,
                            unit: _selectedUnit,
                            contract: _assignedContract,
                            user: _assignedCustomer,
                          );
                        } catch (e) {
                          debugPrint("Error opening PDF: $e");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to open PDF preview: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: AppBorderRadius.medium,
                          boxShadow:
                              isDark ? AppShadows.darkSoft : AppShadows.soft,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.error.withAlpha(isDark ? 35 : 15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded,
                                  color: AppColors.error, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.title,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: textColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${d.category.name.toUpperCase()} • ${(d.fileSizeBytes / 1024).toStringAsFixed(0)} KB',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_rounded,
                                  color: AppColors.accent, size: 20),
                              tooltip: 'Download PDF',
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                messenger.hideCurrentSnackBar();
                                messenger.showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: isDark
                                        ? AppColors.darkCard
                                        : AppColors.lightCard,
                                    content: Row(
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.accent),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Generating & Downloading ${d.title}...',
                                            style: TextStyle(
                                                color: textColor, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                try {
                                  await PdfDocumentGeneratorService.instance
                                      .downloadAndShareDocument(
                                    context: context,
                                    document: d,
                                    unit: _selectedUnit,
                                    contract: _assignedContract,
                                    user: _assignedCustomer,
                                  );
                                } catch (e) {
                                  debugPrint("Error downloading PDF: $e");
                                  if (mounted) {
                                    messenger.hideCurrentSnackBar();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to download PDF: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildCompoundMapSection() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    final comp = _selectedCompound ??
        const CompoundModel(
          id: 'dev_1',
          title: 'Sky Hills',
          location: 'New October',
          category: 'Luxury Compound',
          description: 'High-altitude allocation compound',
          basePriceEGP: 3500000,
          areaSqFt: 1800,
          completionPercentage: 85,
          heroImageUrl: '',
          cardImageUrl: '',
          primaryView: 'Golf View',
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InteractiveTapBounce(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompoundMapScreen(
                compound: comp,
                isOperationsMode: true,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: AppBorderRadius.large,
            boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.map_outlined,
                    color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.exploreInteractiveBlueprint,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.exploreBlueprintSubtitle,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: textMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicGuestPassSection() {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _selectedCompound?.title ?? 'Sky Hills';
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppBorderRadius.large,
          boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dynamicGuestAccessQr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.smartGateAccessFor(title),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                _buildAccessActionCard(
                    l10n.courierQr,
                    Icons.delivery_dining_rounded,
                    () => _showQrPassModal(context, 'Courier'),
                    isDark),
                _buildAccessActionCard(l10n.visitorQr, Icons.group_rounded,
                    () => _showQrPassModal(context, 'Visitor'), isDark),
                _buildAccessActionCard(l10n.serviceQr, Icons.build_rounded,
                    () => _showQrPassModal(context, 'Service Crew'), isDark),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const GatePassVerifierScreen()),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Verify Gate Pass'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppBorderRadius.pill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrPassModal(BuildContext context, String passCategory) {
    final compoundTitle = _selectedCompound?.title ?? 'Sky Hills';
    final unitId = _selectedUnit?.unitNumber ?? _selectedUnit?.id ?? 'UNIT-87';
    final currentProfile = AuthService.instance.currentProfile;
    final hostName = currentProfile?.displayName ?? 'Valued Client';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted =
        isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    final gateService = GateService(gateRepository: FirestoreGateRepository());

    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    int selectedDurationMinutes = 120; // Default 2 hours
    DateTime validUntil =
        DateTime.now().add(Duration(minutes: selectedDurationMinutes));

    GatePass currentPass = gateService.generatePass(
      compoundId: _selectedCompound?.id ?? 'comp_1',
      unitId: unitId,
      hostUserId: currentProfile?.id ?? 'CLIENT_01',
      visitorName: nameController.text.trim().isEmpty
          ? 'Guest ($passCategory)'
          : nameController.text.trim(),
      visitorPhone: phoneController.text.trim().isEmpty
          ? '+20 100 000 0000'
          : phoneController.text.trim(),
      passType: PassType.durationBased,
      validFrom: DateTime.now(),
      validUntil: validUntil,
      serverSecretKey: 'iliving_gate_secret_2026',
    );

    final GlobalKey qrBoundaryKey = GlobalKey();

    Timer? tickerTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final l10n = AppLocalizations.of(modalContext);
        return StatefulBuilder(
          builder: (stfContext, setModalState) {
            tickerTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
              if (modalContext.mounted) {
                setModalState(() {});
              }
            });

            final now = DateTime.now();
            final remainingDiff = currentPass.validUntil.difference(now);
            final remainingSeconds =
                remainingDiff.inSeconds > 0 ? remainingDiff.inSeconds : 0;
            final isExpired = remainingSeconds == 0;

            final hours = (remainingSeconds ~/ 3600).toString().padLeft(2, '0');
            final minutes =
                ((remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
            final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

            final realQrPayload = currentPass.qrPayloadSigned;

            return Container(
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkBackground : AppColors.lightSurface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(stfContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textMuted.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.passTypeTitle(passCategory),
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isExpired
                                            ? AppColors.error
                                            : AppColors.success)
                                        .withAlpha(isDark ? 35 : 20),
                                    borderRadius: AppBorderRadius.pill,
                                  ),
                                  child: Text(
                                    isExpired
                                        ? l10n.passExpired
                                        : l10n.liveActive,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: isExpired
                                          ? AppColors.error
                                          : AppColors.success,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$compoundTitle • Unit $unitId',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: textMuted, size: 22),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Live Ticking Countdown Banner
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? AppColors.error.withAlpha(isDark ? 35 : 15)
                            : AppColors.accent.withAlpha(isDark ? 30 : 12),
                        borderRadius: AppBorderRadius.pill,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isExpired
                                ? Icons.error_outline_rounded
                                : Icons.timer_outlined,
                            color:
                                isExpired ? AppColors.error : AppColors.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isExpired
                                ? l10n.passExpiredNotice
                                : l10n.expiresInCountdown(
                                    hours, minutes, seconds),
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: isExpired
                                  ? AppColors.error
                                  : AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Duration Preset Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            l10n.durationLabel,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...[15, 60, 120, 1440].map((mins) {
                            final label = mins == 15
                                ? l10n.mins15
                                : mins == 60
                                    ? l10n.hour1
                                    : mins == 120
                                        ? l10n.hours2
                                        : l10n.hours24;
                            final isSelected = selectedDurationMinutes == mins;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedDurationMinutes = mins;
                                    validUntil = DateTime.now().add(Duration(
                                        minutes: selectedDurationMinutes));
                                    currentPass = gateService.generatePass(
                                      compoundId:
                                          _selectedCompound?.id ?? 'comp_1',
                                      unitId: unitId,
                                      hostUserId:
                                          currentProfile?.id ?? 'CLIENT_01',
                                      visitorName:
                                          nameController.text.trim().isEmpty
                                              ? 'Guest ($passCategory)'
                                              : nameController.text.trim(),
                                      visitorPhone:
                                          phoneController.text.trim().isEmpty
                                              ? '+20 100 000 0000'
                                              : phoneController.text.trim(),
                                      passType: PassType.durationBased,
                                      validFrom: DateTime.now(),
                                      validUntil: validUntil,
                                      serverSecretKey:
                                          'iliving_gate_secret_2026',
                                    );
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : cardAltBg,
                                    borderRadius: AppBorderRadius.pill,
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color:
                                          isSelected ? Colors.white : textColor,
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Code
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppBorderRadius.large,
                            boxShadow:
                                isDark ? AppShadows.darkSoft : AppShadows.soft,
                          ),
                          child: QrCodeWidget(
                            qrData: realQrPayload,
                            size: 190,
                            primaryColor: isExpired
                                ? Colors.grey
                                : const Color(0xFF1A1A2E),
                            backgroundColor: Colors.white,
                            repaintBoundaryKey: qrBoundaryKey,
                          ),
                        ),
                        if (isExpired)
                          Container(
                            width: 214,
                            height: 214,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(200),
                              borderRadius: AppBorderRadius.large,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_rounded,
                                    color: Colors.redAccent, size: 36),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.passExpired,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.tapRegenerateBelow,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Pass ID
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardAltBg,
                        borderRadius: AppBorderRadius.pill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpired
                                ? Icons.error_outline_rounded
                                : Icons.verified_rounded,
                            color:
                                isExpired ? AppColors.error : AppColors.accent,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ID: ${currentPass.id}',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Optional Visitor Inputs
                    TextField(
                      controller: nameController,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n.visitorNameOptional,
                        hintStyle: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textMuted,
                            fontSize: 13),
                        filled: true,
                        fillColor: cardAltBg,
                        prefixIcon: Icon(Icons.person_outline_rounded,
                            color: textMuted, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AppBorderRadius.pill,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppBorderRadius.pill,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n.visitorMobileOptional,
                        hintStyle: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textMuted,
                            fontSize: 13),
                        filled: true,
                        fillColor: cardAltBg,
                        prefixIcon: Icon(Icons.phone_outlined,
                            color: textMuted, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AppBorderRadius.pill,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppBorderRadius.pill,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Native Share Action
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppBorderRadius.pill),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 16),
                            label: const Text(
                              'Share Pass',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              if (isExpired) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.error,
                                    content: Text(l10n.passExpiredNotice),
                                  ),
                                );
                                return;
                              }
                              final name = nameController.text.trim().isEmpty
                                  ? 'Valued Guest'
                                  : nameController.text.trim();
                              final shareText =
                                  '🚨 *iLiving Smart Gate Access Pass* 🚨\n\n'
                                  '📍 Compound: $compoundTitle\n'
                                  '🚪 Unit: $unitId\n'
                                  '👤 Host: $hostName\n'
                                  '👥 Visitor: $name ($passCategory)\n'
                                  '⏰ Valid Until: ${currentPass.validUntil.toString().substring(0, 16)}\n'
                                  '🔑 Pass ID: ${currentPass.id}\n'
                                  '🔗 Digital Pass Link: $realQrPayload\n\n'
                                  '⚡ Please scan the attached QR code at the compound security gate for instant entry.';
                              await _shareQrPassWithImage(
                                boundaryKey: qrBoundaryKey,
                                shareText: shareText,
                                subject:
                                    'iLiving Smart Gate Pass • $compoundTitle • Unit $unitId',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // WhatsApp Direct Share
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppBorderRadius.pill),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: Text(
                            l10n.whatsapp,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            if (isExpired) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.error,
                                  content: Text(l10n.passExpiredNotice),
                                ),
                              );
                              return;
                            }
                            final name = nameController.text.trim().isEmpty
                                ? 'Valued Guest'
                                : nameController.text.trim();
                            final text = '🚨 *iLiving Smart Gate Pass* 🚨\n'
                                '📍 Compound: $compoundTitle\n'
                                '🚪 Unit: $unitId\n'
                                '👤 Host: $hostName\n'
                                '👥 Visitor: $name\n'
                                '🔖 Type: $passCategory\n'
                                '⏰ Valid Until: ${currentPass.validUntil.toString().substring(0, 16)}\n'
                                '🔑 Pass Code: ${currentPass.id}\n'
                                '🔗 Verify Link: $realQrPayload\n\n'
                                'Please scan the QR code at the security gate.';
                            final waUrl = Uri.parse(
                                'whatsapp://send?text=${Uri.encodeComponent(text)}');
                            final webWaUrl = Uri.parse(
                                'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');

                            try {
                              if (await canLaunchUrl(waUrl)) {
                                await launchUrl(waUrl);
                              } else if (await canLaunchUrl(webWaUrl)) {
                                await launchUrl(webWaUrl,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                await Clipboard.setData(
                                    ClipboardData(text: text));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(l10n.gatePassCopied)),
                                  );
                                }
                              }
                            } catch (_) {
                              await Clipboard.setData(
                                  ClipboardData(text: text));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.gatePassCopied)),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Copy Code & Link
                        IconButton(
                          tooltip: l10n.copyCode,
                          style: IconButton.styleFrom(
                            backgroundColor: cardAltBg,
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.copy_rounded,
                              color: AppColors.accent, size: 20),
                          onPressed: () async {
                            if (isExpired) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.error,
                                  content: Text(l10n.passExpiredNotice),
                                ),
                              );
                              return;
                            }
                            await Clipboard.setData(
                                ClipboardData(text: realQrPayload));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: cardBg,
                                  content: Text(
                                    l10n.gatePassCopied,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Regenerate QR
                        IconButton(
                          tooltip: l10n.regenerateQr,
                          style: IconButton.styleFrom(
                            backgroundColor: cardAltBg,
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.accent, size: 20),
                          onPressed: () {
                            setModalState(() {
                              validUntil = DateTime.now().add(
                                  Duration(minutes: selectedDurationMinutes));
                              currentPass = gateService.generatePass(
                                compoundId: _selectedCompound?.id ?? 'comp_1',
                                unitId: unitId,
                                hostUserId: currentProfile?.id ?? 'CLIENT_01',
                                visitorName: nameController.text.trim().isEmpty
                                    ? 'Guest ($passCategory)'
                                    : nameController.text.trim(),
                                visitorPhone:
                                    phoneController.text.trim().isEmpty
                                        ? '+20 100 000 0000'
                                        : phoneController.text.trim(),
                                passType: PassType.durationBased,
                                validFrom: DateTime.now(),
                                validUntil: validUntil,
                                serverSecretKey: 'iliving_gate_secret_2026',
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      tickerTimer?.cancel();
    });
  }

  Future<void> _shareQrPassWithImage({
    required GlobalKey boundaryKey,
    required String shareText,
    required String subject,
  }) async {
    Rect? shareOrigin;
    try {
      final box = boundaryKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null &&
          box.hasSize &&
          box.size.width > 0 &&
          box.size.height > 0) {
        shareOrigin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}

    if (shareOrigin == null || shareOrigin.isEmpty) {
      try {
        if (mounted) {
          final size = MediaQuery.of(context).size;
          shareOrigin = Rect.fromLTWH(
              0, 0, size.width, size.height > 0 ? size.height / 2 : 300);
        }
      } catch (_) {
        shareOrigin = const Rect.fromLTWH(0, 0, 300, 300);
      }
    }

    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          final tempDir = await getTemporaryDirectory();
          final file = File(
              '${tempDir.path}/iliving_gate_pass_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles(
            [
              XFile(file.path,
                  mimeType: 'image/png', name: 'iLiving_Gate_Pass.png')
            ],
            text: shareText,
            subject: subject,
            sharePositionOrigin: shareOrigin,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Error capturing QR code image for share: $e');
    }
    // Fallback to text share
    await Share.share(
      shareText,
      subject: subject,
      sharePositionOrigin: shareOrigin,
    );
  }

  Widget _buildAccessActionCard(
      String title, IconData icon, VoidCallback onTap, bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return InteractiveTapBounce(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppBorderRadius.medium,
          boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppSharingOverlay() {
    final l10n = AppLocalizations.of(context);
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(200),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                    color: Colors.green, strokeWidth: 4),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.share, color: Colors.green, size: 40),
              const SizedBox(height: 16),
              Text(
                l10n.dispatchingWhatsapp,
                style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.securingPassTokens,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.white70,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedShakeField extends StatefulWidget {
  final Widget child;

  const _AnimatedShakeField({required this.child});

  @override
  State<_AnimatedShakeField> createState() => _AnimatedShakeFieldState();
}

class _AnimatedShakeFieldState extends State<_AnimatedShakeField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });
  }

  void shake() {
    setState(() {
      _hasError = true;
    });
    _shakeController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _hasError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  borderRadius: AppBorderRadius.medium,
                  border: Border.all(
                    color: _hasError
                        ? AppColors.error
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: _hasError ? 1.5 : 1.0,
                  ),
                ),
                child: child!,
              ),
              AnimatedOpacity(
                opacity: _hasError ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 11),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.verifMin5Chars,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: AppColors.error,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
