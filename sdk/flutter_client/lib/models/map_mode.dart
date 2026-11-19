import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The five OpenGeo map modes shown on the "Select a Mode" screen.
///
/// Named [MapMode] rather than NavigationMode because Flutter's material
/// library already exports a `NavigationMode`.
enum MapMode {
  realtime(
    'Realtime',
    'Live traffic, live locations & dynamic updates',
    Icons.bolt,
    AppColors.modeRealtime,
  ),
  essential(
    'Essential',
    '2D Maps, Search & Navigation',
    Icons.place,
    AppColors.modeEssential,
  ),
  intelligence(
    'Intelligence',
    'Spatial AI, Advanced Search & Insights',
    Icons.psychology,
    AppColors.modeIntelligence,
  ),
  spatial(
    'Spatial Engine',
    '3D World, Game Maps & Spatial Events',
    Icons.view_in_ar,
    AppColors.modeSpatial,
  ),
  custom(
    'Custom World',
    'Build Your Own Map',
    Icons.public,
    AppColors.modeCustom,
  );

  const MapMode(this.label, this.subtitle, this.icon, this.color);

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}
