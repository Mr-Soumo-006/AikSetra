import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Primary LAN IP of the PC on Wi-Fi / Ethernet
  static String lanIp = '192.168.29.218';

  // Active host used for HTTP calls
  static String activeHost = '192.168.29.218';

  // Candidate hosts to try automatically (Emulator, LAN Wi-Fi, Hotspot, Firewall-Free Tunnel, USB)
  static List<String> get candidateHosts {
    final list = <String>[
      activeHost,
      '192.168.29.218',
      lanIp,
      '192.168.29.90',
      '192.168.137.1',
      '10.0.2.2',
      'https://aiksetra-npci-soumo.loca.lt',
      '127.0.0.1',
    ];
    final seen = <String>{};
    return list.where((h) => h.isNotEmpty && seen.add(h)).toList();
  }

  static Future<void> loadSavedHost() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('aiksetra_backend_host');
      if (saved != null && saved.trim().isNotEmpty) {
        setCustomHost(saved.trim(), persist: false);
      }
    } catch (_) {}
  }

  static void setCustomHost(String host, {bool persist = true}) {
    final clean = host.trim();
    if (clean.isEmpty) return;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      activeHost = clean.replaceAll(RegExp(r'/$'), '');
    } else {
      final stripped = clean.split(':').first;
      if (stripped.isNotEmpty) {
        lanIp = stripped;
        activeHost = stripped;
      }
    }
    if (persist) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('aiksetra_backend_host', activeHost);
      }).catchError((_) {});
    }
  }

  // Non-blocking background probe for fastest reachable host
  static Future<void> detectAndSetHost() async {
    if (!Platform.isAndroid) {
      activeHost = 'localhost';
      return;
    }
    await loadSavedHost();
    for (final host in [activeHost, '192.168.29.218', '192.168.29.90', '192.168.137.1', '10.0.2.2']) {
      try {
        final socket = await Socket.connect(host, 4000, timeout: const Duration(milliseconds: 400));
        socket.destroy();
        activeHost = host;
        return;
      } catch (_) {}
    }
    // If local LAN sockets are blocked by Windows Public Firewall, use the tunnel bridge
    activeHost = 'https://aiksetra-npci-soumo.loca.lt';
  }

  static String baseUrlForHost(String host) {
    if (host.startsWith('http://') || host.startsWith('https://')) {
      return '$host/api/v1';
    }
    return 'http://$host:4000/api/v1';
  }

  static String get baseUrl {
    if (Platform.isAndroid) {
      return baseUrlForHost(activeHost);
    } else {
      return 'http://localhost:4000/api/v1';
    }
  }

  static String get webSocketSoundboxUrl {
    if (Platform.isAndroid) {
      if (activeHost.startsWith('https://')) {
        return '${activeHost.replaceFirst('https://', 'wss://')}/ws/soundbox';
      }
      return 'ws://$activeHost:4000/ws/soundbox';
    } else {
      return 'ws://localhost:4000/ws/soundbox';
    }
  }

  static const String defaultDevUserId = 'usr_simo_01';
}
