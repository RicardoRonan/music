import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/enriched_track_metadata.dart';

/// AcoustID fingerprint lookup → MusicBrainz-style enrichment.
///
/// The client key is resolved by [resolveAcoustIdClientKey] (see
/// `lib/core/config/acoustid_client_key.dart`), with an optional
/// `--dart-define=ACOUSTID_CLIENT_KEY=...` override.
class AcoustIdRepository {
  AcoustIdRepository({required http.Client httpClient}) : _client = httpClient;

  final http.Client _client;

  static const Duration _httpTimeout = Duration(seconds: 30);

  static const _userAgent =
      'flutter_starter/1.0.0 ( https://github.com/ ; local music player )';

  Future<void> _pace() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  /// POST lookup (fingerprints are too long for many GET URLs).
  Future<EnrichedTrackMetadata?> lookupEnrichment({
    required String clientKey,
    required String fingerprint,
    required int durationSeconds,
  }) async {
    final key = clientKey.trim();
    if (key.isEmpty) return null;
    final fp = fingerprint.trim();
    if (fp.isEmpty || durationSeconds <= 0) return null;

    await _pace();
    final body = <String, String>{
      'client': key,
      'format': 'json',
      'duration': '$durationSeconds',
      'fingerprint': fp,
      'meta': 'recordings+releases+releasegroups',
    };
    final encoded = body.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    final res = await _client
        .post(
          Uri.https('api.acoustid.org', '/v2/lookup'),
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            'User-Agent': _userAgent,
          },
          body: encoded,
        )
        .timeout(_httpTimeout);
    if (res.statusCode != 200) return null;
    Map<String, dynamic>? json;
    try {
      final o = jsonDecode(res.body);
      json = o is Map<String, dynamic> ? o : null;
    } catch (_) {
      return null;
    }
    if (json == null) return null;
    return _pickEnrichment(json);
  }

  EnrichedTrackMetadata? _pickEnrichment(Map<String, dynamic> json) {
    if (json['status'] != 'ok') return null;
    final results = json['results'];
    if (results is! List<dynamic> || results.isEmpty) return null;

    Map<String, dynamic>? bestRes;
    var bestScore = -1.0;
    for (final r in results) {
      if (r is! Map<String, dynamic>) continue;
      final sc = (r['score'] as num?)?.toDouble() ?? 0;
      if (sc > bestScore) {
        bestScore = sc;
        bestRes = r;
      }
    }
    if (bestRes == null) return null;

    final recs = bestRes['recordings'];
    if (recs is! List<dynamic> || recs.isEmpty) return null;

    Map<String, dynamic>? pick;
    var bestRank = -1;
    for (final raw in recs) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id'] as String?;
      final title = (raw['title'] as String?)?.trim();
      if (id == null || id.isEmpty || title == null || title.isEmpty) {
        continue;
      }
      final sources = (raw['sources'] as List<dynamic>?)?.length ?? 0;
      final releases = (raw['releases'] as List<dynamic>?)?.length ?? 0;
      final rank = sources * 20 + releases * 5 + title.length;
      if (rank > bestRank) {
        bestRank = rank;
        pick = raw;
      }
    }
    if (pick == null) return null;

    final recId = pick['id'] as String;
    final recTitle = (pick['title'] as String?)?.trim() ?? '';
    final artist = _firstArtistName(pick['artists']);

    var albumTitle = '';
    String? releaseId;
    final releases = pick['releases'];
    if (releases is List<dynamic>) {
      for (final rel in releases) {
        if (rel is! Map<String, dynamic>) continue;
        final rid = rel['id'] as String?;
        final rt = (rel['title'] as String?)?.trim();
        if (rid != null && rid.isNotEmpty) {
          releaseId = rid;
          albumTitle = rt ?? '';
          break;
        }
      }
    }
    if (albumTitle.isEmpty) {
      final rgs = pick['releasegroups'];
      if (rgs is List<dynamic> && rgs.isNotEmpty) {
        final g = rgs.first;
        if (g is Map<String, dynamic>) {
          albumTitle = (g['title'] as String?)?.trim() ?? '';
        }
      }
    }
    if (albumTitle.isEmpty) {
      albumTitle = recTitle;
    }

    final artworkUrl = releaseId == null || releaseId.isEmpty
        ? null
        : 'https://coverartarchive.org/release/$releaseId/front-500';

    return EnrichedTrackMetadata(
      title: recTitle,
      artistName: artist.isEmpty ? 'Unknown Artist' : artist,
      albumTitle: albumTitle,
      artworkUrl: artworkUrl,
      recordingMbid: recId,
      releaseMbid: releaseId,
      confidence: bestScore.clamp(0.0, 1.0),
    );
  }

  String _firstArtistName(dynamic artists) {
    if (artists is! List<dynamic> || artists.isEmpty) return '';
    final a = artists.first;
    if (a is Map<String, dynamic> && a['name'] is String) {
      return (a['name'] as String).trim();
    }
    return '';
  }
}
