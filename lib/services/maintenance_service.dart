import '../models/maintenance_request.dart';
import '../repositories/interfaces/maintenance_repository.dart';

class MaintenanceService {
  final MaintenanceRepository _maintenanceRepository;

  MaintenanceService({required MaintenanceRepository maintenanceRepository})
      : _maintenanceRepository = maintenanceRepository;

  Future<void> assignTechnician(String ticketId, String technicianUserId) async {
    await _maintenanceRepository.updateTicketStatus(
      ticketId,
      MaintenanceStatus.assigned,
      technicianId: technicianUserId,
    );
  }

  Future<void> completeTicket(String ticketId) async {
    await _maintenanceRepository.updateTicketStatus(
      ticketId,
      MaintenanceStatus.completed,
    );
  }
}
