import 'geo_point.dart';

/// A geographic place as served by the OpenGeo API.
///
/// [rating], [reviewCount] and [priceLevel] are display-only fields: the
/// OpenGeo API does not serve ratings, reviews or price levels. They are
/// populated from the example app's marked sample data and are null for
/// records that came from a real API response.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.longitude,
    required this.latitude,
    this.distanceMeters,
    this.locality,
    this.address,
    this.names = const [],
    this.rating,
    this.reviewCount,
    this.priceLevel,
  });

  final String id;
  final String name;
  final String category;
  final double longitude;
  final double latitude;
  final double? distanceMeters;
  final String? locality;
  final Map<String, dynamic>? address;
  final List<LocalizedName> names;

  // Display-only sample fields — never populated from the API.
  final double? rating;
  final int? reviewCount;
  final String? priceLevel;

  GeoPoint get point => GeoPoint(latitude, longitude);

  /// Primary display name: the untagged name entry when present.
  String get displayName {
    for (final entry in names) {
      if (entry.language.isEmpty) return entry.value;
    }
    return names.isNotEmpty ? names.first.value : name;
  }

  /// "42, Main Road, Shivajinagar" — null when the address has no parts.
  String? get addressLine {
    final a = address;
    if (a == null) return null;
    final parts = <String>[];
    for (final key in const ['house_number', 'street', 'locality']) {
      final value = a[key];
      if (value is String && value.isNotEmpty) parts.add(value);
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Secondary line for lists: "Park · 850 m" or "Cafe · ₹₹".
  String get metaLine {
    final bits = <String>[_categoryLabel];
    if (distanceMeters != null) bits.add(distanceFormatted);
    if (priceLevel != null) bits.add(priceLevel!);
    return bits.join(' · ');
  }

  String get _categoryLabel =>
      category.isEmpty ? 'Place' : category[0].toUpperCase() + category.substring(1);

  /// "850 m" / "1.3 km" / "—" when the distance is unknown.
  String get distanceFormatted {
    final d = distanceMeters;
    if (d == null) return '—';
    if (d < 1000) return '${d.round()} m';
    return '${(d / 1000).toStringAsFixed(1)} km';
  }

  /// "4.6 (2.1k)" — sample data only, null when unrated.
  String? get ratingLabel {
    final r = rating;
    if (r == null) return null;
    final reviews = reviewCount;
    if (reviews == null) return r.toStringAsFixed(1);
    final count = reviews >= 1000
        ? '${(reviews / 1000).toStringAsFixed(1)}k'
        : '$reviews';
    return '${r.toStringAsFixed(1)} ($count)';
  }

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';

  factory Place.fromJson(Map<String, dynamic> json) {
    final rawNames = json['names'];
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      category: (json['category'] as String?) ?? '',
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      locality: json['locality'] as String?,
      address: (json['address'] as Map?)?.cast<String, dynamic>(),
      names: rawNames is List
          ? rawNames
              .whereType<Map>()
              .map((e) => LocalizedName.fromJson(e.cast<String, dynamic>()))
              .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'longitude': longitude,
        'latitude': latitude,
        if (distanceMeters != null) 'distance_meters': distanceMeters,
        if (locality != null) 'locality': locality,
        if (address != null) 'address': address,
        if (names.isNotEmpty)
          'names': names.map((e) => e.toJson()).toList(growable: false),
      };
}

/// A name in one language; empty [language] marks the primary name.
class LocalizedName {
  const LocalizedName({required this.language, required this.value});

  final String language;
  final String value;

  factory LocalizedName.fromJson(Map<String, dynamic> json) => LocalizedName(
        language: (json['language'] as String?) ?? '',
        value: (json['value'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {'language': language, 'value': value};
}
