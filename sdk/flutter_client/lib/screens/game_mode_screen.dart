import 'dart:async';

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/map_viewport.dart';
import '../widgets/slippy_map.dart';

/// Spatial Engine preview: satellite map with a shrinking zone and a
/// sample match HUD.
class GameModeScreen extends StatefulWidget {
  const GameModeScreen({super.key});

  @override
  State<GameModeScreen> createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> {
  // Sample round state — there is no game service behind this screen.
  static const _players = 48;
  static const _alive = 23;

  int _seconds = 12;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds = _seconds == 0 ? 12 : _seconds - 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown =>
      '00:${_seconds.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapViewport(
              center: puneCentre,
              zoom: 13,
              style: MapStyle.satellite,
              markers: [
                MapMarker(
                  point: puneCentre,
                  color: AppColors.primary,
                  icon: Icons.my_location,
                  size: 30,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(S.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        dark: true,
                      ),
                      const SizedBox(width: S.sm),
                      const StatusChip(
                        label: 'Game Mode',
                        color: AppColors.modeSpatial,
                        icon: Icons.sports_esports,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: S.md,
                          vertical: S.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(R.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield, size: 14, color: AppColors.modeRealtime),
                                SizedBox(width: 4),
                                Text(
                                  'Safe Zone',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _countdown,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Spacer(),
                      Column(
                        children: [
                          RoundIconButton(
                            icon: Icons.layers_outlined,
                            tooltip: 'Layers',
                            onPressed: () {},
                            dark: true,
                          ),
                          const SizedBox(height: S.sm),
                          RoundIconButton(
                            icon: Icons.my_location,
                            tooltip: 'Recenter',
                            onPressed: () {},
                            dark: true,
                          ),
                          const SizedBox(height: S.sm),
                          RoundIconButton(
                            icon: Icons.close,
                            tooltip: 'Leave match',
                            onPressed: () => Navigator.of(context).maybePop(),
                            dark: true,
                          ),
                          const SizedBox(height: S.sm),
                          RoundIconButton(
                            icon: Icons.sports_esports,
                            tooltip: 'Inventory',
                            onPressed: () {},
                            dark: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: S.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: S.lg,
                      vertical: S.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(R.card),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.groups, size: 20, color: Colors.white),
                        const SizedBox(width: S.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Players: $_players   Alive: $_alive',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Next Zone in $_countdown',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9FB6D1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const StatusChip(
                          label: 'Sample match',
                          color: AppColors.warning,
                        ),
                      ],
                    ),
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
