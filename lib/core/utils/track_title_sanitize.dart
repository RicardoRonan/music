/// Strips common download-site domains, URL fragments, and bracketed promos so
/// the real track name (or artist string) is what Spotify, YouTube, and
/// MusicBrainz see. Usually a no-op for clean catalog metadata.
String sanitizeTrackTitleForSearch(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return raw.trim();

  // Drop common track-number prefixes from ripped filenames.
  s = s.replaceFirst(RegExp(r'^\s*\d{1,3}\s*[.\-_:]\s*'), '');
  s = s.replaceFirst(RegExp(r'^\s*track\s*\d{1,3}\s*[.\-_:]?\s*', caseSensitive: false), '');

  s = s.replaceAll(
    RegExp(
      r'\.(mp3|m4a|flac|wav|aiff|aif|ogg|opus|aac|wma|webm|mka)$',
      caseSensitive: false,
    ),
    '',
  ).trim();

  for (final re in _bracketedJunkPatterns) {
    s = s.replaceAll(re, ' ');
  }

  for (final token in _domainAndRipperTokens) {
    final esc = RegExp.escape(token);
    s = s.replaceAll(
      RegExp(
        r'''[\s\-_.,[\(]*''' + esc + r'''[\s\-_.,\)\]]*''',
        caseSensitive: false,
      ),
      ' ',
    );
  }

  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  s = s.replaceAll(RegExp(r'^[-_|•,\s]+|[-_|•,\s]+$'), '').trim();

  if (s.isEmpty) return raw.trim();
  return s;
}

final List<RegExp> _bracketedJunkPatterns = [
  RegExp(r'\([^)]*songslover[^)]*\)', caseSensitive: false),
  RegExp(r'\[[^\]]*songslover[^\]]*\]', caseSensitive: false),
  RegExp(r'\([^)]*mp3[^)]*download[^)]*\)', caseSensitive: false),
  RegExp(r'\[[^\]]*mp3[^\]]*download[^\]]*\]', caseSensitive: false),
  RegExp(r'\([^)]*youtube[^)]*\)', caseSensitive: false),
  RegExp(r'\[[^\]]*youtube[^\]]*\]', caseSensitive: false),
  RegExp(r'\([^)]*youtu\.be[^)]*\)', caseSensitive: false),
  RegExp(r'\[[^\]]*youtu\.be[^\]]*\]', caseSensitive: false),
  RegExp(r'\([^)]*soundcloud[^)]*\)', caseSensitive: false),
  RegExp(r'\([^)]*bandcamp[^)]*\)', caseSensitive: false),
  RegExp(r'\([^)]*tiktok[^)]*\)', caseSensitive: false),
  RegExp(r'\([^)]*y2mate[^)]*\)', caseSensitive: false),
  RegExp(r'\([^)]*ytmp3[^)]*\)', caseSensitive: false),
  RegExp(r'\([^)]*320kbps[^)]*\)', caseSensitive: false),
  RegExp(r'\([^)]*128kbps[^)]*\)', caseSensitive: false),
  RegExp(r'\([^)]*official\s+audio[^)]*\)', caseSensitive: false),
  RegExp(r'\([^)]*official\s+video[^)]*\)', caseSensitive: false),
];

/// Lowercase tokens; matching is case-insensitive via RegExp.
const _domainAndRipperTokens = <String>{
  'youtube.com',
  'youtu.be',
  'm.youtube.com',
  'www.youtube.com',
  'music.youtube.com',
  'soundcloud.com',
  'on.soundcloud.com',
  'bandcamp.com',
  'tiktok.com',
  'vm.tiktok.com',
  'instagram.com',
  'facebook.com',
  'fb.watch',
  'reddit.com',
  'twitter.com',
  'x.com',
  'y2mate.com',
  'y2mate.guru',
  'ytmp3.cc',
  'ytmp3.nu',
  'yt1s.com',
  'savefrom.net',
  'ssyoutube.com',
  'onlymp3.to',
  'mp3juices.cc',
  'myfreemp3',
  'songslover',
  'songslover.com',
  'freemp3download',
  'onlinevideoconverter',
  'clipconverter',
  'keepvid',
  '9xbuddy',
  'archive.org',
  'mediafire.com',
  'zippyshare.com',
  'dropbox.com',
  'mega.nz',
  'drive.google.com',
  'tidal.com',
  'deezer.com',
  'spotify.com',
  'open.spotify.com',
  'napster.com',
  'audiomack.com',
  'datpiff.com',
  'livemixtapes.com',
};
