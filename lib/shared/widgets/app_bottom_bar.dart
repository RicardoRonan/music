import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music_rounded),
      label: 'Library',
    ),
    NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder_rounded),
      label: 'Folders',
    ),
    NavigationDestination(
      icon: Icon(Icons.queue_music_outlined),
      selectedIcon: Icon(Icons.queue_music_rounded),
      label: 'Playlists',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_rounded),
      selectedIcon: Icon(Icons.search_rounded),
      label: 'Search',
    ),
  ];

  static const _paths = [
    '/library',
    '/folders',
    '/playlists',
    '/search',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, _destinations.length - 1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _destinations,
        onDestinationSelected: (index) => context.go(_paths[index]),
      ),
    );
  }
}
