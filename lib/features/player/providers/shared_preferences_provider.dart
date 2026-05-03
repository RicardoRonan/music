import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Must be overridden in [main] via [ProviderScope.overrides].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnsupportedError(
    'sharedPreferencesProvider: pass SharedPreferences in ProviderScope.overrides',
  );
});
