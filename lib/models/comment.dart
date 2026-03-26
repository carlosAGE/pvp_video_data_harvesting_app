class Comment {
  final String id;
  final String username;
  final String avatar;
  final String text;
  final DateTime timestamp;
  final int likes;
  
  Comment({
    required this.id,
    required this.username,
    required this.avatar,
    required this.text,
    required this.timestamp,
    required this.likes,
  });
}

// Mock Comment Data
List<Comment> getMockComments() {
  return [
    Comment(
      id: '1',
      username: 'coding_ninja',
      avatar: '🥷',
      text: 'This is so smooth! How did you make those animations?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      likes: 12,
    ),
    Comment(
      id: '2',
      username: 'tech_girl',
      avatar: '👩‍💻',
      text: 'Love the UI design! 🔥',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      likes: 8,
    ),
    Comment(
      id: '3',
      username: 'flutter_dev',
      avatar: '💙',
      text: 'Flutter is amazing for these kind of apps',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      likes: 25,
    ),
    Comment(
      id: '4',
      username: 'ui_wizard',
      avatar: '🧙‍♂️',
      text: 'The transitions are buttery smooth! What animation library did you use?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 31,
    ),
    Comment(
      id: '5',
      username: 'mobile_maker',
      avatar: '📱',
      text: 'This looks better than TikTok tbh 😅',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      likes: 127,
    ),
  ];
}