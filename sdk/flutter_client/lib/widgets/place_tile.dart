import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// One place row: category art, name, distance/rating line, category line.
///
/// Ratings are sample data; [StarRating] renders nothing when the place has no
/// rating, so API records fall back to just the distance.
class PlaceTile extends StatelessWidget {
  const PlaceTile({
    super.key,
    required this.place,
    this.onTap,
    this.trailing,
    this.artSize = 64,
    this.padding = const EdgeInsets.symmetric(vertical: S.sm),
  });

  final Place place;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double artSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(R.card),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryArt(place: place, size: artSize),
            const SizedBox(width: S.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.displayName,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: S.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (place.distanceMeters != null)
                        Text(
                          place.distanceFormatted,
                          style: text.bodySmall,
                        ),
                      StarRating(place: place),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (place.category.isNotEmpty) _category(place.category),
                      if (place.priceLevel != null) place.priceLevel!,
                    ].join(' · '),
                    style: text.bodySmall?.copyWith(color: secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: S.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  static String _category(String value) =>
      value[0].toUpperCase() + value.substring(1);
}
