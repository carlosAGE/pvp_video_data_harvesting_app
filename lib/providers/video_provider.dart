import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// The "State" Provider: This tells the app to go fetch your videos
final videoListProvider = FutureProvider<List<dynamic>>((ref) async {
  return await Supabase.instance.client
      .from('videos') // Make sure your table is named 'videos'
      .select();
});