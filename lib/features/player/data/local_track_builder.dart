import 'package:path/path.dart' as p;

import '../models/song.dart';

/// Builds [Song] rows for the catalog from a resolved file [uriString] and paths.
Song buildLocalSongFromPaths({
  required String uriString,
  required String platformPath,
  Duration duration = Duration.zero,
  String artistName = 'Unknown artist',
}) {
  final fileName = p.basename(platformPath);
  final title = p.basenameWithoutExtension(fileName);
  final folder = p.basename(p.dirname(platformPath));
  final albumTitle =
      folder.trim().isEmpty || folder == '.' ? 'Imported audio' : folder;
  final albumKey = Object.hash(albumTitle, artistName);
  final albumId = 'loc_alb_$albumKey';
  final artistId = 'loc_art_${artistName.hashCode}';
  final id = 'local_${uriString.hashCode}';
  final parent = p.dirname(platformPath);
  final parentPath =
      parent == '.' || parent.isEmpty ? null : p.normalize(parent);
  return Song(
    id: id,
    title: title.isEmpty ? 'Track' : title,
    artistId: artistId,
    artistName: artistName,
    albumId: albumId,
    albumTitle: albumTitle,
    duration: duration,
    localAudioUri: uriString,
    localParentPath: parentPath,
    genreTag: 'Local',
  );
}

/// When only a display name is known (bytes import), folder is a generic label.
Song buildLocalSongFromUriAndNames({
  required String uriString,
  required String title,
  required String albumTitle,
  Duration duration = Duration.zero,
  String artistName = 'Unknown artist',
}) {
  final albumKey = Object.hash(albumTitle, artistName);
  final albumId = 'loc_alb_$albumKey';
  final artistId = 'loc_art_${artistName.hashCode}';
  final id = 'local_${uriString.hashCode}';
  return Song(
    id: id,
    title: title.isEmpty ? 'Track' : title,
    artistId: artistId,
    artistName: artistName,
    albumId: albumId,
    albumTitle: albumTitle.isEmpty ? 'Imported audio' : albumTitle,
    duration: duration,
    localAudioUri: uriString,
    genreTag: 'Local',
  );
}
