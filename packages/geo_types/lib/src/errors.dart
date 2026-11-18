/// Stable, machine-readable error codes shared by every geometry API.
///
/// The codes are part of the public contract: an SDK or agent decides whether
/// to retry, ask the user to fix input, or switch provider from the code alone,
/// never by matching message text.
enum GeoErrorCode {
  invalidCoordinate,
  invalidBoundingBox,
  invalidRing,
  degenerateRing,
  selfIntersectingRing,
  holeOutsideShell,
  invalidGeometry,
  unsupportedCrs,
  malformedGeoJson,
}

/// Thrown when an input violates a documented geographic invariant.
///
/// Every geographic failure is explicit. Silently clamping a bad coordinate is
/// how a swapped pair becomes a production bug.
class GeoException implements Exception {
  const GeoException(this.code, this.message, {this.path});

  final GeoErrorCode code;
  final String message;

  /// Where the failure occurred, e.g. `polygon.rings[1][3]`.
  final String? path;

  @override
  String toString() =>
      'GeoException(${code.name}): $message${path == null ? '' : ' at $path'}';
}
