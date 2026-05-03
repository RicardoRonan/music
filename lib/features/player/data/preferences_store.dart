import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_theme_preference.dart';
import '../models/user_preferences.dart';

const _kLikes = 'music_liked_ids';
const _kRecent = 'music_recent_ids';
const _kSearches = 'music_recent_searches';
const _kTheme = 'app_theme_mode';
const _kTagLocalAudiobook90m = 'pref_tag_local_audiobook_90m';
const _kWelcomeOnboardingDone = 'welcome_onboarding_completed';
const _kExcludeAudioUnder30s = 'pref_exclude_audio_under_30s';
const _kLocalLibraryJson = 'music_local_library_json_v1';

/// Marks returning users as past welcome so they are not shown onboarding again.
Future<void> migrateWelcomeOnboardingIfNeeded(SharedPreferences prefs) async {
  if (prefs.containsKey(_kWelcomeOnboardingDone)) return;
  final raw = prefs.getString(_kLocalLibraryJson);
  final likes = prefs.getStringList(_kLikes) ?? [];
  var legacy = likes.isNotEmpty;
  if (raw != null && raw.isNotEmpty && raw != '[]') {
    legacy = true;
  }
  if (legacy) {
    await prefs.setBool(_kWelcomeOnboardingDone, true);
  }
}

/// Thin persistence — swap for encrypted store / cloud sync later.
class PreferencesStore {
  PreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  UserPreferences load() {
    final likes = _prefs.getStringList(_kLikes) ?? [];
    final recent = _prefs.getStringList(_kRecent) ?? [];
    final searches = _prefs.getStringList(_kSearches) ?? [];
    final theme = AppThemePreference.fromStorage(_prefs.getInt(_kTheme));
    return UserPreferences(
      likedSongIds: likes.toSet(),
      recentlyPlayedSongIds: recent,
      recentSearchQueries: searches,
      themePreference: theme,
      tagLongLocalAudioAsAudiobook:
          _prefs.getBool(_kTagLocalAudiobook90m) ?? true,
      welcomeOnboardingCompleted:
          _prefs.getBool(_kWelcomeOnboardingDone) ?? false,
      excludeAudioUnder30Seconds:
          _prefs.getBool(_kExcludeAudioUnder30s) ?? true,
    );
  }

  Future<void> persist(UserPreferences p) async {
    await _prefs.setStringList(_kLikes, p.likedSongIds.toList());
    await _prefs.setStringList(_kRecent, p.recentlyPlayedSongIds);
    await _prefs.setStringList(_kSearches, p.recentSearchQueries);
    await _prefs.setInt(_kTheme, p.themePreference.storageValue);
    await _prefs.setBool(_kTagLocalAudiobook90m, p.tagLongLocalAudioAsAudiobook);
    await _prefs.setBool(_kWelcomeOnboardingDone, p.welcomeOnboardingCompleted);
    await _prefs.setBool(_kExcludeAudioUnder30s, p.excludeAudioUnder30Seconds);
  }

  Future<UserPreferences> setThemePreference(
    UserPreferences current,
    AppThemePreference theme,
  ) async {
    final u = current.copyWith(themePreference: theme);
    await persist(u);
    return u;
  }

  Future<UserPreferences> setTagLongLocalAudioAsAudiobook(
    UserPreferences current,
    bool value,
  ) async {
    final u = current.copyWith(tagLongLocalAudioAsAudiobook: value);
    await persist(u);
    return u;
  }

  Future<UserPreferences> setWelcomeOnboardingCompleted(
    UserPreferences current,
    bool value,
  ) async {
    final u = current.copyWith(welcomeOnboardingCompleted: value);
    await persist(u);
    return u;
  }

  Future<UserPreferences> setExcludeAudioUnder30Seconds(
    UserPreferences current,
    bool value,
  ) async {
    final u = current.copyWith(excludeAudioUnder30Seconds: value);
    await persist(u);
    return u;
  }

  Future<UserPreferences> toggleLike(UserPreferences current, String id) async {
    final next = Set<String>.from(current.likedSongIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    final u = current.copyWith(likedSongIds: next);
    await persist(u);
    return u;
  }

  Future<UserPreferences> addRecent(UserPreferences current, String id) async {
    final list = List<String>.from(current.recentlyPlayedSongIds)
      ..remove(id)
      ..insert(0, id);
    while (list.length > 40) {
      list.removeLast();
    }
    final u = current.copyWith(recentlyPlayedSongIds: list);
    await persist(u);
    return u;
  }

  Future<UserPreferences> clearRecent(UserPreferences current) async {
    final u = current.copyWith(recentlyPlayedSongIds: []);
    await persist(u);
    return u;
  }

  Future<UserPreferences> addSearch(
    UserPreferences current,
    String query,
  ) async {
    final q = query.trim();
    if (q.isEmpty) return current;
    final list = List<String>.from(current.recentSearchQueries)
      ..remove(q)
      ..insert(0, q);
    while (list.length > 12) {
      list.removeLast();
    }
    final u = current.copyWith(recentSearchQueries: list);
    await persist(u);
    return u;
  }
}
