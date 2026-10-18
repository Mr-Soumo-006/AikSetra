import 'dart:io';

class ApiConfig {
  // Use 10.0.2.2 for Android Studio Emulator, localhost for iOS simulator or web
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000/api/v1';
    } else {
      return 'http://localhost:4000/api/v1';
    }
  }

  static String get webSocketSoundboxUrl {
    if (Platform.isAndroid) {
      return 'ws://10.0.2.2:4000/ws/soundbox';
    } else {
      return 'ws://localhost:4000/ws/soundbox';
    }
  }

  // Active Dev User fallback if no JWT stored
  static const String defaultDevUserId = 'usr_simo_01';
}
