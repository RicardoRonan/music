import 'package:path/path.dart' as p;

/// Lowercase extensions without leading dot (matches [FileType.custom] list).
const Set<String> kLocalAudioFileExtensions = {
  'mp3',
  'm4a',
  'aac',
  'wav',
  'flac',
  'ogg',
  'opus',
  'wma',
  'aiff',
  'aif',
};

/// Same extensions as strings for [FilePicker] `allowedExtensions`.
const List<String> kLocalAudioPickerExtensions = [
  'mp3',
  'm4a',
  'aac',
  'wav',
  'flac',
  'ogg',
  'opus',
  'wma',
  'aiff',
  'aif',
];

bool pathLooksLikeLocalAudioFile(String filePath) {
  final ext = p.extension(filePath).toLowerCase();
  if (ext.length < 2) return false;
  return kLocalAudioFileExtensions.contains(ext.substring(1));
}
