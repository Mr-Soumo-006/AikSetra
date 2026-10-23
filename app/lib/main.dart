import 'package:flutter/material.dart';
import 'api_config.dart';
import 'services/bharat_one_pay_api.dart';
import 'screens/app_lock_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.detectAndSetHost();
  runApp(const AikSetraApp());
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
          surface: const Color(0xFFF8FAFC),
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      home: BharatOnePayApi.isLoggedIn ? const AppLockScreen() : const LoginScreen(),
    );
  }
}
