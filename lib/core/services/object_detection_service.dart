import 'dart:io'; // For Platform check
import 'package:flutter/foundation.dart'; // For WriteBuffer
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter/services.dart'; // Sometimes needed for device orientation

class ObjectDetectionService {
  ObjectDetector? _objectDetector;
  bool _isModelLoaded = false;

  Future<void> initialize() async {
    print("🔧 Starting Google ML Kit Object Detector...");

    try {
      final options = ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      );

      _objectDetector = ObjectDetector(options: options);
      _isModelLoaded = true;

      print("✅ Google ML Kit Object Detector Ready!");
    } catch (e, stackTrace) {
      print("❌ ML Kit initialization failed: $e");
      print("Stack: $stackTrace");
      _isModelLoaded = false;
    }
  }

  Future<List<Map<String, dynamic>>> processFrame(
      CameraImage cameraImage) async {
    if (!_isModelLoaded || _objectDetector == null) {
      print("⚠️ Model not loaded or detector is null");
      return [];
    }

    try {
      print(
          "📸 Processing Frame: ${cameraImage.width}x${cameraImage.height} | Format: ${cameraImage.format.group}");

      // 1. Convert CameraImage to InputImage (The Fix is in here)
      final inputImage = _inputImageFromCameraImage(cameraImage);

      if (inputImage == null) {
        print("❌ InputImage conversion returned null");
        return [];
      }

      // 2. Run Detection
      print("🔍 Sending to ML Kit...");
      final List<DetectedObject> objects =
          await _objectDetector!.processImage(inputImage);
      print("⚡ ML Kit returned ${objects.length} raw objects");

      List<Map<String, dynamic>> detections = [];

      for (var obj in objects) {
        final rect = obj.boundingBox;
        String label = 'unknown';
        double confidence = 0.0;

        if (obj.labels.isNotEmpty) {
          final topLabel = obj.labels.first;
          label = topLabel.text; // Use .text directly from ML Kit
          confidence = topLabel.confidence;
        }

        print("   -> Found: $label ($confidence)");

        detections.add({
          'tag': label,
          'conf': confidence,
          'box': [
            rect.left /
                cameraImage
                    .height, // Note: width/height often swapped in portrait
            rect.top / cameraImage.width,
            rect.right / cameraImage.height,
            rect.bottom / cameraImage.width,
          ],
        });
      }

      return detections;
    } catch (e, stack) {
      print("❌ Detection Error Details: $e");
      print("❌ Stack: $stack");
      return [];
    }
  }

  // ==========================================
  // 🛠️ THE FIX: Correct Image Conversion Logic
  // ==========================================
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // 1. Get the correct rotation
    final camera = cameras[0]; // Assuming using the first camera (back)
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    // 2. Get the format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Validate format (NV21 is default for Android, BGRA8888 for iOS)
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      // Optional: Handle other formats or return null
      // return null;
    }

    // 3. Concatenate the bytes from all planes
    // This is required because CameraImage splits data into planes (Y, U, V),
    // but ML Kit expects a single block of bytes.
    if (image.planes.length != 1 && format != InputImageFormat.nv21) {
      return null;
    }

    // Helper to concatenate planes
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // 4. Create the InputImage
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // The rotation calculated above
        format: format ?? InputImageFormat.nv21, // default to nv21 if null
        bytesPerRow: image.planes[0]
            .bytesPerRow, // <--- THE FIX: Use the first plane's stride
      ),
    );
  }

  Future<void> dispose() async {
    _objectDetector?.close();
    _objectDetector = null;
  }
}
