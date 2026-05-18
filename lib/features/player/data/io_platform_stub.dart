/// Web / wasm: no filesystem access for imports.
String resolvedFileUriForPlayback(String absolutePath) => absolutePath;

Future<String> resolvePlaybackUri(String uriString) async => uriString.trim();

/// Alias key for non-IO platforms — no path normalization.
String playbackUriDedupeKey(String uriString) => uriString.trim();

Future<String?> materializePickedFile({
  String? path,
  List<int>? bytes,
  required String suggestedName,
}) async =>
    null;

Future<Duration?> probeAudioDuration(String uriString) async => null;
