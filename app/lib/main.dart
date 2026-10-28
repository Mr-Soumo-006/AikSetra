import 'package:flutter/material.dart';
import 'api_config.dart';
import 'services/bharat_one_pay_api.dart';
import 'services/theme_manager.dart';
import 'screens/app_lock_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.init();
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'AikSetra',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF671F),
              primary: const Color(0xFFFF671F),
              secondary: const Color(0xFF046A38),
              surface: const Color(0xFFF8FAFC),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'sans-serif',
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF090D16),
            cardColor: const Color(0xFF131B2E),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF671F),
              secondary: Color(0xFF10B981),
              surface: Color(0xFF131B2E),
              onSurface: Colors.white,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'sans-serif',
          ),
          home: (_restored || BharatOnePayApi.isLoggedIn)
              ? const AppLockScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
