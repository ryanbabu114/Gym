import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExercisePage extends StatefulWidget {
  @override
  _ExercisePageState createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  File? _selectedVideo;
  bool isUploading = false;
  List<Map<String, dynamic>> _exercises = [];

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    final response = await _supabase.from('exercises').select();
    setState(() {
      _exercises = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideo = File(result.files.single.path!);
      });
    }
  }

  Future<String?> _uploadVideo(File videoFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = 'exercise-videos/${user.id}/$fileName';

      await _supabase.storage.from('exercise-videos').upload(filePath, videoFile);
      // ✅ Updated: Use signed URL instead of public URL
      final videoUrl = await _supabase.storage.from('exercise-videos').createSignedUrl(filePath, 60 * 60 * 24);
      return videoUrl;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  Future<void> _addExercise() async {
    if (_nameController.text.isEmpty || _detailsController.text.isEmpty || _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a video.')),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final videoUrl = await _uploadVideo(_selectedVideo!);
      if (videoUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video upload failed. Try again.')),
        );
        return;
      }

      await _supabase.from('exercises').insert({
        'trainer_id': _supabase.auth.currentUser!.id,
        'exercise_name': _nameController.text.trim(),
        'details': _detailsController.text.trim(),
        'video_url': videoUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise added successfully!')),
      );
      _nameController.clear();
      _detailsController.clear();
      setState(() => _selectedVideo = null);
      _fetchExercises();
    } catch (e) {
      print("Error: $e");
    }

    setState(() => isUploading = false);
  }

  void _navigateToExerciseDetail(Map<String, dynamic> exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExerciseDetailPage(exercise: exercise)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Tracker'),
        backgroundColor: Colors.indigo[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Exercise Name')),
            TextField(controller: _detailsController, decoration: const InputDecoration(labelText: 'Exercise Details')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickVideo,
              child: const Text('Select Video'),
            ),
            _selectedVideo != null
                ? Text('Selected: ${_selectedVideo!.path.split('/').last}')
                : const Text('No video selected'),
            const SizedBox(height: 20),
            isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _addExercise,
              child: const Text('Add Exercise'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return ListTile(
                    title: Text(exercise['exercise_name']),
                    subtitle: Text(exercise['details']),
                    onTap: () => _navigateToExerciseDetail(exercise),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseDetailPage extends StatefulWidget {
  final Map<String, dynamic> exercise;

  ExerciseDetailPage({required this.exercise});

  @override
  _ExerciseDetailPageState createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("Video URL: ${widget.exercise['video_url']}");
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.exercise['video_url']))


        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
            _isLoading = false;
          });
          _controller.play();
        }).catchError((error) {
          setState(() => _isLoading = false);
          print("Video loading error: $error");
        });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error initializing video: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise['exercise_name'])),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exercise['details'], style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _isVideoInitialized
                ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
                : Center(child: Text("Failed to load video")),
          ],
        ),
      ),
    );
  }
}
