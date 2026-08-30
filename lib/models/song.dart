class Song {
  final String id;
  final String title;
  final String artist;
  final String? url;
  final String? thumbnail;
  final int? duration;
  final int? viewCount;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.url,
    this.thumbnail,
    this.duration,
    this.viewCount,
  });

  String get watchUrl => url ?? 'https://www.youtube.com/watch?v=$id';
}
