import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:nova_app/core/services/camera_service.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({Key? key}) : super(key: key);

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  final CameraService _cameraService = CameraService();
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 1. APP BAR
      appBar: AppBar(
        title: const Text("READ MODE",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.yellowAccent, // Yellow text/icons
        elevation: 0,
      ),

      // 2. MAIN BODY (Camera + Overlays)
      body: Stack(
        children: [
          // A. The Camera Feed
          if (_isCameraInitialized)
            SizedBox.expand(
              child: CameraPreview(_cameraService.controller!),
            )
          else
            const Center(
                child: CircularProgressIndicator(color: Colors.yellowAccent)),

          // B. The "Dimmer" Overlay (Darkens edges to focus attention)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 300,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // C. The Yellow Focus Box (Visual Guide)
          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellowAccent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  "Align Text Here",
                  style: TextStyle(
                      color: Colors.yellowAccent,
                      backgroundColor: Colors.black54,
                      fontSize: 16),
                ),
              ),
            ),
          ),

          // D. Bottom Control Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              color: Colors.black.withOpacity(0.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flashlight Button
                  IconButton(
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

                  // CAPTURE BUTTON (The Big One)
                  GestureDetector(
                    onTap: () {
                      print("📸 Snap! Scanning text...");
                      // We will add the text recognition logic here later
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.black, size: 40),
                    ),
                  ),

                  // Settings / Gallery Placeholder
                  IconButton(
                    icon: const Icon(Icons.settings,
                        color: Colors.white, size: 30),
                    onPressed: () {
                      // Navigate to settings
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
