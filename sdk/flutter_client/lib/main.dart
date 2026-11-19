import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const OpenGeoApp());
}

/// OpenGeo Flutter client — example app for the SDK.
///
/// Flow: splash → Select a Mode → four-tab shell (Map, Explore, Saved, Profile).
class OpenGeoApp extends StatelessWidget {
  const OpenGeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenGeo',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const OnboardingScreen(),
    );
  }
}
