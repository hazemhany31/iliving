import 'package:flutter/foundation.dart';
import 'payment.dart';
import 'installment.dart';
import 'contract.dart';
import 'maintenance_request.dart';
import 'user_profile.dart';
import 'audit_log.dart';

@immutable
class MaintenanceStats {
  final int totalRequests;
  final int pendingRequests;
  final int inProgressRequests;
  final int completedRequests;
  final int cancelledRequests;

  const MaintenanceStats({
    this.totalRequests = 0,
    this.pendingRequests = 0,
    this.inProgressRequests = 0,
    this.completedRequests = 0,
    this.cancelledRequests = 0,
  });

  factory MaintenanceStats.fromJson(Map<String, dynamic> json) {
    return MaintenanceStats(
      totalRequests: (json['totalRequests'] as num?)?.toInt() ?? 0,
      pendingRequests: (json['pendingRequests'] as num?)?.toInt() ?? 0,
      inProgressRequests: (json['inProgressRequests'] as num?)?.toInt() ?? 0,
      completedRequests: (json['completedRequests'] as num?)?.toInt() ?? 0,
      cancelledRequests: (json['cancelledRequests'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRequests': totalRequests,
      'pendingRequests': pendingRequests,
      'inProgressRequests': inProgressRequests,
      'completedRequests': completedRequests,
      'cancelledRequests': cancelledRequests,
    };
  }
}

@immutable
class SalesTrendDataPoint {
  final String label; // e.g. "Jan", "Feb" or "2026-07"
  final double revenue;
  final int unitsSold;

  const SalesTrendDataPoint({
    required this.label,
    required this.revenue,
    required this.unitsSold,
  });

  factory SalesTrendDataPoint.fromJson(Map<String, dynamic> json) {
    return SalesTrendDataPoint(
      label: json['label'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      unitsSold: (json['unitsSold'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'revenue': revenue,
      'unitsSold': unitsSold,
    };
  }
}

@immutable
class ExecutiveDashboardMetrics {
  final int totalProjects;
  final int totalCompounds;
  final int totalBuildings;
  final int totalUnits;
  final int availableUnits;
  final int reservedUnits;
  final int soldUnits;
  final int activeCustomers;
  final int activeContracts;
  final double totalRevenue;
  final double outstandingBalance;
  final double monthlyCollections;
  final double occupancyRate;
  final MaintenanceStats maintenanceStats;
  final List<Payment> recentPayments;
  final List<Installment> upcomingInstallments;
  final List<Contract> recentContracts;
  final List<MaintenanceRequest> latestMaintenanceRequests;
  final List<UserProfile> latestCustomers;
  final List<AuditLog> recentActivities;
  final List<SalesTrendDataPoint> salesTrend;
  final Map<String, int> unitStatusDistribution;
  final DateTime lastUpdated;

  int get openMaintenanceRequests =>
      maintenanceStats.pendingRequests + maintenanceStats.inProgressRequests;

  const ExecutiveDashboardMetrics({
    this.totalProjects = 0,
    this.totalCompounds = 0,
    this.totalBuildings = 0,
    this.totalUnits = 0,
    this.availableUnits = 0,
    this.reservedUnits = 0,
    this.soldUnits = 0,
    this.activeCustomers = 0,
    this.activeContracts = 0,
    this.totalRevenue = 0.0,
    this.outstandingBalance = 0.0,
    this.monthlyCollections = 0.0,
    this.occupancyRate = 0.0,
    this.maintenanceStats = const MaintenanceStats(),
    this.recentPayments = const [],
    this.upcomingInstallments = const [],
    this.recentContracts = const [],
    this.latestMaintenanceRequests = const [],
    this.latestCustomers = const [],
    this.recentActivities = const [],
    this.salesTrend = const [],
    this.unitStatusDistribution = const {},
    required this.lastUpdated,
  });

  factory ExecutiveDashboardMetrics.empty() {
    return ExecutiveDashboardMetrics(lastUpdated: DateTime.now());
  }

  ExecutiveDashboardMetrics copyWith({
    int? totalProjects,
    int? totalCompounds,
    int? totalBuildings,
    int? totalUnits,
    int? availableUnits,
    int? reservedUnits,
    int? soldUnits,
    int? activeCustomers,
    int? activeContracts,
    double? totalRevenue,
    double? outstandingBalance,
    double? monthlyCollections,
    double? occupancyRate,
    MaintenanceStats? maintenanceStats,
    List<Payment>? recentPayments,
    List<Installment>? upcomingInstallments,
    List<Contract>? recentContracts,
    List<MaintenanceRequest>? latestMaintenanceRequests,
    List<UserProfile>? latestCustomers,
    List<AuditLog>? recentActivities,
    List<SalesTrendDataPoint>? salesTrend,
    Map<String, int>? unitStatusDistribution,
    DateTime? lastUpdated,
  }) {
    return ExecutiveDashboardMetrics(
      totalProjects: totalProjects ?? this.totalProjects,
      totalCompounds: totalCompounds ?? this.totalCompounds,
      totalBuildings: totalBuildings ?? this.totalBuildings,
      totalUnits: totalUnits ?? this.totalUnits,
      availableUnits: availableUnits ?? this.availableUnits,
      reservedUnits: reservedUnits ?? this.reservedUnits,
      soldUnits: soldUnits ?? this.soldUnits,
      activeCustomers: activeCustomers ?? this.activeCustomers,
      activeContracts: activeContracts ?? this.activeContracts,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      monthlyCollections: monthlyCollections ?? this.monthlyCollections,
      occupancyRate: occupancyRate ?? this.occupancyRate,
      maintenanceStats: maintenanceStats ?? this.maintenanceStats,
      recentPayments: recentPayments ?? this.recentPayments,
      upcomingInstallments: upcomingInstallments ?? this.upcomingInstallments,
      recentContracts: recentContracts ?? this.recentContracts,
      latestMaintenanceRequests:
          latestMaintenanceRequests ?? this.latestMaintenanceRequests,
      latestCustomers: latestCustomers ?? this.latestCustomers,
      recentActivities: recentActivities ?? this.recentActivities,
      salesTrend: salesTrend ?? this.salesTrend,
      unitStatusDistribution:
          unitStatusDistribution ?? this.unitStatusDistribution,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
