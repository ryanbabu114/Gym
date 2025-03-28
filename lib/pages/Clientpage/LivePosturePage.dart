import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LivePosturePage extends StatefulWidget {
  @override
  _LivePosturePageState createState() => _LivePosturePageState();
}

class _LivePosturePageState extends State<LivePosturePage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  String _postureResult = "Waiting for analysis...";
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras![0], ResolutionPreset.medium);
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _captureAndSendFrame() async {
    if (!_isStreaming || _cameraController == null) return;

    try {
      final XFile file = await _cameraController!.takePicture();
      File imageFile = File(file.path);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.2:5000/posture-correction'), // Replace with your Flask API IP
      );

      request.files.add(await http.MultipartFile.fromPath('frame', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      setState(() {
        _postureResult = jsonResponse['status'] == 'success'
            ? jsonResponse['posture'] + " - " + jsonResponse['corrections'].join(", ")
            : "No posture detected";
      });
    } catch (e) {
      print("Error sending frame: $e");
    }
  }

  void _startStreaming() {
    _isStreaming = true;
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isStreaming) {
        timer.cancel();
      } else {
        _captureAndSendFrame();
      }
    });
  }

  void _stopStreaming() {
    _isStreaming = false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Posture Correction")),
      body: Column(
        children: [
          _cameraController != null && _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : CircularProgressIndicator(),
          SizedBox(height: 10),
          Text(_postureResult, style: TextStyle(fontSize: 18)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startStreaming,
            child: Text("Start Posture Analysis"),
          ),
          ElevatedButton(
            onPressed: _stopStreaming,
            child: Text("Stop"),
          ),
        ],
      ),
    );
  }
}
