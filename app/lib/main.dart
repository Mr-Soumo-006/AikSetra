import 'package:flutter/material.dart';
import 'api_config.dart';
import 'services/bharat_one_pay_api.dart';
import 'screens/app_lock_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AikSetraApp());

  Future.microtask(() async {
    try {
      await ApiConfig.detectAndSetHost();
    } catch (_) {}
  });
}

class AikSetraApp extends StatefulWidget {
  const AikSetraApp({super.key});

  @override
  State<AikSetraApp> createState() => _AikSetraAppState();
}

class _AikSetraAppState extends State<AikSetraApp> {
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final ok = await BharatOnePayApi.restoreSessionFromDisk();
    if (ok && mounted) {
      setState(() => _restored = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AikSetra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF671F),
          primary: const Color(0xFFFF671F),
          secondary: const Color(0xFF046A38),
          surface: const Color(0xFFF8FAFC),
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      home: (_restored || BharatOnePayApi.isLoggedIn)
          ? const AppLockScreen()
          : const LoginScreen(),
    );
  }
}
