import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';
import 'package:flutter/services.dart';

// 1. The "State" Provider: This tells the app to go fetch your videos
final videoListProvider = FutureProvider<List<dynamic>>((ref) async {
  return await Supabase.instance.client
      .from('videos') // Make sure your table is named 'videos'
      .select();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ngxnrvlrbnigknnctkgp.supabase.co',
    anonKey: 'sb_publishable_mXzJSl5LOjVy5ZYcfS3UpQ_UdaS5dol',
  );

  // ProviderScope is required for Riverpod to work
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const VideoFeedScreen(), // Pointing to our new screen below
    );
  }
}

// 2. The "Feed" Screen: This is the actual UI your S24+ will show
class VideoFeedScreen extends ConsumerWidget {
  const VideoFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoAsyncValue = ref.watch(videoListProvider);

    return Scaffold(
      // Change background to a dark grey so you can see the screen is "on"
      backgroundColor: const Color(0xFF1A1A1A), 
      body: videoAsyncValue.when(
        data: (videos) {
          // FIX: If Supabase returns 0 rows, show this instead of a black hole
          if (videos.isEmpty) {
            return const Center(
              child: Text(
                "SYSTEM ERROR: NO DATA HARVESTED\n(Check Supabase 'videos' table)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange, fontFamily: 'monospace'),
              ),
            );
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoCard(
                url: video['video_url'],
                title: video['title'] ?? 'UNKNOWN DATA',
                videoId: video['id'] ?? index.toString(),
                initialLikeCount: video['like_count'] ?? 0,
                creator: video['creator'] ?? 'Unknown Creator',
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "ACCESS DENIED: $err",
              style: const TextStyle(
                color: Colors.red,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        shape: const CircleBorder(side: BorderSide(color: Colors.greenAccent)),
        onPressed: () => print("WISH PORTAL OPENED"),
        child: const Icon(Icons.bolt, color: Colors.greenAccent),
      ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final String url;
  final String title;
  final String videoId;
  final int initialLikeCount;
  final String creator;

  const VideoCard({
    super.key,
    required this.url,
    required this.title,
    required this.videoId,
    required this.initialLikeCount,
    required this.creator,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _likeAnimationController;
  late AnimationController _heartAnimationController;
  late Animation<double> _likeAnimation;

  bool _isLiked = false;
  int _likeCount = 0;
  final List<HeartAnimation> _hearts = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _likeCount = widget.initialLikeCount;
  }

  @override
  void initState() {
    super.initState();
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {}); // Show the first frame
        _controller.play();
        _controller.setLooping(true);
      });
      
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // CRITICAL: Frees up your phone's memory
    _likeAnimationController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }
  
  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });

    if (_isLiked) {
      _addFloatingHeart();
    }

    // TODO: Send like to Supabase
    print('Video ${widget.videoId} ${_isLiked ? 'liked' : 'unliked'}');
  }

  void _addFloatingHeart() {
    final random = Random();
    final heart = HeartAnimation(
      key: UniqueKey(),
      startX:
          MediaQuery.of(context).size.width * 0.5 +
          (random.nextDouble() - 0.5) * 100,
      startY: MediaQuery.of(context).size.height * 0.7,
    );

    setState(() {
      _hearts.add(heart);
    });

    // Remove heart after animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _hearts.removeWhere((h) => h.key == heart.key);
        });
      }
    });
  }

  void _showComments() {
    HapticFeedback.lightImpact(); // Gentle vibration
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => CommentsModal(videoId: widget.videoId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover, // This makes it feel like TikTok/Reels
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent),
                ),
          
          // Floating Hearts Animation
          ..._hearts,

          // Right Side Action Buttons
          Positioned(
            right: 15,
            bottom: 100,
            child: Column(
              children: [
                // Like Button
                AnimatedBuilder(
                  animation: _likeAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _likeAnimation.value,
                      child: GestureDetector(
                        onTap: _handleLike,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5),
                Text(
                  _formatCount(_likeCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                // Comment Button
                GestureDetector(
                  onTap: _showComments,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '12k',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                // Share Button
                GestureDetector(
                  onTap: () => print('Share ${widget.videoId}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Share',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                // Creator Avatar (rotating disc effect)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.grey[800],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Left - Video Info
          Positioned(
            bottom: 40,
            left: 20,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${widget.creator}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  State<HeartAnimation> createState() => _HeartAnimationState();
}

class _HeartAnimationState extends State<HeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _moveUp;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _moveUp = Tween<double>(begin: widget.startY, end: widget.startY - 150)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          left: widget.startX - 20,
          top: _moveUp.value,
          child: Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: const Icon(Icons.favorite, color: Colors.red, size: 40),
            ),
          ),
        );
      },
    );
  }
}

// Individual Comment Tile
class CommentTile extends StatefulWidget {
  final Comment comment;

  const CommentTile({super.key, required this.comment});

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _isLiked = false;

  String _timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            child: Text(
              widget.comment.avatar,
              style: const TextStyle(fontSize: 16),
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and timestamp
                Row(
                  children: [
                    Text(
                      widget.comment.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(widget.comment.timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Comment text
                Text(
                  widget.comment.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),

                const SizedBox(height: 8),

                // Actions
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _isLiked = !_isLiked);
                        HapticFeedback.lightImpact();
                      },
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.comment.likes + (_isLiked ? 1 : 0)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => print('Reply to ${widget.comment.username}'),
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Comment Data Model
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
      text:
          'The transitions are buttery smooth! What animation library did you use?',
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

// Comments Modal Widget
class CommentsModal extends StatefulWidget {
  final String videoId;

  const CommentsModal({super.key, required this.videoId});

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  late List<Comment> _comments;

  @override
  void initState() {
    super.initState();

    _comments = getMockComments();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.insert(
          0,
          Comment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            username: 'you',
            avatar: '😎',
            text: _commentController.text.trim(),
            timestamp: DateTime.now(),
            likes: 0,
          ),
        );
      });
      _commentController.clear();
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            MediaQuery.of(context).size.height * _slideAnimation.value,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_comments.length}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.grey, height: 1),

                // Comments List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return CommentTile(comment: comment);
                    },
                  ),
                ),

                // Comment Input
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    border: Border(top: BorderSide(color: Colors.grey)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.greenAccent,
                        child: Text('😎', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocus,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: (_) => _addComment(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _addComment,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Post',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


// Floating Heart Animation Widget
class HeartAnimation extends StatefulWidget {
  final double startX;
  final double startY;

  const HeartAnimation({super.key, required this.startX, required this.startY});

  @override
  State<HeartAnimation> createState() => _HeartAnimationState();
}
