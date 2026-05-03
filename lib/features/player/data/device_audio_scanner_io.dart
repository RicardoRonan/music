import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'local_audio_extensions.dart';

/// Android: requests audio / legacy storage read. Other platforms: true.
Future<bool> ensureDeviceScanPermissions() async {
  if (!Platform.isAndroid) return true;

  final audio = await Permission.audio.status;
  if (audio.isGranted) return true;
  if (audio.isDenied || audio.isLimited) {
    final req = await Permission.audio.request();
    if (req.isGranted || req.isLimited) return true;
  }

  final storage = await Permission.storage.status;
  if (storage.isGranted) return true;
  final storageReq = await Permission.storage.request();
  return storageReq.isGranted;
}

/// Walks common device roots and returns absolute file paths for audio files.
Future<List<String>> collectDeviceAudioPaths({
  void Function(int filesFound)? onProgress,
  int maxFiles = 10000,
}) async {
  final roots = await _scanRoots();
  if (roots.isEmpty) return [];

  const skipDirNames = {
    'node_modules',
    '.git',
    '.dart_tool',
    'Windows',
    'Program Files',
    'Program Files (x86)',
    'PerfLogs',
    r'$Recycle.Bin',
    'System Volume Information',
    'Library',
    'Caches',
    '.gradle',
    'Android',
    'DerivedData',
  };

  final found = <String>{};
  var yieldCounter = 0;

  for (final entry in roots) {
    final dir = Directory(entry.path);
    if (!await dir.exists()) continue;
    final stack = <_ScanFrame>[_ScanFrame(dir, 0)];
    while (stack.isNotEmpty && found.length < maxFiles) {
      final frame = stack.removeLast();
      if (frame.depth > entry.maxDepth) continue;

      List<FileSystemEntity> children;
      try {
        children = await frame.directory.list(followLinks: false).toList();
      } catch (_) {
        continue;
      }

      for (final e in children) {
        if (found.length >= maxFiles) break;
        if (e is File) {
          if (!pathLooksLikeLocalAudioFile(e.path)) continue;
          if (found.add(e.path)) {
            onProgress?.call(found.length);
          }
        } else if (e is Directory) {
          final name = p.basename(e.path);
          if (name.startsWith('.')) continue;
          if (skipDirNames.contains(name)) continue;
          stack.add(_ScanFrame(e, frame.depth + 1));
        }
      }

      yieldCounter++;
      if (yieldCounter >= 100) {
        yieldCounter = 0;
        await Future<void>.delayed(Duration.zero);
      }
    }
    if (found.length >= maxFiles) break;
  }

  return found.toList()..sort();
}

class _ScanRoot {
  const _ScanRoot(this.path, this.maxDepth);
  final String path;
  final int maxDepth;
}

class _ScanFrame {
  _ScanFrame(this.directory, this.depth);
  final Directory directory;
  final int depth;
}

Future<List<_ScanRoot>> _scanRoots() async {
  if (Platform.isAndroid) {
    final paths = <String>{
      '/storage/emulated/0',
      '/sdcard',
    };
    try {
      final dirs = await getExternalStorageDirectories();
      if (dirs != null) {
        for (final d in dirs) {
          paths.add(d.path);
        }
      }
    } catch (_) {}
    final out = <_ScanRoot>[];
    for (final path in paths) {
      if (await Directory(path).exists()) {
        out.add(_ScanRoot(path, 80));
      }
    }
    return out;
  }

  if (Platform.isIOS) {
    final out = <_ScanRoot>[];
    try {
      final doc = await getApplicationDocumentsDirectory();
      out.add(_ScanRoot(doc.path, 40));
      final lib = await getLibraryDirectory();
      out.add(_ScanRoot(lib.path, 40));
    } catch (_) {}
    return out;
  }

  if (Platform.isWindows) {
    final roots = <_ScanRoot>[];
    final home = Platform.environment['USERPROFILE'];
    if (home != null && await Directory(home).exists()) {
      roots.add(_ScanRoot(home, 60));
    }
    try {
      final dl = await getDownloadsDirectory();
      if (dl != null &&
          await Directory(dl.path).exists() &&
          (home == null || !p.isWithin(home, dl.path))) {
        roots.add(_ScanRoot(dl.path, 60));
      }
    } catch (_) {}
    for (var code = 65; code <= 90; code++) {
      final letter = String.fromCharCode(code);
      final drive = '$letter:\\';
      if (!await Directory(drive).exists()) continue;
      roots.add(_ScanRoot(drive, 10));
    }
    return roots;
  }

  if (Platform.isLinux) {
    final out = <_ScanRoot>[];
    for (final path in const ['/home', '/media', '/mnt']) {
      if (await Directory(path).exists()) {
        out.add(_ScanRoot(path, 60));
      }
    }
    try {
      final dl = await getDownloadsDirectory();
      if (dl != null && await Directory(dl.path).exists()) {
        out.add(_ScanRoot(dl.path, 60));
      }
    } catch (_) {}
    return out;
  }

  if (Platform.isMacOS) {
    final out = <_ScanRoot>[];
    final home = Platform.environment['HOME'];
    if (home != null && await Directory(home).exists()) {
      out.add(_ScanRoot(home, 50));
    }
    try {
      final doc = await getApplicationDocumentsDirectory();
      if (await Directory(doc.path).exists()) {
        out.add(_ScanRoot(doc.path, 40));
      }
      final dl = await getDownloadsDirectory();
      if (dl != null &&
          await Directory(dl.path).exists() &&
          (home == null || !p.isWithin(home, dl.path))) {
        out.add(_ScanRoot(dl.path, 50));
      }
    } catch (_) {}
    if (await Directory('/Users').exists()) {
      out.add(_ScanRoot('/Users', 8));
    }
    return out;
  }

  return const [];
}
