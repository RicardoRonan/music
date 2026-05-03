# Resonate - Flutter Music Player

Resonate is a polished Flutter music player MVP built on `flutter_starter`.
It uses `just_audio` for playback, `flutter_riverpod` for state management, and `go_router` for navigation.

## Features

- Browse a mock catalog and play tracks with a queue.
- Mini player plus full now playing experience.
- Persistent likes, recently played items, and search history via `shared_preferences`.
- Artwork loading with fallback assets.
- Modular feature-first structure ready for real API integration.

## Tech Stack

- Flutter (Dart 3)
- Riverpod
- go_router
- just_audio + audio_service
- shared_preferences

## Getting Started

1. Install Flutter and verify setup:

```bash
flutter doctor
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

Optional:

- Web: `flutter run -d chrome`
- Android device: `flutter run -d <device-id>`

## Project Structure

- `lib/app/`: app shell, router, and global theme setup.
- `lib/core/`: shared UI helpers and utilities.
- `lib/features/`: feature modules (home, search, player, settings, etc.).
- `lib/features/player/`: playback models, service layer, and player state notifier.
- `lib/mock/`: mock data sources (replace with real backend/repository).
- `assets/`: images and demo audio assets.

## Testing

Run tests with:

```bash
flutter test
```

## Android Release Prep (Beta Ready)

Before uploading to Google Play (internal/closed testing), complete:

1. Set a permanent `applicationId` in `android/app/build.gradle.kts` (replace `com.example.flutter_starter`).
2. Configure release signing with your upload keystore.
3. Bump app version in `pubspec.yaml` (`version: x.y.z+buildNumber`).
4. Build release app bundle:

```bash
flutter build appbundle --release
```

Bundle output:

- `build/app/outputs/bundle/release/app-release.aab`

## Roadmap

- Replace mock catalog with a real streaming/music API.
- Add offline downloads and playback from local file URIs.
- Add authentication and cloud sync for likes/history.
- Improve recommendations and playlist intelligence.
