/// Web: no filesystem scan (paths are never collected).
Future<bool> ensureDeviceScanPermissions() async => true;

Future<List<String>> collectDeviceAudioPaths({
  void Function(int filesFound)? onProgress,
  int maxFiles = 10000,
}) async =>
    const [];
