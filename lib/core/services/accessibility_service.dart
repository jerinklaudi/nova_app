import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  // Initialize TTS settings
  Future<void> init() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slower for clarity
    await _flutterTts.setPitch(1.0);
  }

  // The main function to Speak + Vibrate
  Future<void> speakAndVibrate(String text) async {
    // 1. Vibrate (Haptic Feedback)
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50); // Short tick
    }

    // 2. Stop previous speech and speak new text
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  // For Emergency (Longer vibration)
  Future<void> triggerEmergencyFeedback() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000); // 1 second vibration
    }
    await _flutterTts.speak("Emergency Alert Activated. Contacting Support.");
  }
}
