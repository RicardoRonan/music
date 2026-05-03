import 'app_theme_preference.dart';

/// Persisted lightweight prefs — account sync can mirror these keys later.
class UserPreferences {
  const UserPreferences({
    required this.likedSongIds,
    required this.recentlyPlayedSongIds,
    required this.recentSearchQueries,
    required this.themePreference,
    this.tagLongLocalAudioAsAudiobook = true,
    this.welcomeOnboardingCompleted = false,
    this.excludeAudioUnder30Seconds = true,
  });

  final Set<String> likedSongIds;
  final List<String> recentlyPlayedSongIds;
  final List<String> recentSearchQueries;
  final AppThemePreference themePreference;

  /// When duration is at least 90 minutes, set [Song.genreTag] to `Audiobook`.
  final bool tagLongLocalAudioAsAudiobook;

  /// First-run welcome (scan / import guidance) has been dismissed.
  final bool welcomeOnboardingCompleted;

  /// When true, drop or skip local tracks shorter than 30 seconds.
  final bool excludeAudioUnder30Seconds;

  static const UserPreferences empty = UserPreferences(
    likedSongIds: {},
    recentlyPlayedSongIds: [],
    recentSearchQueries: [],
    themePreference: AppThemePreference.system,
    tagLongLocalAudioAsAudiobook: true,
    welcomeOnboardingCompleted: false,
    excludeAudioUnder30Seconds: true,
  );

  UserPreferences copyWith({
    Set<String>? likedSongIds,
    List<String>? recentlyPlayedSongIds,
    List<String>? recentSearchQueries,
    AppThemePreference? themePreference,
    bool? tagLongLocalAudioAsAudiobook,
    bool? welcomeOnboardingCompleted,
    bool? excludeAudioUnder30Seconds,
  }) {
    return UserPreferences(
      likedSongIds: likedSongIds ?? this.likedSongIds,
      recentlyPlayedSongIds:
          recentlyPlayedSongIds ?? this.recentlyPlayedSongIds,
      recentSearchQueries: recentSearchQueries ?? this.recentSearchQueries,
      themePreference: themePreference ?? this.themePreference,
      tagLongLocalAudioAsAudiobook:
          tagLongLocalAudioAsAudiobook ?? this.tagLongLocalAudioAsAudiobook,
      welcomeOnboardingCompleted:
          welcomeOnboardingCompleted ?? this.welcomeOnboardingCompleted,
      excludeAudioUnder30Seconds:
          excludeAudioUnder30Seconds ?? this.excludeAudioUnder30Seconds,
    );
  }
}
