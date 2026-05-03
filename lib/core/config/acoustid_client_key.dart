/// AcoustID API client key.
///
/// Override at build time with `--dart-define=ACOUSTID_CLIENT_KEY=...` if you
/// prefer not to use the project default.
const String _kFromEnvironment = String.fromEnvironment('ACOUSTID_CLIENT_KEY');

/// Resolves the AcoustID `client` parameter for `/v2/lookup`.
String resolveAcoustIdClientKey() {
  final trimmed = _kFromEnvironment.trim();
  if (trimmed.isNotEmpty) return trimmed;
  return 'Ef7p5KSEbE';
}
