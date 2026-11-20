import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/slippy_map.dart';

/// Result of the Map Options sheet.
class MapOptions {
  const MapOptions({
    this.style = MapStyle.street,
    this.traffic = true,
    this.relief = false,
  });

  final MapStyle style;

  /// Shows the sample traffic layer card on the map.
  final bool traffic;

  /// Draws the Esri hillshade layer over the base map for real terrain relief.
  final bool relief;

  MapOptions copyWith({MapStyle? style, bool? traffic, bool? relief}) =>
      MapOptions(
        style: style ?? this.style,
        traffic: traffic ?? this.traffic,
        relief: relief ?? this.relief,
      );
}

/// Bottom sheet matching the reference: layer switches, map style, download area.
class MapOptionsSheet extends StatefulWidget {
  const MapOptionsSheet({super.key, required this.initial});

  final MapOptions initial;

  @override
  State<MapOptionsSheet> createState() => _MapOptionsSheetState();
}

class _MapOptionsSheetState extends State<MapOptionsSheet> {
  late MapOptions _options = widget.initial;
  bool _buildings3d = true;
  bool _indoor = false;
  bool _offline = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, S.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(R.pill),
                ),
              ),
            ),
            const SizedBox(height: S.md),
            Row(
              children: [
                Expanded(child: Text('Map Options', style: text.headlineMedium)),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(_options),
                ),
              ],
            ),
            _SwitchRow(
              label: 'Traffic Layer',
              value: _options.traffic,
              onChanged: (v) =>
                  setState(() => _options = _options.copyWith(traffic: v)),
            ),
            _SwitchRow(
              label: '3D Buildings',
              value: _buildings3d,
              onChanged: (v) => setState(() => _buildings3d = v),
            ),
            _SwitchRow(
              label: 'Satellite View',
              value: _options.style == MapStyle.satellite,
              onChanged: (v) => setState(() => _options = _options.copyWith(
                    style: v ? MapStyle.satellite : MapStyle.street,
                  )),
            ),
            _SwitchRow(
              label: 'Terrain Relief',
              value: _options.relief,
              onChanged: (v) =>
                  setState(() => _options = _options.copyWith(relief: v)),
            ),
            _SwitchRow(
              label: 'Indoor Maps',
              value: _indoor,
              onChanged: (v) => setState(() => _indoor = v),
            ),
            _SwitchRow(
              label: 'Offline Mode',
              value: _offline,
              onChanged: (v) => setState(() => _offline = v),
            ),
            const SizedBox(height: S.lg),
            Text('Map Style', style: text.titleMedium),
            const SizedBox(height: S.md),
            Row(
              children: [
                for (final style in MapStyle.values) ...[
                  Expanded(
                    child: _StyleTile(
                      style: style,
                      selected: _options.style == style,
                      onTap: () => setState(
                        () => _options = _options.copyWith(style: style),
                      ),
                    ),
                  ),
                  if (style != MapStyle.values.last) const SizedBox(width: S.md),
                ],
              ],
            ),
            const SizedBox(height: S.lg),
            Text('Download Area', style: text.titleMedium),
            const SizedBox(height: S.xs),
            Text('Save this area for offline use', style: text.bodySmall),
            const SizedBox(height: S.sm),
            Text(
              'Preview build: map style and the traffic card are wired. '
              'Buildings, terrain, indoor and offline layers need the OpenGeo '
              'tiling service.',
              style: text.labelSmall?.copyWith(color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final MapStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, colors) = switch (style) {
      MapStyle.street => (
          Icons.map_outlined,
          const [Color(0xFFF5F7FA), Color(0xFFDDE7F0)],
        ),
      MapStyle.dark => (
          Icons.nightlight_outlined,
          const [Color(0xFF2C3138), Color(0xFF15181D)],
        ),
      MapStyle.satellite => (
          Icons.satellite_alt_outlined,
          const [Color(0xFF3E5C43), Color(0xFF1F3B52)],
        ),
      MapStyle.terrain => (
          Icons.terrain,
          const [Color(0xFFCBC3A9), Color(0xFF7C8A6A)],
        ),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: '${style.label} map style',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.input),
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(R.input),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outline,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: style == MapStyle.street
                      ? AppColors.textSecondary
                      : Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: S.xs),
            Text(
              style.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
