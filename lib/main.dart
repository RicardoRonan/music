import 'dart:ui' show PlatformDispatcher;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/background_audio_init.dart';
import 'features/player/data/preferences_store.dart';
import 'features/player/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error\n$stack');
    return true;
  };

  await initBackgroundPlayback();

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final prefs = await SharedPreferences.getInstance();
  await migrateWelcomeOnboardingIfNeeded(prefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => prefs),
      ],
      child: const MusicApp(),
    ),
  );
}
