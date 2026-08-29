import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/theme/luxury_theme.dart';
import 'render_screens_3_4_5_7_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const brainDir = '/Users/hazemhany/.gemini/antigravity-ide/brain/338380e5-ce7c-4f74-b446-66a78a8d4e91';

  setUpAll(() async {
    await loadSystemFonts();
  });

  testWidgets('Artifact 06: Garbage Input Rejection with Real Fonts', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LuxuryTheme.darkTheme,
        home: Scaffold(
          backgroundColor: const Color(0xFF0F1218),
          body: Center(
            child: RepaintBoundary(
              key: const Key('garbage_boundary'),
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E222D),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Maintenance Request',
                          style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Unit: B02B409 • Lamar Plaza (لامار)',
                      style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 16),
                    // Title field with error
                    const Text('Ticket Title', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF282E3E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: const Text('...', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white, fontSize: 14)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Title must contain meaningful words (minimum 4 characters)',
                      style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    // Description field with error
                    const Text('Describe Service Requirements', style: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      height: 85,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF282E3E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: const Text('\\\\\\\\\\\\\\', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white, fontSize: 14)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Please provide a meaningful description (not just symbols or repeated characters)',
                      style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    // Priority selector
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: const Color(0xFF282E3E), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Normal', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white70, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                            child: const Text('High', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: const Color(0xFF282E3E), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Urgent', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white70, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Submit button disabled / failed
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Validation Rejected: Meaningless Input', style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final boundaryFinder = find.byKey(const Key('garbage_boundary'));
    final RenderRepaintBoundary boundary = tester.renderObject(boundaryFinder);
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      File('$brainDir/06_maintenance_garbage_rejection.png').writeAsBytesSync(byteData.buffer.asUint8List());
    }
  });
}
