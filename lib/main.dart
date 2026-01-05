import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get_it/get_it.dart';

// Import our new structure
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'core/services/camera_service.dart';
import 'core/services/object_detection_service.dart';

// Dependency Injection Setup (The "Locator")
final locator = GetIt.instance;

void setupLocator() {
  // We register our services so any screen can access them easily
  locator.registerLazySingleton(() => CameraService());
  locator.registerLazySingleton(() => ObjectDetectionService());
}

void main() async {
  // 1. Ensure Flutter engine is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Lock Orientation to Portrait (Important for accessibility stability)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 3. Ask for Camera Permission immediately (Your existing logic)
  await requestCameraPermission();

  // 4. Setup Services
  setupLocator();

  // 5. Start the App
  runApp(const NovaApp());
}

Future<void> requestCameraPermission() async {
  var status = await Permission.camera.status;
  if (!status.isGranted) {
    await Permission.camera.request();
  }
}

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOVA Vision',
      debugShowCheckedModeBanner: false,

      // 🎨 Apply the High Contrast Theme we created
      theme: AppTheme.darkTheme,

      // 🏠 Point to the new "Iron Man" Home Screen
      home: const HomeScreen(),
    );
  }
}
