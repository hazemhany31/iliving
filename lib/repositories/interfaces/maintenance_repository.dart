import '../../models/maintenance_request.dart';
import '../../models/maintenance_comment.dart';

abstract class MaintenanceRepository {
  Future<MaintenanceRequest?> getTicketById(String ticketId);
  Stream<MaintenanceRequest?> streamTicket(String ticketId);
  Stream<List<MaintenanceRequest>> streamTicketsForUser(String userId);
  Stream<List<MaintenanceRequest>> streamTicketsForCompound(String compoundId);
  Stream<List<MaintenanceRequest>> streamAllTickets();
  Future<List<MaintenanceRequest>> getTickets({
    String? compoundId,
    String? residentUserId,
    MaintenanceStatus? status,
    String? category,
    String? urgency,
    int? limit,
    String? startAfterId,
  });
  Future<void> createTicket(MaintenanceRequest ticket);
  Future<void> updateTicket(MaintenanceRequest ticket);
  Future<void> deleteTicket(String ticketId);
  Future<void> updateTicketStatus(String ticketId, MaintenanceStatus status, {String? technicianId});
  Stream<List<MaintenanceComment>> streamCommentsForTicket(String ticketId);
  Future<void> addComment(MaintenanceComment comment);
  Future<void> batchUpdateTicketStatus(List<String> ticketIds, MaintenanceStatus status);
}
