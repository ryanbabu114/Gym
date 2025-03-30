import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class ExercisesScreen extends StatefulWidget {
  @override
  _ExercisesScreenState createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
    try {
      final response = await supabase.from('exercises').select();
      setState(() {
        exercises = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (error) {
      print("❌ Error fetching exercises: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Exercises")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exercises.isEmpty
          ? const Center(child: Text("No exercises found"))
          : ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return ListTile(
            title: Text(exercise['exercise_name'] ?? "N/A"),
            subtitle: Text(exercise['details'] ?? "N/A"),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill),
              onPressed: () {
                if (exercise['video_url'] != null &&
                    exercise['video_url'].isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                          videoUrl: exercise['video_url']),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// 🎬 Video Player Screen (Chewie + VideoPlayer)
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool isVideoReady = false;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  void initializeVideo() async {
    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: true,
        looping: false,
        showControls: true,
      );

      setState(() {
        isVideoReady = true;
      });
    } catch (error) {
      print("❌ Error loading video: $error");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Player")),
      body: Center(
        child: isVideoReady
            ? Chewie(controller: _chewieController!)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            const Text("Loading Video..."),
          ],
        ),
      ),
    );
  }
}
