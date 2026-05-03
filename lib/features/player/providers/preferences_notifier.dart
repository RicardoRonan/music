import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preferences_store.dart';
import '../models/app_theme_preference.dart';
import '../models/user_preferences.dart';
import 'shared_preferences_provider.dart';

final preferencesNotifierProvider =
    NotifierProvider<PreferencesNotifier, UserPreferences>(
  PreferencesNotifier.new,
);

class PreferencesNotifier extends Notifier<UserPreferences> {
  PreferencesStore get _store =>
      PreferencesStore(ref.read(sharedPreferencesProvider));

  @override
  UserPreferences build() => _store.load();

  Future<void> toggleLike(String songId) async {
    state = await _store.toggleLike(state, songId);
  }

  Future<void> addRecentForSong(String songId) async {
    state = await _store.addRecent(state, songId);
  }

  Future<void> clearRecentlyPlayed() async {
    state = await _store.clearRecent(state);
  }

  Future<void> rememberSearch(String query) async {
    state = await _store.addSearch(state, query);
  }

  Future<void> setThemePreference(AppThemePreference theme) async {
    state = await _store.setThemePreference(state, theme);
  }

  Future<void> setTagLongLocalAudioAsAudiobook(bool value) async {
    state = await _store.setTagLongLocalAudioAsAudiobook(state, value);
  }

  Future<void> setWelcomeOnboardingCompleted(bool value) async {
    state = await _store.setWelcomeOnboardingCompleted(state, value);
  }

  Future<void> setExcludeAudioUnder30Seconds(bool value) async {
    state = await _store.setExcludeAudioUnder30Seconds(state, value);
  }

  /// Persists welcome completion and optional short-track rule in one write.
  Future<void> finishWelcomeOnboarding({
    required bool excludeAudioUnder30Seconds,
  }) async {
    var next = await _store.setExcludeAudioUnder30Seconds(
      state,
      excludeAudioUnder30Seconds,
    );
    next = await _store.setWelcomeOnboardingCompleted(next, true);
    state = next;
  }
}
