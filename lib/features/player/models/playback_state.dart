import '../just_audio_import.dart';

/// Maps to [ProcessingState] for UI (loading / buffering / error).
enum AppProcessingState {
  idle,
  loading,
  ready,
  buffering,
  completed,
  error,
}

AppProcessingState mapProcessingState(ProcessingState s) {
  switch (s) {
    case ProcessingState.idle:
      return AppProcessingState.idle;
    case ProcessingState.loading:
      return AppProcessingState.loading;
    case ProcessingState.ready:
      return AppProcessingState.ready;
    case ProcessingState.buffering:
      return AppProcessingState.buffering;
    case ProcessingState.completed:
      return AppProcessingState.completed;
  }
}
