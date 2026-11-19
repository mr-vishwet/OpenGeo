import 'package:flutter/material.dart' hide NavigationMode;
import 'package:opengeo_flutter/app_theme.dart';
import 'package:opengeo_flutter/models/place.dart';
import 'package:opengeo_flutter/screens/place_detail_screen.dart';
import 'package:opengeo_flutter/widgets/place_card.dart';

/// Map screen — displays places on a map with nearby results list.
///
/// Placeholder for MapLibre GL integration. Displays a list of nearby places
/// with the map area shown above. In production, this would embed a
/// MapLibreMap widget from package:maplibre_gl.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<Place> _places = const [
    Place(
      id: 'opengeo:place:0001',
      name: 'Cafe Goodluck',
      category: 'cafe',
      longitude: 73.8794,
      latitude: 18.5158,
      distanceMeters: 320,
      address: {
        'house_number': '759/75',
        'street': 'FC Road',
        'locality': 'Shivajinagar',
        'region': 'Maharashtra',
        'postal_code': '411005',
        'country_code': 'IN',
      },
      names: [
        {'language': '', 'value': 'Cafe Goodluck'},
        {'language': 'mr', 'value': 'कॅफे गुडलक'},
      ],
    ),
    Place(
      id: 'opengeo:place:0002',
      name: 'Cafe Goodluck',
      category: 'cafe',
      longitude: 73.8936,
      latitude: 18.5362,
      distanceMeters: 850,
      address: {
        'house_number': '32',
        'street': 'North Main Road',
        'locality': 'Koregaon Park',
        'region': 'Maharashtra',
        'postal_code': '411001',
        'country_code': 'IN',
      },
    ),
    Place(
      id: 'opengeo:place:0003',
      name: 'Shaniwar Wada',
      category: 'attraction',
      longitude: 73.8562,
      latitude: 18.5196,
      distanceMeters: 1200,
      address: {
        'region': 'Maharashtra',
        'locality': 'Shaniwar Peth',
        'postal_code': '411030',
        'country_code': 'IN',
      },
      names: [
        {'language': '', 'value': 'Shaniwar Wada'},
        {'language': 'mr', 'value': 'शनिवार वाडा'},
      ],
    ),
    Place(
      id: 'opengeo:place:0004',
      name: 'Dagdusheth Halwai Ganpati',
      category: 'worship',
      longitude: 73.8543,
      latitude: 18.5184,
      distanceMeters: 950,
      address: {
        'region': 'Maharashtra',
        'locality': 'Budhwar Peth',
        'country_code': 'IN',
      },
      names: [
        {'language': '', 'value': 'Dagdusheth Halwai Ganpati'},
        {'language': 'mr', 'value': 'दगडूशेठ हलवाई गणपती'},
      ],
    ),
    Place(
      id: 'opengeo:place:0005',
      name: 'Vaishali',
      category: 'cafe',
      longitude: 73.8594,
      latitude: 18.5228,
      distanceMeters: 600,
      address: {
        'street': 'FC Road',
        'locality': 'Shivajinagar',
        'region': 'Maharashtra',
        'postal_code': '411004',
        'country_code': 'IN',
      },
    ),
  ];

  // Not final: mutated by onTap in _onModeSelected
  NavigationMode _selectedMode = NavigationMode.liveRealtime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Map area — placeholder with mode indicator
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: colorScheme.surfaceContainer,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedMode.icon,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Text(
                    '${_selectedMode.label} map',
                    style: AppTheme.headlineMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  Text(
                    'MapLibre GL integration pending — '
                    'add MapLibreMap widget from package:maplibre_gl',
                    style: AppTheme.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  Text(
                    'Pune centre: 18.5204° N, 73.8567° E',
                    style: AppTheme.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Places list
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nearby places',
                        style: AppTheme.headlineSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${_places.length} results',
                        style: AppTheme.labelMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                    ),
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      return PlaceCard(
                        place: _places[index],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailScreen(
                                place: _places[index],
                              ),
                            ),
                          );
                        },
                        isSelected: index == 0,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
