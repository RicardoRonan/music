String formatTrackDuration(Duration d) {
  if (d.inMilliseconds <= 0) return '0:00';
  final total = d.inSeconds;
  final m = total ~/ 60;
  final s = total % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
