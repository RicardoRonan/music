import 'package:flutter/foundation.dart';

import 'spotify_process_env_stub.dart'
    if (dart.library.io) 'spotify_process_env_io.dart' as proc_env;

/// Spotify Web API [client credentials](https://developer.spotify.com/documentation/web-api/tutorials/client-credentials-flow).
///
/// Supply at build time:
/// `--dart-define=SPOTIFY_CLIENT_ID=... --dart-define=SPOTIFY_CLIENT_SECRET=...`
///
/// On mobile/desktop, you can also set `SPOTIFY_CLIENT_ID` and
/// `SPOTIFY_CLIENT_SECRET` in the process environment (e.g. shell `export`)
/// before `flutter run`. Web builds cannot call the token API from the browser
/// due to CORS; enrichment skips Spotify on web.
class SpotifyClientCredentials {
  const SpotifyClientCredentials({
    required this.clientId,
    required this.clientSecret,
  });

  final String clientId;
  final String clientSecret;
}

SpotifyClientCredentials? resolveSpotifyClientCredentials() {
  if (kIsWeb) return null;

  const idDef = String.fromEnvironment('SPOTIFY_CLIENT_ID');
  const secDef = String.fromEnvironment('SPOTIFY_CLIENT_SECRET');
  var id = idDef.trim();
  var secret = secDef.trim();
  if (id.isEmpty || secret.isEmpty) {
    final env = proc_env.readProcessEnvironment();
    id = (env['SPOTIFY_CLIENT_ID'] ?? '').trim();
    secret = (env['SPOTIFY_CLIENT_SECRET'] ?? '').trim();
  }
  if (id.isEmpty || secret.isEmpty) return null;
  return SpotifyClientCredentials(clientId: id, clientSecret: secret);
}
