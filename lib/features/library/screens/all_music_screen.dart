import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../home/widgets/song_row_tile.dart';
import '../../player/models/song.dart';
import '../../player/providers/app_providers.dart';
import '../../player/providers/player_notifier.dart';
import '../../../shared/widgets/app_bottom_chrome.dart';

enum AllMusicSort {
  title,
  artist,
  genre,
  duration,
}

extension on AllMusicSort {
  String get label => switch (this) {
        AllMusicSort.title => 'Title',
        AllMusicSort.artist => 'Artist',
        AllMusicSort.genre => 'Genre',
        AllMusicSort.duration => 'Duration',
      };
}

String _genreLabel(Song s) {
  final g = s.genreTag?.trim();
  return (g != null && g.isNotEmpty) ? g : 'Unknown';
}

class AllMusicScreen extends ConsumerStatefulWidget {
  const AllMusicScreen({super.key});

  @override
  ConsumerState<AllMusicScreen> createState() => _AllMusicScreenState();
}

class _AllMusicScreenState extends ConsumerState<AllMusicScreen> {
  AllMusicSort _sort = AllMusicSort.title;
  String? _genreFilter;
  var _scheduledProbe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledProbe) return;
      _scheduledProbe = true;
      final all = ref.read(musicCatalogProvider).allSongs;
      unawaited(
        ref.read(localLibraryProvider.notifier).probeMissingDurationsInBackground(all),
      );
    });
  }

  List<Song> _filteredSorted(List<Song> all) {
    var list = List<Song>.from(all);
    if (_genreFilter != null) {
      list = list
          .where((s) => _genreLabel(s) == _genreFilter)
          .toList();
    }
    int cmpTitle(Song a, Song b) =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase());
    int cmpArtist(Song a, Song b) =>
        a.artistName.toLowerCase().compareTo(b.artistName.toLowerCase());
    int cmpGenre(Song a, Song b) =>
        _genreLabel(a).toLowerCase().compareTo(_genreLabel(b).toLowerCase());
    int cmpDuration(Song a, Song b) =>
        a.duration.compareTo(b.duration);

    switch (_sort) {
      case AllMusicSort.title:
        list.sort(cmpTitle);
      case AllMusicSort.artist:
        list.sort((a, b) {
          final c = cmpArtist(a, b);
          return c != 0 ? c : cmpTitle(a, b);
        });
      case AllMusicSort.genre:
        list.sort((a, b) {
          final c = cmpGenre(a, b);
          return c != 0 ? c : cmpTitle(a, b);
        });
      case AllMusicSort.duration:
        list.sort((a, b) {
          final c = cmpDuration(a, b);
          return c != 0 ? c : cmpTitle(a, b);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = ref.watch(musicCatalogProvider);
    final genres = catalog.allGenreLabelsSorted();
    final songs = _filteredSorted(catalog.allSongs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All music'),
        actions: [
          PopupMenuButton<AllMusicSort>(
            tooltip: 'Sort by',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (ctx) => [
              for (final o in AllMusicSort.values)
                PopupMenuItem(
                  value: o,
                  child: Row(
                    children: [
                      if (o == _sort) const Icon(Icons.check_rounded, size: 20),
                      if (o == _sort) const SizedBox(width: 8),
                      if (o != _sort) const SizedBox(width: 28),
                      Text(o.label),
                    ],
                  ),
                ),
            ],
            icon: const Icon(Icons.sort_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomChrome(selectedIndex: 0),
      body: ListView(
        padding: AppSpacing.screenHorizontal.copyWith(
          top: AppSpacing.sm,
          bottom: AppSpacing.xxl,
        ),
        children: [
          Text(
            'Genre',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: const Text('All genres'),
                selected: _genreFilter == null,
                onSelected: (_) => setState(() => _genreFilter = null),
              ),
              for (final g in genres)
                FilterChip(
                  label: Text(g),
                  selected: _genreFilter == g,
                  onSelected: (_) =>
                      setState(() => _genreFilter = _genreFilter == g ? null : g),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${songs.length} track${songs.length == 1 ? '' : 's'} · ${_sort.label}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...songs.map(
            (s) => SongRowTile(
              song: s,
              onSwipeLeftEnqueue: () => ref
                  .read(playerNotifierProvider.notifier)
                  .playNext(s),
              onTap: () => ref
                  .read(playerNotifierProvider.notifier)
                  .playFromCollection(
                    songs,
                    songs.indexWhere((x) => x.id == s.id),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

