import 'package:flutter/material.dart';
import 'package:shake/shake.dart'; // This will turn green once 'pub get' works

class ActivationScreen extends StatefulWidget {
  final VoidCallback onActivated;
  const ActivationScreen({super.key, required this.onActivated});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  bool _isAppRunning = false;
  // Use a nullable type to avoid initialization errors
  ShakeDetector? detector;

  @override
  void initState() {
    super.initState();

    // Initializing the shake listener
    detector = ShakeDetector.autoStart(
      onPhoneShake: () {
        _toggleActivation();
      },
      shakeThresholdGravity: 2.7,
    );
  }

  void _toggleActivation() {
    setState(() {
      _isAppRunning = !_isAppRunning;
    });

    // Callback to tell the main app to start/stop the camera and AI
    if (_isAppRunning) {
      widget.onActivated();
    }
  }

  @override
  void dispose() {
    // Crucial for performance: stop the listener when screen is destroyed
    detector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Icon
            Icon(
              _isAppRunning ? Icons.power_settings_new : Icons.power_off,
              size: 120,
              color: _isAppRunning ? Colors.yellowAccent : Colors.white24,
            ),
            const SizedBox(height: 30),

            // Status Text
            Text(
              _isAppRunning ? "NOVA ACTIVE" : "NOVA STANDBY",
              style: TextStyle(
                color: _isAppRunning ? Colors.yellowAccent : Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 60),

            // Huge Activation Button
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isAppRunning ? Colors.redAccent : Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 10,
                ),
                onPressed: _toggleActivation,
                child: Text(
                  _isAppRunning ? "DEACTIVATE" : "ACTIVATE",
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Text(
              "SHAKE TO TOGGLE",
              style: TextStyle(
                  color: Colors.white38, fontSize: 16, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
