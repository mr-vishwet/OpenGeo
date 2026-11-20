import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/map_mode.dart';
import '../models/place.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/place_tile.dart';
import '../widgets/map_viewport.dart';
import '../widgets/slippy_map.dart';
import 'place_detail_screen.dart';

/// Explore tab: search field, map preview, category filters, result list.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.mode,
    this.standalone = false,
    this.onViewOnMap,
  });

  final MapMode mode;

  /// True when pushed as a full page instead of living in the tab shell.
  final bool standalone;

  /// Switches the shell to the Map tab. Null when [standalone] is true.
  final VoidCallback? onViewOnMap;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _controller = TextEditingController(text: 'coffee near me');
  String _filter = 'All';
  final _saved = <String>{};

  static const _filters = ['All', 'Cafe', 'Resto', 'Takeaway'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Place> get _results {
    final tokens = _controller.text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toList();
    return samplePlaces.where((place) {
      if (_filter != 'All') {
        final wanted = _filter == 'Resto' ? 'restaurant' : _filter.toLowerCase();
        if (place.category != wanted) return false;
      }
      if (tokens.isEmpty) return true;
      final haystack =
          '${place.name} ${place.category} ${place.category == 'cafe' ? 'coffee' : ''}'
              .toLowerCase();
      return tokens.any(haystack.contains);
    }).toList();
  }

  void _viewOnMap() {
    if (widget.standalone) {
      Navigator.of(context).maybePop();
    } else {
      widget.onViewOnMap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = _results;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: scheme.surface,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, S.sm),
                child: Row(
                  children: [
                    if (widget.standalone)
                      Padding(
                        padding: const EdgeInsets.only(right: S.sm),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          hintText: 'Search places, addresses...',
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  tooltip: 'Clear search',
                                  onPressed: () => setState(_controller.clear),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 190,
            child: MapViewport(
              center: puneCentre,
              zoom: 12,
              style: MapStyle.street,
              // Small preview: a second WebGL context is not worth it here.
              gl: false,
              markers: [
                for (final place in results)
                  MapMarker(
                    point: place.point,
                    color: AppColors.primary,
                    icon: CategoryArt.iconFor(place.category),
                    size: 28,
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: 8),
              children: [
                for (final filter in _filters) ...[
                  ChoicePill(
                    label: filter,
                    selected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
                  const SizedBox(width: S.sm),
                ],
                IconButton(
                  icon: const Icon(Icons.tune, size: 20),
                  tooltip: 'More filters',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Advanced search filters are not served by the API yet.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(S.xl),
                      child: Text(
                        'No places in this category yet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(S.lg, 0, S.lg, S.lg),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => Divider(color: scheme.outline),
                    itemBuilder: (context, index) {
                      final place = results[index];
                      final saved = _saved.contains(place.id);
                      return PlaceTile(
                        place: place,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlaceDetailScreen(place: place),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, size: 20),
                          tooltip: saved ? 'Remove from saved' : 'Save place',
                          onPressed: () => setState(() {
                            if (saved) {
                              _saved.remove(place.id);
                            } else {
                              _saved.add(place.id);
                            }
                          }),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, S.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _viewOnMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('View on Map'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
