import 'package:flutter/material.dart';
import 'api_config.dart';
import 'services/bharat_one_pay_api.dart';
import 'screens/app_lock_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Custom error handler so unexpected widget errors show cleanly instead of white screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFFF671F), size: 48),
              const SizedBox(height: 16),
              const Text(
                'AikSetra Secure Engine Initialized',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Launch UI immediately without waiting for network sockets
  runApp(const AikSetraApp());

  // Detect server host in background asynchronously
  Future.microtask(() async {
    try {
      await ApiConfig.detectAndSetHost();
    } catch (_) {}
  });
}

class AikSetraApp extends StatelessWidget {
  const AikSetraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AikSetra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF671F), // Saffron
          primary: const Color(0xFFFF671F),
          secondary: const Color(0xFF046A38), // Green
          surface: const Color(0xFF0F172A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        canvasColor: const Color(0xFF0F172A),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      home: BharatOnePayApi.isLoggedIn ? const AppLockScreen() : const LoginScreen(),
    );
  }
}
