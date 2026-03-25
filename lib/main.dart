import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // This "watches" the provider we created above
    final videoAsyncValue = ref.watch(videoListProvider);

    return Scaffold(
      body: videoAsyncValue.when(
        // When data arrives, build the vertical swipe feed
        data: (videos) => PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return Container(
              color: Colors.black,
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      "URL: ${video['video_url']}", 
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 20,
                    child: Text(
                      video['title'] ?? 'REDACTED DATA',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // What to show while loading
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        // What to show if Supabase blocks us
        error: (err, stack) => Center(
          child: Text("ACCESS DENIED: $err", style: const TextStyle(color: Colors.red)),
        ),
      ),
      // The "Wish" Button (Agent Portal)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white10,
        shape: const StadiumBorder(side: BorderSide(color: Colors.greenAccent, width: 1)),
        onPressed: () => print("Wish Requested"),
        child: const Icon(Icons.auto_awesome, color: Colors.greenAccent),
      ),
    );
  }
}