import 'bounding_box.dart';
import 'coordinate.dart';
import 'crs.dart';
import 'errors.dart';

/// Base for every geometry OpenGeo can exchange.
///
/// A geometry always knows its CRS. Validation happens in the constructor, so
/// an instance that exists is one that passed the documented invariants: rings
/// are closed, rings do not cross themselves, holes sit inside their shell,
/// and coordinates are in range.
sealed class Geometry {
  const Geometry(this.crs);

  final Crs crs;

  /// GeoJSON `type` value.
  String get type;

  /// Smallest axis-aligned box covering every position in this geometry.
  ///
  /// shortcut: computed from raw longitudes, so a geometry straddling the
  /// antimeridian yields a box that spans nearly the whole world instead of a
  /// narrow wrapped one. Upgrade when a Pacific dataset is served.
  BoundingBox get bounds;

  /// RFC 7946 shape. The CRS is not serialised: GeoJSON is EPSG:4326 by
  /// definition, and [Crs.assertGeoJsonCompatible] has already run.
  Map<String, Object?> toGeoJson();

  /// Parses RFC 7946 GeoJSON and validates the result.
  static Geometry fromGeoJson(Map<String, Object?> json) {
    final type = json['type'];
    if (type is! String) {
      throw const GeoException(
        GeoErrorCode.malformedGeoJson,
        'geometry needs a string "type" member',
      );
    }
    final coordinates = json['coordinates'];
    switch (type) {
      case 'Point':
        return Point(_pos(coordinates, r'$.coordinates'));
      case 'LineString':
        return LineString(_posList(coordinates, r'$.coordinates'));
      case 'MultiPoint':
        return MultiPoint(_posList(coordinates, r'$.coordinates'));
      case 'MultiLineString':
        return MultiLineString(_posListList(coordinates, r'$.coordinates'));
      case 'Polygon':
        return Polygon(_posListList(coordinates, r'$.coordinates'));
      case 'MultiPolygon':
        return MultiPolygon(_posListListList(coordinates, r'$.coordinates'));
      case 'GeometryCollection':
        final members = json['geometries'];
        if (members is! List) {
          throw const GeoException(
            GeoErrorCode.malformedGeoJson,
            'GeometryCollection needs a "geometries" list',
          );
        }
        return GeometryCollection([
          for (var i = 0; i < members.length; i++)
            Geometry.fromGeoJson(_map(members[i], r'$.geometries[' '$i' ']')),
        ]);
      default:
        throw GeoException(
          GeoErrorCode.malformedGeoJson,
          'unsupported geometry type "$type"',
        );
    }
  }

  static List<Coordinate> _posList(Object? raw, String path) =>
      _posListUnchecked(raw, path);

  static Coordinate _pos(Object? raw, String path) {
    if (raw is! List) {
      throw GeoException(GeoErrorCode.malformedGeoJson, 'expected a position',
          path: path);
    }
    return Coordinate.fromGeoJson(_nums(raw, path));
  }

  static List<Coordinate> _posListUnchecked(Object? raw, String path) {
    if (raw is! List) {
      throw GeoException(GeoErrorCode.malformedGeoJson,
          'expected a list of positions',
          path: path);
    }
    return [
      for (var i = 0; i < raw.length; i++) _pos(raw[i], '$path[$i]'),
    ];
  }

  static List<List<Coordinate>> _posListList(Object? raw, String path) {
    if (raw is! List) {
      throw GeoException(GeoErrorCode.malformedGeoJson,
          'expected a list of position lists',
          path: path);
    }
    return [
      for (var i = 0; i < raw.length; i++)
        _posListUnchecked(raw[i], '$path[$i]'),
    ];
  }

  static List<List<List<Coordinate>>> _posListListList(
      Object? raw, String path) {
    if (raw is! List) {
      throw GeoException(GeoErrorCode.malformedGeoJson,
          'expected a list of polygon coordinate lists',
          path: path);
    }
    return [
      for (var i = 0; i < raw.length; i++)
        _posListList(raw[i], '$path[$i]'),
    ];
  }

  static List<num> _nums(List<Object?> raw, String path) {
    for (final value in raw) {
      if (value is! num) {
        throw GeoException(GeoErrorCode.malformedGeoJson,
            'position members must be numbers',
            path: path);
      }
    }
    return raw.cast<num>();
  }

  static Map<String, Object?> _map(Object? raw, String path) {
    if (raw is! Map) {
      throw GeoException(GeoErrorCode.malformedGeoJson,
          'expected an object',
          path: path);
    }
    return raw.cast<String, Object?>();
  }
}

/// A single position.
class Point extends Geometry {
  Point(this.position, {Crs crs = Crs.wgs84}) : super(crs);

  final Coordinate position;

  @override
  String get type => 'Point';

  @override
  BoundingBox get bounds => BoundingBox(
        west: position.longitude,
        south: position.latitude,
        east: position.longitude,
        north: position.latitude,
      );

  @override
  Map<String, Object?> toGeoJson() {
    crs.assertGeoJsonCompatible();
    return {'type': 'Point', 'coordinates': position.toGeoJson()};
  }
}

/// An ordered sequence of at least two positions.
class LineString extends Geometry {
  LineString(List<Coordinate> positions, {Crs crs = Crs.wgs84})
      : positions = List.unmodifiable(positions),
        super(crs) {
    if (positions.length < 2) {
      throw GeoException(GeoErrorCode.invalidGeometry,
          'LineString needs at least 2 positions, got ${positions.length}');
    }
  }

  final List<Coordinate> positions;

  @override
  String get type => 'LineString';

  @override
  BoundingBox get bounds => _boundsOf(positions);

  @override
  Map<String, Object?> toGeoJson() {
    crs.assertGeoJsonCompatible();
    return {
      'type': 'LineString',
      'coordinates': [for (final p in positions) p.toGeoJson()],
    };
  }
}

/// A shell plus zero or more holes. The first ring is the shell.
///
/// Ring orientation is not enforced: GeoJSON consumers must not rely on
/// winding order, and PostGIS can normalise it on write.
class Polygon extends Geometry {
  Polygon(List<List<Coordinate>> rings, {Crs crs = Crs.wgs84})
      : rings = List<List<Coordinate>>.unmodifiable(
            [for (final r in rings) List<Coordinate>.unmodifiable(r)]),
        super(crs) {
    _validatePolygonRings(rings);
  }

  final List<List<Coordinate>> rings;

  List<Coordinate> get shell => rings.first;

  List<List<Coordinate>> get holes => rings.skip(1).toList(growable: false);

  @override
  String get type => 'Polygon';

  @override
  BoundingBox get bounds => _boundsOf(shell);

  @override
  Map<String, Object?> toGeoJson() {
    crs.assertGeoJsonCompatible();
    return {
      'type': 'Polygon',
      'coordinates': [
        for (final ring in rings) [for (final p in ring) p.toGeoJson()],
      ],
    };
  }
}

class MultiPoint extends Geometry {
  MultiPoint(List<Coordinate> points, {Crs crs = Crs.wgs84})
      : points = List.unmodifiable(points),
        super(crs) {
    if (points.isEmpty) {
      throw const GeoException(
        GeoErrorCode.invalidGeometry,
        'MultiPoint needs at least one position',
      );
    }
  }

  final List<Coordinate> points;

  @override
  String get type => 'MultiPoint';

  @override
  BoundingBox get bounds => _boundsOf(points);

  @override
  Map<String, Object?> toGeoJson() {
    crs.assertGeoJsonCompatible();
    return {
      'type': 'MultiPoint',
      'coordinates': [for (final p in points) p.toGeoJson()],
    };
  }
}

class MultiLineString extends Geometry {
  MultiLineString(List<List<Coordinate>> lines, {Crs crs = Crs.wgs84})
      : lines = List.unmodifiable([
          for (final l in lines) List<Coordinate>.unmodifiable(l)
        ]),
        super(crs) {
    if (lines.isEmpty) {
      throw const GeoException(
        GeoErrorCode.invalidGeometry,
        'MultiLineString needs at least one line',
      );
    }
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].length < 2) {
        throw GeoException(
          GeoErrorCode.invalidGeometry,
          'line $i needs at least 2 positions',
          path: 'lines[$i]',
        );
      }
    }
  }

  final List<List<Coordinate>> lines;

  @override
  String get type => 'MultiLineString';

  @override
  BoundingBox get bounds => _boundsOf(lines.expand((l) => l).toList());

  @override
  Map<String, Object?> toGeoJson() {
    crs.assertGeoJsonCompatible();
    return {
      'type': 'MultiLineString',
      'coordinates': [
        for (final line in lines) [for (final p in line) p.toGeoJson()],
      ],
    };
  }
}

class MultiPolygon extends Geometry {
  MultiPolygon(List<List<List<Coordinate>>> polygons, {Crs crs = Crs.wgs84})
      : polygons = List<List<List<Coordinate>>>.unmodifiable([
          for (final p in polygons)
            List<List<Coordinate>>.unmodifiable([
              for (final r in p) List<Coordinate>.unmodifiable(r)
            ])
        ]),
        super(crs) {
    if (polygons.isEmpty) {
      throw const GeoException(
        GeoErrorCode.invalidGeometry,
        'MultiPolygon needs at least one polygon',
      );
    }
    for (var i = 0; i < polygons.length; i++) {
      _validatePolygonRings(polygons[i]);
    }
    // shortcut: overlapping members of one MultiPolygon are not rejected here;
    // a PostGIS ST_IsValid pass covers that when data reaches the database.
  }

  final List<List<List<Coordinate>>> polygons;

  @override
  String get type => 'MultiPolygon';

  @override
  BoundingBox get bounds =>
      _boundsOf(polygons.expand((p) => p.expand((r) => r)).toList());

  @override
  Map<String, Object?> toGeoJson() {
    crs.assertGeoJsonCompatible();
    return {
      'type': 'MultiPolygon',
      'coordinates': [
        for (final polygon in polygons)
          [
            for (final ring in polygon) [for (final p in ring) p.toGeoJson()],
          ],
      ],
    };
  }
}

class GeometryCollection extends Geometry {
  GeometryCollection(List<Geometry> geometries, {Crs crs = Crs.wgs84})
      : geometries = List.unmodifiable(geometries),
        super(crs) {
    if (geometries.isEmpty) {
      throw const GeoException(
        GeoErrorCode.invalidGeometry,
        'GeometryCollection needs at least one member',
      );
    }
    for (var i = 0; i < geometries.length; i++) {
      if (geometries[i].crs != crs) {
        throw GeoException(
          GeoErrorCode.unsupportedCrs,
          'member $i is in ${geometries[i].crs} but the collection is $crs',
          path: 'geometries[$i]',
        );
      }
    }
  }

  final List<Geometry> geometries;

  @override
  String get type => 'GeometryCollection';

  @override
  BoundingBox get bounds =>
      geometries.map((g) => g.bounds).reduce((a, b) => a.union(b));

  @override
  Map<String, Object?> toGeoJson() {
    crs.assertGeoJsonCompatible();
    return {
      'type': 'GeometryCollection',
      'geometries': [for (final g in geometries) g.toGeoJson()],
    };
  }
}

// ── validation helpers ──────────────────────────────────────────────────────

const double _eps = 1e-12;

BoundingBox _boundsOf(List<Coordinate> positions) {
  var west = positions.first.longitude;
  var east = positions.first.longitude;
  var south = positions.first.latitude;
  var north = positions.first.latitude;
  for (final p in positions.skip(1)) {
    if (p.longitude < west) west = p.longitude;
    if (p.longitude > east) east = p.longitude;
    if (p.latitude < south) south = p.latitude;
    if (p.latitude > north) north = p.latitude;
  }
  return BoundingBox(west: west, south: south, east: east, north: north);
}

void _validatePolygonRings(List<List<Coordinate>> rings) {
  if (rings.isEmpty) {
    throw const GeoException(
      GeoErrorCode.invalidGeometry,
      'Polygon needs a shell ring',
    );
  }
  for (var i = 0; i < rings.length; i++) {
    _validateRing(rings[i], 'rings[$i]');
  }
  final shell = rings.first;
  for (var i = 1; i < rings.length; i++) {
    final hole = rings[i];
    final anchor = hole.first;
    if (_pointOnRing(anchor, shell) || !_pointInRing(anchor, shell)) {
      throw GeoException(
        GeoErrorCode.holeOutsideShell,
        'hole $i does not lie inside the shell',
        path: 'rings[$i][0]',
      );
    }
    if (_ringsIntersect(hole, shell)) {
      throw GeoException(
        GeoErrorCode.holeOutsideShell,
        'hole $i crosses the shell boundary',
        path: 'rings[$i]',
      );
    }
  }
}

void _validateRing(List<Coordinate> ring, String path) {
  if (ring.length < 4) {
    throw GeoException(
      GeoErrorCode.invalidRing,
      'a closed ring needs at least 4 positions, got ${ring.length}',
      path: path,
    );
  }
  if (!ring.first.equalsWithin(ring.last)) {
    throw GeoException(
      GeoErrorCode.invalidRing,
      'ring is not closed: first ${ring.first} != last ${ring.last}',
      path: path,
    );
  }
  if (_ringArea(ring).abs() < 1e-14) {
    throw GeoException(
      GeoErrorCode.degenerateRing,
      'ring encloses zero area',
      path: path,
    );
  }
  if (_selfIntersects(ring)) {
    throw GeoException(
      GeoErrorCode.selfIntersectingRing,
      'ring crosses itself',
      path: path,
    );
  }
}

/// Signed shoelace area in square degrees. Sign carries winding order.
double _ringArea(List<Coordinate> ring) {
  var sum = 0.0;
  for (var i = 0; i < ring.length - 1; i++) {
    final a = ring[i];
    final b = ring[i + 1];
    sum += a.longitude * b.latitude - b.longitude * a.latitude;
  }
  return sum / 2;
}

/// shortcut: O(n^2) segment pairs. Fine for parcel and city-region rings
/// (hundreds of vertices); upgrade to an interval sweep for coastline-scale
/// rings.
bool _selfIntersects(List<Coordinate> ring) {
  final edges = ring.length - 1;
  for (var i = 0; i < edges; i++) {
    for (var j = i + 2; j < edges; j++) {
      if (i == 0 && j == edges - 1) continue; // shares the closing vertex
      if (_segmentsIntersect(ring[i], ring[i + 1], ring[j], ring[j + 1])) {
        return true;
      }
    }
  }
  return false;
}

bool _ringsIntersect(List<Coordinate> a, List<Coordinate> b) {
  for (var i = 0; i < a.length - 1; i++) {
    for (var j = 0; j < b.length - 1; j++) {
      if (_segmentsIntersect(a[i], a[i + 1], b[j], b[j + 1])) return true;
    }
  }
  return false;
}

int _orientation(Coordinate a, Coordinate b, Coordinate c) {
  final value = (b.longitude - a.longitude) * (c.latitude - a.latitude) -
      (b.latitude - a.latitude) * (c.longitude - a.longitude);
  if (value.abs() < _eps) return 0;
  return value > 0 ? 1 : -1;
}

bool _onSegment(Coordinate a, Coordinate b, Coordinate p) =>
    p.longitude >= (a.longitude < b.longitude ? a.longitude : b.longitude) &&
    p.longitude <= (a.longitude > b.longitude ? a.longitude : b.longitude) &&
    p.latitude >= (a.latitude < b.latitude ? a.latitude : b.latitude) &&
    p.latitude <= (a.latitude > b.latitude ? a.latitude : b.latitude);

bool _segmentsIntersect(
    Coordinate a, Coordinate b, Coordinate c, Coordinate d) {
  final o1 = _orientation(a, b, c);
  final o2 = _orientation(a, b, d);
  final o3 = _orientation(c, d, a);
  final o4 = _orientation(c, d, b);
  if (o1 != o2 && o3 != o4) return true;
  if (o1 == 0 && _onSegment(a, b, c)) return true;
  if (o2 == 0 && _onSegment(a, b, d)) return true;
  if (o3 == 0 && _onSegment(c, d, a)) return true;
  if (o4 == 0 && _onSegment(c, d, b)) return true;
  return false;
}

/// Ray casting. Boundary membership is deliberately ambiguous here; callers
/// that care use [_pointOnRing] first.
bool _pointInRing(Coordinate p, List<Coordinate> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i];
    final b = ring[j];
    final straddles = (a.latitude > p.latitude) != (b.latitude > p.latitude);
    if (!straddles) continue;
    final lonAtLat = (b.longitude - a.longitude) *
            (p.latitude - a.latitude) /
            (b.latitude - a.latitude) +
        a.longitude;
    if (p.longitude < lonAtLat) inside = !inside;
  }
  return inside;
}

bool _pointOnRing(Coordinate p, List<Coordinate> ring) {
  for (var i = 0; i < ring.length - 1; i++) {
    if (_orientation(ring[i], ring[i + 1], p) == 0 &&
        _onSegment(ring[i], ring[i + 1], p)) {
      return true;
    }
  }
  return false;
}
