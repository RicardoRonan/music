/// Rules for local imports / device scan (duration-based).
abstract final class LocalAudioClassification {
  static const Duration minKeepDuration = Duration(seconds: 30);
  static const Duration audiobookMinDuration = Duration(minutes: 90);

  /// Drop files once duration is known and under [minKeepDuration].
  /// [Duration.zero] means unknown — do not omit yet.
  static bool shouldOmitShort(
    Duration duration, {
    bool excludeUnder30Seconds = true,
  }) {
    if (!excludeUnder30Seconds) return false;
    if (duration <= Duration.zero) return false;
    return duration < minKeepDuration;
  }

  /// Long-form local audio tagged for library chips / filters.
  static String genreForLocalDuration(
    Duration duration, {
    required bool tagLongAsAudiobook,
  }) {
    if (tagLongAsAudiobook &&
        duration > Duration.zero &&
        duration >= audiobookMinDuration) {
      return 'Audiobook';
    }
    return 'Local';
  }
}
