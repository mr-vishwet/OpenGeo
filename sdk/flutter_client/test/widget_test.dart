import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengeo_flutter/main.dart';
import 'package:opengeo_flutter/models/place.dart' as opengeo_model;

void main() {
  group('App loading', () {
    testWidgets('OpenGeo app loads', (WidgetTester tester) async {
      await tester.pumpWidget(const OpenGeoApp());

      // Verify the app loads without errors
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Home screen has mode icon', (WidgetTester tester) async {
      await tester.pumpWidget(const OpenGeoApp());

      // Verify mode selection icon exists
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('NavigationMode values are correct', (WidgetTester tester) async {
      expect(opengeo_model.NavigationMode.values.length, 4);
      expect(opengeo_model.NavigationMode.liveRealtime.label, 'Live Realtime');
      expect(opengeo_model.NavigationMode.satellite.label, 'Satellite');
      expect(opengeo_model.NavigationMode.llmBased.label, 'LLM Based');
      expect(opengeo_model.NavigationMode.gameMaps.label, 'Game Maps');
    });
  });

  group('kill-the-vibecode-mobile compliance tests', () {
    testWidgets('no invented ratings', (WidgetTester tester) async {
      await tester.pumpWidget(const OpenGeoApp());

      // Verify no fake 5-star ratings
      expect(find.textContaining('5.0'), findsNothing);
      expect(find.textContaining('rating'), findsNothing);
      expect(find.textContaining('star'), findsNothing);
    });

    testWidgets('AppBar has title', (WidgetTester tester) async {
      await tester.pumpWidget(const OpenGeoApp());

      // AppBar should have a proper title
      expect(find.textContaining('OpenGeo'), findsOneWidget);
    });
  });
}