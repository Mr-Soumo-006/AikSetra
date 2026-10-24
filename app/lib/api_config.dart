import 'dart:io';

class ApiConfig {
  // Primary IP of your PC on local Wi-Fi / Ethernet
  static String lanIp = '192.168.29.90';

  // Active host chosen at runtime
  static String activeHost = '192.168.29.90';

  // Automatically detects reachable host (Phone on Wi-Fi, Hotspot, or Emulator)
  static Future<void> detectAndSetHost() async {
    if (!Platform.isAndroid) {
      activeHost = 'localhost';
      return;
    }
    // Check candidate hosts in priority order
    final candidates = ['192.168.29.90', '192.168.137.1', '10.0.2.2', '127.0.0.1'];
    for (final host in candidates) {
      try {
        final socket = await Socket.connect(host, 4000, timeout: const Duration(milliseconds: 600));
        socket.destroy();
        activeHost = host;
        return;
      } catch (_) {}
    }
    activeHost = '192.168.29.90';
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
