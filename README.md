# Resonate — Flutter music player starter

Polished MVP music player built on the existing `flutter_starter` project: mock catalog, real playback via **just_audio** (bundled demo MP3 per track), **Riverpod** for state, **go_router** for navigation, and **shared_preferences** for likes / recent searches / recently played.

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable channel) and run `flutter doctor` until your target platforms are ready.
2. From this directory:

   ```bash
   flutter pub get
   flutter run
   ```

3. Pick a device (e.g. `flutter run -d chrome` or a physical phone). Android requires the `INTERNET` permission for artwork URLs (already declared).

## Architecture (short)

| Layer | Role |
|--------|------|
| `lib/app/` | `MaterialApp.router`, theme, `GoRouter` shell |
| `lib/core/` | Spacing, small widgets, formatting, responsive helpers |
| `lib/features/*/` | Screens + feature widgets; **no** direct `AudioPlayer` usage in UI |
| `lib/features/player/` | Models, `AudioPlayerService` (just_audio), `PlayerNotifier`, preferences |
| `lib/mock/` | `MockMusicData` — replace with API / local library repository |

**Why Riverpod** (see `pubspec.yaml`): compile-safe providers, easy overrides in tests, and room to grow per feature without `InheritedWidget` sprawl.

**Playback flow**: UI calls `ref.read(playerNotifierProvider.notifier).playQueue(...)` → `AudioPlayerService` builds `ConcatenatingAudioSource` from each song’s `assetPath` or `streamingUrl` → streams update `PlayerState` for mini player, Now Playing, and queue.

## Where to extend next

- **Real streaming API**: implement a `MusicCatalog` subclass (or new repository) that returns `Song` rows with `streamingUrl` set; keep `AudioPlayerService` as the single playback entry point.
- **Offline downloads**: add download jobs + local `File` URIs; gate `AudioSource.file` in the service.
- **User authentication**: wrap catalog and prefs with an account scope; sync likes/history from backend.
- **Smart recommendations / AI playlists**: feed home “For you” from a recommender service instead of `genreTag` filters.
- **Crossfade / gapless / lyrics / social sharing**: see TODO comments in `lib/features/player/services/audio_player_service.dart`, `queue_screen.dart`, and `settings_screen.dart`.

## Assets

- `assets/audio/sample.mp3` — short demo clip (all mock songs point at it for a reliable MVP).
- `assets/images/artwork_placeholder.svg` — fallback when artwork fails or is missing.

## Tests

```bash
flutter test
```
