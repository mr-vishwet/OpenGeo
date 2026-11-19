import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengeo_flutter/main.dart';
import 'package:opengeo_flutter/models/map_mode.dart';
import 'package:opengeo_flutter/screens/select_mode_screen.dart';

void main() {
  testWidgets('splash shows the brand and Get Started', (tester) async {
    await tester.pumpWidget(const OpenGeoApp());

    expect(find.text('OpenGeo'), findsOneWidget);
    expect(find.text('Explore. Navigate. Build Smarter.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).theme, isNotNull);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).darkTheme,
      isNotNull,
    );
  });

  testWidgets('Get Started opens Select a Mode with all five modes',
      (tester) async {
    await tester.pumpWidget(const OpenGeoApp());
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(SelectModeScreen), findsOneWidget);
    expect(find.text('Select a Mode'), findsOneWidget);
    expect(find.text('Choose how you want to explore maps'), findsOneWidget);
    for (final mode in MapMode.values) {
      expect(find.text(mode.label), findsOneWidget);
    }
  });

  testWidgets('mode cards fit a 360x640 screen without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: SelectModeScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Custom World'), 200);
    expect(find.text('Custom World'), findsOneWidget);
  });
}
