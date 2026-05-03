class Artist {
  const Artist({
    required this.id,
    required this.name,
    this.bio,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? bio;
  final String? imageUrl;
}
