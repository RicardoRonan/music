import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_audio_scanner.dart';
import '../data/io_platform.dart';
import '../data/web_audio_storage.dart';
import 'library_scan_progress_provider.dart';
import '../data/local_audio_classification.dart';
import '../data/local_audio_extensions.dart';
import '../data/local_library_dedupe.dart';
import '../data/local_music_store.dart';
import '../data/local_song_factory.dart';
import '../models/enriched_track_metadata.dart';
import '../models/song.dart';
import 'preferences_notifier.dart';
import 'shared_preferences_provider.dart';

final localLibraryProvider = NotifierProvider<LocalLibraryNotifier, List<Song>>(
    LocalLibraryNotifier.new);

class LocalLibraryNotifier extends Notifier<List<Song>> {
  LocalMusicStore get _store =>
      LocalMusicStore(ref.read(sharedPreferencesProvider));

  @override
  List<Song> build() {
    final loaded = _store.loadSongs();
    final afterDedupe = dedupePersistedLibrary(loaded);
    final excludeShort =
        ref.read(preferencesNotifierProvider).excludeAudioUnder30Seconds;
    final afterShort = _stripKnownShortTracks(afterDedupe, excludeShort);
    if (afterDedupe.length != loaded.length ||
        afterShort.length != afterDedupe.length) {
      Future<void>.delayed(Duration.zero, () async {
        await _store.saveSongs(afterShort);
      });
    }
    if (kIsWeb && afterShort.isNotEmpty) {
      unawaited(() async {
        await WebAudioStorage.instance.init();
        await WebAudioStorage.instance.warmUrls(
          afterShort
              .map((s) => s.localAudioUri)
              .whereType<String>()
              .where((u) => u.trim().isNotEmpty),
        );
      }());
    }
    return afterShort;
  }

  List<Song> _stripKnownShortTracks(
    List<Song> songs,
    bool excludeUnder30Seconds,
  ) =>
      songs
          .where(
            (s) => !LocalAudioClassification.shouldOmitShort(
              s.duration,
              excludeUnder30Seconds: excludeUnder30Seconds,
            ),
          )
          .toList();

  /// Returns number of tracks added (after dedupe).
  Future<int> importAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: kLocalAudioPickerExtensions,
    );
    if (result == null || result.files.isEmpty) return 0;

    final existingKeys = <String>{
      for (final s in state) songPlaybackDedupeKey(s),
    };
    final merged = List<Song>.from(state);
    var added = 0;

    for (final f in result.files) {
      final name = f.name;
      final path = f.path;
      final bytes = f.bytes;
      final uri = await materializePickedFile(
        path: path,
        bytes: bytes,
        suggestedName: name,
      );
      if (uri == null) {
        continue;
      }

      final probePath = (path != null && path.isNotEmpty) ? path : name;
      final duration =
          await probeAudioDuration(uri) ?? Duration.zero;

      final userPrefs = ref.read(preferencesNotifierProvider);
      if (LocalAudioClassification.shouldOmitShort(
        duration,
        excludeUnder30Seconds: userPrefs.excludeAudioUnder30Seconds,
      )) {
        continue;
      }

      final prefs = userPrefs;
      final genre = LocalAudioClassification.genreForLocalDuration(
        duration,
        tagLongAsAudiobook: prefs.tagLongLocalAudioAsAudiobook,
      );
      final song = LocalSongFactory.fromResolvedUri(
        sourceUri: uri,
        displayPathOrName: probePath,
        duration: duration,
        genreTag: genre,
      );
      final dk = songPlaybackDedupeKey(song);
      if (existingKeys.contains(dk)) {
        continue;
      }

      merged.removeWhere((s) => songPlaybackDedupeKey(s) == dk);
      merged.add(song);
      existingKeys.add(dk);
      added++;
    }

    final clean = dedupePersistedLibrary(merged);
    await _store.saveSongs(clean);
    state = clean;
    return added;
  }

  bool get _isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Crawls accessible folders for known audio extensions. On Windows, scans
  /// the user Music folder (including OneDrive). Skips probing duration for
  /// speed; length shows as 0:00 until playback resolves real duration.
  ///
  /// Returns added count, `0` if nothing new, or `-1` if Android read
  /// permission was denied.
  Future<int> scanDeviceForMusic() async {
    if (kIsWeb) return importAudioFiles();
    final progress = ref.read(libraryScanProgressProvider.notifier);
    try {
      if (!await ensureDeviceScanPermissions()) return -1;

      progress.setCollecting(0);
      final paths = _isWindowsDesktop
          ? await collectWindowsMusicFolderPaths(
              maxFiles: 10000,
              onProgress: (n) {
                if (n == 1 || n % 250 == 0) {
                  progress.setCollecting(n);
                }
              },
            )
          : await collectDeviceAudioPaths(
              maxFiles: 10000,
              onProgress: (n) {
                if (n == 1 || n % 250 == 0) {
                  progress.setCollecting(n);
                }
              },
            );

      if (paths.isEmpty && _isWindowsDesktop) {
        return pickMusicFolderAndScan();
      }
      if (paths.isEmpty) return 0;

      return _importScannedPaths(paths);
    } finally {
      progress.clear();
    }
  }

  /// Opens a folder picker (Windows/desktop) and scans that tree for audio.
  Future<int> pickMusicFolderAndScan() async {
    if (kIsWeb) return importAudioFiles();

    String? initialDirectory;
    if (_isWindowsDesktop) {
      final folders = await existingWindowsMusicFolderPaths();
      if (folders.isNotEmpty) initialDirectory = folders.first;
    }

    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select your Music folder',
      initialDirectory: initialDirectory,
    );
    if (picked == null || picked.trim().isEmpty) return 0;

    final progress = ref.read(libraryScanProgressProvider.notifier);
    try {
      progress.setCollecting(0);
      final paths = await collectAudioPathsInFolder(
        picked,
        maxFiles: 10000,
        onProgress: (n) {
          if (n == 1 || n % 250 == 0) {
            progress.setCollecting(n);
          }
        },
      );
      if (paths.isEmpty) return 0;
      return _importScannedPaths(paths);
    } finally {
      progress.clear();
    }
  }

  Future<int> _importScannedPaths(List<String> paths) async {
    if (paths.isEmpty) return 0;

    final progress = ref.read(libraryScanProgressProvider.notifier);
    final existingKeys = <String>{
      for (final s in state) songPlaybackDedupeKey(s),
    };
    final merged = List<Song>.from(state);
    var added = 0;
    final total = paths.length;
    final importReportStep = total < 200 ? 1 : (total ~/ 100).clamp(1, 500);

    final prefs = ref.read(preferencesNotifierProvider);
    for (var i = 0; i < paths.length; i++) {
      final filePath = paths[i];
      final uri = resolvedFileUriForPlayback(filePath);
      final genre = LocalAudioClassification.genreForLocalDuration(
        Duration.zero,
        tagLongAsAudiobook: prefs.tagLongLocalAudioAsAudiobook,
      );
      final song = LocalSongFactory.fromResolvedUri(
        sourceUri: uri,
        displayPathOrName: filePath,
        genreTag: genre,
      );
      final dk = songPlaybackDedupeKey(song);
      if (!existingKeys.contains(dk)) {
        merged.add(song);
        existingKeys.add(dk);
        added++;
      }

      if (i % importReportStep == 0 || i == paths.length - 1) {
        progress.setImporting(i + 1, total);
      }

      if (added % 500 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    if (added == 0) return 0;
    final clean = dedupePersistedLibrary(merged);
    await _store.saveSongs(clean);
    state = clean;
    return added;
  }

  /// Persists decoder length for local files when stored metadata was missing
  /// or a short placeholder (e.g. after device scan). Returns the patched [Song]
  /// when the library entry was updated.
  Future<Song?> applyPlaybackResolvedDuration(
    String songId,
    Duration resolved,
  ) async {
    if (resolved <= const Duration(seconds: 2)) return null;
    final idx = state.indexWhere((s) => s.id == songId);
    if (idx == -1) return null;
    final s = state[idx];
    if (s.localAudioUri == null || s.localAudioUri!.trim().isEmpty) {
      return null;
    }

    final userPrefs0 = ref.read(preferencesNotifierProvider);
    if (LocalAudioClassification.shouldOmitShort(
      resolved,
      excludeUnder30Seconds: userPrefs0.excludeAudioUnder30Seconds,
    )) {
      await removeSong(songId);
      return null;
    }

    final prefs = userPrefs0;
    final sm = s.duration.inMilliseconds;
    final rm = resolved.inMilliseconds;
    if (sm > 2000 && rm <= sm + 500) return null;
    if (rm < sm - 2000) return null;

    var patched = s.withDuration(resolved);
    final tag = LocalAudioClassification.genreForLocalDuration(
      resolved,
      tagLongAsAudiobook: prefs.tagLongLocalAudioAsAudiobook,
    );
    if ((patched.genreTag ?? '') != tag) {
      patched = patched.withGenreTag(tag);
    }
    final next = List<Song>.from(state);
    next[idx] = patched;
    final clean = dedupePersistedLibrary(next);
    await _store.saveSongs(clean);
    state = clean;
    return patched;
  }

  /// Writes AcoustID / MusicBrainz fields onto a local library row (same [Song.id]).
  Future<void> applyEnrichedMetadataIfChanged(
    String songId,
    EnrichedTrackMetadata meta,
  ) async {
    if (kIsWeb) return;
    final idx = state.indexWhere((s) => s.id == songId);
    if (idx == -1) return;
    final before = state[idx];
    if (!before.isLocalFile) return;
    final updated = before.withEnrichedLocalMetadata(meta);
    if (before.title == updated.title &&
        before.artistName == updated.artistName &&
        before.albumTitle == updated.albumTitle &&
        (before.artworkUrl ?? '') == (updated.artworkUrl ?? '') &&
        (before.spotifyUrl ?? '') == (updated.spotifyUrl ?? '')) {
      return;
    }
    final next = [...state];
    next[idx] = updated;
    final clean = dedupePersistedLibrary(next);
    await _store.saveSongs(clean);
    state = clean;
  }

  Future<void> removeSong(String id) async {
    if (kIsWeb) {
      final idx = state.indexWhere((s) => s.id == id);
      if (idx != -1) {
        final uri = state[idx].localAudioUri;
        if (uri != null) {
          final storageId = webAudioStorageId(uri);
          if (storageId != null) {
            await WebAudioStorage.instance.delete(storageId);
          }
        }
      }
    }
    final next = state.where((s) => s.id != id).toList();
    final clean = dedupePersistedLibrary(next);
    await _store.saveSongs(clean);
    state = clean;
  }

  Future<void> clearLibrary() async {
    if (kIsWeb) {
      await WebAudioStorage.instance.clear();
    }
    await _store.saveSongs([]);
    state = [];
  }

  /// Probes local files with unknown/zero duration so lists can show lengths
  /// before playback (capped per call to avoid blocking the UI thread).
  Future<void> probeMissingDurationsInBackground(
    Iterable<Song> candidates, {
    int maxProbes = 80,
  }) async {
    final wantIds = <String>{};
    for (final c in candidates) {
      if (c.duration > const Duration(seconds: 2)) continue;
      if (!c.isLocalFile) continue;
      wantIds.add(c.id);
    }
    if (wantIds.isEmpty) return;
    var done = 0;
    for (final id in wantIds) {
      if (done >= maxProbes) break;
      final idx = state.indexWhere((s) => s.id == id);
      if (idx == -1) continue;
      final s = state[idx];
      final uri = s.localAudioUri?.trim();
      if (uri == null || uri.isEmpty) continue;
      final d = await probeAudioDuration(uri);
      if (d == null || d <= const Duration(seconds: 2)) continue;
      await applyPlaybackResolvedDuration(id, d);
      done++;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  /// Refresh Audiobook tags from current prefs and drop known short tracks.
  Future<void> reapplyClassificationFromPreferences() async {
    final prefs = ref.read(preferencesNotifierProvider);
    final next = <Song>[];
    for (final s in state) {
      if (LocalAudioClassification.shouldOmitShort(
        s.duration,
        excludeUnder30Seconds: prefs.excludeAudioUnder30Seconds,
      )) {
        continue;
      }
      final tag = LocalAudioClassification.genreForLocalDuration(
        s.duration,
        tagLongAsAudiobook: prefs.tagLongLocalAudioAsAudiobook,
      );
      if ((s.genreTag ?? '') != tag) {
        next.add(s.withGenreTag(tag));
      } else {
        next.add(s);
      }
    }
    final clean = dedupePersistedLibrary(next);
    await _store.saveSongs(clean);
    state = clean;
  }
}
