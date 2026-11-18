/// Stable, machine-readable error codes shared by every geometry API.
///
/// The codes are part of the public contract: an SDK or agent decides whether
/// to retry, ask the user to fix input, or switch provider from the code alone,
/// never by matching message text. `wireCode` is the spelling the Python
/// service puts on the wire, and both surfaces are checked against the same
/// vectors in `tests/parity/geometry_vectors.json`.
enum GeoErrorCode {
  invalidCoordinate('invalid_coordinate'),
  invalidBoundingBox('invalid_bounding_box'),
  invalidRing('invalid_ring'),
  degenerateRing('degenerate_ring'),
  selfIntersectingRing('self_intersecting_ring'),
  holeOutsideShell('hole_outside_shell'),
  invalidGeometry('invalid_geometry'),
  emptyGeometry('empty_geometry'),
  unsupportedGeometryType('unsupported_geometry_type'),
  unsupportedCrs('unsupported_crs'),
  malformedGeoJson('malformed_geojson');

  const GeoErrorCode(this.wireCode);

  final String wireCode;
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
