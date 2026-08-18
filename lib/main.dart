import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';
import 'services/history_service.dart';
import 'screens/calculator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HistoryService.init(); // sets up Hive before the app starts
  runApp(const PreviewApp());
}

/// Outer wrapper that shows the real app inside an iPhone 13 device frame.
/// This is purely a visual preview shell (handy for Chrome/desktop testing
/// or screenshots) — on a real iPhone, the app will just fill the screen
/// as normal since there's no frame around a physical device.
class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        body: Center(
          child: DeviceFrame(
            device: Devices.ios.iPhone13,
            isFrameVisible: true,
            orientation: Orientation.portrait,
            screen: Builder(
              builder: (deviceContext) => MaterialApp(
                debugShowCheckedModeBanner: false,
                useInheritedMediaQuery: true,
                theme: ThemeData.dark(),
                home: const CalculatorScreen(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}