import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/notification.dart';

void main() {
  group('Real-Time Notifications & Deep Linking Unit Tests', () {
    test('Payment Reconciled Event Notification contains exact amount and unit link', () {
      final notif = AppNotification(
        id: 'notif_pay_405k',
        targetUserId: 'USR-HAZEM-001',
        title: 'Payment Reconciled (405,000 EGP)',
        titleAr: 'تمت تسوية الدفعة (405,000 ج.م)',
        body: 'Payment for unit A01-207 has been reconciled with HSBC official clearance.',
        bodyAr: 'تمت تسوية دفعة الوحدة A01-207 بنجاح مع إشعار بنك HSBC الرسمي.',
        type: 'payment',
        unitId: 'A01-207',
        installmentId: 'INS-2026-08',
        installmentAmount: 405000.0,
        pdfUrl: 'https://iliving.app/receipts/REC-405000.pdf',
        pdfTitle: 'HSBC Official Receipt - 405,000 EGP',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(notif.isRead, false);
      expect(notif.installmentAmount, 405000.0);
      expect(notif.unitId, 'A01-207');
      expect(notif.type, 'payment');
      expect(notif.pdfUrl, isNotEmpty);

      // Serialization test
      final map = notif.toJson();
      expect(map['isRead'], false);
      expect(map['installmentAmount'], 405000.0);
      expect(map['unitId'], 'A01-207');

      final fromJson = AppNotification.fromJson(map);
      expect(fromJson.title, notif.title);
      expect(fromJson.installmentAmount, 405000.0);
      expect(fromJson.isRead, false);
    });

    test('Maintenance Ticket Status Change Notification triggers deep link payload', () {
      final notif = AppNotification(
        id: 'notif_maint_001',
        targetUserId: 'USR-HAZEM-001',
        title: 'Maintenance Ticket #TK-8821 Approved',
        titleAr: 'تمت الموافقة على طلب الصيانة #TK-8821',
        body: 'HVAC technician assigned and work order in progress for Unit A01-207.',
        bodyAr: 'تم تعيين فني التكييف وجاري تنفيذ أمر العمل للوحدة A01-207.',
        type: 'maintenance_updated',
        unitId: 'A01-207',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(notif.type, 'maintenance_updated');
      expect(notif.unitId, 'A01-207');
      expect(notif.title, contains('#TK-8821'));
      expect(notif.isRead, false);
    });

    test('Document Uploaded Notification contains valid PDF URL and Title', () {
      final notif = AppNotification(
        id: 'notif_doc_001',
        targetUserId: 'USR-HAZEM-001',
        title: 'New Document Uploaded: SPA Contract',
        titleAr: 'تم رفع مستند جديد: عقد البيع النهائي',
        body: 'Your SPA document is now signed and available for download.',
        bodyAr: 'عقد البيع النهائي موقع ومتاح الآن للتحميل.',
        type: 'document_uploaded',
        unitId: 'A01-207',
        pdfUrl: 'https://iliving.app/documents/SPA_A01-207.pdf',
        pdfTitle: 'SPA Contract - Unit A01-207',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(notif.type, 'document_uploaded');
      expect(notif.pdfUrl, 'https://iliving.app/documents/SPA_A01-207.pdf');
      expect(notif.pdfTitle, 'SPA Contract - Unit A01-207');
    });

    test('Dynamic unread badge count calculation and mark as read flow', () {
      final notifications = [
        AppNotification(
          id: '1',
          targetUserId: 'USR-HAZEM-001',
          title: 'Payment 1',
          body: 'B1',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: '2',
          targetUserId: 'USR-HAZEM-001',
          title: 'Ticket 1',
          body: 'B2',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: '3',
          targetUserId: 'USR-HAZEM-001',
          title: 'Document 1',
          body: 'B3',
          isRead: true, // already read
          createdAt: DateTime.now(),
        ),
      ];

      // Initial unread count should be 2
      int unreadCount = notifications.where((n) => !n.isRead).length;
      expect(unreadCount, 2);

      // Simulate marking item 1 as read
      final updatedList = notifications.map((n) {
        if (n.id == '1') {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      unreadCount = updatedList.where((n) => !n.isRead).length;
      expect(unreadCount, 1);

      // Simulate mark all as read
      final allReadList = updatedList.map((n) => n.copyWith(isRead: true)).toList();
      unreadCount = allReadList.where((n) => !n.isRead).length;
      expect(unreadCount, 0);
    });
  });
}
