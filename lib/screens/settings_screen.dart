import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Dummy settings state for the demo
  bool _voiceFeedback = true;
  bool _vibration = true;
  bool _highContrast = true;
  bool _autoFlash = false;
  double _speechRate = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SETTINGS",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("AUDIO & VOICE"),
          _buildSwitch("Voice Feedback", "Read out detected objects",
              _voiceFeedback, (v) => setState(() => _voiceFeedback = v)),
          const SizedBox(height: 16),
          Text(
            "Speaking Rate: ${_speechRate.toStringAsFixed(1)}x",
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          Slider(
            value: _speechRate,
            min: 0.5,
            max: 2.0,
            divisions: 6,
            activeColor: AppTheme.primary,
            inactiveColor: Colors.grey[800],
            onChanged: (val) => setState(() => _speechRate = val),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("HAPTICS & ALERTS"),
          _buildSwitch("Vibration Alerts", "Vibrate on obstacle detection",
              _vibration, (v) => setState(() => _vibration = v)),
          const SizedBox(height: 24),
          _buildSectionHeader("VISION AID"),
          _buildSwitch("High Contrast Mode", "Increase UI visibility",
              _highContrast, (v) => setState(() => _highContrast = v)),
          _buildSwitch("Auto-Flashlight", "Turn on light in dark areas",
              _autoFlash, (v) => setState(() => _autoFlash = v)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Settings Reset")));
              },
              child: const Text("RESET ALL SETTINGS",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitch(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? AppTheme.primary : Colors.grey[800]!),
      ),
      child: SwitchListTile(
        activeColor: AppTheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
