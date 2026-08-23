abstract class AnalyticsRepository {
  Future<Map<String, dynamic>> fetchExecutiveDashboardMetrics();
  Future<Map<String, dynamic>> fetchCompoundMetrics(String compoundId);
}
