class ChromaprintRunResult {
  const ChromaprintRunResult({
    required this.fingerprint,
    required this.durationSeconds,
  });

  final String fingerprint;
  final int durationSeconds;
}

Future<ChromaprintRunResult?> chromaprintFromFileUri(String uriString) async =>
    null;
