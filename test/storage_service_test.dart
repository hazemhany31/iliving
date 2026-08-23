import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/services/storage_service.dart';

void main() {
  group('StorageService Upload Proof Tests', () {
    test('1. Payment proof receipt upload produces valid storage URL', () async {
      final fakeBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]); // JPEG header
      double lastProgress = 0.0;

      final downloadUrl = await StorageService.instance.uploadPaymentProof(
        paymentId: 'PAY-10029',
        file: fakeBytes,
        fileName: 'bank_transfer_receipt.jpg',
        onProgress: (p) => lastProgress = p,
      );

      expect(downloadUrl, isNotEmpty);
      expect(downloadUrl, contains('receipts'));
      expect(downloadUrl, contains('PAY-10029'));
      expect(lastProgress, equals(1.0));
    });

    test('2. KYC document upload produces valid storage URL with proper path', () async {
      final fakePdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // %PDF header
      double lastProgress = 0.0;

      final downloadUrl = await StorageService.instance.uploadKycDocument(
        userId: 'USR-87321',
        docType: 'national_id_front',
        file: fakePdfBytes,
        fileName: 'national_id.pdf',
        onProgress: (p) => lastProgress = p,
      );

      expect(downloadUrl, isNotEmpty);
      expect(downloadUrl, contains('users'));
      expect(downloadUrl, contains('USR-87321'));
      expect(downloadUrl, contains('kyc'));
      expect(downloadUrl, contains('national_id_front'));
      expect(lastProgress, equals(1.0));
    });

    test('3. Profile avatar upload produces valid user avatar URL', () async {
      final fakeAvatarBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header
      double lastProgress = 0.0;

      final downloadUrl = await StorageService.instance.uploadProfileAvatar(
        userId: 'client_87',
        file: fakeAvatarBytes,
        fileName: 'new_avatar.png',
        onProgress: (p) => lastProgress = p,
      );

      expect(downloadUrl, isNotEmpty);
      expect(downloadUrl, contains('users'));
      expect(downloadUrl, contains('client_87'));
      expect(downloadUrl, contains('avatar'));
      expect(lastProgress, equals(1.0));
    });
  });
}
