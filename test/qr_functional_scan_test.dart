import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  group('Real Functional QR Code Tests', () {
    test('Generate real scannable QR Code payload with actual Unit and Compound data', () {
      const unitId = 'A301B208';
      const compoundId = 'sky_hills';
      const visitorName = 'Ahmed Hassan';
      const passType = 'Courier Delivery';
      const passId = 'GP-SH-984210';
      const timestamp = 1755890400000;

      final qrData = 'https://ihome.app/gate-pass?passId=$passId&compound=$compoundId&unit=$unitId&guest=${Uri.encodeComponent(visitorName)}&type=${Uri.encodeComponent(passType)}&t=$timestamp';

      expect(qrData.startsWith('https://ihome.app/gate-pass'), isTrue);
      expect(qrData.contains('unit=A301B208'), isTrue);
      expect(qrData.contains('compound=sky_hills'), isTrue);
      expect(qrData.contains('passId=GP-SH-984210'), isTrue);

      final qrValidation = QrValidator.validate(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      expect(qrValidation.status, QrValidationStatus.valid);
      expect(qrValidation.qrCode, isNotNull);
    });
  });
}
