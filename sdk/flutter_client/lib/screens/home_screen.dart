import 'package:flutter/material.dart';
import 'package:opengeo_flutter/app_theme.dart';

/// Home screen with mode selection via AppBar dropdown.
///
/// Modes available:
/// - Live Realtime (default)
/// - Satellite
/// - LLM Based
/// - Game Maps
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_ModeInfo> _modes = [
    _ModeInfo('Live Realtime', Icons.map, 'realtime'),
    _ModeInfo('Satellite', Icons.satellite, 'satellite'),
    _ModeInfo('LLM Based', Icons.psychology, 'llm'),
    _ModeInfo('Game Maps', Icons.sports_esports, 'game'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenGeo Maps'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) {
              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'realtime',
                  icon: Icon(Icons.layers, color: colorScheme.onSurface),
                  onChanged: (String? newValue) {
                    // Navigate to selected mode
                  },
                  items: _modes.map<DropdownMenuItem<String>>((mode) {
                    return DropdownMenuItem<String>(
                      value: mode.id,
                      child: Row(
                        children: [
                          Icon(mode.icon, size: 18),
                          const SizedBox(width: AppTheme.spaceSm),
                          Text(mode.label),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            color: colorScheme.onSurface,
            onPressed: () {
              // TODO: Show search dialog
            },
          ),
        ],
      ),
      body: const LiveMapPlaceholder(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // Mode selection handled via AppBar dropdown
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.directions), label: 'Route'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Places'),
        ],
      ),
    );
  }
}

class _ModeInfo {
  final String label;
  final IconData icon;
  final String id;

  const _ModeInfo(this.label, this.icon, this.id);
}

/// Live Realtime map placeholder.
/// In production, replace with MapLibreMap widget from package:maplibre_gl
class LiveMapPlaceholder extends StatelessWidget {
  const LiveMapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Map header with controls
        Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.gps_fixed),
                color: colorScheme.primary,
                onPressed: () {
                  // TODO: Center map on user location
                },
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search nearby...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Map container (placeholder)
        Expanded(
          child: Container(
            color: colorScheme.surfaceContainer,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 96,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Text(
                  'Live Realtime Map',
                  style: AppTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXs),
                Text(
                  'MapLibre GL integration pending\nAdd MapLibreMap widget from package:maplibre_gl',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}