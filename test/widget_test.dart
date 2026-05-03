import 'package:flutter_starter/app/app.dart';
import 'package:flutter_starter/app/background_audio_init.dart';
import 'package:flutter_starter/features/player/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initBackgroundPlayback();
  });

  testWidgets('Music app loads library after welcome is completed', (tester) async {
    SharedPreferences.setMockInitialValues({
      'welcome_onboarding_completed': true,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWith((ref) => prefs),
        ],
        child: const MusicApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Library'), findsOneWidget);
  });
}
