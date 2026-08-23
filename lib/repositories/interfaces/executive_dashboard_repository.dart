import '../../models/executive_dashboard_metrics.dart';
import '../../models/audit_log.dart';

abstract class ExecutiveDashboardRepository {
  /// Stream real-time metrics for the Executive Dashboard with optional filtering by project or compound
  Stream<ExecutiveDashboardMetrics> streamExecutiveDashboardMetrics({
    String? projectId,
    String? compoundId,
  });

  /// Log an audit log / activity for quick actions or system events
  Future<void> logAuditActivity(AuditLog log);

  /// Record a payment in real time
  Future<void> recordPayment({
    required String unitId,
    required String buyerUserId,
    required double amount,
    required String paymentMethod,
    required String installmentId,
  });

  /// Create a maintenance request ticket
  Future<void> createMaintenanceTicket({
    required String compoundId,
    required String unitId,
    required String residentUserId,
    required String title,
    required String category,
    required String urgency,
  });
}
