import 'package:flutter/material.dart';

import '../models/geo_point.dart';
import 'slippy_map.dart';

/// Non-web build: the raster slippy map is the whole viewport.
///
/// `pitch` and `buildings` exist to keep the API identical to the web
/// renderer; raster tiles have no 3D data, so they are no-ops here.
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
  final bool gl;
  final ValueChanged<int>? onMarkerTap;

  @override
  MapViewportState createState() => MapViewportState();
}

class MapViewportState extends State<MapViewport> {
  final GlobalKey<SlippyMapState> _key = GlobalKey<SlippyMapState>();

  /// Centres the map, matching [SlippyMapState.recenter].
  void recenter([GeoPoint? point]) => _key.currentState?.recenter(point);

  void zoomIn() => _key.currentState?.zoomIn();

  void zoomOut() => _key.currentState?.zoomOut();

  @override
  Widget build(BuildContext context) {
    return SlippyMap(
      key: _key,
      center: widget.center,
      zoom: widget.zoom,
      style: widget.style,
      markers: widget.markers,
      route: widget.route,
      routeColor: widget.routeColor,
      showAttribution: widget.showAttribution,
      relief: widget.relief,
      onMarkerTap: widget.onMarkerTap,
    );
  }
}
