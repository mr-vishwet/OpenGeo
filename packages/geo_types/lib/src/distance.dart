import 'errors.dart';

enum DistanceUnit {
  metre(1),
  kilometre(1000),
  mile(1609.344),
  nauticalMile(1852);

  const DistanceUnit(this.metresPerUnit);

  final double metresPerUnit;
}

/// How a distance was obtained. Without this, a straight line and a road trip
/// are the same number, and users are misled.
enum DistanceMethod {
  /// Great-circle or ellipsoidal distance between two positions.
  geodesic,

  /// Planar distance inside a projected CRS. Meaningful only for the
  /// projection and area it was computed in.
  projectedPlanar,

  /// Distance along a routable network. Produced only by a routing engine.
  networkTravel,
}

/// A distance with an explicit unit and method.
class Distance {
  const Distance(this.value, {this.unit = DistanceUnit.metre, required this.method});

  final double value;
  final DistanceUnit unit;
  final DistanceMethod method;

  /// Converts a planar or geodesic distance to metres.
  ///
  /// Network travel distances are not convertible: they are already expressed
  /// in the requested unit and must not be re-scaled by consumers.
  double toMetres() {
    if (value.isNaN || value.isInfinite) {
      throw const GeoException(
        GeoErrorCode.invalidGeometry,
        'distance value must be finite',
      );
    }
    return value * unit.metresPerUnit;
  }

  Distance inUnit(DistanceUnit target) =>
      Distance(value * unit.metresPerUnit / target.metresPerUnit,
          unit: target, method: method);

  @override
  bool operator ==(Object other) =>
      other is Distance &&
      other.value == value &&
      other.unit == unit &&
      other.method == method;

  @override
  int get hashCode => Object.hash(value, unit, method);

  @override
  String toString() => '${value.toStringAsFixed(2)} ${unit.name} (${method.name})';
}
