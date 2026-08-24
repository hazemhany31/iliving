import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A production-ready, ISO-compliant QR Code Widget for smart gate access passes and unit verification.
class QrCodeWidget extends StatelessWidget {
  final String qrData;
  final double size;
  final Color primaryColor;
  final Color backgroundColor;
  final IconData? centerIcon;
  final GlobalKey? repaintBoundaryKey;

  const QrCodeWidget({
    super.key,
    required this.qrData,
    this.size = 200,
    this.primaryColor = const Color(0xFF1B1E28),
    this.backgroundColor = Colors.white,
    this.centerIcon,
    this.repaintBoundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    final qrWidget = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor == Colors.white ? const Color(0xFFC5A880).withAlpha(80) : primaryColor.withAlpha(30),
          width: 1.5,
        ),
      ),
      child: Center(
        child: QrImageView(
          data: qrData.isEmpty ? 'https://iliving.app' : qrData,
          version: QrVersions.auto,
          size: size - 24,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: primaryColor,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: primaryColor,
          ),
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        ),
      ),
    );

    if (repaintBoundaryKey != null) {
      return RepaintBoundary(
        key: repaintBoundaryKey,
        child: qrWidget,
      );
    }
    return qrWidget;
  }
}
