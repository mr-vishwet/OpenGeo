import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/geo_point.dart';
import '../theme/app_theme.dart';

/// Tile source for the raster base map.
enum MapStyle {
  defaultStyle('Default'),
  dark('Dark'),
  satellite('Satellite');

  const MapStyle(this.label);

  final String label;
}

/// A pin drawn on the map.
class MapMarker {
  const MapMarker({
    required this.point,
    required this.color,
    this.icon = Icons.place,
    this.size = 36,
    this.highlighted = false,
  });

  final GeoPoint point;
  final Color color;
  final IconData icon;
  final double size;
  final bool highlighted;
}

/// Lightweight slippy map: Web-Mercator projection over a 256 px raster tile
/// grid, with pan and pinch-zoom.
///
/// Tiles come from Esri's public World Street Map, Dark Gray Canvas and
/// World Imagery services. A production deployment should point [tileUrl] at
/// the OpenGeo tile endpoint once it serves raster tiles.
class SlippyMap extends StatefulWidget {
  const SlippyMap({
    super.key,
    required this.center,
    this.zoom = 13,
    this.style = MapStyle.defaultStyle,
    this.markers = const [],
    this.route = const [],
    this.routeColor,
    this.showAttribution = true,
    this.onMarkerTap,
  });

  final GeoPoint center;
  final double zoom;
  final MapStyle style;
  final List<MapMarker> markers;
  final List<GeoPoint> route;
  final Color? routeColor;
  final bool showAttribution;
  final ValueChanged<int>? onMarkerTap;

  @override
  SlippyMapState createState() => SlippyMapState();
}

class SlippyMapState extends State<SlippyMap> {
  static const _tileSize = 256.0;
  static const _minZoom = 2.0;
  static const _maxZoom = 18.0;

  late double _zoom;
  late Offset _center; // normalised world coordinates in [0, 1]
  late Offset _startCenter;
  late Offset _startFocal;
  late double _startZoom;

  @override
  void initState() {
    super.initState();
    _zoom = widget.zoom;
    _center = normalise(widget.center);
  }

  @override
  void didUpdateWidget(SlippyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center) {
      _center = normalise(widget.center);
    }
    if (oldWidget.zoom != widget.zoom) {
      _zoom = widget.zoom;
    }
  }

  void zoomIn() => setState(() => _zoom = (_zoom + 1).clamp(_minZoom, _maxZoom));

  void zoomOut() => setState(() => _zoom = (_zoom - 1).clamp(_minZoom, _maxZoom));

  void recenter([GeoPoint? point]) {
    setState(() => _center = normalise(point ?? widget.center));
  }

  static Offset normalise(GeoPoint p) {
    final sinLat = math.sin(p.latitude * math.pi / 180);
    final y = 0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi);
    return Offset((p.longitude + 180) / 360, y.clamp(0.0, 1.0));
  }

  double get _worldPx => _tileSize * math.pow(2, _zoom).toDouble();

  Offset _screenOf(GeoPoint point, Size size) {
    final n = normalise(point);
    return Offset(
      (n.dx - _center.dx) * _worldPx + size.width / 2,
      (n.dy - _center.dy) * _worldPx + size.height / 2,
    );
  }

  String _tileUrl(int z, int x, int y) {
    switch (widget.style) {
      case MapStyle.defaultStyle:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/$z/$y/$x';
      case MapStyle.dark:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/$z/$y/$x';
      case MapStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/$y/$x';
    }
  }

  String get _attribution => switch (widget.style) {
        MapStyle.satellite => 'Esri, Maxar, Earthstar Geographics',
        _ => '© OpenStreetMap contributors · Esri',
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = switch (widget.style) {
      MapStyle.dark => AppColors.darkSurfaceSunken,
      MapStyle.satellite => const Color(0xFF3A3F39),
      MapStyle.defaultStyle =>
        dark ? AppColors.darkSurfaceSunken : AppColors.surfaceAlt,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final z = _zoom.floor().clamp(2, 18);
        final n = 1 << z;
        final world = _tileSize * n;
        final left = _center.dx * world - size.width / 2;
        final top = _center.dy * world - size.height / 2;
        final firstX = (left / _tileSize).floor();
        final lastX = ((left + size.width) / _tileSize).ceil();
        final firstY = (top / _tileSize).floor();
        final lastY = ((top + size.height) / _tileSize).ceil();

        final tiles = <Widget>[];
        for (var x = firstX; x <= lastX; x++) {
          for (var y = firstY; y <= lastY; y++) {
            if (y < 0 || y >= n) continue;
            final wrappedX = ((x % n) + n) % n;
            tiles.add(Positioned(
              left: x * _tileSize - left,
              top: y * _tileSize - top,
              width: _tileSize,
              height: _tileSize,
              child: Image.network(
                _tileUrl(z, wrappedX, y),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => ColoredBox(color: base),
              ),
            ));
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (details) {
            _startZoom = _zoom;
            _startCenter = _center;
            _startFocal = details.localFocalPoint;
          },
          onScaleUpdate: (details) {
            setState(() {
              _zoom = (_startZoom + math.log(details.scale) / math.ln2)
                  .clamp(_minZoom, _maxZoom);
              final delta = details.localFocalPoint - _startFocal;
              _center = Offset(
                (_startCenter.dx - delta.dx / _worldPx).clamp(0.0, 1.0),
                (_startCenter.dy - delta.dy / _worldPx).clamp(0.0, 1.0),
              );
            });
          },
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: base),
                ...tiles,
                if (widget.route.length > 1)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RoutePainter(
                          points: widget.route,
                          project: (p) => _screenOf(p, size),
                          color: widget.routeColor ?? AppColors.primary,
                          dark: dark,
                        ),
                      ),
                    ),
                  ),
                for (var i = 0; i < widget.markers.length; i++)
                  _positionedMarker(i, size),
                if (widget.showAttribution)
                  Positioned(
                    right: 6,
                    bottom: 4,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: size.width - 20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: (dark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            _attribution,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _positionedMarker(int index, Size size) {
    final marker = widget.markers[index];
    final at = _screenOf(marker.point, size);
    final s = marker.size;
    return Positioned(
      left: at.dx - s / 2,
      top: at.dy - s,
      width: s,
      height: s,
      child: GestureDetector(
        onTap: widget.onMarkerTap == null
            ? null
            : () => widget.onMarkerTap!(index),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (marker.highlighted)
              Container(
                width: s * 0.7,
                height: s * 0.7,
                decoration: BoxDecoration(
                  color: marker.color.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
            Icon(
              marker.icon,
              size: s,
              color: marker.color,
              shadows: const [
                Shadow(color: Color(0x55000000), blurRadius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.points,
    required this.project,
    required this.color,
    required this.dark,
  });

  final List<GeoPoint> points;
  final Offset Function(GeoPoint) project;
  final Color color;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = project(points[i]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final halo = Paint()
      ..color = (dark ? Colors.black : Colors.white).withValues(alpha: 0.85)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final line = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, halo);
    canvas.drawPath(path, line);

    final dot = Paint()..color = color;
    final ring = Paint()
      ..color = dark ? Colors.black : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(project(points.first), 7, ring);
    canvas.drawCircle(project(points.first), 4.5, dot);
    canvas.drawCircle(project(points.last), 8, ring);
    canvas.drawCircle(project(points.last), 5.5, dot);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.points != points || old.color != color || old.dark != dark;
}
