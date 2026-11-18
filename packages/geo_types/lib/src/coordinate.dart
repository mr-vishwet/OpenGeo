import 'errors.dart';

/// A single geographic position in EPSG:4326.
///
/// Longitude and latitude are named, not positional, because a swapped pair is
/// valid-looking data. A swap that pushes latitude past ±90 fails here; a swap
/// between two mid-latitude values cannot be detected from range alone and
/// needs a regional plausibility check (bounding box, dataset extent) instead.
class Coordinate {
  Coordinate({
    required this.longitude,
    required this.latitude,
    this.altitude,
  }) {
    if (!longitude.isFinite || !latitude.isFinite) {
      throw const GeoException(
        GeoErrorCode.invalidCoordinate,
        'longitude and latitude must be finite',
      );
    }
    if (longitude < -180 || longitude > 180) {
      throw GeoException(
        GeoErrorCode.invalidCoordinate,
        'longitude $longitude is outside [-180, 180]; a value near ±90 usually '
        'means latitude and longitude were swapped',
      );
    }
    if (latitude < -90 || latitude > 90) {
      throw GeoException(
        GeoErrorCode.invalidCoordinate,
        'latitude $latitude is outside [-90, 90]; a value near ±180 usually '
        'means latitude and longitude were swapped',
      );
    }
    if (altitude != null && !altitude!.isFinite) {
      throw const GeoException(
        GeoErrorCode.invalidCoordinate,
        'altitude must be finite when present',
      );
    }
  }

  /// Degrees east of the prime meridian, in [-180, 180].
  final double longitude;

  /// Degrees north of the equator, in [-90, 90].
  final double latitude;

  /// Metres. The vertical datum is never implied: it is ellipsoidal,
  /// orthometric or game-local depending on the source, and the source must
  /// declare which. `null` means unknown, not zero.
  final double? altitude;

  /// GeoJSON position: `[longitude, latitude]` or `[longitude, latitude, alt]`.
  List<double> toGeoJson() =>
      altitude == null ? [longitude, latitude] : [longitude, latitude, altitude!];

  /// Parses a GeoJSON position. Rejects wrong arity and non-finite values
  /// rather than coercing them.
  factory Coordinate.fromGeoJson(List<num> position) {
    if (position.length < 2 || position.length > 3) {
      throw GeoException(
        GeoErrorCode.malformedGeoJson,
        'a position needs 2 or 3 numbers, got ${position.length}',
      );
    }
    return Coordinate(
      longitude: position[0].toDouble(),
      latitude: position[1].toDouble(),
      altitude: position.length == 3 ? position[2].toDouble() : null,
    );
  }

  /// Equality within [epsilon] degrees (~0.1 mm at the equator by default).
  bool equalsWithin(Coordinate other, {double epsilon = 1e-9}) =>
      (longitude - other.longitude).abs() <= epsilon &&
      (latitude - other.latitude).abs() <= epsilon &&
      (altitude ?? 0) - (other.altitude ?? 0) <= epsilon;

  @override
  bool operator ==(Object other) =>
      other is Coordinate &&
      other.longitude == longitude &&
      other.latitude == latitude &&
      other.altitude == altitude;

  @override
  int get hashCode => Object.hash(longitude, latitude, altitude);

  @override
  String toString() => altitude == null
      ? 'Coordinate($longitude, $latitude)'
      : 'Coordinate($longitude, $latitude, alt: $altitude m)';
}
