import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'video_model.dart';

final videoListProvider = FutureProvider<List<Video>>((ref) async {
  final response = await Supabase.instance.client
      .from('videos') // Your table name
      .select();
  
  return (response as List).map((map) => Video.fromMap(map)).toList();
});