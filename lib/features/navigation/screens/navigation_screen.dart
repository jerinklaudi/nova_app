import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:nova_app/core/services/camera_service.dart';
import 'package:nova_app/core/services/object_detection_service.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final CameraService _cameraService = CameraService();
  final ObjectDetectionService _objectDetectionService =
      ObjectDetectionService();

  bool _isDetecting = false;
  List<Map<String, dynamic>> _detectedObjects = [];
  int _frameCounter = 0;

  @override
  void initState() {
    super.initState();
    print(
        "🚀 NAV SCREEN: Starting Initialization..."); // LOOK FOR THIS IN CONSOLE
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    try {
      await _cameraService.initialize();
      print("✅ NAV SCREEN: Camera is Ready");

      await _objectDetectionService.initialize();
      print("✅ NAV SCREEN: Object Detection Brain is Ready");

      _startScanning();
    } catch (e) {
      print("❌ NAV SCREEN ERROR: $e");
    }
  }

  void _startScanning() {
    if (_cameraService.controller == null) return;

    print("🚀 NAV SCREEN: Starting Video Stream...");
    _cameraService.controller!.startImageStream((CameraImage image) async {
      _frameCounter++;
      // Print a dot every 30 frames so we know it's alive
      if (_frameCounter % 30 == 0) print("... video stream active ...");

      if (_frameCounter % 5 != 0) return; // Skip frames for speed
      if (_isDetecting) return;

      _isDetecting = true;
      try {
        print("🔍 NAV SCREEN: Scanning for objects...");
        final results = await _objectDetectionService.processFrame(image);

        if (results.isNotEmpty) {
          print("🎯 FOUND OBJECTS: $results"); // 👈 THIS IS WHAT WE WANT
        } else {
          print("👀 Scanning... nothing found.");
        }

        if (mounted) {
          setState(() {
            _detectedObjects = results;
          });
        }
      } catch (e) {
        print("❌ DETECTION ERROR: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _objectDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraService.controller == null ||
        !_cameraService.controller!.value.isInitialized) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(
            width: size.width,
            height: size.height,
            child: CameraPreview(_cameraService.controller!),
          ),
          ..._detectedObjects.map((obj) {
            final box = obj["box"];
            return Positioned(
              left: box[0] * size.width,
              top: box[1] * size.height,
              width: (box[2] - box[0]) * size.width,
              height: (box[3] - box[1]) * size.height,
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.yellow, width: 3)),
                child: Text(
                  "${obj['tag']}",
                  style: const TextStyle(
                      backgroundColor: Colors.yellow, color: Colors.black),
                ),
              ),
            );
          }).toList(),
          Positioned(
            top: 40,
            left: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.yellow,
              child: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
