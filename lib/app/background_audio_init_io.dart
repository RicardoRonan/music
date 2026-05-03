import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Registers [audio_service] for lock screen / notification / headset controls.
Future<void> initBackgroundPlayback() async {
  await JustAudioBackground.init(
    androidNotificationChannelId:
        'com.example.flutter_starter.channel.media.v2',
    androidNotificationChannelName: 'Media playback',
    androidNotificationChannelDescription: 'Now playing and transport controls',
    // [androidNotificationOngoing] requires [androidStopForegroundOnPause] true; use
    // ongoing false so we can keep the rich media notification when paused.
    androidNotificationOngoing: false,
    // Keep the media-style notification while paused so transport + seek stay available.
    androidStopForegroundOnPause: false,
    androidNotificationIcon: 'mipmap/ic_launcher',
    preloadArtwork: true,
    fastForwardInterval: const Duration(seconds: 15),
    rewindInterval: const Duration(seconds: 15),
    // Uses the app's theme color for notification background.
    // Artwork is loaded from the song's artworkUrl (cover art).
    notificationColor: const Color(0xFF121218), // Dark theme color for notification
  );
}
