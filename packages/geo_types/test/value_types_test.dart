import 'package:geo_types/geo_types.dart';
import 'package:test/test.dart';

void main() {
  group('Coordinate', () {
    test('accepts valid positions at the edges of the range', () {
      expect(() => Coordinate(longitude: -180, latitude: -90), returnsNormally);
      expect(() => Coordinate(longitude: 180, latitude: 90), returnsNormally);
      expect(() => Coordinate(longitude: 0, latitude: 0), returnsNormally);
    });

    test('rejects out-of-range longitude', () {
      expect(
        () => Coordinate(longitude: 181, latitude: 0),
        throwsA(isA<GeoException>().having(
            (e) => e.code, 'code', GeoErrorCode.invalidCoordinate)),
      );
    });

    test('rejects out-of-range latitude', () {
      expect(
        () => Coordinate(longitude: 0, latitude: 91),
        throwsA(isA<GeoException>().having(
            (e) => e.code, 'code', GeoErrorCode.invalidCoordinate)),
      );
    });

    test('a swap that pushes latitude past 90 is rejected', () {
      // Krabi: longitude 99.0, latitude 8.0. Swapped, latitude becomes 99.
      expect(
        () => Coordinate(longitude: 8.0, latitude: 99.0),
        throwsA(isA<GeoException>().having(
            (e) => e.code, 'code', GeoErrorCode.invalidCoordinate)),
      );
    });

    test('a mid-latitude swap is NOT detectable from range alone', () {
      // Pune is longitude 73.8567, latitude 18.5204. Swapped, both values are
      // still legal, so range validation cannot catch it. Documented limit:
      // catching this needs a bounding-box or dataset-extent check.
      final swapped = Coordinate(longitude: 18.5204, latitude: 73.8567);
      expect(swapped.latitude, 73.8567);
    });

    test('rejects non-finite values', () {
      expect(
        () => Coordinate(longitude: double.nan, latitude: 0),
        throwsA(isA<GeoException>()),
      );
      expect(
        () => Coordinate(longitude: 0, latitude: double.infinity),
        throwsA(isA<GeoException>()),
      );
    });

    test('serialises in GeoJSON longitude-first order', () {
      final c = Coordinate(longitude: 73.8567, latitude: 18.5204);
      expect(c.toGeoJson(), [73.8567, 18.5204]);
    });

    test('round-trips through GeoJSON including altitude', () {
      final c = Coordinate(longitude: 73.8567, latitude: 18.5204, altitude: 560);
      final parsed = Coordinate.fromGeoJson(c.toGeoJson());
      expect(parsed, c);
    });

    test('rejects a position with the wrong arity', () {
      expect(() => Coordinate.fromGeoJson([73.8]),
          throwsA(isA<GeoException>()));
      expect(() => Coordinate.fromGeoJson([73.8, 18.5, 560, 1]),
          throwsA(isA<GeoException>()));
    });

    test('null altitude means unknown, not zero', () {
      final flat = Coordinate(longitude: 1, latitude: 2);
      final zero = Coordinate(longitude: 1, latitude: 2, altitude: 0);
      expect(flat == zero, isFalse);
    });
  });

  group('Crs', () {
    test('WGS84 is geographic and GeoJSON safe', () {
      expect(Crs.wgs84.isGeographic, isTrue);
      expect(Crs.wgs84.assertGeoJsonCompatible, returnsNormally);
    });

    test('Web Mercator cannot be serialised as GeoJSON', () {
      expect(Crs.webMercator.assertGeoJsonCompatible,
          throwsA(isA<UnsupportedCrsException>()));
    });

    test('latitude-first order cannot be serialised as GeoJSON', () {
      const latFirst = Crs(4326, axisOrder: AxisOrder.latitudeLongitude);
      expect(latFirst.assertGeoJsonCompatible,
          throwsA(isA<UnsupportedCrsException>()));
    });
  });

  group('BoundingBox', () {
    test('contains an interior point', () {
      final box = BoundingBox(west: 73.7, south: 18.4, east: 74.0, north: 18.7);
      expect(box.contains(Coordinate(longitude: 73.8567, latitude: 18.5204)),
          isTrue);
    });

    test('excludes a point outside', () {
      final box = BoundingBox(west: 73.7, south: 18.4, east: 74.0, north: 18.7);
      expect(box.contains(Coordinate(longitude: 72.0, latitude: 18.5)), isFalse);
    });

    test('edges count as inside', () {
      final box = BoundingBox(west: 0, south: 0, east: 1, north: 1);
      expect(box.contains(Coordinate(longitude: 0, latitude: 0)), isTrue);
      expect(box.contains(Coordinate(longitude: 1, latitude: 1)), isTrue);
    });

    test('an antimeridian box wraps the long way round', () {
      final box = BoundingBox(west: 170, south: -10, east: -170, north: 10);
      expect(box.crossesAntimeridian, isTrue);
      expect(box.longitudeSpan, 20);
      expect(box.contains(Coordinate(longitude: 179, latitude: 0)), isTrue);
      expect(box.contains(Coordinate(longitude: -179, latitude: 0)), isTrue);
      expect(box.contains(Coordinate(longitude: 0, latitude: 0)), isFalse);
    });

    test('rejects an inverted north/south pair', () {
      expect(
        () => BoundingBox(west: 0, south: 10, east: 1, north: 0),
        throwsA(isA<GeoException>().having(
            (e) => e.code, 'code', GeoErrorCode.invalidBoundingBox)),
      );
    });

    test('rejects longitude beyond the antimeridian', () {
      expect(
        () => BoundingBox(west: -181, south: 0, east: 1, north: 1),
        throwsA(isA<GeoException>()),
      );
    });

    test('union of adjacent boxes is the enclosing box', () {
      final a = BoundingBox(west: 0, south: 0, east: 1, north: 1);
      final b = BoundingBox(west: 2, south: 2, east: 3, north: 3);
      expect(a.union(b),
          BoundingBox(west: 0, south: 0, east: 3, north: 3));
    });

    test('union with a wrapped box stays wrapped when that is shorter', () {
      final across = BoundingBox(west: 170, south: -10, east: -170, north: 10);
      final nearby = BoundingBox(west: 175, south: -5, east: 178, north: 5);
      final union = across.union(nearby);
      expect(union.crossesAntimeridian, isTrue);
      expect(union.west, 170);
      expect(union.east, -170);
    });

    test('union of two wrapped boxes keeps the shorter arc', () {
      final a = BoundingBox(west: 170, south: 0, east: -170, north: 1);
      final b = BoundingBox(west: -175, south: 0, east: -160, north: 1);
      final union = a.union(b);
      expect(union.crossesAntimeridian, isTrue);
      expect(union.west, 170);
      expect(union.east, -160);
    });

    test('union of a wrapped box and a box on the far side covers both', () {
      final across = BoundingBox(west: 170, south: 0, east: -170, north: 1);
      final far = BoundingBox(west: 0, south: 0, east: 10, north: 1);
      final union = across.union(far);
      expect(union.west, 0);
      expect(union.east, -170);
      expect(union.longitudeSpan, 190);
    });
  });

  group('Distance', () {
    test('converts kilometres to metres', () {
      const d = Distance(1.5,
          unit: DistanceUnit.kilometre, method: DistanceMethod.geodesic);
      expect(d.toMetres(), 1500);
    });

    test('keeps the method, so a road trip is not mistaken for a line', () {
      const straight = Distance(1200, method: DistanceMethod.geodesic);
      const road =
          Distance(1200, method: DistanceMethod.networkTravel);
      expect(straight == road, isFalse);
    });

    test('rejects a non-finite value', () {
      const d = Distance(double.nan, method: DistanceMethod.geodesic);
      expect(() => d.toMetres(), throwsA(isA<GeoException>()));
    });

    test('unit conversion is reversible', () {
      const d = Distance(2, unit: DistanceUnit.mile, method: DistanceMethod.geodesic);
      final back = d.inUnit(DistanceUnit.mile);
      expect(back.value, closeTo(2, 1e-9));
    });
  });
}
