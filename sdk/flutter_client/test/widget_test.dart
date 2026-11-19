// This is a basic Flutter widget test for the OpenGeo client.
import 'package:flutter_test/flutter_test.dart';
import 'package:opengeo_flutter/main.dart';

void main() {
  testWidgets('OpenGeo app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OpenGeoApp());

    // Verify that the app title appears.
    expect(find.text('OpenGeo — Pune'), findsOneWidget);
  });
}
