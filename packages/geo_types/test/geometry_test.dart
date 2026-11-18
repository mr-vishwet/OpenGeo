import 'package:geo_types/geo_types.dart';
import 'package:test/test.dart';

List<Coordinate> square(double lon, double lat, {double size = 0.01}) => [
      Coordinate(longitude: lon, latitude: lat),
      Coordinate(longitude: lon + size, latitude: lat),
      Coordinate(longitude: lon + size, latitude: lat + size),
      Coordinate(longitude: lon, latitude: lat + size),
      Coordinate(longitude: lon, latitude: lat),
    ];

void main() {
  group('Point', () {
    test('has a degenerate bounding box', () {
      final p = Point(Coordinate(longitude: 73.8567, latitude: 18.5204));
      expect(p.bounds.west, 73.8567);
      expect(p.bounds.north, 18.5204);
    });

    test('round-trips through GeoJSON', () {
      final p = Point(Coordinate(longitude: 73.8567, latitude: 18.5204));
      final parsed = Geometry.fromGeoJson(p.toGeoJson());
      expect(parsed, isA<Point>());
      expect((parsed as Point).position, p.position);
    });
  });

  group('LineString', () {
    test('needs at least two positions', () {
      expect(
        () => LineString([Coordinate(longitude: 0, latitude: 0)]),
        throwsA(isA<GeoException>().having(
            (e) => e.code, 'code', GeoErrorCode.invalidGeometry)),
      );
    });

    test('bounds cover every position', () {
      final line = LineString([
        Coordinate(longitude: 73.8, latitude: 18.4),
        Coordinate(longitude: 74.0, latitude: 18.7),
      ]);
      expect(line.bounds,
          BoundingBox(west: 73.8, south: 18.4, east: 74.0, north: 18.7));
    });
  });

  group('Polygon', () {
    test('accepts a closed square shell', () {
      expect(() => Polygon([square(73.85, 18.52)]), returnsNormally);
    });

    test('rejects a ring that is not closed', () {
      final open = square(73.85, 18.52)..removeLast();
      open.add(Coordinate(longitude: 73.86, latitude: 18.53));
      expect(
        () => Polygon([open]),
        throwsA(isA<GeoException>()
            .having((e) => e.code, 'code', GeoErrorCode.invalidRing)),
      );
    });

    test('rejects a ring with fewer than four positions', () {
      final triangle = [
        Coordinate(longitude: 0, latitude: 0),
        Coordinate(longitude: 1, latitude: 0),
        Coordinate(longitude: 0, latitude: 0),
      ];
      expect(
        () => Polygon([triangle]),
        throwsA(isA<GeoException>()
            .having((e) => e.code, 'code', GeoErrorCode.invalidRing)),
      );
    });

    test('rejects a degenerate zero-area ring', () {
      final flat = [
        Coordinate(longitude: 0, latitude: 0),
        Coordinate(longitude: 1, latitude: 0),
        Coordinate(longitude: 2, latitude: 0),
        Coordinate(longitude: 0, latitude: 0),
      ];
      expect(
        () => Polygon([flat]),
        throwsA(isA<GeoException>()
            .having((e) => e.code, 'code', GeoErrorCode.degenerateRing)),
      );
    });

    test('rejects a self-intersecting ring', () {
      // A bowtie with non-zero shoelace area, so it fails on intersection
      // rather than on degeneracy.
      final bowtie = [
        Coordinate(longitude: 0, latitude: 0),
        Coordinate(longitude: 2, latitude: 2),
        Coordinate(longitude: 2, latitude: 0),
        Coordinate(longitude: 0, latitude: 1),
        Coordinate(longitude: 0, latitude: 0),
      ];
      expect(
        () => Polygon([bowtie]),
        throwsA(isA<GeoException>()
            .having((e) => e.code, 'code', GeoErrorCode.selfIntersectingRing)),
      );
    });

    test('accepts a hole inside the shell', () {
      final hole = square(73.855, 18.525, size: 0.002);
      expect(() => Polygon([square(73.85, 18.52), hole]), returnsNormally);
    });

    test('rejects a hole outside the shell', () {
      final hole = square(74.5, 19.5);
      expect(
        () => Polygon([square(73.85, 18.52), hole]),
        throwsA(isA<GeoException>()
            .having((e) => e.code, 'code', GeoErrorCode.holeOutsideShell)),
      );
    });

    test('rejects a hole that crosses the shell', () {
      final hole = [
        Coordinate(longitude: 73.855, latitude: 18.525),
        Coordinate(longitude: 74.0, latitude: 18.525),
        Coordinate(longitude: 74.0, latitude: 18.53),
        Coordinate(longitude: 73.855, latitude: 18.525),
      ];
      expect(
        () => Polygon([square(73.85, 18.52), hole]),
        throwsA(isA<GeoException>()
            .having((e) => e.code, 'code', GeoErrorCode.holeOutsideShell)),
      );
    });

    test('rejects a polygon with no rings', () {
      expect(
        () => Polygon([]),
        throwsA(isA<GeoException>().having(
            (e) => e.code, 'code', GeoErrorCode.invalidRing)),
      );
    });

    test('round-trips through GeoJSON with a hole', () {
      final polygon = Polygon([
        square(73.85, 18.52),
        square(73.855, 18.525, size: 0.002),
      ]);
      final parsed = Geometry.fromGeoJson(polygon.toGeoJson());
      expect(parsed, isA<Polygon>());
      expect((parsed as Polygon).rings.length, 2);
      expect(parsed.toGeoJson(), polygon.toGeoJson());
    });

    test('bounds ignore holes', () {
      final polygon = Polygon([
        square(73.85, 18.52),
        square(73.855, 18.525, size: 0.002),
      ]);
      expect(polygon.bounds,
          BoundingBox(west: 73.85, south: 18.52, east: 73.86, north: 18.53));
    });
  });

  group('MultiPolygon', () {
    test('validates every member', () {
      final bad = [
        [
          [
            Coordinate(longitude: 0, latitude: 0),
            Coordinate(longitude: 1, latitude: 0),
            Coordinate(longitude: 0, latitude: 0),
          ]
        ]
      ];
      expect(() => MultiPolygon(bad), throwsA(isA<GeoException>()));
    });

    test('round-trips through GeoJSON', () {
      final mp = MultiPolygon([
        [square(73.85, 18.52)],
        [square(73.90, 18.60)],
      ]);
      final parsed = Geometry.fromGeoJson(mp.toGeoJson());
      expect(parsed, isA<MultiPolygon>());
      expect(parsed.toGeoJson(), mp.toGeoJson());
    });
  });

  group('GeometryCollection', () {
    test('combines member bounds', () {
      final collection = GeometryCollection([
        Point(Coordinate(longitude: 73.8, latitude: 18.4)),
        LineString([
          Coordinate(longitude: 74.0, latitude: 18.7),
          Coordinate(longitude: 74.1, latitude: 18.8),
        ]),
      ]);
      expect(collection.bounds,
          BoundingBox(west: 73.8, south: 18.4, east: 74.1, north: 18.8));
      expect(collection.toGeoJson()['type'], 'GeometryCollection');
    });

    test('rejects a mixed-CRS collection', () {
      expect(
        () => GeometryCollection([
          Point(Coordinate(longitude: 0, latitude: 0)),
          Point(Coordinate(longitude: 0, latitude: 0), crs: Crs.webMercator),
        ]),
        throwsA(isA<GeoException>()),
      );
    });
  });

  group('GeoJSON parsing', () {
    test('rejects an unknown geometry type', () {
      expect(
        () => Geometry.fromGeoJson({'type': 'Circle', 'coordinates': []}),
        throwsA(isA<GeoException>()
            .having((e) => e.code, 'code', GeoErrorCode.unsupportedGeometryType)),
      );
    });

    test('rejects a non-numeric position member', () {
      expect(
        () => Geometry.fromGeoJson({
          'type': 'Point',
          'coordinates': ['73.8', 18.5],
        }),
        throwsA(isA<GeoException>()),
      );
    });

    test('rejects a geometry without a type', () {
      expect(
        () => Geometry.fromGeoJson({'coordinates': [0, 0]}),
        throwsA(isA<GeoException>()),
      );
    });
  });

  group('CRS enforcement', () {
    test('a projected point cannot be serialised as GeoJSON', () {
      final p = Point(Coordinate(longitude: 0, latitude: 0),
          crs: Crs.webMercator);
      expect(p.toGeoJson, throwsA(isA<UnsupportedCrsException>()));
    });
  });
}
