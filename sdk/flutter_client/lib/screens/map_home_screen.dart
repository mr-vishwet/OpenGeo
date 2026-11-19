import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/map_mode.dart';
import '../models/place.dart';
import '../sheets/map_options_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/place_tile.dart';
import '../widgets/slippy_map.dart';
import 'ai_assistant_screen.dart';
import 'custom_world_screen.dart';
import 'explore_screen.dart';
import 'game_mode_screen.dart';
import 'place_detail_screen.dart';

/// Map tab: brand header, search, live raster map, floating controls, Nearby card.
class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key, required this.mode});

  final MapMode mode;

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  final _mapKey = GlobalKey<SlippyMapState>();
  MapOptions _options = const MapOptions();
  bool _saved = false;

  static final _markers = [
    for (final place in samplePlaces)
      MapMarker(
        point: place.point,
        color: place.category == 'park'
            ? AppColors.modeRealtime
            : AppColors.primary,
        icon: CategoryArt.iconFor(place.category),
        size: 30,
      ),
  ];

  void _openExplore() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExploreScreen(mode: widget.mode, standalone: true),
      ),
    );
  }

  Future<void> _openOptions() async {
    final result = await showModalBottomSheet<MapOptions>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MapOptionsSheet(initial: _options),
    );
    if (result != null && mounted) setState(() => _options = result);
  }

  void _openModeAction() {
    final screen = switch (widget.mode) {
      MapMode.intelligence => const AiAssistantScreen(),
      MapMode.spatial => const GameModeScreen(),
      MapMode.custom => const CustomWorldScreen(),
      _ => null,
    };
    if (screen == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: scheme.surface,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, S.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const BrandMark(size: 30),
                        const SizedBox(width: S.sm),
                        Text('OpenGeo', style: text.titleLarge),
                        const Spacer(),
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 19,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: S.md),
                    InkWell(
                      onTap: _openExplore,
                      borderRadius: BorderRadius.circular(R.input),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: S.md),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(R.input),
                          border: Border.all(color: scheme.outline),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 20, color: scheme.onSurfaceVariant),
                            const SizedBox(width: S.sm),
                            Expanded(
                              child: Text(
                                'Search places, addresses...',
                                style: text.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Icon(Icons.tune, size: 20, color: scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SlippyMap(
                    key: _mapKey,
                    center: puneCentre,
                    zoom: 12,
                    style: _options.style,
                    markers: _markers,
                  ),
                ),
                Positioned(
                  top: S.md,
                  left: S.md,
                  child: StatusChip(
                    label: _statusLabel,
                    color: _statusColor,
                    icon: widget.mode.icon,
                  ),
                ),
                Positioned(
                  top: S.md,
                  right: S.md,
                  child: Column(
                    children: [
                      RoundIconButton(
                        icon: Icons.my_location,
                        tooltip: 'Centre on Pune',
                        onPressed: () => _mapKey.currentState?.recenter(),
                        dark: dark,
                      ),
                      const SizedBox(height: S.sm),
                      RoundIconButton(
                        icon: Icons.layers_outlined,
                        tooltip: 'Map options',
                        onPressed: _openOptions,
                        dark: dark,
                      ),
                      const SizedBox(height: S.sm),
                      RoundIconButton(
                        icon: Icons.add,
                        tooltip: 'Zoom in',
                        onPressed: () => _mapKey.currentState?.zoomIn(),
                        dark: dark,
                      ),
                      const SizedBox(height: S.sm),
                      RoundIconButton(
                        icon: Icons.remove,
                        tooltip: 'Zoom out',
                        onPressed: () => _mapKey.currentState?.zoomOut(),
                        dark: dark,
                      ),
                    ],
                  ),
                ),
                if (widget.mode == MapMode.realtime && _options.traffic)
                  const Positioned(
                    left: S.md,
                    bottom: 168,
                    child: _TrafficLegend(),
                  ),
                if (_modeActionLabel != null)
                  Positioned(
                    left: S.md,
                    right: S.md,
                    bottom: 168,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        avatar: Icon(widget.mode.icon, size: 18, color: widget.mode.color),
                        label: Text(_modeActionLabel!),
                        onPressed: _openModeAction,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        side: BorderSide(color: scheme.outline),
                      ),
                    ),
                  ),
                Positioned(
                  left: S.md,
                  right: S.md,
                  bottom: S.md,
                  child: _NearbyCard(
                    place: samplePlaces.first,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlaceDetailScreen(place: samplePlaces.first),
                      ),
                    ),
                    onSeeAll: _openExplore,
                    saved: _saved,
                    onSave: () => setState(() => _saved = !_saved),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _statusLabel => switch (widget.mode) {
        MapMode.realtime => 'Live Traffic · Updated just now',
        MapMode.essential => 'Essential · 2D map',
        MapMode.intelligence => 'Intelligence · AI ready',
        MapMode.spatial => 'Spatial Engine · 3D world',
        MapMode.custom => 'Custom World · Preview',
      };

  Color get _statusColor => switch (widget.mode) {
        MapMode.realtime => AppColors.modeRealtime,
        MapMode.essential => AppColors.modeEssential,
        MapMode.intelligence => AppColors.modeIntelligence,
        MapMode.spatial => AppColors.modeSpatial,
        MapMode.custom => AppColors.modeCustom,
      };

  String? get _modeActionLabel => switch (widget.mode) {
        MapMode.intelligence => 'Ask OpenGeo AI',
        MapMode.spatial => 'Game Mode',
        MapMode.custom => 'Custom World',
        _ => null,
      };
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.place,
    required this.onOpen,
    required this.onSeeAll,
    required this.saved,
    required this.onSave,
  });

  final Place place;
  final VoidCallback onOpen;
  final VoidCallback onSeeAll;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(R.card),
        boxShadow: AppShadows.float,
      ),
      padding: const EdgeInsets.fromLTRB(S.md, S.sm, S.md, S.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nearby',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('See all'),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
          PlaceTile(
            place: place,
            onTap: onOpen,
            artSize: 56,
            padding: const EdgeInsets.only(bottom: S.xs),
            trailing: IconButton(
              icon: Icon(
                saved ? Icons.bookmark : Icons.bookmark_border,
                size: 20,
              ),
              tooltip: saved ? 'Remove from saved' : 'Save place',
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficLegend extends StatelessWidget {
  const _TrafficLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: S.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(R.card),
        boxShadow: AppShadows.card,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendDot(color: AppColors.danger, label: 'Heavy'),
          _LegendDot(color: AppColors.warning, label: 'Moderate'),
          _LegendDot(color: AppColors.success, label: 'Smooth'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
