import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

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
  const VideoCard({super.key, required this.url, required this.title});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {}); // Show the first frame
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // CRITICAL: Frees up your phone's memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
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
        Positioned(
          bottom: 40,
          left: 20,
          child: Text(
            widget.title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}