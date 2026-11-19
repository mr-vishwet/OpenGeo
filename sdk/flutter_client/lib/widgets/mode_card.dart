import 'package:flutter/material.dart' hide NavigationMode;
import 'package:opengeo_flutter/app_theme.dart';
import 'package:opengeo_flutter/models/place.dart';

/// Navigation mode card — selectable mode tile.
///
/// One card per navigation mode (Live Realtime, Satellite, LLM Based,
/// Game Maps). Selected state shows a colored border and filled icon.
class ModeCard extends StatelessWidget {
  const ModeCard({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final NavigationMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: isSelected ? mode.color : colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? mode.color.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  mode.icon,
                  color: isSelected ? mode.color : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXs / 2),
                    Text(
                      mode.subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? mode.color : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
