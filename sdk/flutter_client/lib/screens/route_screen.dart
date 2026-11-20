import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/place.dart';
import '../theme/app_theme.dart';
import '../widgets/map_viewport.dart';
import '../widgets/slippy_map.dart';

enum _Transport { drive, walk, transit }

/// Route preview with a sample polyline.
///
/// Turn-by-turn routing is an unsupported capability on the OpenGeo API, so
/// the durations and the polyline here are labelled sample values and Start
/// Navigation says so instead of pretending to navigate.
class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key, this.destination});

  final Place? destination;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  _Transport _transport = _Transport.drive;

  Place get _destination =>
      widget.destination ??
      samplePlaces.firstWhere((place) => place.id == 'shaniwar-wada');

  ({String duration, String distance, String traffic}) get _estimate =>
      switch (_transport) {
        _Transport.drive => (duration: '12 min', distance: '3.8 km', traffic: 'Moderate traffic'),
        _Transport.walk => (duration: '48 min', distance: '3.6 km', traffic: 'Walk route'),
        _Transport.transit => (duration: '22 min', distance: '4.4 km', traffic: 'Bus 42'),
      };

  void _start() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Routing is not served by the OpenGeo API yet. This is a sample preview.',
        ),
      ),
    );
  }

  void _showSteps() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(S.lg, S.md, S.lg, S.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Steps', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: S.md),
            for (final step in const [
              ('Head west on JM Road', '450 m'),
              ('Turn right onto FC Road', '1.2 km'),
              ('Continue to Shaniwar Wada', '2.1 km'),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: S.sm),
                child: Row(
                  children: [
                    const Icon(Icons.turn_right, size: 18),
                    const SizedBox(width: S.md),
                    Expanded(child: Text(step.$1)),
                    Text(step.$2, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            const SizedBox(height: S.sm),
            Text(
              'Sample steps — the OpenGeo API does not serve routing yet.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estimate = _estimate;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: scheme.surface,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(S.sm, S.sm, S.lg, S.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: S.md,
                              vertical: S.sm,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(R.input),
                              border: Border.all(color: scheme.outline),
                            ),
                            child: Column(
                              children: [
                                _Endpoint(
                                  color: scheme.primary,
                                  label: 'Your Location',
                                ),
                                Divider(color: scheme.outline, height: S.md),
                                _Endpoint(
                                  color: AppColors.modeEssential,
                                  label: _destination.displayName,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_vert),
                          tooltip: 'Swap',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Origin is fixed at Your Location in this build.'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: S.sm),
                    Row(
                      children: [
                        for (final transport in _Transport.values) ...[
                          _TransportChip(
                            transport: transport,
                            selected: _transport == transport,
                            onTap: () => setState(() => _transport = transport),
                          ),
                          const SizedBox(width: S.sm),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: MapViewport(
              center: sampleRouteCentre,
              zoom: 13,
              route: sampleRoute,
              markers: [
                MapMarker(
                  point: _destination.point,
                  color: AppColors.modeEssential,
                  size: 38,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(S.lg, S.md, S.lg, S.md),
              decoration: BoxDecoration(
                color: scheme.surface,
                boxShadow: AppShadows.float,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estimate.duration,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${estimate.distance} · ${estimate.traffic}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up),
                        tooltip: 'Steps',
                        onPressed: _showSteps,
                      ),
                    ],
                  ),
                  const SizedBox(height: S.sm),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.navigation_outlined, size: 18),
                          label: const Text('Start Navigation'),
                        ),
                      ),
                      const SizedBox(width: S.md),
                      OutlinedButton(
                        onPressed: _showSteps,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.list_alt, size: 18),
                            SizedBox(width: S.xs),
                            Text('Steps'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: S.sm),
                  Text(
                    'Sample preview · Routing is an unsupported capability of the API',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: S.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TransportChip extends StatelessWidget {
  const _TransportChip({
    required this.transport,
    required this.selected,
    required this.onTap,
  });

  final _Transport transport;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, label) = switch (transport) {
      _Transport.drive => (Icons.directions_car, 'Drive'),
      _Transport.walk => (Icons.directions_walk, 'Walk'),
      _Transport.transit => (Icons.directions_bus, 'Transit'),
    };

    return Expanded(
      child: Material(
        color: selected ? scheme.primary : scheme.surface,
        borderRadius: BorderRadius.circular(R.input),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(R.input),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(R.input),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: S.xs),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
