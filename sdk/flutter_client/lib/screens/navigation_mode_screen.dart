import 'package:flutter/material.dart' hide NavigationMode;
import 'package:opengeo_flutter/app_theme.dart';
import 'package:opengeo_flutter/models/place.dart';
import 'package:opengeo_flutter/widgets/mode_card.dart';

/// Navigation mode selection screen.
///
/// Four modes: Live Realtime, Satellite, LLM Based, Game Maps.
/// Selecting a mode updates the map display style.
class NavigationModeScreen extends StatelessWidget {
  const NavigationModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Mode'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how OpenGeo renders the map',
              style: AppTheme.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              'Each mode serves a different use case — the underlying '
              'geography engine stays the same.',
              style: AppTheme.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            ...NavigationMode.values.map(
              (mode) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
                child: ModeCard(
                  mode: mode,
                  isSelected: mode == NavigationMode.liveRealtime,
                  onTap: () {
                    Navigator.of(context).pop(mode);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).pop(NavigationMode.liveRealtime);
          },
          child: const Text('Continue with Live Realtime'),
        ),
      ),
    );
  }
}
