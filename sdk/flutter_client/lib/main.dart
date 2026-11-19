import 'package:flutter/material.dart';

void main() {
  runApp(const OpenGeoApp());
}

/// OpenGeo Flutter client — scaffold for the MapLibre-powered map client.
///
/// This is a skeleton app. The MapLibre GL map view needs to be wired up using
/// the `maplibre_gl` package (already added to pubspec.yaml). See
/// https://pub.dev/packages/maplibre_gl for the API reference.
class OpenGeoApp extends StatelessWidget {
  const OpenGeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenGeo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}

/// Map page — placeholder for the MapLibre GL map.
///
/// To activate the map, add a `MapLibreMap` widget from the `maplibre_gl`
/// package and point it at the OpenGeo API (http://localhost:8080).
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenGeo — Pune'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.map, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text(
              'OpenGeo Map Client',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'MapLibre GL integration pending — '
              'add MapLibreMap widget from package:maplibre_gl',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pune centre: 18.5204° N, 73.8567° E',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Centre on Pune (pending MapLibre integration)',
        child: const Icon(Icons.my_location),
        onPressed: () {},
      ),
    );
  }
}
