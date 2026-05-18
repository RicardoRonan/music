import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/widgets/app_loader_overlay.dart';
import '../features/player/data/preferences_store.dart';
import '../features/player/data/web_audio_storage.dart';
import '../features/player/providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'app.dart';
import 'background_audio_init.dart';

/// Runs async startup work while showing [AppLoaderOverlay], then mounts [MusicApp].
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  SharedPreferences? _prefs;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await initBackgroundPlayback();

      if (kIsWeb) {
        await WebAudioStorage.instance.init();
      }

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      final prefs = await SharedPreferences.getInstance();
      await migrateWelcomeOnboardingIfNeeded(prefs);

      if (!mounted) return;
      setState(() => _prefs = prefs);
    } catch (e, st) {
      debugPrint('AppBootstrap init failed: $e\n$st');
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_prefs != null) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWith((ref) => _prefs!),
        ],
        child: const MusicApp(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: _error == null
            ? const AppLoaderOverlay()
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not start the app.\n$_error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
      ),
    );
  }
}

void installGlobalErrorHandlers() {
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
}
