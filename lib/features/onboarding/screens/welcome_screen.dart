import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../player/providers/local_library_notifier.dart';
import '../../player/providers/preferences_notifier.dart';

/// First-run screen: explains local scan/import and short-track filtering.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  var _excludeUnder30s = true;

  Future<void> _continue() async {
    await ref
        .read(preferencesNotifierProvider.notifier)
        .finishWelcomeOnboarding(
          excludeAudioUnder30Seconds: _excludeUnder30s,
        );
    await ref
        .read(localLibraryProvider.notifier)
        .reapplyClassificationFromPreferences();
    if (!mounted) return;
    context.go('/library');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenHorizontal.copyWith(
            top: AppSpacing.xl,
            bottom: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Welcome to Music', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Music is a simple offline music player for your local MP3 and audio files. '
                'To get started, scan your device for music or import audio files from storage '
                '(available in Settings and the Folders tab after this step).',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: SwitchListTile(
                  title: const Text('Exclude clips under 30 seconds'),
                  subtitle: const Text(
                    'Skips very short files (ringtones, previews) when importing '
                    'or when length is detected during playback.',
                  ),
                  value: _excludeUnder30s,
                  onChanged: (v) => setState(() => _excludeUnder30s = v),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _continue,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
