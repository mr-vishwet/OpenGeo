import 'dart:convert';
import 'dart:io';

import 'package:geo_types/geo_types.dart';
import 'package:test/test.dart';

/// Cross-surface parity: the Python service validates the same file, so a
/// validation rule that drifts on either surface fails one of the two suites.
void main() {
  final file = File('../../tests/parity/geometry_vectors.json');
  final vectors = (jsonDecode(file.readAsStringSync()) as Map<String, Object?>)['vectors']!
      as List<Object?>;

  for (final raw in vectors) {
    final vector = raw! as Map<String, Object?>;
    final expected = vector['code'] as String?;
    final geometry = (vector['geometry']! as Map).cast<String, Object?>();

    test('${vector['name']}', () {
      if (expected == null) {
        expect(() => Geometry.fromGeoJson(geometry), returnsNormally);
      } else {
        expect(
          () => Geometry.fromGeoJson(geometry),
          throwsA(isA<GeoException>()
              .having((e) => e.code.wireCode, 'code', expected)),
        );
      }
    });
  }
}
