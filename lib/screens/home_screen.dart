import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_tts/flutter_tts.dart'; // ✨ NEW: Import TTS

import '../core/services/camera_service.dart';
import '../core/services/object_detection_service.dart';
import '../core/services/face_detection_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CameraService _cameraService = GetIt.instance<CameraService>();
  final ObjectDetectionService _objectService =
      GetIt.instance<ObjectDetectionService>();
  final FaceDetectionService _faceService = FaceDetectionService();

  // ✨ NEW: Text To Speech Instance
  final FlutterTts _flutterTts = FlutterTts();

  bool _isCameraInitialized = false;
  int _currentModeIndex = 1;
  List<Map<String, dynamic>> _detections = [];
  bool _isProcessingFrame = false;
  int _frameCounter = 0;

  // ✨ NEW: Flashlight state
  bool _isFlashOn = false;

  // ✨ NEW: Speaking throttling to prevent voice spam
  String _lastLabelSpoken = "";
  DateTime _lastSpeakTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _cameraService.initialize();
    await _objectService.initialize();
    await _faceService.initialize();

    // ✨ NEW: Initialize TTS settings
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slower speed for clarity
    await _flutterTts.setPitch(1.0);

    if (mounted) {
      setState(() => _isCameraInitialized = true);

      _cameraService.controller!.startImageStream((CameraImage image) async {
        _frameCounter++;

        // 0. STOP if in Read Mode (Save battery)
        if (_currentModeIndex == 0) return;

        // 1. THROTTLE: Process every 10th frame
        if (_frameCounter % 10 != 0) return;

        if (_isProcessingFrame) return;
        _isProcessingFrame = true;

        try {
          List<Map<String, dynamic>> finalResults = [];

          // ---------------------------------------------------------
          // ✨ NEW: COMBINED MODE (Index 1)
          // ---------------------------------------------------------
          if (_currentModeIndex == 1) {
            // A. Run Object Detection
            try {
              final objects = await _objectService.processFrame(image);
              if (objects.isNotEmpty) {
                print("📦 OBJECTS FOUND: ${objects.length}"); // DEBUG LOG
                finalResults.addAll(objects);
              }
            } catch (e) {
              print("❌ Object Detection Error: $e");
            }

            /*// B. Run Face Detection
            try {
              final faces = await _faceService.processFrame(image);
              if (faces.isNotEmpty) {
                print("😀 FACES FOUND: ${faces.length}"); // DEBUG LOG
                finalResults.addAll(faces);
              }
            } catch (e) {
              print("❌ Face Detection Error: $e");
            }
            */

            // C. Speak Results
            if (finalResults.isNotEmpty) {
              String labelToSpeak = finalResults.first['tag'];
              _speakLabel(labelToSpeak);
            } else {
              // print("Total results empty this frame");
            }
          }

          if (mounted) {
            setState(() {
              _detections = finalResults;
            });
          }
        } catch (e) {
          debugPrint("General Error: $e");
        } finally {
          _isProcessingFrame = false;
        }
      });
    }
  }

  // ✨ NEW: Smart Speaking Logic
  void _speakLabel(String label) async {
    // 1. Don't repeat the same word instantly (wait 2 seconds)
    // 2. Or speak immediately if it's a NEW object
    if (label != _lastLabelSpoken ||
        DateTime.now().difference(_lastSpeakTime).inSeconds > 2) {
      _lastLabelSpoken = label;
      _lastSpeakTime = DateTime.now();
      await _flutterTts.speak(label);
    }
  }

  @override
  void dispose() {
    if (_cameraService.controller != null &&
        _cameraService.controller!.value.isStreamingImages) {
      _cameraService.controller!.stopImageStream();
    }
    _objectService.dispose();
    _faceService.dispose();
    _flutterTts.stop(); // Stop speaking on exit
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("NOVA VISION",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()))),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primary),
              accountName: Text("Demo User"),
              accountEmail: Text("vision@nova.ai"),
              currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white, child: Icon(Icons.person)),
            ),
            ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text("Settings",
                    style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. Camera Feed
          // 1. Camera Feed (FIXED)
          if (_isCameraInitialized && _cameraService.controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  // We use the actual size of the camera sensor to prevent stretching
                  width: _cameraService.controller!.value.previewSize!.height,
                  height: _cameraService.controller!.value.previewSize!.width,
                  child: CameraPreview(_cameraService.controller!),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // 2. READ MODE OVERLAYS
          if (_currentModeIndex == 0) ...[
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6), BlendMode.srcOut),
              child: Stack(
                children: [
                  Container(
                      decoration: const BoxDecoration(
                          color: Colors.transparent,
                          backgroundBlendMode: BlendMode.dstOut)),
                  Center(
                    child: Container(
                      width: 320,
                      height: 180,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                width: 320,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Align Text Here",
                        style: TextStyle(
                            color: Colors.cyanAccent,
                            backgroundColor: Colors.black54)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white, size: 30),
                onPressed: () {
                  setState(() {
                    _isFlashOn = !_isFlashOn;
                    _cameraService.controller?.setFlashMode(
                        _isFlashOn ? FlashMode.torch : FlashMode.off);
                  });
                },
              ),
            ),
          ],

          // 3. DETECT MODE OVERLAYS
          if (_isCameraInitialized && _currentModeIndex != 0)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: BoundingBoxPainter(
                    detections: _detections, color: _getModeColor()),
              ),
            ),

          // ✨ NEW: ON-SCREEN DEBUGGER (Visible in Detect Mode)
          if (_currentModeIndex != 0)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.black54,
                  child: Text(
                    "AI Status: Found ${_detections.length} objects",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          // 4. Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF121212).withOpacity(0.9),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(
                children: [
                  if (_currentModeIndex == 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("📸 Scanning Text...")));
                        },
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.cyan,
                          child: const Icon(Icons.camera_alt,
                              color: Colors.black, size: 30),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: _getModeColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _getModeColor(), width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: _getModeColor()),
                          const SizedBox(width: 10),
                          Text(
                            _getBannerText(),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getModeColor()),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModeBtn(Icons.menu_book, "READ", 0),
                      _buildModeBtn(Icons.remove_red_eye, "SMART DETECT", 1),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBannerText() {
    if (_currentModeIndex == 0) return "Mode: Text Reader";
    if (_detections.isEmpty) return "Scanning surroundings...";
    return "Found: ${_detections[0]['tag']} (${_detections.length} items)";
  }

  Color _getModeColor() {
    if (_currentModeIndex == 0) return Colors.cyan;
    if (_currentModeIndex == 2) return Colors.green;
    return AppTheme.warning;
  }

  Widget _buildModeBtn(IconData icon, String label, int index) {
    bool isActive = _currentModeIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentModeIndex = index;
          _detections = [];
          // Stop speaking when switching modes
          _flutterTts.stop();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _getModeColor() : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive ? _getModeColor() : Colors.grey, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.black : Colors.white, size: 28),
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ✨ UPDATED PAINTER CLASS
class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Color color;

  BoundingBoxPainter({required this.detections, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // --- DEBUG: DRAW A RED BORDER AROUND SCREEN ---
    // If you don't see this red border, the CustomPaint is hidden!
    final debugPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), debugPaint);
    // ----------------------------------------------

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (var detection in detections) {
      // ⚠️ Check if your Service uses 'box' or 'rect' as the key
      if (!detection.containsKey('box')) continue;

      final List<dynamic> box = detection['box'];

      double x1 = box[0].toDouble();
      double y1 = box[1].toDouble();
      double x2 = box[2].toDouble();
      double y2 = box[3].toDouble();

      // LOGIC: Normalize Coordinates
      // If the model returns values between 0.0 and 1.0 (MLKit), we multiply by screen size.
      // If the model returns pixels (YOLO sometimes), we assume it matches the image.

      // Case 1: Normalized (0.0 - 1.0) -> Scale up
      if (x2 <= 2.0 && y2 <= 2.0) {
        x1 *= size.width;
        y1 *= size.height;
        x2 *= size.width;
        y2 *= size.height;
      }
      // Case 2: Large Pixels (e.g., 640x480) -> Scale to fit screen
      // This is a rough fix for different aspect ratios
      else if (x2 > size.width || y2 > size.height) {
        // If boxes are HUGE, we might need to scale them down (optional logic)
        // For now, let's leave them as absolute pixels.
      }

      // Draw Rect
      final rect = Rect.fromLTRB(x1, y1, x2, y2);
      canvas.drawRect(rect, paint);

      // Draw Label
      final String labelText = detection['tag'] ?? 'Unknown';

      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top - 24, textPainter.width + 12, 24),
        bgPaint,
      );
      textPainter.paint(canvas, Offset(rect.left + 6, rect.top - 22));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
