import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_player_service.dart';
import '../../../services/review_prompt_service.dart';
import 'shared_preferences_provider.dart';

export 'catalog_providers.dart';
export 'library_scan_progress_provider.dart';
export 'local_library_notifier.dart';
export 'shared_preferences_provider.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final s = AudioPlayerService();
  ref.onDispose(s.dispose);
  return s;
});

final reviewPromptServiceProvider = Provider<ReviewPromptService>((ref) {
  return ReviewPromptService(ref.read(sharedPreferencesProvider));
});
