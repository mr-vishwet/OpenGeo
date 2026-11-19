import 'package:flutter_test/flutter_test.dart';
import 'package:opengeo_flutter/models/place.dart';

void main() {
  const place = Place(
    id: 'osho-garden',
    name: 'Osho Garden',
    category: 'park',
    latitude: 18.5089,
    longitude: 73.8584,
    distanceMeters: 850,
    rating: 4.6,
    reviewCount: 12000,
  );

  group('Place', () {
    test('displayName prefers the untagged localized name', () {
      const withNames = Place(
        id: 'x',
        name: 'Pune',
        category: 'city',
        latitude: 18.52,
        longitude: 73.85,
        names: [
          LocalizedName(language: 'mr', value: 'पुणे'),
          LocalizedName(language: '', value: 'Pune City'),
        ],
      );
      expect(withNames.displayName, 'Pune City');
    });

    test('displayName falls back to name', () {
      expect(place.displayName, 'Osho Garden');
    });

    test('distanceFormatted switches at one kilometre', () {
      expect(place.distanceFormatted, '850 m');
      expect(
        const Place(
          id: 'y',
          name: 'Y',
          category: 'cafe',
          latitude: 18,
          longitude: 73,
          distanceMeters: 1300,
        ).distanceFormatted,
        '1.3 km',
      );
    });

    test('distanceFormatted is a dash when distance is unknown', () {
      const unknown = Place(
        id: 'z',
        name: 'Z',
        category: 'cafe',
        latitude: 18,
        longitude: 73,
      );
      expect(unknown.distanceFormatted, '—');
    });

    test('ratingLabel abbreviates thousands', () {
      expect(place.ratingLabel, '4.6 (12.0k)');
      expect(
        const Place(
          id: 'w',
          name: 'W',
          category: 'cafe',
          latitude: 18,
          longitude: 73,
          rating: 4.4,
          reviewCount: 932,
        ).ratingLabel,
        '4.4 (932)',
      );
    });

    test('ratingLabel is null for unrated records', () {
      const unrated = Place(
        id: 'u',
        name: 'U',
        category: 'cafe',
        latitude: 18,
        longitude: 73,
      );
      expect(unrated.ratingLabel, isNull);
    });

    test('metaLine joins category, distance and price', () {
      expect(place.metaLine, 'Park · 850 m');
      expect(
        const Place(
          id: 'p',
          name: 'P',
          category: 'cafe',
          latitude: 18,
          longitude: 73,
          distanceMeters: 650,
          priceLevel: '₹₹',
        ).metaLine,
        'Cafe · 650 m · ₹₹',
      );
    });

    test('coordinatesLabel is labelled and four decimals', () {
      expect(place.coordinatesLabel, '18.5089° N, 73.8584° E');
    });

    test('addressLine joins the known address parts', () {
      const addressed = Place(
        id: 'a',
        name: 'A',
        category: 'cafe',
        latitude: 18,
        longitude: 73,
        address: {'house_number': '12', 'street': 'FC Road', 'locality': 'Shivajinagar'},
      );
      expect(addressed.addressLine, '12, FC Road, Shivajinagar');
      expect(place.addressLine, isNull);
    });

    test('fromJson never invents sample-only fields', () {
      final parsed = Place.fromJson({
        'id': 'api-1',
        'name': 'API Place',
        'category': 'cafe',
        'longitude': 73.85,
        'latitude': 18.52,
        'distance_meters': 320,
      });
      expect(parsed.distanceMeters, 320);
      expect(parsed.rating, isNull);
      expect(parsed.reviewCount, isNull);
      expect(parsed.priceLevel, isNull);
      expect(parsed.ratingLabel, isNull);
    });

    test('fromJson reads localized names', () {
      final parsed = Place.fromJson({
        'id': 'api-2',
        'name': 'Pune',
        'longitude': 73.85,
        'latitude': 18.52,
        'names': [
          {'language': 'mr', 'value': 'पुणे'},
          {'language': '', 'value': 'Pune'},
        ],
      });
      expect(parsed.displayName, 'Pune');
      expect(parsed.category, '');
    });

    test('toJson round-trips the core fields', () {
      final json = place.toJson();
      expect(json['id'], 'osho-garden');
      expect(json['longitude'], 73.8584);
      expect(json['distance_meters'], 850);
      expect(json.containsKey('rating'), isFalse);
    });
  });
}
