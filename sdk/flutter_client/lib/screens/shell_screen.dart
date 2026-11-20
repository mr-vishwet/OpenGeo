import 'package:flutter/material.dart';

import '../models/map_mode.dart';
import '../widgets/slippy_map.dart';
import 'explore_screen.dart';
import 'map_home_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

/// The four-tab app shell from the reference: Map, Explore, Saved, Profile.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.mode, this.initialStyle});

  final MapMode mode;
  final MapStyle? initialStyle;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          MapHomeScreen(mode: widget.mode, initialStyle: widget.initialStyle),
          ExploreScreen(
            mode: widget.mode,
            onViewOnMap: () => setState(() => _index = 0),
          ),
          const SavedScreen(),
          ProfileScreen(mode: widget.mode),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
