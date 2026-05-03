import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LibraryScanKind { collecting, importing }

@immutable
class LibraryScanProgress {
  const LibraryScanProgress({
    required this.kind,
    this.filesFound = 0,
    this.current = 0,
    this.total = 0,
  });

  final LibraryScanKind kind;
  final int filesFound;
  final int current;
  final int total;

  /// Non-null only while importing paths into the library (0–100).
  int? get percent => kind == LibraryScanKind.importing && total > 0
      ? (100 * current / total).round().clamp(0, 100)
      : null;
}

final libraryScanProgressProvider =
    NotifierProvider<LibraryScanProgressNotifier, LibraryScanProgress?>(
  LibraryScanProgressNotifier.new,
);

class LibraryScanProgressNotifier extends Notifier<LibraryScanProgress?> {
  @override
  LibraryScanProgress? build() => null;

  void setCollecting(int filesFound) {
    state = LibraryScanProgress(
      kind: LibraryScanKind.collecting,
      filesFound: filesFound,
    );
  }

  void setImporting(int current, int total) {
    state = LibraryScanProgress(
      kind: LibraryScanKind.importing,
      current: current,
      total: total,
    );
  }

  void clear() {
    state = null;
  }
}
