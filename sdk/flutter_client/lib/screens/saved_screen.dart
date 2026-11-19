import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/place.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/place_tile.dart';
import 'place_detail_screen.dart';

/// Saved tab: All / Favorites / Visits.
///
/// Saved ids come from the app's sample data. Favorites and visits are empty
/// because the OpenGeo API has no user-account endpoints yet.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _tab = 'All';

  static const _tabs = ['All', 'Favorites', 'Visits'];

  List<Place> get _places => [
        for (final id in savedPlaceIds)
          for (final place in samplePlaces)
            if (place.id == id) place,
      ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final places = _tab == 'All' ? _places : const <Place>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Saved Places',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  Text(
                    '${_places.length} saved',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: 10),
                children: [
                  for (final tab in _tabs) ...[
                    ChoicePill(
                      label: tab,
                      selected: _tab == tab,
                      onTap: () => setState(() => _tab = tab),
                    ),
                    const SizedBox(width: S.sm),
                  ],
                ],
              ),
            ),
            Expanded(
              child: places.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(S.xl),
                        child: Text(
                          _tab == 'Visits'
                              ? 'No visits recorded yet.'
                              : 'No favorites yet. Tap the heart on a saved place.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(S.lg, 0, S.lg, S.lg),
                      itemCount: places.length,
                      separatorBuilder: (_, _) => Divider(color: scheme.outline),
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return PlaceTile(
                          place: place,
                          artSize: 56,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlaceDetailScreen(place: place),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.favorite,
                              size: 20,
                              color: AppColors.modeEssential,
                            ),
                            tooltip: 'Remove from favorites',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Saved places are sample data in this build.'),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
