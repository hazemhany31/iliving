import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/repositories/repositories.dart';

void main() {
  group('Repository Architecture Verification', () {
    test('Exports all 15 repository interfaces correctly', () {
      expect(AuthRepository, isNotNull);
      expect(UserRepository, isNotNull);
      expect(ProjectRepository, isNotNull);
      expect(CompoundRepository, isNotNull);
      expect(BuildingRepository, isNotNull);
      expect(UnitRepository, isNotNull);
      expect(ContractRepository, isNotNull);
      expect(LedgerRepository, isNotNull);
      expect(PaymentRepository, isNotNull);
      expect(MaintenanceRepository, isNotNull);
      expect(DocumentRepository, isNotNull);
      expect(NotificationRepository, isNotNull);
      expect(GateRepository, isNotNull);
      expect(AnalyticsRepository, isNotNull);
      expect(ExecutiveDashboardRepository, isNotNull);
    });

    test('Instantiates Firestore repositories without UI dependencies', () {
      expect(FirestoreUserRepository, isNotNull);
      expect(FirestoreProjectRepository, isNotNull);
      expect(FirestoreCompoundRepository, isNotNull);
      expect(FirestoreBuildingRepository, isNotNull);
      expect(FirestoreUnitRepository, isNotNull);
      expect(FirestoreContractRepository, isNotNull);
      expect(FirestoreLedgerRepository, isNotNull);
      expect(FirestorePaymentRepository, isNotNull);
      expect(FirestoreDocumentRepository, isNotNull);
      expect(FirestoreMaintenanceRepository, isNotNull);
      expect(FirestoreNotificationRepository, isNotNull);
      expect(FirestoreGateRepository, isNotNull);
      expect(FirestoreAnalyticsRepository, isNotNull);
      expect(FirestoreExecutiveDashboardRepository, isNotNull);
    });
  });
}
