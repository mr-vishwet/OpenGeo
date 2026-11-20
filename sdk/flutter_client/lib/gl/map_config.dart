import 'dart:convert';

import '../widgets/slippy_map.dart';

/// Where the MapLibre vector renderer gets its base styles.
///
/// [MapStyle.street] is the only vector style: OpenFreeMap's openmaptiles
/// tiles carry building heights, so it is the one style that can render 3D
/// buildings. The rest are raster sources, identical to the fallback map.
const String vectorStreetStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';

/// Raster sources for the MapLibre renderer — same tiles as [MapStyle.url],
/// so the two renderers are visually interchangeable.
String rasterStyleJson(MapStyle style, {required String attribution}) {
  final template = style.tileTemplate;
  assert(template.contains('{z}'), 'tile template missing placeholder');

  return jsonEncode({
    'version': 8,
    'name': 'OpenGeo ${style.label}',
    'sources': {
      'og-base': {
        'type': 'raster',
        'tiles': [template],
        'tileSize': 256,
        'minzoom': 2,
        'maxzoom': 18,
        'attribution': attribution,
      },
    },
    'layers': [
      {'id': 'og-bg', 'type': 'background', 'paint': {'background-color': _backgroundColor(style)}},
      {
        'id': 'og-base',
        'type': 'raster',
        'source': 'og-base',
        'paint': {'raster-fade-duration': 150},
      },
    ],
  });
}

String _backgroundColor(MapStyle style) => switch (style) {
      MapStyle.dark => '#1E2126',
      MapStyle.satellite => '#3A3F39',
      MapStyle.terrain => '#E8E4DA',
      MapStyle.street => '#F5F7FA',
    };

/// True when [style] can render 3D buildings (only the vector style can).
bool styleHasBuildings(MapStyle style) => style == MapStyle.street;

/// The style payload for MapLibre: a URL for vector styles, JSON for raster.
(String style, bool isUrl) stylePayloadFor(MapStyle style) => style == MapStyle.street
    ? (vectorStreetStyleUrl, true)
    : (rasterStyleJson(style, attribution: style.attribution), false);

/// `?renderer=` deep link: anything except `raster` keeps the GL renderer.
bool useGlRenderer(String? rendererParam) =>
    rendererParam == null || rendererParam.isEmpty || rendererParam != 'raster';

/// `?pitch=1` opens the map in 3D perspective.
bool pitchFromQuery(Map<String, String> query) => query['pitch'] == '1';

/// `?zoom=15` opens the map at a specific zoom. A pitched map starts closer
/// because that is where 3D buildings and terrain relief are readable.
double mapZoom(Map<String, String> query, {required bool pitched}) =>
    double.tryParse(query['zoom'] ?? '') ?? (pitched ? 14.5 : 12);

/// Attribution shown by the GL renderer: the vector street style serves
/// OpenFreeMap tiles, not Esri, so it must credit the right provider.
String glAttributionFor(MapStyle style) => style == MapStyle.street
    ? '© OpenStreetMap contributors · OpenFreeMap'
    : style.attribution;
