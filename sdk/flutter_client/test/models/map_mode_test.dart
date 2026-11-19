import 'package:flutter_test/flutter_test.dart';
import 'package:opengeo_flutter/models/map_mode.dart';

void main() {
  test('there are five modes in reference order', () {
    expect(MapMode.values.map((m) => m.label), [
      'Realtime',
      'Essential',
      'Intelligence',
      'Spatial Engine',
      'Custom World',
    ]);
  });

  test('each mode carries the reference subtitle', () {
    expect(MapMode.realtime.subtitle, 'Live traffic, live locations & dynamic updates');
    expect(MapMode.essential.subtitle, '2D Maps, Search & Navigation');
    expect(MapMode.intelligence.subtitle, 'Spatial AI, Advanced Search & Insights');
    expect(MapMode.spatial.subtitle, '3D World, Game Maps & Spatial Events');
    expect(MapMode.custom.subtitle, 'Build Your Own Map');
  });
}
