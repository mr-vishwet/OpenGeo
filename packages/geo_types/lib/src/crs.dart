/// Axis order is stated, never assumed. A GeoJSON position is
/// `[longitude, latitude]`; some legacy formats are the reverse.
enum AxisOrder { longitudeLatitude, latitudeLongitude }

/// A coordinate reference system identifier plus its declared axis order.
///
/// Only EPSG:4326 is accepted for GeoJSON interchange. Other systems may be
/// named so a dataset can record what it was authored in, but transforming
/// between systems is PROJ's job and is deliberately not implemented here.
class Crs {
  const Crs(this.epsg, {this.axisOrder = AxisOrder.longitudeLatitude});

  final int epsg;
  final AxisOrder axisOrder;

  /// WGS 84 geographic coordinates, longitude first. The default for all
  /// public interchange.
  static const Crs wgs84 = Crs(4326);

  /// Web Mercator. A projected system: distances here are not metres.
  static const Crs webMercator = Crs(3857);

  bool get isGeographic => epsg == 4326;

  /// Throws [UnsupportedCrsException] when this system cannot be serialised
  /// as GeoJSON.
  void assertGeoJsonCompatible() {
    if (!isGeographic) {
      throw UnsupportedCrsException(epsg);
    }
    if (axisOrder != AxisOrder.longitudeLatitude) {
      throw UnsupportedCrsException(epsg,
          reason: 'GeoJSON requires longitude-first axis order');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Crs && other.epsg == epsg && other.axisOrder == axisOrder;

  @override
  int get hashCode => Object.hash(epsg, axisOrder);

  @override
  String toString() => 'EPSG:$epsg';
}

class UnsupportedCrsException implements Exception {
  UnsupportedCrsException(this.epsg, {this.reason});

  final int epsg;
  final String? reason;

  @override
  String toString() => 'UnsupportedCrsException: EPSG:$epsg cannot be used for '
      'GeoJSON interchange${reason == null ? '' : ' ($reason)'}';
}
