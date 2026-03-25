class Video {
  final String id;
  final String url;
  final String title;

  Video({required this.id, required this.url, required this.title});

  // This maps your Supabase table columns to the Flutter object
  factory Video.fromMap(Map<String, dynamic> map) {
    return Video(
      id: map['id'].toString(),
      url: map['video_url'] ?? '', // Make sure this matches your column name
      title: map['title'] ?? 'Untitled Chaos',
    );
  }
}