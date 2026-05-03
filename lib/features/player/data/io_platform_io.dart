import 'dart:async';
import 'dart:io';

import '../just_audio_import.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stable `file:` URI for an absolute path (Windows vs POSIX).
String resolvedFileUriForPlayback(String absolutePath) =>
    Uri.file(absolutePath, windows: Platform.isWindows).toString();

/// Normalized path/key for detecting the same backing file regardless of URI
/// string variants (slashes, casing on Windows).
String playbackUriDedupeKey(String uriString) {
  final t = uriString.trim();
  if (t.isEmpty) {
    return '';
  }
  final parsed = Uri.tryParse(t);
  if (parsed != null && parsed.isAbsolute && parsed.scheme == 'file') {
    try {
      final fp = parsed.toFilePath(windows: Platform.isWindows);
      if (fp.isEmpty) {
        return t;
      }
      var norm = p.normalize(fp).replaceAll(RegExp(r'[/\\]+$'), '');
      if (Platform.isWindows) {
        norm = norm.toLowerCase();
      }
      return norm;
    } catch (_) {
      return t;
    }
  }
  return t;
}

Future<String?> materializePickedFile({
  String? path,
  List<int>? bytes,
  required String suggestedName,
}) async {
  if (path != null && path.isNotEmpty) {
    return Uri.file(path, windows: Platform.isWindows).toString();
  }
  if (bytes != null && bytes.isNotEmpty) {
    final dir = await getTemporaryDirectory();
    final ext = p.extension(suggestedName);
    final raw = suggestedName.replaceAll(RegExp(r'[^\w\-. ]'), '_');
    final safe = raw.length > 80 ? raw.substring(0, 80) : raw;
    final name =
        'import_${DateTime.now().millisecondsSinceEpoch}_$safe${ext.isEmpty ? '.bin' : ''}';
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.uri.toString();
  }
  return null;
}

Future<Duration?> probeAudioDuration(String uriString) async {
  final player = AudioPlayer();
  try {
    await player.setAudioSource(AudioSource.uri(Uri.parse(uriString)));
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
