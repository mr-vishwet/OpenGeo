import 'package:flutter/material.dart';
import 'package:opengeo_flutter/app_theme.dart';
import 'package:opengeo_flutter/screens/map_screen.dart';
import 'package:opengeo_flutter/screens/navigation_mode_screen.dart';

void main() {
  runApp(const OpenGeoApp());
}

/// OpenGeo Flutter client — scaffold for the MapLibre-powered map client.
///
/// Displays nearby places around Pune with support for multiple navigation
/// modes (Live Realtime, Satellite, LLM Based, Game Maps).
///
/// Follows Ponytail / kill-the-vibecode-mobile principles:
/// - Material 3 design tokens (color, type, spacing, shape)
/// - Safe areas respected
/// - 48dp minimum touch targets
/// - Light + dark theme support
/// - No gradient app bars, emoji, or fake ratings
/// - Placeholder for MapLibre GL integration (add MapLibreMap widget)
class OpenGeoApp extends StatelessWidget {
  const OpenGeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenGeo',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const MapScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/mode') {
          return MaterialPageRoute(
            builder: (_) => const NavigationModeScreen(),
          );
        }
        return null;
      },
    );
  }
}
