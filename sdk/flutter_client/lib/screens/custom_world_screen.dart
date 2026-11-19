import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/slippy_map.dart';

/// Custom World preview: base map plus a layer checklist and a world card.
class CustomWorldScreen extends StatefulWidget {
  const CustomWorldScreen({super.key});

  @override
  State<CustomWorldScreen> createState() => _CustomWorldScreenState();
}

class _CustomWorldScreenState extends State<CustomWorldScreen> {
  final _layers = <String, bool>{
    'Buildings': true,
    'Terrain': true,
    'Water': true,
    'Events': true,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: SlippyMap(
              center: puneCentre,
              zoom: 13,
              style: MapStyle.defaultStyle,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(S.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: S.sm),
                      const StatusChip(
                        label: 'Custom World',
                        color: AppColors.modeCustom,
                        icon: Icons.public,
                      ),
                    ],
                  ),
                  const SizedBox(height: S.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 172,
                      padding: const EdgeInsets.symmetric(vertical: S.xs),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(R.card),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        children: [
                          for (final entry in _layers.entries)
                            InkWell(
                              onTap: () => setState(
                                () => _layers[entry.key] = !entry.value,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: S.md,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      entry.value
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 18,
                                      color: scheme.primary,
                                    ),
                                    const SizedBox(width: S.sm),
                                    Text(
                                      entry.key,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: S.md,
                      vertical: S.xs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(R.chip),
                    ),
                    child: Text(
                      'Layer checklist is local to this preview. Custom world '
                      'assets are not served by the API yet.',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: S.sm),
                  Container(
                    padding: const EdgeInsets.all(S.md),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(R.card),
                      boxShadow: AppShadows.float,
                    ),
                    child: Row(
                      children: [
                        const ModeBadge(
                          icon: Icons.view_in_ar,
                          color: AppColors.modeCustom,
                        ),
                        const SizedBox(width: S.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fantasy Realm',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Explore custom worlds',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: scheme.onSurfaceVariant,
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
