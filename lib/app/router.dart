import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/folders/screens/folders_screen.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/library/screens/all_music_screen.dart';
import '../features/library/screens/album_detail_screen.dart';
import '../features/library/screens/library_folder_screen.dart';
import '../features/library/screens/library_screen.dart';
import '../features/library/screens/playlist_detail_screen.dart';
import '../features/player/screens/now_playing_screen.dart';
import '../features/player/screens/queue_screen.dart';
import '../features/player/widgets/root_mini_player_overlay.dart';
import '../features/playlists/screens/playlists_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/player/providers/preferences_notifier.dart';
import '../theme/windows_classic_theme_extension.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

CustomTransitionPage<void> _fadeSlidePage(
  GoRouterState state,
  Widget child, {
  Offset begin = const Offset(0.04, 0),
  bool attachRootMiniPlayer = false,
}) {
  final pageChild = attachRootMiniPlayer
      ? RootMiniPlayerOverlay(child: child)
      : child;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: pageChild,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (context.isWindowsClassicTheme) {
        return child;
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/library',
    redirect: (context, state) {
      if (kIsWeb) return null;
      final prefs = ref.read(preferencesNotifierProvider);
      final loc = state.matchedLocation;
      if (!prefs.welcomeOnboardingCompleted) {
        if (loc != '/welcome') return '/welcome';
      } else if (loc == '/welcome') {
        return '/library';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(
          state,
          const WelcomeScreen(),
          begin: const Offset(0, 0.04),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) => _fadeSlidePage(
                  state,
                  const LibraryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/folders',
                pageBuilder: (context, state) => _fadeSlidePage(
                  state,
                  const FoldersScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/playlists',
                pageBuilder: (context, state) => _fadeSlidePage(
                  state,
                  const PlaylistsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => _fadeSlidePage(
                  state,
                  const SearchScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(
          state,
          const SettingsScreen(),
          begin: const Offset(0, 0.03),
        ),
      ),
      GoRoute(
        path: '/playlist/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadeSlidePage(
            state,
            PlaylistDetailScreen(playlistId: id),
          );
        },
      ),
      GoRoute(
        path: '/album/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadeSlidePage(
            state,
            AlbumDetailScreen(albumId: id),
          );
        },
      ),
      GoRoute(
        path: '/now-playing',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _fadeSlidePage(state, const NowPlayingScreen()),
      ),
      GoRoute(
        path: '/queue',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(
          state,
          const QueueScreen(),
        ),
      ),
      GoRoute(
        path: '/library/all-music',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlidePage(
          state,
          const AllMusicScreen(),
        ),
      ),
      GoRoute(
        path: '/library/folder',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final args = state.extra as LibraryFolderArgs?;
          if (args == null) {
            return _fadeSlidePage(
              state,
              const Scaffold(
                body: Center(child: Text('No folder selected.')),
              ),
              attachRootMiniPlayer: true,
            );
          }
          return _fadeSlidePage(
            state,
            LibraryFolderScreen(args: args),
          );
        },
      ),
    ],
  );
});
