import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_bottom_chrome.dart';
import '../../player/models/app_theme_preference.dart';
import '../../player/providers/app_providers.dart';
import '../../player/widgets/library_scan_progress_dialog.dart';
import '../../player/providers/preferences_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static final Uri _githubUri = Uri.parse('https://github.com/RicardoRonan');
  static final Uri _linkedinUri = Uri.parse(
    'https://www.linkedin.com/in/the-dev-ricardo/',
  );
  static final Uri _portfolioUri = Uri.parse('https://thedevricardo.netlify.app/');

  Future<void> _openExternalLink(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.toString()}')),
      );
    }
  }

  Future<void> _showAboutAppSheet(BuildContext context, ThemeData theme) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              24 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About this app', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Timeless Music Player is my personal app project. I am a solo developer, I listen to music every day, and I built this app for myself. I constantly use it, improve it, and ship updates to keep making it better.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Check out more by me:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('GitHub'),
                  subtitle: const Text('https://github.com/RicardoRonan'),
                  onTap: () => _openExternalLink(sheetContext, _githubUri),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.work_outline_rounded),
                  title: const Text('LinkedIn'),
                  subtitle: const Text(
                    'https://www.linkedin.com/in/the-dev-ricardo/',
                  ),
                  onTap: () => _openExternalLink(sheetContext, _linkedinUri),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Portfolio'),
                  subtitle: const Text('https://thedevricardo.netlify.app/'),
                  onTap: () => _openExternalLink(sheetContext, _portfolioUri),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(preferencesNotifierProvider);
    final notifier = ref.read(preferencesNotifierProvider.notifier);
    final local = ref.watch(localLibraryProvider);

    return Scaffold(
      bottomNavigationBar: const AppBottomChrome(selectedIndex: 0),
      body: ListView(
        padding: AppSpacing.screenHorizontal.copyWith(top: AppSpacing.xl),
        children: [
          Text('Settings', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            subtitle: Text('Theme: ${prefs.themePreference.label}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final choice = await showModalBottomSheet<AppThemePreference>(
                context: context,
                showDragHandle: true,
                builder: (ctx) => _ThemeSheet(current: prefs.themePreference),
              );
              if (choice != null && context.mounted) {
                await notifier.setThemePreference(choice);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            kIsWeb ? 'Your library' : 'On this device',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            kIsWeb
                ? 'Choose audio files from your computer. Tracks are stored in this browser for playback.'
                : 'Files you import are grouped by folder as albums.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
            if (local.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${local.length} imported track${local.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tag 90+ minute files as Audiobook'),
              subtitle: const Text(
                'Sets genre to Audiobook for long local titles (1½ hours or more).',
              ),
              value: prefs.tagLongLocalAudioAsAudiobook,
              onChanged: (v) async {
                await notifier.setTagLongLocalAudioAsAudiobook(v);
                await ref
                    .read(localLibraryProvider.notifier)
                    .reapplyClassificationFromPreferences();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Exclude audio under 30 seconds'),
              subtitle: const Text(
                'Omits very short local files from the library. Turning this off '
                'does not restore files already removed.',
              ),
              value: prefs.excludeAudioUnder30Seconds,
              onChanged: (v) async {
                await notifier.setExcludeAudioUnder30Seconds(v);
                await ref
                    .read(localLibraryProvider.notifier)
                    .reapplyClassificationFromPreferences();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.upload_file_rounded),
              title: Text(kIsWeb ? 'Choose music files' : 'Import audio files'),
              subtitle: Text(
                kIsWeb
                    ? 'Pick MP3 and other audio files from your computer.'
                    : 'Pick files from your device storage.',
              ),
              onTap: () async {
                final n = await ref
                    .read(localLibraryProvider.notifier)
                    .importAudioFiles();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      n == 0
                          ? 'No new files added (or picker was cancelled).'
                          : 'Added $n track${n == 1 ? '' : 's'}.',
                    ),
                  ),
                );
              },
            ),
            if (!kIsWeb)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.manage_search_rounded),
                title: const Text('Scan device for music'),
                subtitle: const Text(
                  'Find audio already on your device (up to 10,000 files per scan).',
                ),
                onTap: () async {
                  final n = await runDeviceMusicScanWithProgressDialog(
                    context,
                    ref,
                  );
                  if (!context.mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  if (n == -1) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not read storage. Allow audio access in system settings, then try again.',
                        ),
                      ),
                    );
                  } else if (n == 0) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No new audio files found (up to 10,000 files per scan).',
                        ),
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added $n track${n == 1 ? '' : 's'} from device scan.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Clear local library'),
              subtitle: const Text(
                'Removes imported tracks from this app only. Files on disk are not deleted.',
              ),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove imports?'),
                    content: const Text(
                      'This removes imported tracks from Resonate. '
                      'Your original files on disk are not deleted.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await ref.read(localLibraryProvider.notifier).clearLibrary();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Imported library cleared.'),
                      ),
                    );
                  }
                }
              },
            ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Clear recently played'),
            subtitle: const Text('Removes local history only.'),
            onTap: () async {
              await notifier.clearRecentlyPlayed();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recently played cleared.')),
                );
              }
            },
          ),
          const Divider(height: AppSpacing.xxl),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About Timeless Music Player'),
            subtitle: const Text('Built by TheDevRicardo'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showAboutAppSheet(context, theme),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy'),
            subtitle: Text('Your music stays on your device.'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.current});

  final AppThemePreference current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Theme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final mode in AppThemePreference.values)
            RadioListTile<AppThemePreference>(
              title: Text(mode.label),
              value: mode,
              groupValue: current,
              onChanged: (v) {
                if (v != null) Navigator.pop(context, v);
              },
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
