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
      // ⚡ CHANGED TO LOW.
      // This creates a small image (320x240) that fits perfectly into the AI's memory.
      // This solves the "4915200 bytes" crash.
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller!.initialize();
  }

  void dispose() {
    controller?.dispose();
  }
}
