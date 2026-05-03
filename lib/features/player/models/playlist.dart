class Playlist {
  const Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.songIds,
    this.coverUrl,
    this.category,
  });

  final String id;
  final String title;
  final String description;
  final List<String> songIds;
  final String? coverUrl;

  /// Home sections: Recently Played, For You, Focus, Chill, Workout.
  final String? category;

  int get songCount => songIds.length;
}
