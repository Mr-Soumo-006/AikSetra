import 'dart:io';

class ApiConfig {
  // Primary LAN IP of the PC on Wi-Fi / Ethernet
  static String lanIp = '192.168.29.90';

  // Active host used for HTTP calls
  static String activeHost = '192.168.29.90';

  // Candidate hosts to try automatically (Emulator, LAN Wi-Fi, Hotspot, Firewall-Free Tunnel, USB)
  static List<String> get candidateHosts {
    final list = <String>[
      activeHost,
      '10.0.2.2',
      lanIp,
      '192.168.29.90',
      '192.168.137.1',
      'https://aiksetra-npci-soumo.loca.lt',
      '127.0.0.1',
    ];
    final seen = <String>{};
    return list.where((h) => h.isNotEmpty && seen.add(h)).toList();
  }

  static void setCustomHost(String host) {
    final clean = host.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      activeHost = clean.replaceAll(RegExp(r'/$'), '');
      return;
    }
    final stripped = clean.split(':').first;
    if (stripped.isNotEmpty) {
      lanIp = stripped;
      activeHost = stripped;
    }
  }

  // Non-blocking background probe for fastest reachable host
  static Future<void> detectAndSetHost() async {
    if (!Platform.isAndroid) {
      activeHost = 'localhost';
      return;
    }
    for (final host in ['10.0.2.2', '192.168.29.90', '192.168.137.1']) {
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
