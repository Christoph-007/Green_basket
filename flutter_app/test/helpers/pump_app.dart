import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbasket_app/config/theme.dart';

/// Shows [child] inside the app theme at a given screen size and text scale.
///
/// Phone-sized by default (360 x 740) so layout problems show up the way they
/// would on a small device. Pass [textScale] 2.0 to mimic a person who has set
/// the largest system font. Scrolls vertically so tall content is not clipped
/// by the test screen; sideways overflow is still reported.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  double textScale = 1.0,
  Size size = const Size(360, 740),
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(
        body: SafeArea(child: SingleChildScrollView(child: child)),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
