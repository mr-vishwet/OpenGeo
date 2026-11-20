/// Map viewport that picks the renderer per platform: MapLibre GL (Web)
/// with the raster [SlippyMap] as the stub/fallback elsewhere.
export 'map_viewport_stub.dart'
    if (dart.library.js_interop) 'map_viewport_web.dart';
