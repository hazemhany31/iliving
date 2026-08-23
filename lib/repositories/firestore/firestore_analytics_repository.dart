import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/analytics_repository.dart';

class FirestoreAnalyticsRepository implements AnalyticsRepository {
  final FirebaseFirestore _firestore;

  FirestoreAnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>> fetchExecutiveDashboardMetrics() async {
    final unitsCount = await _firestore.collection('units').count().get();
    final usersCount = await _firestore.collection('users').count().get();
    final paymentsCount = await _firestore.collection('payments').count().get();

    return {
      'totalUnits': unitsCount.count,
      'totalUsers': usersCount.count,
      'totalPaymentsLogged': paymentsCount.count,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> fetchCompoundMetrics(String compoundId) async {
    final compoundUnits = await _firestore
        .collection('units')
        .where('compoundId', isEqualTo: compoundId)
        .get();

    final total = compoundUnits.docs.length;
    int available = 0;
    int reserved = 0;
    int contracted = 0;
    int delivered = 0;

    for (var doc in compoundUnits.docs) {
      final status = doc.data()['status'] as String?;
      switch (status) {
        case 'AVAILABLE':
          available++;
          break;
        case 'RESERVED':
        case 'HOLD':
          reserved++;
          break;
        case 'CONTRACTED':
          contracted++;
          break;
        case 'DELIVERED':
          delivered++;
          break;
      }
    }

    return {
      'compoundId': compoundId,
      'totalUnits': total,
      'availableUnits': available,
      'reservedUnits': reserved,
      'contractedUnits': contracted,
      'deliveredUnits': delivered,
    };
  }
}
