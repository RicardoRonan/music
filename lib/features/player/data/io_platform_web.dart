import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../just_audio_import.dart';
import 'web_audio_storage.dart' show WebAudioStorage, kWebAudioScheme, webAudioStorageId;

String resolvedFileUriForPlayback(String absolutePath) => absolutePath;

String playbackUriDedupeKey(String uriString) {
  final id = webAudioStorageId(uriString);
  if (id != null) return id;
  return uriString.trim();
}

Future<String> resolvePlaybackUri(String uriString) async {
  final id = webAudioStorageId(uriString);
  if (id != null) {
    final blob = await WebAudioStorage.instance.getOrCreateBlobUrl(id);
    if (blob == null || blob.isEmpty) {
      throw StateError('Missing stored audio for $id');
    }
    return blob;
  }
  return uriString.trim();
}

Future<String?> materializePickedFile({
  String? path,
  List<int>? bytes,
  required String suggestedName,
}) async {
  if (bytes == null || bytes.isEmpty) return null;
  final ext = p.extension(suggestedName);
  final id =
      'aud_${DateTime.now().millisecondsSinceEpoch}_${suggestedName.hashCode.abs()}';
  await WebAudioStorage.instance.put(
    id: id,
    bytes: Uint8List.fromList(bytes),
    fileName: suggestedName,
    extension: ext,
  );
  return '$kWebAudioScheme://$id';
}

Future<Duration?> probeAudioDuration(String uriString) async {
  final player = AudioPlayer();
  try {
    final resolved = await resolvePlaybackUri(uriString);
    await player.setAudioSource(AudioSource.uri(Uri.parse(resolved)));
    final immediate = player.duration;
    if (immediate != null && immediate > Duration.zero) {
      return immediate;
    }
    try {
      return await player.durationStream
          .where((d) => d != null && d > Duration.zero)
          .map((d) => d as Duration)
          .first
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      return null;
    }
  } catch (_) {
    return null;
  } finally {
    await player.dispose();
  }
}
