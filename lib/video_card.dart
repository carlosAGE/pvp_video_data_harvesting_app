import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCard extends StatefulWidget {
  final String url;
  const VideoCard({super.key, required this.url});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.setLooping(true);
        _controller.play(); // Auto-play when ready
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // Important: Frees up memory on your S24+
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: _isInitialized
          ? Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
    );
  }
}