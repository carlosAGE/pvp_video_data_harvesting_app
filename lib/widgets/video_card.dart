import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';
import 'heart_animation.dart';
import 'comments_modal.dart';

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
      startX: MediaQuery.of(context).size.width * 0.5 + (random.nextDouble() - 0.5) * 100,
      startY: MediaQuery.of(context).size.height * 0.7,
    );
    
    setState(() {
      _hearts.add(heart);
    });

    // Remove heart after animation
    Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _hearts.removeWhere((h) => h.key == heart.key!);
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
}