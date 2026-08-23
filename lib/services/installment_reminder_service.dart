import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../models/installment.dart';
import '../models/notification.dart';
import '../repositories/firestore/firestore_admin_settings_repository.dart';
import '../repositories/firestore/firestore_document_repository.dart';
import '../repositories/firestore/firestore_ledger_repository.dart';
import '../repositories/firestore/firestore_notification_repository.dart';
import '../repositories/interfaces/admin_settings_repository.dart';
import '../repositories/interfaces/document_repository.dart';
import '../repositories/interfaces/ledger_repository.dart';
import '../repositories/interfaces/notification_repository.dart';
import '../repositories/operations_mock_data.dart';

class PdfResolutionResult {
  final String url;
  final String title;
  final bool isNewestUpload;

  const PdfResolutionResult({
    required this.url,
    required this.title,
    this.isNewestUpload = true,
  });
}

class InstallmentReminderService {
  final LedgerRepository _ledgerRepository;
  final NotificationRepository _notificationRepository;
  final DocumentRepository _documentRepository;
  final AdminSettingsRepository _adminSettingsRepository;

  InstallmentReminderService({
    LedgerRepository? ledgerRepository,
    NotificationRepository? notificationRepository,
    DocumentRepository? documentRepository,
    AdminSettingsRepository? adminSettingsRepository,
  })  : _ledgerRepository = ledgerRepository ?? FirestoreLedgerRepository(),
        _notificationRepository = notificationRepository ?? FirestoreNotificationRepository(),
        _documentRepository = documentRepository ?? FirestoreDocumentRepository(),
        _adminSettingsRepository = adminSettingsRepository ?? FirestoreAdminSettingsRepository();

  /// Resolves the latest available statement or payment PDF for an installment.
  /// 1. Searches documents matching unitId or ownerUserId.
  /// 2. Filters for valid PDF documents.
  /// 3. Sorts by creation date descending so the latest uploaded PDF is selected.
  /// 4. If no PDF exists, returns null (hiding the PDF button).
  Future<PdfResolutionResult?> resolveLatestPdfForInstallment(Installment installment) async {
    try {
      List<DocumentItem> docs = await _documentRepository
          .getDocuments(unitId: installment.unitId)
          .timeout(const Duration(seconds: 2), onTimeout: () => []);

      if (docs.isEmpty && installment.buyerUserId.isNotEmpty) {
        docs = await _documentRepository
            .getDocuments(ownerUserId: installment.buyerUserId)
            .timeout(const Duration(seconds: 2), onTimeout: () => []);
      }

      // Fallback check against in-memory mock documents if offline/empty
      if (docs.isEmpty) {
        docs = OperationsMockData.dummyDocuments.where((d) {
          return d.associatedUnitId == installment.unitId ||
              d.ownerUserId == installment.buyerUserId;
        }).toList();
      }

      // Filter for PDF documents
      final pdfDocs = docs.where((d) {
        final isPdfExt = d.fileExtension.toLowerCase() == 'pdf' || d.fileUrl.toLowerCase().contains('.pdf');
        return isPdfExt && d.fileUrl.isNotEmpty;
      }).toList();

      if (pdfDocs.isEmpty) return null;

      // Sort by creation date descending (latest PDF first)
      pdfDocs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final latestDoc = pdfDocs.first;
      return PdfResolutionResult(
        url: latestDoc.fileUrl,
        title: latestDoc.title.isNotEmpty
            ? latestDoc.title
            : 'Installment Statement PDF - ${installment.unitId}',
        isNewestUpload: pdfDocs.length == 1 || pdfDocs.first.id == latestDoc.id,
      );
    } catch (e) {
      debugPrint('[InstallmentReminderService] Error resolving PDF: $e');
      return null;
    }
  }

  /// Evaluates all pending installments against configured reminder days in Admin Settings
  /// and dispatches push notifications to targeted customers.
  Future<int> checkAndDispatchReminders({DateTime? customCurrentDate}) async {
    final now = customCurrentDate ?? DateTime.now();
    final settings = await _adminSettingsRepository.getInstallmentReminderSettings();

    if (!settings.autoRemindersEnabled && customCurrentDate == null) {
      debugPrint('[InstallmentReminderService] Auto reminders disabled in settings.');
      return 0;
    }

    final reminderDays = settings.reminderDays;
    if (reminderDays.isEmpty) return 0;

    // Fetch all installments
    List<Installment> installments = [];
    try {
      installments = await _ledgerRepository
          .getAllInstallments()
          .timeout(const Duration(seconds: 3), onTimeout: () => []);
    } catch (_) {}

    if (installments.isEmpty) {
      installments = OperationsMockData.dummyInstallments;
    }

    int dispatchedCount = 0;

    for (final inst in installments) {
      // Skip fully paid or waived installments
      if (inst.isPaid || inst.status == InstallmentStatus.waived) continue;

      // Calculate days until due date
      final differenceInDays = inst.dueDate.difference(now).inDays;
      final isExactTriggerDay = reminderDays.contains(differenceInDays);
      final isOverdue = inst.dueDate.isBefore(now);

      // Trigger if exact reminder day or overdue
      if (isExactTriggerDay || (isOverdue && reminderDays.contains(0))) {
        final pdfResult = await resolveLatestPdfForInstallment(inst);
        final String daysTextEn = isOverdue
            ? 'OVERDUE by ${differenceInDays.abs()} days'
            : differenceInDays == 0
                ? 'DUE TODAY'
                : 'Due in $differenceInDays days';
        final String daysTextAr = isOverdue
            ? 'متأخر بـ ${differenceInDays.abs()} يوم'
            : differenceInDays == 0
                ? 'مستحق اليوم'
                : 'مستحق خلال $differenceInDays أيام';

        final String typeNameEn = _getInstallmentTypeNameEn(inst.installmentType);
        final String typeNameAr = _getInstallmentTypeNameAr(inst.installmentType);

        final String formattedAmount = _formatCurrency(inst.remainingAmount);

        final notificationId = 'NTF-REM-${inst.id}-$differenceInDays';

        // Check if notification already exists to avoid duplicate pushes
        final existing = await _notificationRepository
            .getNotificationById(notificationId)
            .timeout(const Duration(seconds: 2), onTimeout: () => null);
        if (existing != null) continue;

        final notif = AppNotification(
          id: notificationId,
          targetUserId: inst.buyerUserId,
          title: 'Installment Reminder: $typeNameEn ($daysTextEn)',
          titleAr: 'تنبيه استحقاق قسط: $typeNameAr ($daysTextAr)',
          body: 'Unit ${inst.unitId} • Amount: EGP $formattedAmount • Due: ${_formatDate(inst.dueDate)}',
          bodyAr: 'الوحدة ${inst.unitId} • المبلغ: $formattedAmount ج.م • الاستحقاق: ${_formatDate(inst.dueDate)}',
          priority: isOverdue ? NotificationPriority.critical : NotificationPriority.high,
          deepLinkRoute: '/installment_payment?id=${inst.id}',
          type: 'installment_reminder',
          installmentId: inst.id,
          unitId: inst.unitId,
          contractId: inst.contractId,
          installmentAmount: inst.remainingAmount,
          dueDate: inst.dueDate,
          installmentName: '$typeNameEn #${inst.sequenceNumber}',
          installmentNameAr: '$typeNameAr #${inst.sequenceNumber}',
          unitInfo: 'Unit ${inst.unitId}',
          unitInfoAr: 'وحدة ${inst.unitId}',
          pdfUrl: pdfResult?.url,
          pdfTitle: pdfResult?.title,
          createdAt: DateTime.now(),
        );

        await _notificationRepository
            .sendNotification(notif)
            .timeout(const Duration(seconds: 2), onTimeout: () {});
        dispatchedCount++;
      }
    }

    // Update last run timestamp in Admin Settings
    final updatedSettings = settings.copyWith(lastRunTimestamp: DateTime.now());
    await _adminSettingsRepository
        .saveInstallmentReminderSettings(updatedSettings)
        .timeout(const Duration(seconds: 2), onTimeout: () {});

    return dispatchedCount;
  }

  static String _getInstallmentTypeNameEn(InstallmentType type) {
    switch (type) {
      case InstallmentType.downPayment:
        return 'Down Payment';
      case InstallmentType.regularQuarterly:
        return 'Quarterly Installment';
      case InstallmentType.semiAnnual:
        return 'Semi-Annual Installment';
      case InstallmentType.annual:
        return 'Annual Installment';
      case InstallmentType.balloon:
        return 'Balloon Payment';
      case InstallmentType.maintenanceFund:
        return 'Maintenance Deposit';
      case InstallmentType.deliveryPayment:
        return 'Handover Delivery Payment';
    }
  }

  static String _getInstallmentTypeNameAr(InstallmentType type) {
    switch (type) {
      case InstallmentType.downPayment:
        return 'دفعة التعاقد المقدمة';
      case InstallmentType.regularQuarterly:
        return 'القسط الدوري الربع سنوي';
      case InstallmentType.semiAnnual:
        return 'القسط النصف سنوي';
      case InstallmentType.annual:
        return 'القسط السنوي';
      case InstallmentType.balloon:
        return 'الدفعة الكبرى (Balloon)';
      case InstallmentType.maintenanceFund:
        return 'وديعة الصيانة';
      case InstallmentType.deliveryPayment:
        return 'دفعة الاستلام والتسليم';
    }
  }

  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
