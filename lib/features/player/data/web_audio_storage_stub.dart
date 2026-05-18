import 'dart:typed_data';

/// No-op on non-web platforms.
class WebAudioStorage {
  WebAudioStorage._();
  static final WebAudioStorage instance = WebAudioStorage._();

  Future<void> init() async {}

  Future<void> put({
    required String id,
    required Uint8List bytes,
    required String fileName,
    required String extension,
  }) async {}

  Future<String?> getOrCreateBlobUrl(String id) async => null;

  Future<void> warmUrls(Iterable<String> storedUris) async {}

  Future<void> delete(String id) async {}

  Future<void> clear() async {}
}

const String kWebAudioScheme = 'web-audio';

bool isWebAudioUri(String uri) =>
    Uri.tryParse(uri.trim())?.scheme == kWebAudioScheme;

String? webAudioStorageId(String uri) {
  final parsed = Uri.tryParse(uri.trim());
  if (parsed == null || parsed.scheme != kWebAudioScheme) return null;
  if (parsed.host.isNotEmpty) return parsed.host;
  final path = parsed.path;
  return path.isEmpty ? null : path.replaceFirst('/', '');
}
