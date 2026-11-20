import 'package:flutter/material.dart';

import 'models/map_mode.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/custom_world_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/game_mode_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/route_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/shell_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/slippy_map.dart';

void main() {
  // Bound decoded tile memory: the viewport only ever shows a few dozen tiles,
  // so the default 100 MB / 1000-image budget is wasted headroom.
  WidgetsFlutterBinding.ensureInitialized();
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSizeBytes = 64 << 20; // 64 MB
  imageCache.maximumSize = 256;
  runApp(const OpenGeoApp());
}

/// Resolves `?mode=<name>` so a mode can be linked or screenshotted directly.
/// Returns null when absent or unknown, which keeps the normal splash flow.
MapMode? mapModeFromName(String? name) {
  if (name == null || name.isEmpty) return null;
  for (final mode in MapMode.values) {
    if (mode.name == name) return mode;
  }
  return null;
}

/// Resolves `?screen=<name>` to a single full-screen route, used by docs and
/// deep links. Returns null for absent or unknown values.
Widget? screenFromName(String? name) => switch (name) {
      'ai' => const AiAssistantScreen(),
      'game' => const GameModeScreen(),
      'custom-world' => const CustomWorldScreen(),
      'route' => const RouteScreen(),
      'explore' => const ExploreScreen(mode: MapMode.essential),
      'saved' => const SavedScreen(),
      _ => null,
    };

/// Resolves `?style=<name>` to a base-map preset.
MapStyle? mapStyleFromName(String? name) {
  if (name == null || name.isEmpty) return null;
  for (final style in MapStyle.values) {
    if (style.name == name) return style;
  }
  return null;
}

/// OpenGeo Flutter client — example app for the SDK.
///
/// Flow: splash → Select a Mode → four-tab shell (Map, Explore, Saved, Profile).
class OpenGeoApp extends StatelessWidget {
  const OpenGeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final query = Uri.base.queryParameters;
    final direct = screenFromName(query['screen']);
    final mode = mapModeFromName(query['mode']);
    return MaterialApp(
      title: 'OpenGeo',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: direct ??
          (mode == null
              ? const OnboardingScreen()
              : ShellScreen(
                  mode: mode,
                  initialStyle: mapStyleFromName(query['style']),
                )),
    );
  }
}
