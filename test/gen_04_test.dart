import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/user_profile.dart';
import 'package:iliving/theme/luxury_theme.dart';
import 'render_screens_3_4_5_7_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const brainDir = '/Users/hazemhany/.gemini/antigravity-ide/brain/338380e5-ce7c-4f74-b446-66a78a8d4e91';

  final userB = UserProfile(
    uid: 'client_89',
    clientCode: '89',
    email: 'mahmoud.ghanem.ibrahim@new-build-egypt.com',
    fullName: 'محمود غانم إبراهيم',
    phoneNumber: '032465795140',
    role: UserRole.customer,
    associatedUnitIds: ['B101B409'],
    createdAt: DateTime(2024, 2, 20),
  );

  setUpAll(() async {
    await loadSystemFonts();
  });

  testWidgets('Artifact 04: User B Login Home Screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LuxuryTheme.darkTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('capture_boundary'),
            child: buildResidentDashboard(
              user: userB,
              unitNumber: 'B101B409',
              compoundName: 'Lamar Plaza (لامار)',
              statusLabel: 'LOGGED IN',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundaryFinder = find.byKey(const Key('capture_boundary'));
    final RenderRepaintBoundary boundary = tester.renderObject(boundaryFinder);
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      File('$brainDir/04_user_b_home_screen.png').writeAsBytesSync(byteData.buffer.asUint8List());
    }
  });
}
