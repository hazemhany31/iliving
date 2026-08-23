import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../models/unit_model.dart';
import '../models/compound_model.dart';
import '../models/project.dart';
import '../models/building.dart';
import '../models/contract.dart';
import '../models/user_profile.dart';
import '../models/installment.dart';
import '../models/document.dart';
import '../models/maintenance_request.dart';

import '../repositories/firestore/firestore_unit_repository.dart';
import '../repositories/firestore/firestore_project_repository.dart';
import '../repositories/firestore/firestore_compound_repository.dart';
import '../repositories/firestore/firestore_building_repository.dart';
import '../repositories/firestore/firestore_user_repository.dart';
import '../repositories/firestore/firestore_contract_repository.dart';
import '../repositories/firestore/firestore_ledger_repository.dart';
import '../repositories/firestore/firestore_maintenance_repository.dart';
import '../repositories/firestore/firestore_document_repository.dart';
import '../repositories/price_sync_repository.dart';

import '../widgets/luxury_shimmer.dart';
import '../widgets/image_loader.dart';
import '../services/auth_service.dart';
import 'compound_map_screen.dart';
import 'document_viewer_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  final VoidCallback? onToggleNotifications;
  final int unreadNotificationsCount;

  const OwnerHomeScreen({
    super.key,
    this.onToggleNotifications,
    this.unreadNotificationsCount = 0,
  });

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> with TickerProviderStateMixin {
  // Repositories
  final FirestoreProjectRepository _projectRepo = FirestoreProjectRepository();
  final FirestoreCompoundRepository _compoundRepo = FirestoreCompoundRepository();
  final FirestoreBuildingRepository _buildingRepo = FirestoreBuildingRepository();
  final FirestoreUnitRepository _unitRepo = FirestoreUnitRepository();
  final FirestoreUserRepository _userRepo = FirestoreUserRepository();
  final FirestoreContractRepository _contractRepo = FirestoreContractRepository();
  final FirestoreLedgerRepository _ledgerRepo = FirestoreLedgerRepository();
  final FirestoreMaintenanceRepository _maintRepo = FirestoreMaintenanceRepository();
  final FirestoreDocumentRepository _docRepo = FirestoreDocumentRepository();

  // Selection Hierarchy
  CompoundModel? _selectedCompound;
  Building? _selectedBuilding;
  Unit? _selectedUnit;
  Contract? _assignedContract;

  // Master collections
  // ignore: unused_field
  List<Project> _allProjects = [];
  List<CompoundModel> _allCompounds = [];
  // ignore: unused_field
  List<Building> _allBuildings = [];
  List<Unit> _allUnits = [];
  // ignore: unused_field
  List<UserProfile> _allUsers = [];

  // Selected Unit's Stream Data
  List<Installment> _unitInstallments = [];
  List<MaintenanceRequest> _unitMaintenanceTickets = [];
  List<DocumentItem> _unitDocuments = [];

  // Status & UI State
  bool _isLoadingMasterData = true;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _bookmarkedUnitIds = {};

  int _selectedFilterPillIndex = 0; // 0: All Units, 1: Contracted, 2: Available, 3: Under Maintenance
  int _selectedDetailTabIndex = 0; // 0: Overview, 1: Financials, 2: Schedule, 3: Guest/Services

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
    _loadMasterCollections();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    unitNumber: 'A01-207',
    configuration: '2 Bedroom Suite • Modern Villa',
    areaSqFt: 4301.0,
    priceEGP: 3020000.0,
    isVacant: false,
    assetClass: 'Residential Luxury',
    furnishingStatus: 'Fully Furnished • Designer Edition',
    pricePerSqFt: 702.0,
    parkingSpaces: 1,
    constructionPhase: 'Delivered & Handed Over',
    parentCompoundId: 'sky_hills',
    buildingId: 'B207',
    floorTier: '2nd Floor',
    status: UnitStatus.contracted,
  );

  List<Unit> get _userAccessibleUnits {
    final user = AuthService.instance.currentProfile;
    final bool isAdmin = user != null && (user.isAdmin || user.isStaff);

    if (isAdmin) {
      if (_allUnits.isNotEmpty) return _allUnits;
      return [_defaultSkyHillsUnit];
    }

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
    }

    if (_allUnits.isNotEmpty) {
      final defaultOwnerUnit = _allUnits.firstWhere(
        (u) => u.unitNumber == 'A01-207' || u.unitNumber == 'A301B208' || u.id == 'A01-207',
        orElse: () => _allUnits.first,
      );
      return [defaultOwnerUnit];
    }

    return [_defaultSkyHillsUnit];
  }

  void _loadMasterCollections() {
    setState(() {
      _isLoadingMasterData = true;
    });

    final initialAvailable = _userAccessibleUnits;
    if (initialAvailable.isNotEmpty && _selectedUnit == null) {
      _onUnitSelected(initialAvailable.first);
    }

    try {
      _projectsSub = _projectRepo.streamAllProjects().listen(
        (projects) {
          if (mounted) setState(() => _allProjects = projects);
        },
        onError: (e) => debugPrint("[OwnerHome] Error streaming projects: $e"),
      );

      _compoundsSub = _compoundRepo.streamAllCompounds().listen(
        (compounds) {
          if (mounted) setState(() => _allCompounds = compounds);
        },
        onError: (e) => debugPrint("[OwnerHome] Error streaming compounds: $e"),
      );

      _unitsSub = _unitRepo.streamAllUnits().listen(
        (units) {
          if (mounted) {
            setState(() {
              _allUnits = units;
              _isLoadingMasterData = false;
            });

            final available = _userAccessibleUnits;
            if (available.isNotEmpty) {
              final alreadySelected = _selectedUnit != null &&
                  available.any((u) => u.id == _selectedUnit!.id || u.unitNumber == _selectedUnit!.unitNumber);
              if (!alreadySelected) {
                _onUnitSelected(available.first);
              }
            }
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _isLoadingMasterData = false;
            });
          }
        },
      );

      _usersSub = _userRepo.streamAllUsers().listen(
        (users) {
          if (mounted) setState(() => _allUsers = users);
        },
        onError: (e) => debugPrint("[OwnerHome] Error streaming users: $e"),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMasterData = false;
        });
      }
    }
  }

  Future<void> _onUnitSelected(Unit unit) async {
    _cancelUnitSubscriptions();

    setState(() {
      _selectedUnit = unit;
      _assignedContract = null;
      _unitInstallments = [];
      _unitMaintenanceTickets = [];
      _unitDocuments = [];
    });

    try {
      if (_allCompounds.isNotEmpty) {
        _selectedCompound = _allCompounds.firstWhere(
          (c) => (c.id == unit.compoundId || c.title.toLowerCase().contains(unit.compoundId.toLowerCase())) && !c.title.toLowerCase().contains('lamar'),
          orElse: () => _allCompounds.firstWhere(
            (c) => c.title.toLowerCase().contains('sky hills') || c.id.toLowerCase().contains('sky'),
            orElse: () => _allCompounds.first,
          ),
        );
      }

      final String? compId = _selectedCompound?.id;

      final results = await Future.wait([
        compId != null ? _buildingRepo.getBuildingsForCompound(compId).catchError((_) => <Building>[]) : Future.value(<Building>[]),
        _contractRepo.getContracts(limit: 200).catchError((_) => <Contract>[]),
      ]);

      final buildings = results[0] as List<Building>;
      final contracts = results[1] as List<Contract>;

      if (mounted) {
        setState(() {
          _allBuildings = buildings;

          if (buildings.isNotEmpty && unit.buildingId != null) {
            _selectedBuilding = buildings.firstWhere(
              (b) => b.id == unit.buildingId || b.name.toLowerCase() == unit.buildingId!.toLowerCase(),
              orElse: () => buildings.first,
            );
          } else if (buildings.isNotEmpty) {
            _selectedBuilding = buildings.first;
          }

          Contract? matchedContract;
          for (final c in contracts) {
            if (c.unitId == unit.id ||
                c.unitId == unit.unitNumber ||
                c.contractNumber.contains(unit.unitNumber)) {
              matchedContract = c;
              break;
            }
          }

          _assignedContract = matchedContract;
        });
      }

      final contractForInst = _assignedContract;
      if (contractForInst != null) {
        _installmentsSub = _ledgerRepo.streamInstallmentsForContract(contractForInst.id).listen((insts) {
          if (mounted) {
            setState(() {
              _unitInstallments = insts.isNotEmpty ? insts : _generateInstallments(unit, contractForInst);
            });
          }
        });
      }

      _maintenanceSub = _maintRepo.streamAllTickets().listen((tix) {
        if (mounted) {
          final unitTickets = tix.where((t) => t.unitId == unit.id || t.unitId == unit.unitNumber).toList();
          setState(() {
            _unitMaintenanceTickets = unitTickets.isNotEmpty ? unitTickets : _generateTickets(unit);
          });
        }
      });

      _documentsSub = _docRepo.streamDocumentsForUnit(unit.id).listen((docs) {
        if (mounted) {
          setState(() {
            _unitDocuments = docs.isNotEmpty ? docs : _generateDocuments(unit);
          });
        }
      });
    } catch (e) {
      debugPrint("[OwnerHome] Error loading unit details: $e");
    } finally {
      if (mounted) {
        setState(() {
          if (_unitInstallments.isEmpty && _assignedContract != null) {
            _unitInstallments = _generateInstallments(unit, _assignedContract!);
          }
          if (_unitMaintenanceTickets.isEmpty) {
            _unitMaintenanceTickets = _generateTickets(unit);
          }
          if (_unitDocuments.isEmpty) {
            _unitDocuments = _generateDocuments(unit);
          }
        });
      }
    }
  }

  static List<Installment> _generateInstallments(Unit unit, Contract contract) {
    final list = <Installment>[];
    final startDate = DateTime(2023, 6, 15);
    final count = contract.totalInstallmentsCount > 0 ? contract.totalInstallmentsCount : 24;
    final totalRemaining = contract.agreedTotalPrice - contract.downPaymentAmount;
    final amount = totalRemaining / count;

    for (int i = 1; i <= count; i++) {
      final dueDate = DateTime(startDate.year, startDate.month + (i - 1) * 3, 15);
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
        status: isPaid ? InstallmentStatus.paid : (isOverdue ? InstallmentStatus.overdue : InstallmentStatus.unpaid),
        paymentMethodLastUsed: isPaid ? 'Bank Transfer (CIB)' : null,
        receiptNumber: isPaid ? 'TXN-CIB-2024-$i' : null,
      ));
    }
    return list;
  }

  static List<MaintenanceRequest> _generateTickets(Unit unit) {
    final residentId = unit.currentOwnerId;
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
        title: 'Water Pressure & Smart Filter Inspection',
        description: 'Periodic inspection of automated shut-off valves and water filtration pressure.',
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
        title: 'Smart Home Hub Calibration',
        description: 'Firmware sync for ambient lighting scenes and entrance motion sensors.',
        status: MaintenanceStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<DocumentItem> _generateDocuments(Unit unit) {
    return [
      DocumentItem(
        id: 'doc-cnt-1',
        title: 'Official Ownership Deed & Handover Contract',
        description: 'Verified Title Deed registered under Sky Hills Master Development.',
        category: DocumentCategory.contract,
        fileUrl: 'https://ihome.app/docs/contract_${unit.unitNumber}.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 2450000,
        associatedUnitId: unit.id,
        createdAt: DateTime(2023, 3, 15),
      ),
      DocumentItem(
        id: 'doc-blp-2',
        title: 'Architectural Blueprint & MEP Layout',
        description: 'High-resolution floor plan blueprint, MEP electrical specifications.',
        category: DocumentCategory.blueprint,
        fileUrl: 'https://ihome.app/docs/blueprint_${unit.unitNumber}.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 5800000,
        associatedUnitId: unit.id,
        createdAt: DateTime(2023, 4, 1),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    if (_isLoadingMasterData) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                LuxuryShimmerGrid(itemCount: 3, crossAxisCount: 3, childAspectRatio: 1.35),
                SizedBox(height: 20),
                LuxuryShimmerGrid(itemCount: 3, crossAxisCount: 3, childAspectRatio: 0.60),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: cardBg,
          onRefresh: () async {
            _loadMasterCollections();
            if (_selectedUnit != null) {
              await _onUnitSelected(_selectedUnit!);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // 1. Greeting Header Row (Hello, Jemision + Dropdown Location + Notification Bell)
                _buildGreetingHeader(),
                const SizedBox(height: 16),

                // 2. Headline with two-weight typography
                _buildExploreHeadline(),
                const SizedBox(height: 18),

                // 3. Search Bar + Filter Icon
                _buildPillSearchBar(),
                const SizedBox(height: 16),

                // 4. Horizontal Category Pills Row (All Units, Contracted, Available, Under Maintenance)
                _buildCategoryPillsRow(),
                const SizedBox(height: 24),

                // 5. "Top Property" Section Header + View All
                _buildTopPropertySectionHeader(),
                const SizedBox(height: 14),

                // 6. Top Property Card (Rounded Full-Bleed Card)
                _buildTopPropertyHeroCard(),
                const SizedBox(height: 28),

                // 7. Second Reference Card (Luxury City Apartment Details, Specs, Tabs, Sticky Bar)
                _buildPropertyDetailCardSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Greeting Header Row
  Widget _buildGreetingHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final user = AuthService.instance.currentProfile;
    final ownerName = user?.fullName.split(' ').first ?? 'Owner';
    final locationText = _selectedCompound?.location ?? 'New October, Giza';
    final compoundName = _selectedCompound?.title.split('(').first.trim() ?? 'Sky Hills';

    final accessibleUnits = _userAccessibleUnits;
    final isMultiUnit = accessibleUnits.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Greeting & Location Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $ownerName',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              GestureDetector(
                onTap: isMultiUnit ? _showAssetPickerBottomSheet : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, color: textMuted, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '$compoundName, $locationText',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, color: textMuted, size: 16),
                  ],
                ),
              ),
            ],
          ),

          // Right: Notification Bell with live cloud sync dot & unread badge
          ValueListenableBuilder<SyncStatus>(
            valueListenable: PriceSyncRepository.instance.statusNotifier,
            builder: (context, status, _) {
              final syncColor = status == SyncStatus.live
                  ? AppColors.success
                  : status == SyncStatus.syncing
                      ? AppColors.accent
                      : status == SyncStatus.offline
                          ? AppColors.error
                          : AppColors.warning;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onToggleNotifications,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cardAltBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor, width: 1),
                          boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: textColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Sync Dot
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: syncColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(color: syncColor.withAlpha(180), blurRadius: 4, spreadRadius: 1),
                        ],
                      ),
                    ),
                  ),
                  // Unread Notification Badge
                  if (widget.unreadNotificationsCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: AppBorderRadius.pill,
                          border: Border.all(
                            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Center(
                          child: Text(
                            widget.unreadNotificationsCount > 99 ? '99+' : '${widget.unreadNotificationsCount}',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 2. Headline Typography
  Widget _buildExploreHeadline() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: textColor,
            fontSize: 26,
            height: 1.25,
            letterSpacing: -0.4,
          ),
          children: const [
            TextSpan(
              text: 'Explore ',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
            TextSpan(
              text: 'Modern Living\n',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: 'Spaces Near You',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Search Bar with Docked Filter Icon
  Widget _buildPillSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final accessibleUnits = _userAccessibleUnits;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: cardAltBg,
                borderRadius: AppBorderRadius.pill,
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textColor,
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Search unit, compound, or contract...',
                  hintStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: textMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                ),
                onSubmitted: (query) {
                  if (query.trim().isEmpty) return;
                  final q = query.trim().toLowerCase();
                  final match = accessibleUnits.firstWhere(
                    (u) => u.unitNumber.toLowerCase().contains(q) || u.id.toLowerCase().contains(q),
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
              ),
              child: const Icon(Icons.tune_rounded, color: AppColors.textDark, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Horizontal Category Pills Row
  Widget _buildCategoryPillsRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = [
      {'title': 'All Units', 'icon': Icons.apartment_rounded},
      {'title': 'Contracted', 'icon': Icons.verified_rounded},
      {'title': 'Available', 'icon': Icons.vpn_key_rounded},
      {'title': 'Under Maintenance', 'icon': Icons.build_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: List.generate(categories.length, (idx) {
          final isSelected = _selectedFilterPillIndex == idx;
          final item = categories[idx];

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilterPillIndex = idx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.accent : const Color(0xFF1B1E28))
                      : (isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt),
                  borderRadius: AppBorderRadius.pill,
                  boxShadow: isSelected ? (isDark ? AppShadows.darkSoft : AppShadows.soft) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: isSelected ? Colors.white : (isDark ? AppColors.textLight : AppColors.textDark),
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  /// 5. Top Property Section Header
  Widget _buildTopPropertySectionHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Top Property',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          GestureDetector(
            onTap: _showAssetPickerBottomSheet,
            child: const Text(
              'View All',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.textDarkSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Full-bleed rounded property card (Matching Reference Card 1)
  Widget _buildTopPropertyHeroCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unit = _selectedUnit ?? _defaultSkyHillsUnit;
    final buildingName = _selectedBuilding?.name ?? unit.buildingId ?? 'Building B207';
    final compoundName = _selectedCompound?.title.split('(').first.trim() ?? 'Sky Hills';
    final unitNumber = unit.unitNumber;
    final priceValuation = unit.priceEGP > 0 ? unit.priceEGP : 3020000.0;
    final priceDisplay = '${(priceValuation / 1000000).toStringAsFixed(2)}M EGP';

    final isSaved = _bookmarkedUnitIds.contains(unit.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 330,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Real property image
              const ImageLoader(
                imageUrl: 'images/skyhills/ski-hills.jpg',
                fit: BoxFit.cover,
              ),

              // Gradient Scrim for text clarity
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.7, 1.0],
                      colors: [
                        Colors.black.withAlpha(20),
                        Colors.transparent,
                        Colors.black.withAlpha(140),
                        Colors.black.withAlpha(220),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Floating Bookmark / Favorite Heart
              Positioned(
                top: 14,
                right: 14,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSaved) {
                        _bookmarkedUnitIds.remove(unit.id);
                      } else {
                        _bookmarkedUnitIds.add(unit.id);
                      }
                    });
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSaved ? AppColors.highlight : Colors.white.withAlpha(200),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isSaved ? Colors.white : const Color(0xFF1A1A2E),
                      size: 18,
                    ),
                  ),
                ),
              ),

              // Bottom Overlay: Location, Title, Price, Rating, Action Button
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Location pin + compound/building
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$compoundName • $buildingName',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Unit Title
                    Text(
                      'Unit $unitNumber',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Price & Rating Badge Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(80),
                            borderRadius: AppBorderRadius.pill,
                            border: Border.all(color: Colors.white.withAlpha(40)),
                          ),
                          child: Text(
                            priceDisplay,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Row(
                          children: [
                            Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 15),
                            SizedBox(width: 3),
                            Text(
                              '5.0 reviews',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Frosted Action Pill: "See Unit Details" with arrow circle
                    GestureDetector(
                      onTap: _showUnitSpecificationsBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: AppBorderRadius.pill,
                          border: Border.all(color: Colors.white.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'See Apartment Details',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: Colors.white,
                                fontSize: 12.5,
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
      ),
    );
  }

  /// 7. Second Reference Card (Luxury City Apartment Details, Spec Icons, Tabs, Sticky Bottom Bar)
  Widget _buildPropertyDetailCardSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    final unit = _selectedUnit ?? _defaultSkyHillsUnit;
    final priceValuation = unit.priceEGP > 0 ? unit.priceEGP : 3020000.0;
    final priceDisplay = '${(priceValuation / 1000000).toStringAsFixed(2)}M';

    final tabs = ['Overview', 'Financials', 'Schedule', 'Guest Pass'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Luxury City Apartment',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 14),

            // Spec Icons + Room Gallery preview card (Matching Reference 2)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardAltBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Left: 3 Stacked circular spec icons
                  Column(
                    children: [
                      _buildMiniSpecCircle(Icons.bed_rounded, isDark),
                      const SizedBox(height: 8),
                      _buildMiniSpecCircle(Icons.square_foot_rounded, isDark),
                      const SizedBox(height: 8),
                      _buildMiniSpecCircle(Icons.directions_car_rounded, isDark),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Right: "Spacious 4 Room" + 3 image thumbnails
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${unit.configuration.isNotEmpty ? unit.configuration : "Spacious Luxury Suite"} • Unit ${unit.unitNumber}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: const ImageLoader(
                                  imageUrl: 'images/skyhills/ski-hills-units.jpg',
                                  height: 68,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: const ImageLoader(
                                  imageUrl: 'images/skyhills/ski-hills-pricing.jpg',
                                  height: 68,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: const ImageLoader(
                                  imageUrl: 'images/skyhills/ski-hills-services.jpg',
                                  height: 68,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Horizontal Tab Row (Facilities / Offers / Host / Location -> Overview / Financials / Schedule / Guest Pass)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (idx) {
                  final isSelected = _selectedDetailTabIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedDetailTabIndex = idx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.accent : const Color(0xFF1B1E28))
                              : (isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt),
                          borderRadius: AppBorderRadius.pill,
                        ),
                        child: Text(
                          tabs[idx],
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: isSelected ? Colors.white : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),

            // Active Tab Content Display (Real Data)
            _buildActiveTabContent(unit, isDark, textColor, textMuted),
            const SizedBox(height: 22),

            // Sticky Bottom Bar inside card (Matching Reference 2 bottom: Price on left + Pink/Accent CTA Button on right)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardAlt : const Color(0xFFF9F9FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Price on left
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Valuation',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$priceDisplay EGP',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Pill Action Button: "Manage Unit" (Pink / Coral highlight pill as reference)
                  ElevatedButton(
                    onPressed: _showUnitSpecificationsBottomSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5286), // Reference vibrant pink pill button
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    child: const Text(
                      'Manage Unit',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

  Widget _buildMiniSpecCircle(IconData icon, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.accent, size: 17),
    );
  }

  /// Real Dynamic Content for the 4 Detail Tabs
  Widget _buildActiveTabContent(Unit unit, bool isDark, Color textColor, Color textMuted) {
    if (_selectedDetailTabIndex == 0) {
      // Overview / Specifications
      return Column(
        children: [
          _buildSpecRow('Unit Number', 'Unit ${unit.unitNumber}', textColor, textMuted),
          const Divider(height: 14),
          _buildSpecRow('Floor Area', '${unit.areaSquareMeters.toStringAsFixed(0)} sqm (${unit.areaSqFt.toStringAsFixed(0)} sqft)', textColor, textMuted),
          const Divider(height: 14),
          _buildSpecRow('Parking Slot', '${unit.parkingSpaces} Dedicated Bay', textColor, textMuted),
          const Divider(height: 14),
          _buildSpecRow('Handover Status', unit.status.nameString, AppColors.success, textMuted),
        ],
      );
    } else if (_selectedDetailTabIndex == 1) {
      // Financials Summary
      final totalContract = _assignedContract?.agreedTotalPrice ?? unit.priceEGP;
      final totalPaid = _unitInstallments.where((i) => i.isPaid).fold(0.0, (sum, i) => sum + i.paidAmount);
      final remaining = (totalContract - totalPaid).clamp(0.0, double.infinity);

      return Column(
        children: [
          _buildSpecRow('Contract Value', '${(totalContract / 1000000).toStringAsFixed(2)}M EGP', AppColors.accent, textMuted),
          const Divider(height: 14),
          _buildSpecRow('Paid to Date', '${(totalPaid / 1000000).toStringAsFixed(2)}M EGP', AppColors.success, textMuted),
          const Divider(height: 14),
          _buildSpecRow('Remaining Balance', '${(remaining / 1000000).toStringAsFixed(2)}M EGP', remaining > 0 ? AppColors.error : AppColors.success, textMuted),
        ],
      );
    } else if (_selectedDetailTabIndex == 2) {
      // Schedule Summary
      final nextInstallment = _unitInstallments.firstWhere((i) => !i.isPaid, orElse: () => _unitInstallments.firstOrNull ?? Installment(id: '1', contractId: '', unitId: unit.id, sequenceNumber: 1, installmentType: InstallmentType.regularQuarterly, dueDate: DateTime.now(), principalAmount: 125000, buyerUserId: 'owner', gracePeriodEndDate: DateTime.now().add(const Duration(days: 14))));
      return Column(
        children: [
          _buildSpecRow('Next Due Date', '${nextInstallment.dueDate.day}/${nextInstallment.dueDate.month}/${nextInstallment.dueDate.year}', AppColors.accent, textMuted),
          const Divider(height: 14),
          _buildSpecRow('Next Amount', '${nextInstallment.totalAmountDue.toStringAsFixed(0)} EGP', textColor, textMuted),
          const Divider(height: 14),
          _buildSpecRow('Total Schedule Count', '${_unitInstallments.length} Installments', textColor, textMuted),
        ],
      );
    } else {
      // Guest Pass / Quick Actions
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CompoundMapScreen(compound: _selectedCompound ?? const CompoundModel(id: 'sky_hills', title: 'Sky Hills', location: 'New October', category: 'Luxury', description: '', basePriceEGP: 3500000, areaSqFt: 1800, completionPercentage: 85, heroImageUrl: '', cardImageUrl: '', primaryView: '')))),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                  borderRadius: AppBorderRadius.pill,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, color: AppColors.accent, size: 15),
                    SizedBox(width: 6),
                    Text('Compound Map', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_unitDocuments.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DocumentViewerScreen(title: _unitDocuments.first.title, documentUrl: _unitDocuments.first.fileUrl)));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                  borderRadius: AppBorderRadius.pill,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_rounded, color: AppColors.accent, size: 15),
                    SizedBox(width: 6),
                    Text('Deed & Docs', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSpecRow(String label, String value, Color valColor, Color labelColor) {
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

  /// Bottom Sheet for switching Compounds and Units
  void _showAssetPickerBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final accessibleUnits = _userAccessibleUnits;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(20),
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
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted.withAlpha(80),
                    borderRadius: AppBorderRadius.pill,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Property Unit',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: accessibleUnits.length,
                  itemBuilder: (context, idx) {
                    final u = accessibleUnits[idx];
                    final isSelected = u.id == _selectedUnit?.id || u.unitNumber == _selectedUnit?.unitNumber;
                    return GestureDetector(
                      onTap: () {
                        _onUnitSelected(u);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent.withAlpha(isDark ? 40 : 20) : cardAltBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.accent : Colors.transparent, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.accent : (isDark ? AppColors.darkCard : Colors.white),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.home_work_rounded, color: isSelected ? Colors.white : AppColors.accent, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unit ${u.unitNumber}',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${u.configuration.isNotEmpty ? u.configuration : u.assetClass} • ${u.areaSquareMeters.toStringAsFixed(0)} sqm',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
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
                                color: isSelected ? AppColors.accent : textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Full Specifications Modal
  void _showUnitSpecificationsBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final u = _selectedUnit ?? _defaultSkyHillsUnit;

    final buildingName = _selectedBuilding?.name ?? u.buildingId ?? 'Building B207';
    final config = u.configuration.isNotEmpty ? u.configuration : u.assetClass;
    final priceVal = u.priceEGP;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
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
                          const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Sky Hills • $buildingName',
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              const SizedBox(height: 20),
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
                    _buildSpecRow('Total Valuation', '${(priceVal / 1000000).toStringAsFixed(2)}M EGP', AppColors.accent, textMuted),
                    const Divider(height: 16),
                    _buildSpecRow('Floor Level', u.floorTier, textColor, textMuted),
                    const Divider(height: 16),
                    _buildSpecRow('Parking Bay', '${u.parkingSpaces} Dedicated', textColor, textMuted),
                    const Divider(height: 16),
                    _buildSpecRow('Ownership Status', 'Verified Resident Owner', AppColors.success, textMuted),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.pill),
                  ),
                  child: const Text('Close', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
