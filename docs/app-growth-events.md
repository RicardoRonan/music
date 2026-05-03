# App Growth Event Plan

This plan defines product analytics events for discoverability, conversion, retention, and quality signals. It is implementation-ready but does not add any analytics SDK.

## Event catalog

### app_open
- Trigger: App enters foreground (cold start and resume)
- Useful properties: `source` (cold_start|resume), `app_version`, `device_locale`
- Why it matters: Baseline DAU/MAU, retention cohorts, and launch reliability

### onboarding_started
- Trigger: Welcome/onboarding screen first shown
- Useful properties: `app_version`, `install_age_days`
- Why it matters: Measures first-time user funnel entry

### onboarding_completed
- Trigger: User taps continue and onboarding preference is saved
- Useful properties: `exclude_short_audio`, `time_to_complete_seconds`
- Why it matters: Measures first-run completion and setup friction

### permission_requested
- Trigger: App asks for media/audio/storage permission before scan
- Useful properties: `permission_type`, `surface` (library|home|settings)
- Why it matters: Identifies permission funnel drop-off

### permission_granted
- Trigger: OS permission result returns granted
- Useful properties: `permission_type`, `surface`
- Why it matters: Tracks readiness to import/scan user music

### song_played
- Trigger: Playback successfully starts for a track
- Useful properties: `song_source` (local|remote), `play_context` (library|search|playlist|queue), `queue_length`
- Why it matters: Core activation event linked to retention

### favourite_added
- Trigger: User marks a track as liked/favorite
- Useful properties: `song_id`, `surface` (now_playing|list_row), `library_size`
- Why it matters: Strong positive engagement indicator

### playlist_created
- Trigger: New playlist is created (including save-from-queue)
- Useful properties: `creation_surface`, `initial_song_count`
- Why it matters: High-intent behavior that predicts retention

### search_used
- Trigger: User submits a non-empty search query
- Useful properties: `query_length`, `filter`, `result_count`
- Why it matters: Measures content discoverability and search quality

### review_prompt_shown
- Trigger: In-app review flow request is initiated
- Useful properties: `app_opens`, `days_since_first_launch`, `meaningful_actions`
- Why it matters: Validates review-ask timing strategy

### review_prompt_completed
- Trigger: Best-effort completion signal after review flow returns
- Useful properties: `flow` (in_app_review), `available` (true|false)
- Why it matters: Measures review funnel outcomes and prompt quality

### error_occurred
- Trigger: User-visible error states and caught runtime failures
- Useful properties: `error_type`, `screen`, `operation`, `is_recoverable`
- Why it matters: Helps reduce crashes/friction that can hurt Play ranking

## Implementation guidance
- Keep event names stable and snake_case.
- Add `app_version` and `build_number` to every event automatically.
- Avoid sending song titles/file paths for privacy; prefer IDs and enums.
- Sample high-volume events (if needed) but never sample errors.
