import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'route_screen.dart';

/// Place detail with the identity, sample rating and EPSG:4326 coordinates.
class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final Place place;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
                  tooltip: _saved ? 'Remove from saved' : 'Save place',
                  onPressed: () => setState(() => _saved = !_saved),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: scheme.primaryContainer,
                  child: Center(
                    child: Icon(
                      CategoryArt.iconFor(place.category),
                      size: 72,
                      color: scheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(S.lg),
              sliver: SliverList.list(
                children: [
                  Text(place.displayName, style: text.displaySmall),
                  const SizedBox(height: S.xs),
                  Row(
                    children: [
                      Text(
                        [
                          if (place.category.isNotEmpty)
                            place.category[0].toUpperCase() +
                                place.category.substring(1),
                          if (place.distanceMeters != null)
                            place.distanceFormatted,
                        ].join(' · '),
                        style: text.bodySmall,
                      ),
                      if (place.ratingLabel != null) ...[
                        const SizedBox(width: S.md),
                        StarRating(place: place),
                      ],
                    ],
                  ),
                  if (place.rating != null) ...[
                    const SizedBox(height: S.xs),
                    Text('Sample rating, not served by the API', style: text.labelSmall),
                  ],
                  const SizedBox(height: S.lg),
                  Container(
                    padding: const EdgeInsets.all(S.md),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(R.card),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coordinates', style: text.titleSmall),
                        const SizedBox(height: S.sm),
                        MetaRow(
                          icon: Icons.place_outlined,
                          label: place.coordinatesLabel,
                        ),
                        const MetaRow(
                          icon: Icons.grid_on,
                          label: 'EPSG:4326 · WGS 84',
                        ),
                        MetaRow(
                          icon: Icons.tag,
                          label: place.id,
                        ),
                      ],
                    ),
                  ),
                  if (place.addressLine != null) ...[
                    const SizedBox(height: S.lg),
                    Text('Address', style: text.titleSmall),
                    const SizedBox(height: S.xs),
                    Text(place.addressLine!, style: text.bodyMedium),
                  ],
                  const SizedBox(height: S.xl),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RouteScreen(destination: place),
                            ),
                          ),
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Directions'),
                        ),
                      ),
                      const SizedBox(width: S.md),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _saved = !_saved),
                        icon: Icon(
                          _saved ? Icons.bookmark : Icons.bookmark_border,
                          size: 18,
                        ),
                        label: Text(_saved ? 'Saved' : 'Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: S.md),
                  Text(
                    'Directions open a sample route preview: the OpenGeo API '
                    'does not serve routing yet.',
                    style: text.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
