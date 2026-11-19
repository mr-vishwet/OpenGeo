import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengeo_flutter/models/place.dart' as opengeo_model;

void main() {
  group('Place', () {
    test('displayName returns name when names is null', () {
      const place = opengeo_model.Place(
        id: 'test-1',
        name: 'Test Cafe',
        category: 'cafe',
        longitude: 73.85,
        latitude: 18.52,
      );

      expect(place.displayName, 'Test Cafe');
    });

    test('displayName returns first value when language is empty', () {
      const place = opengeo_model.Place(
        id: 'test-1',
        name: 'Test Cafe',
        category: 'cafe',
        longitude: 73.85,
        latitude: 18.52,
        names: [
          {'language': '', 'value': 'Official Name'},
          {'language': 'mr', 'value': 'मराठी नाव'},
        ],
      );

      expect(place.displayName, 'Official Name');
    });

    test('addressLine returns formatted address', () {
      const place = opengeo_model.Place(
        id: 'test-1',
        name: 'Test Cafe',
        category: 'cafe',
        longitude: 73.85,
        latitude: 18.52,
        address: {
          'house_number': '42',
          'street': 'Main Road',
          'locality': 'Shivajinagar',
        },
      );

      expect(place.addressLine, '42, Main Road, Shivajinagar');
    });

    test('distanceFormatted returns correct string for meters', () {
      const place = opengeo_model.Place(
        id: 'test-1',
        name: 'Test Cafe',
        category: 'cafe',
        longitude: 73.85,
        latitude: 18.52,
        distanceMeters: 500,
      );

      expect(place.distanceFormatted, '500 m');
    });

    test('distanceFormatted returns correct string for kilometers', () {
      const place = opengeo_model.Place(
        id: 'test-1',
        name: 'Test Cafe',
        category: 'cafe',
        longitude: 73.85,
        latitude: 18.52,
        distanceMeters: 2500,
      );

      expect(place.distanceFormatted, '2.5 km');
    });

    test('distanceFormatted returns dash when distance is null', () {
      const place = opengeo_model.Place(
        id: 'test-1',
        name: 'Test Cafe',
        category: 'cafe',
        longitude: 73.85,
        latitude: 18.52,
        distanceMeters: null,
      );

      expect(place.distanceFormatted, '—');
    });
  });

  group('NavigationMode', () {
    test('label returns correct strings for each mode', () {
      expect(opengeo_model.NavigationMode.liveRealtime.label, 'Live Realtime');
      expect(opengeo_model.NavigationMode.satellite.label, 'Satellite');
      expect(opengeo_model.NavigationMode.llmBased.label, 'LLM Based');
      expect(opengeo_model.NavigationMode.gameMaps.label, 'Game Maps');
    });

    test('subtitle returns correct descriptions', () {
      expect(opengeo_model.NavigationMode.liveRealtime.subtitle, 'Real-time traffic & POIs');
      expect(opengeo_model.NavigationMode.satellite.subtitle, 'Satellite imagery & terrain');
      expect(opengeo_model.NavigationMode.llmBased.subtitle, 'Natural language queries');
      expect(opengeo_model.NavigationMode.gameMaps.subtitle, 'Stylized game rendering');
    });

    test('color returns distinct colors for each mode', () {
      expect(opengeo_model.NavigationMode.liveRealtime.color, const Color(0xFF00796B));
      expect(opengeo_model.NavigationMode.satellite.color, const Color(0xFF1A237E));
      expect(opengeo_model.NavigationMode.llmBased.color, const Color(0xFF6A1B9A));
      expect(opengeo_model.NavigationMode.gameMaps.color, const Color(0xFFE65100));
    });
  });
}