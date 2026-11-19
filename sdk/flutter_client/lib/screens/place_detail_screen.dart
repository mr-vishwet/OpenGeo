import 'package:flutter/material.dart';
import 'package:opengeo_flutter/app_theme.dart';
import 'package:opengeo_flutter/models/place.dart';

/// Place detail screen — full place information with boundary semantics.
///
/// Shows place name, category, address, coordinates, and distance.
/// Explicitly shows that coordinates are EPSG:4326 (longitude, latitude).
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(place.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place header
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                side: BorderSide(color: colorScheme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
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
                                style: AppTheme.headlineMedium.copyWith(
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
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  place.category.toUpperCase(),
                                  style: AppTheme.labelSmall.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (place.distanceMeters != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                place.distanceFormatted,
                                style: AppTheme.headlineMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceXs),
                              Text(
                                'from you',
                                style: AppTheme.labelSmall.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (place.addressLine != null) ...[
                      const SizedBox(height: AppTheme.spaceMd),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppTheme.spaceXs),
                          Expanded(
                            child: Text(
                              place.addressLine!,
                              style: AppTheme.bodyMedium.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppTheme.spaceMd),
                    Row(
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppTheme.spaceXs),
                        Text(
                          '${place.latitude.toStringAsFixed(4)}°, ${place.longitude.toStringAsFixed(4)}°',
                          style: AppTheme.bodyMedium.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMd),
                        Text(
                          'EPSG:4326',
                          style: AppTheme.labelSmall.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            // About section
            Text(
              'About this place',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: BorderSide(color: colorScheme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      context,
                      'Place ID',
                      place.id,
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      context,
                      'Category',
                      place.category.toUpperCase(),
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      context,
                      'Source',
                      'OpenStreetMap (ODbL)',
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      context,
                      'Distance',
                      place.distanceMeters != null
                          ? place.distanceFormatted
                          : 'Not available',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            // Note about boundary semantics
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: BorderSide(color: colorScheme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spaceXs),
                        Text(
                          'Boundary semantics',
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    Text(
                      'OpenGeo uses two distinct predicates for containment: '
                      'contains excludes the boundary; '
                      'covers includes it. '
                      'This place result reflects the predicate used at query time.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTheme.labelMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
