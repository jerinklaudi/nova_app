import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'activation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(NovaResearchApp(cameras: cameras));
}

class NovaResearchApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  const NovaResearchApp({super.key, required this.cameras});

  @override
  State<NovaResearchApp> createState() => _NovaResearchAppState();
}

class _NovaResearchAppState extends State<NovaResearchApp> {
  bool _isActivated = false;

  void _handleActivation() {
    setState(() => _isActivated = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.yellowAccent,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: _isActivated
          ? NovaMainScreen(
              cameras: widget.cameras,
              onDeactivate: () => setState(() => _isActivated = false))
          : ActivationScreen(onActivated: _handleActivation),
    );
  }
}

class NovaMainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final VoidCallback onDeactivate;
  const NovaMainScreen(
      {super.key, required this.cameras, required this.onDeactivate});

  @override
  State<NovaMainScreen> createState() => _NovaMainScreenState();
}

class _NovaMainScreenState extends State<NovaMainScreen> {
  late CameraController _controller;
  late PageController _modeController;
  final FlutterTts _tts = FlutterTts();

  int _currentModeIndex = 0;
  bool _isCameraInitialized = false;

  final List<String> _modes = ["NAVIGATION", "READING", "RECOGNITION"];
  final List<String> _descriptions = [
    "Detecting obstacles ahead",
    "Point at text to read",
    "Identifying faces and objects"
  ];

  @override
  void initState() {
    super.initState();
    _modeController = PageController(initialPage: 0);
    _initCamera();
    _setupTts();
  }

  // --- TTS SETUP ---
  Future<void> _setupTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    _speak("Nova System Active. Navigation Mode.");
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  // --- CAMERA SETUP ---
  Future<void> _initCamera() async {
    _controller = CameraController(widget.cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _modeController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.black.withOpacity(0.95),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.yellowAccent),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person_pin_circle,
                        size: 60, color: Colors.black),
                    SizedBox(height: 10),
                    Text("USER: JERIN",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                      Icons.face_retouching_natural, "Face Enrollment"),
                  _buildDrawerItem(Icons.people, "Saved Faces"),
                  _buildDrawerItem(Icons.record_voice_over, "Voice Assistant"),
                  _buildDrawerItem(Icons.volume_up, "Audio Settings"),
                  _buildDrawerItem(Icons.contact_phone, "Emergency Contacts"),
                  const Divider(color: Colors.white24),
                  _buildDrawerItem(Icons.menu_book, "Tutorials"),
                  _buildDrawerItem(Icons.info_outline, "About Nova"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. CAMERA PREVIEW
          Positioned.fill(
            child: _isCameraInitialized
                ? CameraPreview(_controller)
                : Container(color: Colors.black),
          ),

          // 2. MODE SWIPER
          PageView.builder(
            controller: _modeController,
            onPageChanged: (index) {
              setState(() => _currentModeIndex = index);
              _speak("${_modes[index]} Mode");
            },
            itemCount: _modes.length,
            itemBuilder: (context, index) =>
                _buildModeOverlay(_modes[index], _descriptions[index]),
          ),

          // 3. TOP NAV BAR
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Builder(
                  builder: (context) => Container(
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10)),
                    child: IconButton(
                      icon: const Icon(Icons.menu_open,
                          color: Colors.yellowAccent, size: 40),
                      onPressed: () {
                        _speak("Opening Settings");
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.yellowAccent, width: 2),
                    ),
                    child: Text(
                      _modes[_currentModeIndex],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. BOTTOM BUTTONS
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  radius: 30,
                  child: IconButton(
                    icon: const Icon(Icons.power_settings_new,
                        color: Colors.black),
                    onPressed: widget.onDeactivate,
                  ),
                ),
                FloatingActionButton.large(
                  backgroundColor: Colors.yellowAccent,
                  onPressed: () => _speak("Listening for commands"),
                  child: const Icon(Icons.mic, size: 50, color: Colors.black),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER METHODS ---
  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 18)),
      onTap: () {
        _speak("Opening $title");
        Navigator.pop(context);
      },
    );
  }

  Widget _buildModeOverlay(String title, String desc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Spacer(),
        Container(
          width: double.infinity,
          color: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
        ),
        const SizedBox(height: 140),
      ],
    );
  }
}
