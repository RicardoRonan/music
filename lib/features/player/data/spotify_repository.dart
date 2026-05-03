import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/spotify_client_credentials.dart';
import '../../../core/utils/track_title_sanitize.dart';
import '../models/enriched_track_metadata.dart';
import 'musicbrainz_repository.dart';

/// Spotify Web API: client-credentials token + track search for enrichment.
class SpotifyRepository {
  SpotifyRepository({required http.Client httpClient}) : _client = httpClient;

  final http.Client _client;

  static const Duration _httpTimeout = Duration(seconds: 25);

  static const _userAgent =
      'flutter_starter/1.0.0 ( local music player; metadata lookup only )';

  String? _accessToken;
  DateTime? _tokenExpiresAt;

  Future<String?> _bearer(SpotifyClientCredentials creds) async {
    final now = DateTime.now();
    if (_accessToken != null &&
        _tokenExpiresAt != null &&
        now.isBefore(_tokenExpiresAt!.subtract(const Duration(seconds: 30)))) {
      return _accessToken;
    }

    final basic = base64Encode(
      utf8.encode('${creds.clientId}:${creds.clientSecret}'),
    );
    final res = await _client
        .post(
          Uri.https('accounts.spotify.com', '/api/token'),
          headers: {
            'Authorization': 'Basic $basic',
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': _userAgent,
          },
          body: 'grant_type=client_credentials',
        )
        .timeout(_httpTimeout);

    if (res.statusCode != 200) {
      if (kDebugMode) {
        debugPrint(
          'SpotifyRepository: token ${res.statusCode} ${res.body.length > 200 ? "${res.body.substring(0, 200)}..." : res.body}',
        );
      }
      return null;
    }

    Map<String, dynamic>? json;
    try {
      final o = jsonDecode(res.body);
      json = o is Map<String, dynamic> ? o : null;
    } catch (_) {
      return null;
    }
    final token = (json?['access_token'] as String?)?.trim();
    final expiresIn = (json?['expires_in'] as num?)?.toInt() ?? 3600;
    if (token == null || token.isEmpty) return null;
    _accessToken = token;
    _tokenExpiresAt = now.add(Duration(seconds: expiresIn));
    return token;
  }

  /// Best-effort track search from title / artist / album hints (no playback).
  Future<EnrichedTrackMetadata?> searchTrackEnrichment({
    required String title,
    required String artistName,
    required String albumTitle,
  }) async {
    if (kIsWeb) return null;
    final creds = resolveSpotifyClientCredentials();
    if (creds == null) return null;

    final t = sanitizeTrackTitleForSearch(title).trim();
    final a = sanitizeTrackTitleForSearch(artistName).trim();
    final al = sanitizeTrackTitleForSearch(albumTitle).trim();
    if (t.isEmpty && a.isEmpty) return null;

    final parts = <String>[];
    if (t.isNotEmpty) parts.add('track:${_spotifyQueryToken(t)}');
    if (a.isNotEmpty) parts.add('artist:${_spotifyQueryToken(a)}');
    if (al.isNotEmpty &&
        !MusicBrainzRepository.isGenericAlbumTitle(al) &&
        al.toLowerCase() != t.toLowerCase()) {
      parts.add('album:${_spotifyQueryToken(al)}');
    }
    if (parts.isEmpty) return null;
    final q = parts.join(' ');

    final token = await _bearer(creds);
    if (token == null) return null;

    final uri = Uri.https('api.spotify.com', '/v1/search', {
      'q': q,
      'type': 'track',
      'limit': '5',
    });

    final res = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      },
    ).timeout(_httpTimeout);

    if (res.statusCode != 200) return null;

    Map<String, dynamic>? root;
    try {
      final o = jsonDecode(res.body);
      root = o is Map<String, dynamic> ? o : null;
    } catch (_) {
      return null;
    }

    final tracks = root?['tracks'];
    if (tracks is! Map<String, dynamic>) return null;
    final items = tracks['items'];
    if (items is! List<dynamic> || items.isEmpty) return null;

    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final meta = _trackItemToEnrichment(raw);
      if (meta != null) return meta;
    }
    return null;
  }

  static String _spotifyQueryToken(String s) {
    final u = s.trim();
    if (u.contains('"')) {
      return '"${u.replaceAll('"', ' ')}"';
    }
    if (u.contains(' ') || u.contains(':')) {
      return '"$u"';
    }
    return u;
  }

  EnrichedTrackMetadata? _trackItemToEnrichment(Map<String, dynamic> item) {
    final name = (item['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return null;

    final artists = item['artists'];
    var artist = '';
    if (artists is List<dynamic>) {
      final names = <String>[];
      for (final ar in artists) {
        if (ar is Map<String, dynamic>) {
          final n = (ar['name'] as String?)?.trim();
          if (n != null && n.isNotEmpty) names.add(n);
        }
      }
      artist = names.join(', ');
    }
    if (artist.isEmpty) artist = 'Unknown Artist';

    final album = item['album'];
    var albumTitle = '';
    String? imageUrl;
    if (album is Map<String, dynamic>) {
      albumTitle = (album['name'] as String?)?.trim() ?? '';
      imageUrl = _pickBestImageUrl(album['images']);
    }
    if (albumTitle.isEmpty) albumTitle = name;

    final ext = item['external_urls'];
    String? spotifyUrl;
    if (ext is Map<String, dynamic>) {
      spotifyUrl = (ext['spotify'] as String?)?.trim();
    }

    return EnrichedTrackMetadata(
      title: name,
      artistName: artist,
      albumTitle: albumTitle,
      artworkUrl: imageUrl,
      spotifyOpenUrl: spotifyUrl,
    );
  }

  String? _pickBestImageUrl(dynamic images) {
    if (images is! List<dynamic> || images.isEmpty) return null;
    var bestW = -1;
    String? best;
    for (final img in images) {
      if (img is! Map<String, dynamic>) continue;
      final url = (img['url'] as String?)?.trim();
      if (url == null || url.isEmpty) continue;
      final w = (img['width'] as num?)?.toInt() ?? 0;
      if (w >= bestW) {
        bestW = w;
        best = url;
      }
    }
    return best;
  }
}
