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

const _skipDirNames = {
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
  'AppData',
  'Local',
  'Roaming',
  'Temp',
  'tmp',
};

/// Walks common device roots and returns absolute file paths for audio files.
Future<List<String>> collectDeviceAudioPaths({
  void Function(int filesFound)? onProgress,
  int maxFiles = 10000,
}) async {
  final roots = await _scanRoots();
  return _collectFromRoots(roots, onProgress: onProgress, maxFiles: maxFiles);
}

/// Scans the Windows user Music folder (and common OneDrive variants).
Future<List<String>> collectWindowsMusicFolderPaths({
  void Function(int filesFound)? onProgress,
  int maxFiles = 10000,
}) async {
  final roots = await _windowsMusicScanRoots();
  return _collectFromRoots(roots, onProgress: onProgress, maxFiles: maxFiles);
}

/// Scans a single folder tree chosen by the user (e.g. custom Music path).
Future<List<String>> collectAudioPathsInFolder(
  String folderPath, {
  void Function(int filesFound)? onProgress,
  int maxFiles = 10000,
  int maxDepth = 80,
}) async {
  final norm = p.normalize(folderPath.trim());
  if (norm.isEmpty || !await Directory(norm).exists()) return [];
  return _collectFromRoots(
    [_ScanRoot(norm, maxDepth)],
    onProgress: onProgress,
    maxFiles: maxFiles,
  );
}

/// Existing Music folder paths on Windows, for UI labels and folder picker defaults.
Future<List<String>> existingWindowsMusicFolderPaths() async {
  final out = <String>[];
  for (final root in await _windowsMusicScanRoots()) {
    out.add(root.path);
  }
  return out;
}

Future<List<String>> _collectFromRoots(
  List<_ScanRoot> roots, {
  void Function(int filesFound)? onProgress,
  int maxFiles = 10000,
}) async {
  if (roots.isEmpty) return [];

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
          if (_skipDirNames.contains(name)) continue;
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

Future<List<_ScanRoot>> _windowsMusicScanRoots() async {
  final roots = <_ScanRoot>[];
  final seen = <String>{};

  Future<void> addRoot(String path, int depth) async {
    final norm = p.normalize(path);
    if (seen.contains(norm)) return;
    if (!await Directory(norm).exists()) return;
    seen.add(norm);
    roots.add(_ScanRoot(norm, depth));
  }

  final home = Platform.environment['USERPROFILE'];
  if (home == null) return roots;

  await addRoot(p.join(home, 'Music'), 80);
  await addRoot(p.join(home, 'OneDrive', 'Music'), 80);
  await addRoot(p.join(home, 'OneDrive', 'Documents', 'Music'), 80);
  await addRoot(p.join(home, 'My Music'), 80);

  try {
    final dl = await getDownloadsDirectory();
    if (dl != null) {
      final musicInDownloads = p.join(dl.path, 'Music');
      await addRoot(musicInDownloads, 80);
    }
  } catch (_) {}

  return roots;
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
    return _windowsMusicScanRoots();
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
