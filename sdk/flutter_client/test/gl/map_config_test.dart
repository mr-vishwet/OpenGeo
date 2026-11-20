import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:opengeo_flutter/gl/map_config.dart';
import 'package:opengeo_flutter/widgets/slippy_map.dart';

void main() {
  group('rasterStyleJson', () {
    for (final style in MapStyle.values) {
      test('${style.label} builds a valid MapLibre raster style', () {
        final json = rasterStyleJson(style, attribution: style.attribution);
        final decoded = jsonDecode(json) as Map<String, dynamic>;

        expect(decoded['version'], 8);
        final sources = decoded['sources'] as Map<String, dynamic>;
        final source = sources['og-base'] as Map<String, dynamic>;
        expect(source['type'], 'raster');
        expect(source['tileSize'], 256);
        expect(source['minzoom'], 2);
        expect(source['maxzoom'], 18);
        expect(source.containsKey('minZoom'), isFalse);
        expect(source.containsKey('maxZoom'), isFalse);
        expect(source['attribution'], style.attribution);

        final tiles = (source['tiles'] as List).single as String;
        expect(tiles, contains('{z}'));
        expect(tiles, contains('{x}'));
        expect(tiles, contains('{y}'));

        final layers = decoded['layers'] as List;
        expect(layers, hasLength(2));
        expect((layers[1] as Map<String, dynamic>)['source'], 'og-base');
      });
    }

    test('keeps the Esri y-before-x tile order', () {
      final json = rasterStyleJson(MapStyle.satellite, attribution: 'a');
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final source =
          (decoded['sources'] as Map<String, dynamic>)['og-base']
              as Map<String, dynamic>;
      final tiles = (source['tiles'] as List).single as String;
      expect(tiles, endsWith('/tile/{z}/{y}/{x}'));
    });

    test('keeps the OpenTopoMap x-before-y tile order', () {
      final json = rasterStyleJson(MapStyle.terrain, attribution: 'a');
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final source =
          (decoded['sources'] as Map<String, dynamic>)['og-base']
              as Map<String, dynamic>;
      final tiles = (source['tiles'] as List).single as String;
      expect(tiles, endsWith('/{z}/{x}/{y}.png'));
    });
  });

  test('stylePayloadFor uses the vector URL only for street', () {
    final (streetPayload, streetIsUrl) = stylePayloadFor(MapStyle.street);
    expect(streetIsUrl, isTrue);
    expect(streetPayload, vectorStreetStyleUrl);

    final (satPayload, satIsUrl) = stylePayloadFor(MapStyle.satellite);
    expect(satIsUrl, isFalse);
    expect(jsonDecode(satPayload), isA<Map<String, dynamic>>());
  });

  test('glAttributionFor names the right provider', () {
    expect(glAttributionFor(MapStyle.street), contains('OpenFreeMap'));
    expect(glAttributionFor(MapStyle.satellite), contains('Esri'));
    expect(glAttributionFor(MapStyle.terrain), contains('OpenTopoMap'));
  });

  test('styleHasBuildings only for the vector street style', () {
    expect(styleHasBuildings(MapStyle.street), isTrue);
    expect(styleHasBuildings(MapStyle.dark), isFalse);
    expect(styleHasBuildings(MapStyle.satellite), isFalse);
    expect(styleHasBuildings(MapStyle.terrain), isFalse);
  });

  test('useGlRenderer defaults on and honours ?renderer=raster', () {
    expect(useGlRenderer(null), isTrue);
    expect(useGlRenderer(''), isTrue);
    expect(useGlRenderer('gl'), isTrue);
    expect(useGlRenderer('raster'), isFalse);
  });

  test('pitchFromQuery only accepts ?pitch=1', () {
    expect(pitchFromQuery({}), isFalse);
    expect(pitchFromQuery({'pitch': '1'}), isTrue);
    expect(pitchFromQuery({'pitch': '0'}), isFalse);
    expect(pitchFromQuery({'pitch': 'yes'}), isFalse);
  });

  test('mapZoom defaults and honours ?zoom=', () {
    expect(mapZoom({}, pitched: false), 12);
    expect(mapZoom({}, pitched: true), 14.5);
    expect(mapZoom({'zoom': '16'}, pitched: false), 16);
    expect(mapZoom({'zoom': 'nope'}, pitched: true), 14.5);
  });
}
