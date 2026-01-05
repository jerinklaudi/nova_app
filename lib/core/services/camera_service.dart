import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraService {
  CameraController? controller;

  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    controller = CameraController(
      firstCamera,
      ResolutionPreset.low,  // Low resolution to prevent memory crash
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,  // YUV420 format for YOLO
    );

    await controller!.initialize();
    // No rotation lock here, to prevent the sideways screen issue.
  }

  void dispose() {
    controller?.dispose();
  }
}
