import 'dart:io';

class ApiConfig {
  // Primary IP of your PC on local Wi-Fi / Ethernet
  static String lanIp = '192.168.29.90';

  // Active host chosen at runtime
  static String activeHost = '10.0.2.2';

  // Automatically detects if running in Emulator (10.0.2.2) or on a physical phone (LAN IP)
  static Future<void> detectAndSetHost() async {
    if (!Platform.isAndroid) {
      activeHost = 'localhost';
      return;
    }
    try {
      // Test if Android Studio emulator host 10.0.2.2 is reachable
      final socket = await Socket.connect('10.0.2.2', 4000, timeout: const Duration(milliseconds: 700));
      socket.destroy();
      activeHost = '10.0.2.2';
    } catch (_) {
      // Running on a real physical phone: use PC's LAN IP
      activeHost = lanIp;
    }
  }

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://$activeHost:4000/api/v1';
    } else {
      return 'http://localhost:4000/api/v1';
    }
  }

  static String get webSocketSoundboxUrl {
    if (Platform.isAndroid) {
      return 'ws://$activeHost:4000/ws/soundbox';
    } else {
      return 'ws://localhost:4000/ws/soundbox';
    }
  }

  // Active Dev User fallback if no JWT stored
  static const String defaultDevUserId = 'usr_simo_01';
}
