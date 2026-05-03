import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../home/widgets/song_row_tile.dart';
import '../../player/data/music_catalog.dart';
import '../../player/models/album.dart';
import '../../player/models/artist.dart';
import '../../player/models/playlist.dart';
import '../../player/models/song.dart';
import '../../player/providers/app_providers.dart';
import '../../player/providers/player_notifier.dart';
import '../../player/providers/preferences_notifier.dart';

enum SearchFilter { songs, artists, albums, playlists, folders, files }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _searchFocus = FocusNode();
  GoRouter? _router;
  String? _lastMatchedLocation;
  SearchFilter _filter = SearchFilter.songs;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (!identical(_router, router)) {
      _router?.routerDelegate.removeListener(_onRouterChanged);
      _router = router;
      _router!.routerDelegate.addListener(_onRouterChanged);
      _onRouterChanged();
    }
  }

  void _onRouterChanged() {
    if (!mounted) return;
    final loc = GoRouter.of(context).state.matchedLocation;
    if (loc == '/search' && _lastMatchedLocation != '/search') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
    _lastMatchedLocation = loc;
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouterChanged);
    _searchFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(String raw) {
    setState(() => _query = raw.trim());
    final q = raw.trim();
    if (q.isNotEmpty) {
      ref.read(preferencesNotifierProvider.notifier).rememberSearch(q);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(musicCatalogProvider);
    final prefs = ref.watch(preferencesNotifierProvider);
    final theme = Theme.of(context);

    final songs = _query.isEmpty ? <Song>[] : catalog.searchSongs(_query);
    final artists = _query.isEmpty ? <Artist>[] : catalog.searchArtists(_query);
    final albums = _query.isEmpty ? <Album>[] : catalog.searchAlbums(_query);
    final playlists =
        _query.isEmpty ? <Playlist>[] : catalog.searchPlaylists(_query);
    final folders = _query.isEmpty
        ? <MapEntry<String, List<Song>>>[]
        : catalog.deviceSongsByFolder.entries
            .where((e) => e.key.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    final files = _query.isEmpty
        ? <Song>[]
        : catalog.allSongs.where((song) {
            final path = song.localAudioUri ?? '';
            return path.toLowerCase().contains(_query.toLowerCase());
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.screenHorizontal.copyWith(top: AppSpacing.md),
          child: TextField(
            controller: _controller,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            onSubmitted: _runSearch,
            onChanged: _runSearch,
            decoration: InputDecoration(
              hintText: 'Songs, artists, albums, folders, files',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty || _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: SearchFilter.values.map((f) {
              final selected = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: FilterChip(
                  label: Text(_label(f)),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? _EmptySearch(
                  recent: prefs.recentSearchQueries,
                  onPick: (q) {
                    _controller.text = q;
                    _runSearch(q);
                  },
                )
              : _ResultsList(
                  filter: _filter,
                  songs: songs,
                  artists: artists,
                  albums: albums,
                  playlists: playlists,
                  folders: folders,
                  files: files,
                  theme: theme,
                ),
        ),
      ],
    );
  }

  static String _label(SearchFilter f) {
    switch (f) {
      case SearchFilter.songs:
        return 'Songs';
      case SearchFilter.artists:
        return 'Artists';
      case SearchFilter.albums:
        return 'Albums';
      case SearchFilter.playlists:
        return 'Playlists';
      case SearchFilter.folders:
        return 'Folders';
      case SearchFilter.files:
        return 'Files';
    }
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.recent, required this.onPick});

  final List<String> recent;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (recent.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Search the catalog — try “Nova”, “focus”, or “stride”.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      );
    }
    return ListView(
      padding: AppSpacing.screenHorizontal,
      children: [
        Text(
          'Recent searches',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...recent.map(
          (q) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history_rounded),
            title: Text(q),
            onTap: () => onPick(q),
          ),
        ),
      ],
    );
  }
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList({
    required this.filter,
    required this.songs,
    required this.artists,
    required this.albums,
    required this.playlists,
    required this.folders,
    required this.files,
    required this.theme,
  });

  final SearchFilter filter;
  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final List<MapEntry<String, List<Song>>> folders;
  final List<Song> files;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (filter) {
      case SearchFilter.songs:
        if (songs.isEmpty) return _noHits(theme);
        return ListView.separated(
          itemCount: songs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
          itemBuilder: (context, i) {
            final s = songs[i];
            return SongRowTile(
              song: s,
              onSwipeLeftEnqueue: () => ref
                  .read(playerNotifierProvider.notifier)
                  .playNext(s),
              onTap: () => ref
                  .read(playerNotifierProvider.notifier)
                  .playFromCollection(songs, i),
            );
          },
        );
      case SearchFilter.artists:
        if (artists.isEmpty) return _noHits(theme);
        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, i) {
            final a = artists[i];
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                ),
              ),
              title: Text(a.name),
              subtitle: Text(a.bio ?? ''),
            );
          },
        );
      case SearchFilter.albums:
        if (albums.isEmpty) return _noHits(theme);
        return ListView.builder(
          itemCount: albums.length,
          itemBuilder: (context, i) {
            final a = albums[i];
            return ListTile(
              title: Text(a.title),
              subtitle: Text('Album · ${a.year ?? ''}'),
            );
          },
        );
      case SearchFilter.playlists:
        if (playlists.isEmpty) return _noHits(theme);
        return ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (context, i) {
            final p = playlists[i];
            return ListTile(
              title: Text(p.title),
              subtitle: Text(p.description),
              onTap: () => context.push('/playlist/${p.id}'),
            );
          },
        );
      case SearchFilter.folders:
        if (folders.isEmpty) return _noHits(theme);
        return ListView.builder(
          itemCount: folders.length,
          itemBuilder: (context, i) {
            final f = folders[i];
            return ListTile(
              leading: const Icon(Icons.folder_rounded),
              title: Text(MusicCatalog.folderDisplayTitle(f.key)),
              subtitle: Text('${f.value.length} songs'),
            );
          },
        );
      case SearchFilter.files:
        if (files.isEmpty) return _noHits(theme);
        return ListView.separated(
          itemCount: files.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
          itemBuilder: (context, i) {
            final s = files[i];
            return SongRowTile(
              song: s,
              onSwipeLeftEnqueue: () => ref
                  .read(playerNotifierProvider.notifier)
                  .playNext(s),
              onTap: () => ref
                  .read(playerNotifierProvider.notifier)
                  .playFromCollection(files, i),
            );
          },
        );
    }
  }

  static Widget _noHits(ThemeData theme) {
    return Center(
      child: Text(
        'No matches in this category.',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}
