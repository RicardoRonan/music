import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ChromaprintRunResult {
  const ChromaprintRunResult({
    required this.fingerprint,
    required this.durationSeconds,
  });

  final String fingerprint;
  final int durationSeconds;
}

/// Runs Chromaprint [fpcalc] when installed (PATH). Returns null on failure or
/// non-`file:` URIs (e.g. `content:` on Android).
Future<ChromaprintRunResult?> chromaprintFromFileUri(String uriString) async {
  if (kIsWeb) return null;
  final u = Uri.tryParse(uriString.trim());
  if (u == null || u.scheme != 'file') return null;
  late final String path;
  try {
    path = u.toFilePath(windows: Platform.isWindows);
  } catch (_) {
    return null;
  }
  if (path.isEmpty || !File(path).existsSync()) return null;

  try {
    final out = await Process.run(
      'fpcalc',
      ['-json', '-length', '120', path],
      runInShell: false,
    ).timeout(const Duration(seconds: 12));
    if (out.exitCode != 0) return null;
    final raw = _stdoutToString(out.stdout).trim();
    if (raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final fp = decoded['fingerprint'] as String?;
    final dur = decoded['duration'];
    if (fp == null || fp.isEmpty) return null;
    final sec = switch (dur) {
      int d => d,
      num d => d.round(),
      _ => 0,
    };
    if (sec <= 0) return null;
    return ChromaprintRunResult(fingerprint: fp, durationSeconds: sec);
  } catch (_) {
    return null;
  }
}

String _stdoutToString(Object? stdout) {
  if (stdout == null) return '';
  if (stdout is String) return stdout;
  if (stdout is List<int>) {
    return utf8.decode(stdout, allowMalformed: true);
  }
  return stdout.toString();
}
