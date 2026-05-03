import 'dart:io' show File, Platform;

import 'package:flutter/material.dart';

Widget? artworkFromFileUri(
  String uriString,
  double size,
  BorderRadius borderRadius,
  Widget fallback,
) {
  final parsed = Uri.tryParse(uriString);
  if (parsed == null || !parsed.isScheme('file')) return null;
  final path = parsed.toFilePath(windows: Platform.isWindows);
  if (path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return ClipRRect(
    borderRadius: borderRadius,
    child: SizedBox(
      width: size,
      height: size,
      child: Image.file(
        file,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
      ),
    ),
  );
}
