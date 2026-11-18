import 'dart:math' as math;

import 'coordinate.dart';
import 'errors.dart';

/// An axis-aligned bounding box in degrees.
///
/// `west > east` means the box crosses the antimeridian. That is the only
/// representation in which a Pacific-spanning box stays a single rectangle,
/// and it must be handled explicitly rather than normalised away.
class BoundingBox {
  BoundingBox({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  }) {
    if (!west.isFinite || !south.isFinite || !east.isFinite || !north.isFinite) {
      throw const GeoException(
        GeoErrorCode.invalidBoundingBox,
        'all bounding box edges must be finite',
      );
    }
    if (west < -180 || west > 180 || east < -180 || east > 180) {
      throw GeoException(
        GeoErrorCode.invalidBoundingBox,
        'longitude edges must be in [-180, 180], got west=$west east=$east',
      );
    }
    if (south < -90 || south > 90 || north < -90 || north > 90) {
      throw GeoException(
        GeoErrorCode.invalidBoundingBox,
        'latitude edges must be in [-90, 90], got south=$south north=$north',
      );
    }
    if (south > north) {
      throw GeoException(
        GeoErrorCode.invalidBoundingBox,
        'south ($south) must not be greater than north ($north)',
      );
    }
  }

  final double west;
  final double south;
  final double east;
  final double north;

  bool get crossesAntimeridian => west > east;

  double get latitudeSpan => north - south;

  /// Longitude span, correct for antimeridian-crossing boxes.
  double get longitudeSpan =>
      crossesAntimeridian ? (180 - west) + (east + 180) : east - west;

  /// True when [point] is inside the box. Edges count as inside.
  bool contains(Coordinate point) {
    if (point.latitude < south || point.latitude > north) return false;
    if (crossesAntimeridian) {
      return point.longitude >= west || point.longitude <= east;
    }
    return point.longitude >= west && point.longitude <= east;
  }

  /// GeoJSON `bbox`: `[west, south, east, north]`.
  List<double> toGeoJson() => [west, south, east, north];

  /// Smallest box covering both inputs. Antimeridian-crossing boxes use the
  /// shorter of the two possible longitude spans.
  ///
  /// shortcut: only two boxes are merged here; merging a set needs a running
  /// fold that re-evaluates the antimeridian choice, upgrade when a caller
  /// needs it.
  BoundingBox union(BoundingBox other) {
    final south = this.south < other.south ? this.south : other.south;
    final north = this.north > other.north ? this.north : other.north;
    final merged = _unionLongitudes(west, east, other.west, other.east);
    return BoundingBox(
        west: merged.$1, south: south, east: merged.$2, north: north);
  }

  /// Both boxes must be covered by one arc, so measure eastward from each
  /// candidate start and keep the shorter arc. This handles a wrapped box next
  /// to a normal one without special cases.
  static (double, double) _unionLongitudes(
      double westA, double eastA, double westB, double eastB) {
    final spanA = _spanOf(westA, eastA);
    final spanB = _spanOf(westB, eastB);
    double eastOf(double start, double lon) => (lon - start) % 360;

    var bestStart = westA;
    var bestSpan = 360.0;
    for (final start in [westA, westB]) {
      final span = math.max(eastOf(start, westA) + spanA, eastOf(start, westB) + spanB);
      if (span < bestSpan) {
        bestSpan = span;
        bestStart = start;
      }
    }
    if (bestSpan >= 360) return (-180, 180);
    var east = bestStart + bestSpan;
    if (east > 180) east -= 360;
    return (bestStart, east);
  }

  static double _spanOf(double west, double east) =>
      west > east ? (180 - west) + (east + 180) : east - west;

  @override
  bool operator ==(Object other) =>
      other is BoundingBox &&
      other.west == west &&
      other.south == south &&
      other.east == east &&
      other.north == north;

  @override
  int get hashCode => Object.hash(west, south, east, north);

  @override
  String toString() => 'BoundingBox(W $west, S $south, E $east, N $north)';
}
