import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  FaceDetector? _faceDetector;
  bool _isBusy = false;

  Future<void> initialize() async {
    // High-performance mode for video streams
    final options = FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<List<Map<String, dynamic>>> processFrame(
      CameraImage cameraImage) async {
    if (_faceDetector == null || _isBusy) return [];
    _isBusy = true;

    try {
      final inputImage = _convertCameraImage(cameraImage);
      if (inputImage == null) return [];

      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      List<Map<String, dynamic>> results = [];
      for (Face face in faces) {
        final rect = face.boundingBox;
        results.add({
          "tag": "Face", // Always tag as "Face"
          "box": [rect.left, rect.top, rect.width, rect.height],
        });
      }
      _isBusy = false;
      return results;
    } catch (e) {
      _isBusy = false;
      return [];
    }
  }

  // Reuse the same image converter logic
  InputImage? _convertCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final imageRotation = InputImageRotation.rotation90deg;
    final inputImageFormat = InputImageFormat.nv21;

    final inputImageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  void dispose() {
    _faceDetector?.close();
  }
}
