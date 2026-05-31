import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../../core/utils/track_title_sanitize.dart';
import '../models/discovered_recording.dart';
import '../models/enriched_track_metadata.dart';

/// MusicBrainz search + Cover Art Archive artwork URLs.
///
/// Respects [MusicBrainz API etiquette](https://musicbrainz.org/doc/MusicBrainz_API#Etiquette)
/// (User-Agent, ~1 req/s pacing).
class MusicBrainzRepository {
  MusicBrainzRepository({required http.Client httpClient}) : _client = httpClient;

  final http.Client _client;

  static const Duration _httpTimeout = Duration(seconds: 25);

  static DateTime? _nextAllowedUtc;

  static const _userAgent =
      'flutter_starter/1.0.0 ( local music player; contact via project maintainer )';

  static final _genericAlbumLower = {
    'imports',
    'imported audio',
    'local',
    'unknown album',
    'unknown title',
    'on this device',
    'unknown',
  };

  static bool isGenericAlbumTitle(String albumTitle) =>
      _genericAlbumLower.contains(albumTitle.trim().toLowerCase());

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
  }) =>
      _client.get(uri, headers: headers).timeout(_httpTimeout);

  Future<void> _pace() async {
    final now = DateTime.now().toUtc();
    if (_nextAllowedUtc != null && now.isBefore(_nextAllowedUtc!)) {
      await Future<void>.delayed(_nextAllowedUtc!.difference(now));
    }
    _nextAllowedUtc =
        DateTime.now().toUtc().add(const Duration(milliseconds: 1100));
  }

  /// Best-effort lookup from filename / folder hints on a local import.
  ///
  /// Runs several Lucene strategies (tag artist, folder-as-album, folder-as-artist
  /// when tags are unknown, folder containing tag artist, recording-only) and only
  /// accepts a hit when a linked release lists this track (by recording id or
  /// normalized title). Tries the next strategy when a search returns no usable match.
  Future<EnrichedTrackMetadata?> lookupFromLocalHints({
    required String title,
    required String artistName,
    required String albumTitle,
    int? expectedAlbumTrackCount,
  }) async {
    final cleanTitle = sanitizeTrackTitleForSearch(title);
    final cleanArtist = sanitizeTrackTitleForSearch(artistName);
    final cleanAlbum = sanitizeTrackTitleForSearch(albumTitle);
    final queries = _buildSearchStrategies(
      title: cleanTitle,
      artistName: cleanArtist,
      albumTitle: cleanAlbum,
    );
    if (queries.isEmpty) return null;

    for (final query in queries) {
      await _pace();
      final list = await _fetchRecordingSearch(query);
      if (list == null || list.isEmpty) continue;

      final sorted = [...list]
        ..sort(
          (a, b) => ((b['score'] as num?)?.toInt() ?? 0)
              .compareTo((a['score'] as num?)?.toInt() ?? 0),
        );

      for (final rec in sorted) {
        if (rec is! Map<String, dynamic>) continue;
        final enriched = _enrichIfReleaseContainsTrack(
          recording: rec,
          localTitle: cleanTitle,
          localArtist: cleanArtist,
          localAlbum: cleanAlbum,
          expectedAlbumTrackCount: expectedAlbumTrackCount,
        );
        if (enriched != null) return enriched;
      }
    }
    return null;
  }

  /// Ordered Lucene queries; duplicates removed.
  List<String> _buildSearchStrategies({
    required String title,
    required String artistName,
    required String albumTitle,
  }) {
    final tq = _luceneQuotedPhrase(title);
    if (tq == null) return [];

    final artist = artistName.trim();
    final tagArtistUseful = artist.isNotEmpty &&
        artist.toLowerCase() != 'unknown artist';
    final arq = tagArtistUseful ? _luceneQuotedPhrase(artist) : null;

    final folder = albumTitle.trim();
    final folderUseful = folder.isNotEmpty &&
        !_genericAlbumLower.contains(folder.toLowerCase());
    final folderQ = folderUseful ? _luceneQuotedPhrase(folder) : null;

    final folderLower = folder.toLowerCase();
    final artistLower = artist.toLowerCase();
    final folderContainsTagArtist = tagArtistUseful &&
        artistLower.isNotEmpty &&
        folderLower.contains(artistLower);

    final folderEqualsTagArtist = tagArtistUseful &&
        folderUseful &&
        folderLower == artistLower;

    final seen = <String>{};
    final out = <String>[];

    void add(String q) {
      if (seen.add(q)) out.add(q);
    }

    // 1) Tag artist + folder as release (album path), when release isn't redundant
    if (arq != null && folderQ != null && !folderEqualsTagArtist) {
      add('recording:$tq AND artist:$arq AND release:$folderQ');
    }

    // 2) Folder contains tag artist: still try release-heavy query first is (1);
    //    add artist + recording without release if folder is only artist name
    if (arq != null && folderEqualsTagArtist) {
      add('recording:$tq AND artist:$arq');
    }

    // 3) Tag artist only (when not already only query)
    if (arq != null && !folderEqualsTagArtist) {
      add('recording:$tq AND artist:$arq');
    }

    // 4) Folder as album / release name
    if (folderQ != null) {
      add('recording:$tq AND release:$folderQ');
    }

    // 5) Unknown artist: treat parent folder as artist name (…/Artist/track.mp3)
    if (!tagArtistUseful && folderQ != null) {
      add('recording:$tq AND artist:$folderQ');
    }

    // 6) Folder contains artist but tags weak: folder-as-artist can help misfiling
    if (tagArtistUseful && folderQ != null && folderContainsTagArtist) {
      add('recording:$tq AND artist:$folderQ');
    }

    // 7) Broad fallback
    add('recording:$tq');

    return out;
  }

  static const List<String> discoverTagSlugs = [
    'jazz',
    'electronic',
    'ambient',
    'rock',
    'folk',
    'soul',
  ];

  /// Public catalog browse via MusicBrainz tag search (`tag:jazz`, …).
  /// Returned rows are outbound-only unless you attach your own playable URI.
  Future<List<DiscoveredRecording>> fetchDiscoverFeed({
    required String tagSlug,
    int offset = 0,
    int limit = 24,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    final safeOffset = offset < 0 ? 0 : offset;
    await _pace();
    final trimmed = tagSlug.trim().toLowerCase();
    final query =
        trimmed.isEmpty ? _defaultDiscoverTagQuery() : 'tag:${_escapeLuceneWord(trimmed)}';

    final uri = Uri.https('musicbrainz.org', '/ws/2/recording', {
      'query': query,
      'fmt': 'json',
      'limit': safeLimit.toString(),
      'offset': safeOffset.toString(),
    });

    final res = await _get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      },
    );
    if (res.statusCode != 200) return const [];

    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return const [];
    final list = body['recordings'];
    if (list is! List<dynamic> || list.isEmpty) return const [];

    return _recordingsToDiscoverList(list);
  }

  /// Tag slugs documented for [fetchDiscoverFeed] — rotates as user pages.
  static String discoverTagForPage(int zeroBasedPage) {
    final i = zeroBasedPage % discoverTagSlugs.length;
    return discoverTagSlugs[i];
  }

  static String _defaultDiscoverTagQuery() =>
      'tag:${_escapeLuceneWord(discoverTagSlugs.first)}';

  /// Minimal quoting for lucene keyword tag values.
  static String _escapeLuceneWord(String s) {
    final t = s.trim();
    if (t.isEmpty) {
      return discoverTagSlugs.first;
    }
    if (t.contains(' ') ||
        t.contains(':') ||
        t.contains('+') ||
        t.contains('\\')) {
      final escaped = t.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      return '"$escaped"';
    }
    return t;
  }

  List<DiscoveredRecording> _recordingsToDiscoverList(List<dynamic> raw) {
    final seen = <String>{};
    final out = <DiscoveredRecording>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final d = _mapRecordingToDiscover(item);
      if (d != null && seen.add(d.recordingMbid)) {
        out.add(d);
      }
    }
    return out;
  }

  DiscoveredRecording? _mapRecordingToDiscover(Map<String, dynamic> recording) {
    final recordingId = recording['id'] as String?;
    final recTitle = (recording['title'] as String?)?.trim();
    if (recordingId == null ||
        recordingId.isEmpty ||
        recTitle == null ||
        recTitle.isEmpty) {
      return null;
    }
    final artist = (_primaryArtistName(recording))?.trim();
    if (artist == null || artist.isEmpty) return null;

    var albumTitle = '';
    String? releaseId;
    final releasesRaw = recording['releases'];
    if (releasesRaw is List<dynamic> && releasesRaw.isNotEmpty) {
      final ordered = _orderReleasesForPick(releasesRaw);
      for (final release in ordered) {
        final rid = release['id'] as String?;
        if (rid != null && rid.isNotEmpty) {
          releaseId = rid;
          final rt = (release['title'] as String?)?.trim();
          albumTitle =
              rt != null && rt.isNotEmpty ? rt : recTitle;
          break;
        }
      }
    }

    final artworkUrl = releaseId == null || releaseId.isEmpty
        ? null
        : 'https://coverartarchive.org/release/$releaseId/front-500';

    if (albumTitle.isEmpty) {
      albumTitle = recTitle;
    }

    return DiscoveredRecording(
      recordingMbid: recordingId,
      title: recTitle,
      artistName: artist,
      albumTitle: albumTitle,
      artworkUrl: artworkUrl,
    );
  }

  Future<List<dynamic>?> _fetchRecordingSearch(String query) async {
    final uri = Uri.https('musicbrainz.org', '/ws/2/recording', {
      'query': query,
      'fmt': 'json',
      'limit': '25',
    });

    final res = await _get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      },
    );
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return null;
    final list = body['recordings'];
    if (list is! List<dynamic> || list.isEmpty) return null;
    return list;
  }

  EnrichedTrackMetadata? _enrichIfReleaseContainsTrack({
    required Map<String, dynamic> recording,
    required String localTitle,
    required String localArtist,
    required String localAlbum,
    int? expectedAlbumTrackCount,
  }) {
    final recTitle = recording['title'] as String?;
    if (recTitle == null || recTitle.trim().isEmpty) return null;

    if (!_titlesMatchForLocalFile(recTitle.trim(), localTitle)) {
      return null;
    }

    final mbArtist = (_primaryArtistName(recording) ?? '').trim();
    if (_artistHintUseful(localArtist)) {
      if (mbArtist.isEmpty || !_metadataCorrelates(mbArtist, localArtist)) {
        return null;
      }
    }

    final recordingId = recording['id'] as String?;
    if (recordingId == null || recordingId.isEmpty) return null;

    final releasesRaw = recording['releases'];
    if (releasesRaw is! List<dynamic> || releasesRaw.isEmpty) return null;

    final orderedReleases = _orderReleasesForPick(
      releasesRaw,
      expectedTrackCount: expectedAlbumTrackCount,
    );

    for (final release in orderedReleases) {
      final releaseTitle = (release['title'] as String?)?.trim() ?? '';
      if (_albumHintUseful(localAlbum)) {
        if (releaseTitle.isEmpty ||
            !_metadataCorrelates(releaseTitle, localAlbum)) {
          continue;
        }
      }

      if (!_releaseContainsLocalTrack(
        release,
        localTitle: localTitle,
        recordingMbid: recordingId,
      )) {
        continue;
      }

      final artist = (_primaryArtistName(recording) ?? '').trim();
      if (artist.isEmpty) return null;

      final album = (release['title'] as String?)?.trim() ?? '';
      final releaseId = release['id'] as String?;

      final artworkUrl = releaseId == null || releaseId.isEmpty
          ? null
          : 'https://coverartarchive.org/release/$releaseId/front-500';

      return EnrichedTrackMetadata(
        title: recTitle.trim(),
        artistName: artist.trim(),
        albumTitle: album.isEmpty ? recTitle.trim() : album,
        artworkUrl: artworkUrl,
        recordingMbid: recordingId,
        releaseMbid: releaseId,
        confidence: 0.78,
      );
    }
    return null;
  }

  /// True if [release] lists this recording or a track title matching [localTitle].
  bool _releaseContainsLocalTrack(
    Map<String, dynamic> release, {
    required String localTitle,
    required String recordingMbid,
  }) {
    final media = release['media'];
    if (media is! List<dynamic> || media.isEmpty) {
      return false;
    }

    for (final m in media) {
      if (m is! Map<String, dynamic>) continue;
      final tracks =
          (m['tracks'] is List<dynamic>) ? m['tracks'] : m['track'];
      if (tracks is! List<dynamic>) continue;
      for (final t in tracks) {
        if (t is! Map<String, dynamic>) continue;

        final rec = t['recording'];
        if (rec is Map<String, dynamic>) {
          final rid = rec['id'] as String?;
          if (rid == recordingMbid) return true;
          if (rid != null && rid.isNotEmpty && rid != recordingMbid) {
            continue;
          }
        }

        final trackTitle = t['title'] as String?;
        if (trackTitle != null &&
            _titlesMatchForLocalFile(trackTitle, localTitle)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _titlesMatchForLocalFile(String mbTitle, String localTitle) {
    final a = _normalizeTitle(mbTitle);
    final b = _normalizeTitle(localTitle);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;

    final wordsA = a.split(' ').where((w) => w.length >= 3).toSet();
    final wordsB = b.split(' ').where((w) => w.length >= 3).toSet();
    if (wordsA.isEmpty || wordsB.isEmpty) {
      return a.length >= 3 && a == b;
    }

    final overlap = wordsA.intersection(wordsB).length;
    final requiredMatches =
        (math.max(wordsA.length, wordsB.length) * 0.6).ceil();
    return overlap >= requiredMatches;
  }

  bool _artistHintUseful(String localArtist) {
    final t = localArtist.trim().toLowerCase();
    return t.isNotEmpty &&
        t != 'unknown artist' &&
        t != 'unknown' &&
        t != 'various artists';
  }

  bool _albumHintUseful(String localAlbum) =>
      localAlbum.trim().isNotEmpty && !isGenericAlbumTitle(localAlbum);

  /// Loose match for artist name or folder vs MusicBrainz release title.
  bool _metadataCorrelates(String mb, String local) {
    final a = _normalizeTitle(mb);
    final b = _normalizeTitle(local);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    final ta = a.split(' ').where((t) => t.length > 1).toSet();
    final tb = b.split(' ').where((t) => t.length > 1).toSet();
    return ta.intersection(tb).isNotEmpty;
  }

  String _normalizeTitle(String s) {
    final lower = s.toLowerCase().trim();
    return lower.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  List<Map<String, dynamic>> _orderReleasesForPick(
    List<dynamic> releasesRaw, {
    int? expectedTrackCount,
  }) {
    final all = <Map<String, dynamic>>[];
    for (final r in releasesRaw) {
      if (r is Map<String, dynamic>) all.add(r);
    }
    if (all.isEmpty) return const [];

    int rank(Map<String, dynamic> r) {
      var score = 0;
      if (r['status'] == 'Official') score += 4;
      final rg = r['release-group'];
      if (rg is Map<String, dynamic> && rg['primary-type'] == 'Album') {
        score += 2;
      }
      if (expectedTrackCount != null && expectedTrackCount > 1) {
        final count = _releaseTrackCount(r);
        if (count > 0 && count == expectedTrackCount) {
          score += 6;
        }
      }
      return score;
    }

    all.sort((a, b) => rank(b).compareTo(rank(a)));
    return all;
  }

  int _releaseTrackCount(Map<String, dynamic> release) {
    final media = release['media'];
    if (media is! List<dynamic>) return 0;
    var total = 0;
    for (final m in media) {
      if (m is! Map<String, dynamic>) continue;
      final tracks =
          (m['tracks'] is List<dynamic>) ? m['tracks'] : m['track'];
      if (tracks is List<dynamic>) {
        total += tracks.length;
      }
    }
    return total;
  }

  String? _luceneQuotedPhrase(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final escaped = t.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }

  /// Cover Art Archive front image for a release whose track listing matches
  /// [songTitles] closely enough (names compared case-insensitively).
  Future<String?> lookupAlbumCoverArtUrl({
    required String albumTitle,
    required String primaryArtistName,
    required List<String> songTitles,
  }) async {
    final trimmedAlbum = albumTitle.trim();
    if (trimmedAlbum.isEmpty || isGenericAlbumTitle(trimmedAlbum)) {
      return null;
    }
    if (songTitles.isEmpty) return null;

    final cleanTitles = songTitles
        .map(sanitizeTrackTitleForSearch)
        .where((t) => t.isNotEmpty)
        .toList();
    if (cleanTitles.isEmpty) return null;

    final aq = _luceneQuotedPhrase(trimmedAlbum);
    if (aq == null) return null;

    String? artistClause;
    final art = primaryArtistName.trim();
    if (art.isNotEmpty && art.toLowerCase() != 'unknown artist') {
      final arq = _luceneQuotedPhrase(art);
      if (arq != null) {
        artistClause = ' AND artist:$arq';
      }
    }

    await _pace();
    var releases =
        await _releaseSearch('release:$aq${artistClause ?? ''}');
    if (releases.isEmpty) {
      await _pace();
      releases = await _releaseSearch('release:$aq');
      if (releases.isEmpty) return null;
    }

    int rankRelease(Map<String, dynamic> r) {
      var score = 0;
      if (r['status'] == 'Official') score += 4;
      final rg = r['release-group'];
      if (rg is Map<String, dynamic> && rg['primary-type'] == 'Album') {
        score += 2;
      }
      final tc = r['track-count'];
      if (tc is num && tc.toInt() == cleanTitles.length) {
        score += 3;
      }
      return score;
    }

    final sorted = [...releases]
      ..sort((a, b) => rankRelease(b).compareTo(rankRelease(a)));

    final seenIds = <String>{};
    for (final rel in sorted) {
      final id = rel['id'] as String?;
      if (id == null || id.isEmpty || !seenIds.add(id)) continue;

      await _pace();
      final detail = await _fetchReleaseWithRecordings(id);
      if (detail == null) continue;

      final mbTitles = _recordingTitlesFromReleaseDetail(detail);
      if (!_trackListsMatchForAlbum(cleanTitles, mbTitles)) continue;

      return 'https://coverartarchive.org/release/$id/front-500';
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _releaseSearch(String query) async {
    final uri = Uri.https('musicbrainz.org', '/ws/2/release', {
      'query': query,
      'fmt': 'json',
      'limit': '15',
    });

    final res = await _get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      },
    );
    if (res.statusCode != 200) return [];

    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return [];
    final list = body['releases'];
    if (list is! List<dynamic>) return [];
    final out = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) out.add(item);
    }
    return out;
  }

  Future<Map<String, dynamic>?> _fetchReleaseWithRecordings(
    String releaseMbid,
  ) async {
    final uri =
        Uri.https('musicbrainz.org', '/ws/2/release/$releaseMbid', {
      'fmt': 'json',
      'inc': 'recordings',
    });

    final res = await _get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      },
    );
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return null;
    return body;
  }

  List<String> _recordingTitlesFromReleaseDetail(Map<String, dynamic> release) {
    final titles = <String>[];
    final media = release['media'];
    if (media is! List<dynamic>) return titles;
    for (final m in media) {
      if (m is! Map<String, dynamic>) continue;
      final trackList =
          (m['tracks'] is List<dynamic>) ? m['tracks'] : m['track'];
      if (trackList is! List<dynamic>) continue;
      for (final t in trackList) {
        if (t is! Map<String, dynamic>) continue;
        final rec = t['recording'];
        String? title = (t['title'] as String?)?.trim();
        if (rec is Map<String, dynamic>) {
          final rt = (rec['title'] as String?)?.trim();
          if (rt != null && rt.isNotEmpty) title = rt;
        }
        if (title != null && title.isNotEmpty) titles.add(title);
      }
    }
    return titles;
  }

  bool _trackListsMatchForAlbum(
    List<String> ourNormalizedTitles,
    List<String> mbTitles,
  ) {
    if (ourNormalizedTitles.isEmpty || mbTitles.isEmpty) return false;

    var matched = 0;
    for (final ours in ourNormalizedTitles) {
      var hit = false;
      for (final mb in mbTitles) {
        if (_titlesMatchForLocalFile(mb, ours)) {
          hit = true;
          break;
        }
      }
      if (hit) matched++;
    }

    final n = ourNormalizedTitles.length;
    if (n == 1) return matched >= 1;
    final threshold = math.max(2, ((n * 0.52).ceil()));
    return matched >= threshold;
  }

  String? _primaryArtistName(Map<String, dynamic> recording) {
    final credits = recording['artist-credit'];
    if (credits is! List<dynamic> || credits.isEmpty) return null;
    final buf = StringBuffer();
    for (final c in credits) {
      if (c is! Map<String, dynamic>) continue;
      final join = c['joinphrase'] as String? ?? '';
      final name = c['name'] as String?;
      if (name != null && name.isNotEmpty) {
        buf.write(name);
        buf.write(join);
      }
    }
    final s = buf.toString().trim();
    if (s.isNotEmpty) return s;
    final first = credits.first;
    if (first is Map<String, dynamic>) {
      final a = first['artist'];
      if (a is Map<String, dynamic>) {
        final n = a['name'] as String?;
        if (n != null && n.trim().isNotEmpty) return n.trim();
      }
    }
    return null;
  }
}
