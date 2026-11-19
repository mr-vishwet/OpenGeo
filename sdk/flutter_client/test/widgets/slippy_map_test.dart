import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:opengeo_flutter/models/geo_point.dart';
import 'package:opengeo_flutter/widgets/slippy_map.dart';

void main() {
  test('Web-Mercator normalisation maps Pune to the expected tile', () {
    final n = SlippyMapState.normalise(const GeoPoint(18.5204, 73.8567));
    final zoom = 12;
    final tiles = math.pow(2, zoom).toInt();

    expect(n.dx * tiles ~/ 1, 2888);
    expect(n.dy * tiles ~/ 1, 1833);
  });

  test('normalisation stays inside the unit square at the poles', () {
    for (final lat in [90.0, -90.0, 85.0, -85.0]) {
      final n = SlippyMapState.normalise(GeoPoint(lat, 0));
      expect(n.dy, inInclusiveRange(0.0, 1.0));
      expect(n.dx, inInclusiveRange(0.0, 1.0));
    }
  });
}
