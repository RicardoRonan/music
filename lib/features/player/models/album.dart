class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artistId,
    this.artworkUrl,
    this.year,
  });

  final String id;
  final String title;
  final String artistId;
  final String? artworkUrl;
  final int? year;
}
