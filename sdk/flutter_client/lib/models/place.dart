import 'package:flutter/material.dart';

/// A geographic place served by OpenGeo — one deterministic record per place.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.longitude,
    required this.latitude,
    this.distanceMeters,
    this.address,
    this.names,
  });

  final String id;
  final String name;
  final String category;
  final double longitude;
  final double latitude;
  final double? distanceMeters;
  final Map<String, dynamic>? address;
  final List<Map<String, dynamic>>? names;

  /// Primary display name — first name entry with empty language, or the
  /// provided [name] fallback.
  String get displayName {
    if (names != null && names!.isNotEmpty) {
      for (final entry in names!) {
        if (entry['language'] == '' || entry['language'] == null) {
          return entry['value'] as String? ?? name;
        }
      }
      return names!.first['value'] as String? ?? name;
    }
    return name;
  }

  /// Short address line for display.
  String? get addressLine {
    if (address == null) return null;
    final parts = <String>[];
    if (address!['house_number'] != null) parts.add(address!['house_number']);
    if (address!['street'] != null) parts.add(address!['street']);
    if (address!['locality'] != null) parts.add(address!['locality']);
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  /// Human-readable distance string.
  String get distanceFormatted {
    if (distanceMeters == null) return '—';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'longitude': longitude,
        'latitude': latitude,
        if (distanceMeters != null) 'distance_meters': distanceMeters,
        if (address != null) 'address': address,
        if (names != null) 'names': names,
      };

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      distanceMeters:
          (json['distance_meters'] as num?)?.toDouble(),
      address: json['address'] as Map<String, dynamic>?,
      names: (json['names'] as List?)?.cast<Map<String, dynamic>>(),
    );
  }
}

/// Navigation mode — one of four supported map rendering modes.
enum NavigationMode {
  liveRealtime,
  satellite,
  llmBased,
  gameMaps,
}

extension NavigationModeX on NavigationMode {
  String get label {
    switch (this) {
      case NavigationMode.liveRealtime:
        return 'Live Realtime';
      case NavigationMode.satellite:
        return 'Satellite';
      case NavigationMode.llmBased:
        return 'LLM Based';
      case NavigationMode.gameMaps:
        return 'Game Maps';
    }
  }

  String get subtitle {
    switch (this) {
      case NavigationMode.liveRealtime:
        return 'Real-time traffic & POIs';
      case NavigationMode.satellite:
        return 'Satellite imagery & terrain';
      case NavigationMode.llmBased:
        return 'Natural language queries';
      case NavigationMode.gameMaps:
        return 'Stylized game rendering';
    }
  }

  IconData get icon {
    switch (this) {
      case NavigationMode.liveRealtime:
        return Icons.traffic;
      case NavigationMode.satellite:
        return Icons.satellite;
      case NavigationMode.llmBased:
        return Icons.psychology;
      case NavigationMode.gameMaps:
        return Icons.sports_esports;
    }
  }

  Color get color {
    switch (this) {
      case NavigationMode.liveRealtime:
        return const Color(0xFF00796B); // teal
      case NavigationMode.satellite:
        return const Color(0xFF1A237E); // indigo
      case NavigationMode.llmBased:
        return const Color(0xFF6A1B9A); // purple
      case NavigationMode.gameMaps:
        return const Color(0xFFE65100); // deep orange
    }
  }
}

/// A navigation result — distance, duration, and polyline.
class RouteResult {
  const RouteResult({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
    required this.source,
  });

  final double distanceMeters;
  final int durationSeconds;
  final List<List<double>> geometry; // [[lon, lat], ...]
  final String source;

  String get distanceFormatted {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationFormatted {
    if (durationSeconds < 60) {
      return '${durationSeconds}s';
    }
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final secondsStr = seconds > 0 ? ' ${seconds}s' : '';
    return '$minutes min$secondsStr';
  }
}
