import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/data/musicbrainz_repository.dart';
import '../../player/models/discovered_recording.dart';
import '../../player/providers/music_brainz_providers.dart';

@immutable
class DiscoverFeedState {
  const DiscoverFeedState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<DiscoveredRecording> items;
  final bool loading;
  final bool loadingMore;

  /// False when pagination exhausts MusicBrainz results for rotated tags.
  final bool hasMore;
  final String? error;

  DiscoverFeedState copyWith({
    List<DiscoveredRecording>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) =>
      DiscoverFeedState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

class DiscoverFeedNotifier extends Notifier<DiscoverFeedState> {
  static const _pageSize = 20;

  int _apiOffset = 0;
  int _tagIndex = 0;

  MusicBrainzRepository get _repo => ref.read(musicBrainzRepositoryProvider);

  String _currentTag() => MusicBrainzRepository
      .discoverTagSlugs[_tagIndex % MusicBrainzRepository.discoverTagSlugs.length];

  @override
  DiscoverFeedState build() => const DiscoverFeedState();

  /// First page (idempotent unless [forceReset] clears and refetches).
  Future<void> loadInitial({bool forceReset = false}) async {
    if (state.loading && !forceReset) return;
    if (!forceReset && state.items.isNotEmpty) return;

    if (forceReset) {
      _apiOffset = 0;
      _tagIndex = 0;
      state = const DiscoverFeedState(
        items: [],
        loading: true,
        loadingMore: false,
        hasMore: true,
      );
    } else {
      state = state.copyWith(loading: true, clearError: true);
    }

    try {
      final batch = await _fetchFirstNonEmptyBatch();
      state = DiscoverFeedState(
        items: batch,
        loading: false,
        loadingMore: false,
        hasMore: batch.isNotEmpty,
        error: batch.isEmpty
            ? 'Nothing turned up yet. Pull to retry in a moment.'
            : null,
      );
      _apiOffset = batch.length;
    } catch (e, st) {
      debugPrint('DiscoverFeedNotifier: $e\n$st');
      state = state.copyWith(
        loading: false,
        error: 'Could not reach MusicBrainz. Check your connection.',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.loading || state.items.isEmpty) {
      return;
    }

    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final batch = await _repo.fetchDiscoverFeed(
        tagSlug: _currentTag(),
        offset: _apiOffset,
        limit: _pageSize,
      );

      if (batch.isEmpty) {
        _tagIndex++;
        _apiOffset = 0;
        final rotated = await _repo.fetchDiscoverFeed(
          tagSlug: _currentTag(),
          offset: 0,
          limit: _pageSize,
        );
        if (rotated.isEmpty) {
          state = state.copyWith(loadingMore: false, hasMore: false);
          return;
        }
        final merged = [...state.items, ...rotated];
        state = state.copyWith(
          items: merged,
          loadingMore: false,
          hasMore: true,
          clearError: true,
        );
        _apiOffset = rotated.length;
        return;
      }

      final merged = [...state.items, ...batch];
      state = state.copyWith(
        items: merged,
        loadingMore: false,
        hasMore: true,
        clearError: true,
      );
      _apiOffset += batch.length;
    } catch (e, st) {
      debugPrint('DiscoverFeedNotifier loadMore: $e\n$st');
      state = state.copyWith(
        loadingMore: false,
        error: 'Could not load more. Try scrolling again.',
      );
    }
  }

  Future<void> refresh() => loadInitial(forceReset: true);

  Future<List<DiscoveredRecording>> _fetchFirstNonEmptyBatch() async {
    for (var attempt = 0;
        attempt < MusicBrainzRepository.discoverTagSlugs.length;
        attempt++) {
      final batch = await _repo.fetchDiscoverFeed(
        tagSlug: _currentTag(),
        offset: 0,
        limit: _pageSize,
      );
      if (batch.isNotEmpty) {
        return batch;
      }
      _tagIndex++;
    }
    return const [];
  }
}

final discoverFeedNotifierProvider =
    NotifierProvider<DiscoverFeedNotifier, DiscoverFeedState>(
  DiscoverFeedNotifier.new,
);
