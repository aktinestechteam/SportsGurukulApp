import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:sports_gurukul/app/app.dart';
import 'package:sports_gurukul/app/dependencies.dart';

void main() {
  setUpAll(() {
    Dependencies.initialize();
  });

  Future<void> settleApp(WidgetTester tester) async {
    await tester.pumpWidget(const SportsGurukulApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('repro hit-test crash on desktop size', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await settleApp(tester);

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(const Offset(200, 200));
    await tester.pump();
    await gesture.removePointer();
  });

  testWidgets('repro hit-test crash on compact size', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await settleApp(tester);

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(const Offset(200, 200));
    await tester.pump();
    await gesture.removePointer();
  });
}
