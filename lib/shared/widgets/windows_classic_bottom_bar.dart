import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/windows_classic_theme_extension.dart';

/// Win95-style tab bar — replaces Material 3 [NavigationBar] (pill indicator).
class WindowsClassicBottomBar extends StatelessWidget {
  const WindowsClassicBottomBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _items = [
    (label: 'Library', icon: Icons.library_music, path: '/library'),
    (label: 'Folders', icon: Icons.folder, path: '/folders'),
    (label: 'Playlists', icon: Icons.queue_music, path: '/playlists'),
    (label: 'Search', icon: Icons.search, path: '/search'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.winColors;
    final idx = selectedIndex.clamp(0, _items.length - 1);

    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: _NavTab(
                label: _items[i].label,
                icon: _items[i].icon,
                selected: i == idx,
                colors: c,
                isFirst: i == 0,
                isLast: i == _items.length - 1,
                onTap: () => context.go(_items[i].path),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.colors,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final WindowsClassicColors colors;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: selected ? 46 : 44,
        margin: EdgeInsets.only(
          top: selected ? 0 : 2,
          left: isFirst ? 2 : 0,
          right: isLast ? 2 : 0,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.chrome,
          border: Border(
            top: BorderSide(color: colors.highlight, width: 2),
            left: BorderSide(color: colors.highlight, width: 2),
            right: BorderSide(color: colors.shadow, width: 2),
            bottom: BorderSide(
              color: selected ? colors.chrome : colors.shadow,
              width: selected ? 1 : 2,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? colors.accent : colors.onSurface,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'Tahoma',
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? colors.accent : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
