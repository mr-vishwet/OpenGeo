import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../gl/map_config.dart';
import '../models/geo_point.dart';
import 'slippy_map.dart';

/// MapLibre GL handle. Every method is a direct JS call on the adapter class
/// defined in `web/maplibre/opengeo_map.js`.
extension type GlMap._(JSObject _) implements JSObject {
  external void setStyle(String json, bool isUrl);
  external void setRelief(bool on);
  external void setBuildings(bool on);
  external void setPitch(double degrees);
  external void setMarkers(String json);
  external void setRoute(String json, String color);
  external void recenter(double lng, double lat);
  external void zoomIn();
  external void zoomOut();
  external void resize();
  external void destroy();
}

@JS('ogCreateMap')
external GlMap? _createMap(
  JSObject container,
  String configJson,
  JSFunction onLoad,
  JSFunction onError,
  JSFunction onMarkerTap,
);

@JS('globalThis')
external JSObject get _globalThis;

/// Web viewport: MapLibre GL platform view with the raster [SlippyMap] as an
/// automatic fallback when WebGL or the style bundle is unavailable.
class MapViewport extends StatefulWidget {
  const MapViewport({
    super.key,
    required this.center,
    this.zoom = 13,
    this.style = MapStyle.street,
    this.markers = const [],
    this.route = const [],
    this.routeColor,
    this.showAttribution = true,
    this.relief = false,
    this.pitch = 0,
    this.buildings = false,
    this.gl = true,
    this.onMarkerTap,
  });

  final GeoPoint center;
  final double zoom;
  final MapStyle style;
  final List<MapMarker> markers;
  final List<GeoPoint> route;
  final Color? routeColor;
  final bool showAttribution;
  final bool relief;
  final double pitch;
  final bool buildings;

  /// False keeps this instance on the raster fallback (small preview maps
  /// that do not justify a second WebGL context).
  final bool gl;
  final ValueChanged<int>? onMarkerTap;

  @override
  MapViewportState createState() => MapViewportState();
}

class MapViewportState extends State<MapViewport> {
  static int _seq = 0;
  late final String _viewType = 'opengeo-gl-${_seq++}';

  final GlobalKey<SlippyMapState> _fallbackKey = GlobalKey<SlippyMapState>();
  JSObject? _container;
  GlMap? _gl;
  bool _useGl = false;
  bool _failed = false;
  bool _polling = false;

  /// Centres the map on [point] (or the widget's centre), matching
  /// [SlippyMapState.recenter].
  void recenter([GeoPoint? point]) {
    final p = point ?? widget.center;
    if (_gl != null) {
      _gl!.recenter(p.longitude, p.latitude);
    } else {
      _fallbackKey.currentState?.recenter(point);
    }
  }

  void zoomIn() => _gl?.zoomIn();

  void zoomOut() => _gl?.zoomOut();

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int id) {
      final doc = _globalThis.getProperty('document'.toJS)! as JSObject;
      final div = doc.callMethod<JSObject>('createElement'.toJS, 'div'.toJS);
      div.setProperty('id'.toJS, ('og-map-$_viewType-$id').toJS);
      div.setProperty('className'.toJS, 'og-map-host'.toJS);
      _container = div;
      // The element joins the DOM after this callback returns; start on the
      // next frame when it can be measured.
      SchedulerBinding.instance.addPostFrameCallback((_) => _maybeStartMap());
      return div;
    });
  }

  @override
  void didUpdateWidget(covariant MapViewport old) {
    super.didUpdateWidget(old);
    final gl = _gl;
    if (gl == null) return;
    if (old.style != widget.style) {
      final (payload, isUrl) = stylePayloadFor(widget.style);
      gl.setStyle(payload, isUrl);
    }
    if (old.relief != widget.relief) gl.setRelief(widget.relief);
    if (old.buildings != widget.buildings) gl.setBuildings(widget.buildings);
    if (old.pitch != widget.pitch) gl.setPitch(widget.pitch);
    if (!identical(old.markers, widget.markers)) {
      gl.setMarkers(_markersJson());
    }
    if (!identical(old.route, widget.route) ||
        old.routeColor != widget.routeColor) {
      gl.setRoute(
        _routeJson(),
        _hexOf(widget.routeColor ?? const Color(0xFF1A73E8)),
      );
    }
    if (old.center != widget.center) recenter();
  }

  bool get _engineReady =>
      _globalThis.hasProperty('ogCreateMap'.toJS).toDart;

  /// `?renderer=raster` opts out of GL for the whole session.
  late final bool _glEnabled =
      widget.gl && useGlRenderer(Uri.base.queryParameters['renderer']);

  void _maybeStartMap() {
    if (!_glEnabled || _gl != null || _failed || _container == null) return;
    if (_engineReady) {
      _startMap();
      return;
    }
    if (_polling) return;
    _polling = true;
    // The local ESM bundle loads async; poll briefly before giving up.
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (!mounted || _gl != null || _failed) return false;
      if (!_engineReady) return true;
      _startMap();
      return false;
    }).timeout(
      const Duration(seconds: 8),
      onTimeout: () {
            if (mounted && _gl == null) setState(() => _failed = true);
      },
    );
  }

  void _startMap() {
    if (_gl != null || _failed || _container == null || !mounted) return;
    final (payload, isUrl) = stylePayloadFor(widget.style);
    final config = jsonEncode({
      'style': payload,
      'styleIsUrl': isUrl,
      'lng': widget.center.longitude,
      'lat': widget.center.latitude,
      'zoom': widget.zoom,
      'pitch': widget.pitch,
      'relief': widget.relief,
      'buildings': widget.buildings && styleHasBuildings(widget.style),
      'attribution': glAttributionFor(widget.style),
    });

    try {
      _gl = _createMap(
        _container!,
        config,
        _onGlLoad.toJS,
        _onGlError.toJS,
        _onGlMarkerTap.toJS,
      );
    } catch (_) {
      _gl = null;
    }
    if (_gl == null) {
      setState(() => _failed = true);
      return;
    }
    _gl!.setMarkers(_markersJson());
    _gl!.setRoute(
      _routeJson(),
      _hexOf(widget.routeColor ?? const Color(0xFF1A73E8)),
    );
    // The container may have measured 0x0 before insertion; resize once the
    // platform view has been laid out, then once more after the map settles.
    SchedulerBinding.instance.addPostFrameCallback((_) => _gl?.resize());
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _gl?.resize();
    });
  }

  void _onGlLoad() {
    if (mounted) setState(() => _useGl = true);
  }

  void _onGlError(JSAny? e) {
    // Style/WebGL failure before first load: drop to the raster renderer.
    if (_useGl || !mounted) return;
    _gl?.destroy();
    _gl = null;
    setState(() => _failed = true);
  }

  void _onGlMarkerTap(JSAny? index) {
    if (index == null) return;
    final i = (index as JSNumber).toDartDouble.toInt();
    widget.onMarkerTap?.call(i);
  }

  String _markersJson() => jsonEncode([
        for (final m in widget.markers)
          {
            'lng': m.point.longitude,
            'lat': m.point.latitude,
            'color': _hexOf(m.color),
            'highlighted': m.highlighted,
          },
      ]);

  String _routeJson() =>
      jsonEncode([for (final p in widget.route) [p.longitude, p.latitude]]);

  static String _hexOf(Color c) {
    final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  @override
  void dispose() {
    _gl?.destroy();
    _gl = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // One platform view for the widget's whole life: recreating it would
    // detach the GL map from its container. The raster fallback sits on top
    // until the GL map reports its first successful load.
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_glEnabled) HtmlElementView(viewType: _viewType),
        if (!_useGl)
          SlippyMap(
            key: _fallbackKey,
            center: widget.center,
            zoom: widget.zoom,
            style: widget.style,
            markers: widget.markers,
            route: widget.route,
            routeColor: widget.routeColor,
            showAttribution: widget.showAttribution,
            relief: widget.relief,
            onMarkerTap: widget.onMarkerTap,
          ),
      ],
    );
  }
}
