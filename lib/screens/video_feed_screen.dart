import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_provider.dart';
import '../widgets/video_card.dart';

// The "Feed" Screen: This is the actual UI your S24+ will show
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