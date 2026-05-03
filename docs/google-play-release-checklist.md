# Google Play Release Checklist

## Store listing essentials
- [ ] Final app title selected and within 30 characters
- [ ] Short description finalized (<=80 chars)
- [ ] Full description finalized with clear value proposition
- [ ] 6-8 phone screenshots uploaded (localized if needed)
- [ ] High-res app icon uploaded
- [ ] Feature graphic uploaded
- [ ] Optional promo video link added

## Policy and trust
- [ ] Privacy policy URL published and added to Play Console
- [ ] App category set to Music & Audio
- [ ] Tags added (Music Player, Offline, MP3, Local Files, Playlist)
- [ ] Content rating questionnaire completed
- [ ] Data safety form completed accurately
- [ ] Ads declaration set correctly (No ads, if applicable)

## Build and technical readiness
- [ ] Version name and version code updated
- [ ] Release build signed (Play App Signing enabled)
- [ ] Min/target SDK compliant with current Play requirements
- [ ] Startup smoke test completed on low-end Android device
- [ ] Offline playback tested with airplane mode
- [ ] Media permission flow tested from fresh install
- [ ] No layout overflows on small screens
- [ ] Playback crash test completed (play/pause/seek/queue)

## Product quality and growth readiness
- [ ] In-app review prompt logic tested (not first launch)
- [ ] Empty library state explains scan/import steps clearly
- [ ] Error messages are actionable and user-friendly
- [ ] Navigation paths validated (library/search/playlists/now playing)
- [ ] Key retention surfaces visible (favorites, recent, playlists)

## Release operations
- [ ] Internal testing track build uploaded
- [ ] Closed testing track QA completed
- [ ] Pre-launch report reviewed in Play Console
- [ ] Crash/ANR dashboard checked before production rollout
- [ ] Staged rollout plan defined (e.g., 10% -> 50% -> 100%)

## Store listing A/B experiments (Play Store Listing Experiments)

### 1) App icon
- Hypothesis: A high-contrast icon improves browse-to-install conversion.
- Variant A: Current icon.
- Variant B: Simplified icon with stronger contrast and single focal shape.
- Success metric: Store listing conversion rate (visitors -> installs).

### 2) Screenshot first frame
- Hypothesis: Leading with "Offline music, made simple" increases install intent.
- Variant A: Feature-heavy first screenshot.
- Variant B: Value-proposition first screenshot focused on offline/no ads.
- Success metric: Conversion rate and first-time install completion.

### 3) Short description
- Hypothesis: "Offline MP3 player" wording increases search relevance and conversion.
- Variant A: "Simple Android music player for local files, playlists, and queue control."
- Variant B: "Offline MP3 player for your local music. No account, no ads, just playback."
- Success metric: Search conversion rate and overall listing CVR.

### 4) Feature graphic
- Hypothesis: A cleaner feature graphic improves listing engagement.
- Variant A: Current graphic.
- Variant B: Minimal graphic with one benefit headline and device mockup.
- Success metric: Conversion rate from listing visitors.

### 5) App title variation
- Hypothesis: Including "Offline MP3 Player" in title improves keyword discoverability.
- Variant A: "Music"
- Variant B: "Music: Offline MP3 Player"
- Success metric: Search impressions, ranking on target keywords, and installs.
