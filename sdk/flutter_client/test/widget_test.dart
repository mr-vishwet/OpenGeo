// This is a basic Flutter widget test for the OpenGeo client.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengeo_flutter/main.dart';
import 'package:opengeo_flutter/models/place.dart' as opengeo_model;

void main() {
  testWidgets('OpenGeo app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OpenGeoApp());

    // Verify the app loads without errors (MapScreen shows nearby places)
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.textContaining('Nearby places'), findsOneWidget);
  });

  testWidgets('NavigationMode values are correct', (WidgetTester tester) async {
    // Verify NavigationMode enum has correct number of values
    expect(opengeo_model.NavigationMode.values.length, 4);
    expect(opengeo_model.NavigationMode.values[0], opengeo_model.NavigationMode.liveRealtime);
    expect(opengeo_model.NavigationMode.values[1], opengeo_model.NavigationMode.satellite);
    expect(opengeo_model.NavigationMode.values[2], opengeo_model.NavigationMode.llmBased);
    expect(opengeo_model.NavigationMode.values[3], opengeo_model.NavigationMode.gameMaps);
  });
}
