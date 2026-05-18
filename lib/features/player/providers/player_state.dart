import '../just_audio_import.dart' hide PlayerState;

import '../models/playback_state.dart';
import '../models/song.dart';

/// UI-ready snapshot — updated from [AudioPlayer] streams in [PlayerNotifier].
class PlayerState {
  const PlayerState({
    required this.queue,
    required this.currentIndex,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.shuffleEnabled,
    required this.loopMode,
    required this.processingState,
    required this.volume,
    this.errorMessage,
  });

  final List<Song> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool shuffleEnabled;
  final LoopMode loopMode;
  final AppProcessingState processingState;
  final double volume;
  final String? errorMessage;

  Song? get currentSong {
    if (queue.isEmpty) return null;
    final i = currentIndex.clamp(0, queue.length - 1);
    return queue[i];
  }

  static const PlayerState empty = PlayerState(
    queue: [],
    currentIndex: 0,
    position: Duration.zero,
    duration: Duration.zero,
    isPlaying: false,
    shuffleEnabled: false,
    loopMode: LoopMode.off,
    processingState: AppProcessingState.idle,
    volume: 1,
  );

  PlayerState copyWith({
    List<Song>? queue,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? shuffleEnabled,
    LoopMode? loopMode,
    AppProcessingState? processingState,
    double? volume,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlayerState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      loopMode: loopMode ?? this.loopMode,
      processingState: processingState ?? this.processingState,
      volume: volume ?? this.volume,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
