import '../models/geo_point.dart';
import '../models/place.dart';

/// Pune sample data for the example app.
///
/// Coordinates and names come from the Pune OpenStreetMap fixture. Distances,
/// ratings, review counts and price levels are marked sample values — the
/// OpenGeo API does not serve them, so [Place.fromJson] leaves them null.
const samplePlaces = <Place>[
  Place(
    id: 'osho-garden',
    name: 'Osho Garden',
    category: 'park',
    latitude: 18.5089,
    longitude: 73.8584,
    distanceMeters: 850,
    rating: 4.6,
    reviewCount: 12000,
  ),
  Place(
    id: 'blue-tokai',
    name: 'Blue Tokai Coffee',
    category: 'cafe',
    latitude: 18.5362,
    longitude: 73.8940,
    distanceMeters: 650,
    rating: 4.6,
    reviewCount: 2100,
    priceLevel: '₹₹',
  ),
  Place(
    id: 'third-wave',
    name: 'Third Wave Coffee',
    category: 'cafe',
    latitude: 18.5484,
    longitude: 73.9067,
    distanceMeters: 1100,
    rating: 4.5,
    reviewCount: 1800,
    priceLevel: '₹₹',
  ),
  Place(
    id: 'subko',
    name: 'Subko Coffee',
    category: 'cafe',
    latitude: 18.5392,
    longitude: 73.8917,
    distanceMeters: 1300,
    rating: 4.4,
    reviewCount: 932,
    priceLevel: '₹₹₹',
  ),
  Place(
    id: 'cafe-goodluck',
    name: 'Cafe Goodluck',
    category: 'cafe',
    latitude: 18.5158,
    longitude: 73.8794,
    distanceMeters: 1600,
    rating: 4.3,
    reviewCount: 711,
    priceLevel: '₹₹',
  ),
  Place(
    id: 'saras-baug',
    name: 'Saras Baug',
    category: 'park',
    latitude: 18.5018,
    longitude: 73.8485,
    distanceMeters: 1100,
    rating: 4.7,
    reviewCount: 3200,
  ),
  Place(
    id: 'empress-garden',
    name: 'Empress Garden',
    category: 'park',
    latitude: 18.5117,
    longitude: 73.8925,
    distanceMeters: 2200,
    rating: 4.4,
    reviewCount: 1500,
  ),
  Place(
    id: 'shaniwar-wada',
    name: 'Shaniwar Wada',
    category: 'historic',
    latitude: 18.5196,
    longitude: 73.8562,
    distanceMeters: 1400,
  ),
  Place(
    id: 'phoenix-mall',
    name: 'Phoenix Mall',
    category: 'mall',
    latitude: 18.5626,
    longitude: 73.9169,
    distanceMeters: 4200,
  ),
];

/// Pune city centre, the default map camera.
const puneCentre = GeoPoint(18.5204, 73.8567);

/// Sample origin used by the route screen.
const sampleOrigin = GeoPoint(18.5120, 73.8210);

/// Sample polyline from [sampleOrigin] to Shaniwar Wada, about 3.7 km.
const sampleRoute = <GeoPoint>[
  sampleOrigin,
  GeoPoint(18.5135, 73.8290),
  GeoPoint(18.5152, 73.8370),
  GeoPoint(18.5168, 73.8440),
  GeoPoint(18.5180, 73.8500),
  GeoPoint(18.5196, 73.8562),
];

/// Camera centre that keeps [sampleRoute] in frame.
const sampleRouteCentre = GeoPoint(18.5160, 73.8386);

Iterable<Place> placesInCategory(String category) =>
    samplePlaces.where((p) => p.category == category);

/// The four saved places from the reference screen.
const savedPlaceIds = <String>['phoenix-mall', 'shaniwar-wada', 'osho-garden', 'blue-tokai'];
