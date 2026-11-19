import 'package:flutter/material.dart';
import 'package:opengeo_flutter/app_theme.dart';
import 'package:opengeo_flutter/models/place.dart';

/// Place card — boundary-aware display of a place result.
///
/// Shows the place name, category, address, and optional distance.
/// Boundary-inclusive semantics are the responsibility of the caller;
/// this card only displays what the API returned.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    this.onTap,
    this.isSelected = false,
  });

  final Place place;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.displayName,
                          style: AppTheme.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceSm,
                            vertical: AppTheme.spaceXs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withValues(alpha: 0.1)
                                : colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: Text(
                            place.category.toUpperCase(),
                            style: AppTheme.labelSmall.copyWith(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (place.distanceMeters != null)
                    Text(
                      place.distanceMeters! < 1000
                          ? '${place.distanceMeters!.round()} m'
                          : '${(place.distanceMeters! / 1000).toStringAsFixed(1)} km',
                      style: AppTheme.titleMedium.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              if (place.addressLine != null) ...[
                const SizedBox(height: AppTheme.spaceSm),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppTheme.spaceXs),
                    Expanded(
                      child: Text(
                        place.addressLine!,
                        style: AppTheme.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
