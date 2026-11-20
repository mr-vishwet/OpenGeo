import 'package:flutter_test/flutter_test.dart';
import 'package:opengeo_flutter/main.dart';
import 'package:opengeo_flutter/models/map_mode.dart';
import 'package:opengeo_flutter/screens/ai_assistant_screen.dart';
import 'package:opengeo_flutter/screens/custom_world_screen.dart';
import 'package:opengeo_flutter/screens/explore_screen.dart';
import 'package:opengeo_flutter/screens/game_mode_screen.dart';
import 'package:opengeo_flutter/screens/route_screen.dart';
import 'package:opengeo_flutter/screens/saved_screen.dart';

void main() {
  test('mapModeFromName resolves the reference mode names', () {
    expect(mapModeFromName('realtime'), MapMode.realtime);
    expect(mapModeFromName('essential'), MapMode.essential);
    expect(mapModeFromName('intelligence'), MapMode.intelligence);
    expect(mapModeFromName('spatial'), MapMode.spatial);
    expect(mapModeFromName('custom'), MapMode.custom);
  });

  test('mapModeFromName rejects unknown, empty and null values', () {
    expect(mapModeFromName(null), isNull);
    expect(mapModeFromName(''), isNull);
    expect(mapModeFromName('satellite'), isNull);
    expect(mapModeFromName('Realtime'), isNull);
  });

  test('screenFromName resolves the documented deep links', () {
    expect(screenFromName('ai'), isA<AiAssistantScreen>());
    expect(screenFromName('game'), isA<GameModeScreen>());
    expect(screenFromName('custom-world'), isA<CustomWorldScreen>());
    expect(screenFromName('route'), isA<RouteScreen>());
    expect(screenFromName('explore'), isA<ExploreScreen>());
    expect(screenFromName('saved'), isA<SavedScreen>());
    expect(screenFromName(null), isNull);
    expect(screenFromName('nope'), isNull);
  });
}
