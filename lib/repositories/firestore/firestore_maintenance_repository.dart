import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/maintenance_request.dart';
import '../../models/maintenance_comment.dart';
import '../../services/notification_service.dart';
import '../interfaces/maintenance_repository.dart';
import 'firestore_notification_repository.dart';

class FirestoreMaintenanceRepository implements MaintenanceRepository {
  final FirebaseFirestore _firestore;

  FirestoreMaintenanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  NotificationService get _notifService => NotificationService(
        notificationRepository: FirestoreNotificationRepository(firestore: _firestore),
      );

  CollectionReference<Map<String, dynamic>> get _ticketsRef =>
      _firestore.collection('maintenance_tickets');

  @override
  Future<MaintenanceRequest?> getTicketById(String ticketId) async {
    final doc = await _ticketsRef.doc(ticketId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return MaintenanceRequest.fromJson(data);
  }

  @override
  Stream<MaintenanceRequest?> streamTicket(String ticketId) {
    return _ticketsRef.doc(ticketId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return MaintenanceRequest.fromJson(data);
    });
  }

  @override
  Stream<List<MaintenanceRequest>> streamTicketsForUser(String userId) {
    return _ticketsRef
        .where('residentUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceRequest.fromJson(doc.data()))
            .toList());
  }

  @override
  Stream<List<MaintenanceRequest>> streamTicketsForCompound(String compoundId) {
    return _ticketsRef
        .where('compoundId', isEqualTo: compoundId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceRequest.fromJson(doc.data()))
            .toList());
  }

  @override
  Stream<List<MaintenanceRequest>> streamAllTickets() {
    return _ticketsRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => MaintenanceRequest.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<List<MaintenanceRequest>> getTickets({
    String? compoundId,
    String? residentUserId,
    MaintenanceStatus? status,
    String? category,
    String? urgency,
    int? limit,
    String? startAfterId,
  }) async {
    Query<Map<String, dynamic>> q = _ticketsRef;

    if (compoundId != null && compoundId.isNotEmpty) {
      q = q.where('compoundId', isEqualTo: compoundId);
    }
    if (residentUserId != null && residentUserId.isNotEmpty) {
      q = q.where('residentUserId', isEqualTo: residentUserId);
    }
    if (status != null) {
      q = q.where('status', isEqualTo: status.name);
    }
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }

    if (startAfterId != null && startAfterId.isNotEmpty) {
      final lastDoc = await _ticketsRef.doc(startAfterId).get();
      if (lastDoc.exists) {
        q = q.startAfterDocument(lastDoc);
      }
    }

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    final snap = await q.get();
    var list = snap.docs.map((doc) => MaintenanceRequest.fromJson(doc.data())).toList();

    if (urgency != null && urgency.isNotEmpty) {
      list = list.where((t) => t.urgency.name.toLowerCase() == urgency.toLowerCase()).toList();
    }

    return list;
  }

  @override
  Future<void> createTicket(MaintenanceRequest ticket) async {
    await _ticketsRef.doc(ticket.id).set(ticket.toJson());
    try {
      await _notifService.notifyTicketCreated(
        residentUserId: ticket.residentUserId,
        unitId: ticket.unitId,
        ticketNumber: ticket.ticketNumber,
        title: ticket.title,
        urgency: ticket.urgency.name,
      );
    } catch (_) {}
  }

  @override
  Future<void> updateTicket(MaintenanceRequest ticket) async {
    await _ticketsRef.doc(ticket.id).update(ticket.toJson());
    try {
      await _notifService.notifyTicketUpdated(
        residentUserId: ticket.residentUserId,
        unitId: ticket.unitId,
        ticketNumber: ticket.ticketNumber,
        title: ticket.title,
        status: ticket.status.name,
      );
    } catch (_) {}
  }

  @override
  Future<void> deleteTicket(String ticketId) async {
    await _ticketsRef.doc(ticketId).delete();
  }

  @override
  Future<void> updateTicketStatus(String ticketId, MaintenanceStatus status,
      {String? technicianId}) async {
    final Map<String, dynamic> updateData = {
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (technicianId != null) {
      updateData['assignedTechnicianUserId'] = technicianId;
    }
    await _ticketsRef.doc(ticketId).update(updateData);

    try {
      final t = await getTicketById(ticketId);
      if (t != null) {
        await _notifService.notifyTicketUpdated(
          residentUserId: t.residentUserId,
          unitId: t.unitId,
          ticketNumber: t.ticketNumber,
          title: t.title,
          status: status.name,
        );
      }
    } catch (_) {}
  }

  @override
  Stream<List<MaintenanceComment>> streamCommentsForTicket(String ticketId) {
    return _ticketsRef
        .doc(ticketId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceComment.fromJson(doc.data()))
            .toList());
  }

  @override
  Future<void> addComment(MaintenanceComment comment) async {
    await _ticketsRef
        .doc(comment.ticketId)
        .collection('comments')
        .doc(comment.id)
        .set(comment.toJson());

    try {
      await _notifService.notifyTicketCommentAdded(
        targetUserId: comment.authorUserId,
        ticketNumber: comment.ticketId,
        authorName: comment.authorName,
        message: comment.commentText,
      );
    } catch (_) {}
  }

  @override
  Future<void> batchUpdateTicketStatus(List<String> ticketIds, MaintenanceStatus status) async {
    if (ticketIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in ticketIds) {
      batch.update(_ticketsRef.doc(id), {
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  }
}
