/// Web: no filesystem scan (paths are never collected).
Future<bool> ensureDeviceScanPermissions() async => true;

Future<List<String>> collectDeviceAudioPaths({
  void Function(int filesFound)? onProgress,
  int maxFiles = 10000,
}) async =>
    const [];

Future<List<String>> collectWindowsMusicFolderPaths({
  void Function(int filesFound)? onProgress,
  int maxFiles = 10000,
}) async =>
    const [];

Future<List<String>> collectAudioPathsInFolder(
  String folderPath, {
  void Function(int filesFound)? onProgress,
  int maxFiles = 10000,
  int maxDepth = 80,
}) async =>
    const [];

Future<List<String>> existingWindowsMusicFolderPaths() async => const [];
