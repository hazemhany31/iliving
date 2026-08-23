import '../repositories/interfaces/analytics_repository.dart';

class AnalyticsService {
  final AnalyticsRepository _analyticsRepository;

  AnalyticsService({required AnalyticsRepository analyticsRepository})
      : _analyticsRepository = analyticsRepository;

  Future<Map<String, dynamic>> getExecutiveDashboardKpis() async {
    return await _analyticsRepository.fetchExecutiveDashboardMetrics();
  }

  Future<Map<String, dynamic>> getCompoundOccupancyReport(String compoundId) async {
    return await _analyticsRepository.fetchCompoundMetrics(compoundId);
  }
}
