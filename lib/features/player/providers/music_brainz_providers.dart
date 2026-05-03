import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/musicbrainz_repository.dart';

final musicBrainzRepositoryProvider = Provider<MusicBrainzRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return MusicBrainzRepository(httpClient: client);
});
