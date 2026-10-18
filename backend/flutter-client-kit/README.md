# 📱 Bharat One Pay - Flutter Integration Kit

This directory contains pre-built Dart models, API client services, and architectural guidelines for the Flutter development team building the **Bharat One Pay** Android & iOS apps.

---

## 🚀 Quick Setup for Flutter Team

### 1. Add Dependencies in your `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  web_socket_channel: ^3.0.0
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.0.0
```

### 2. Copy the Client Kit
Copy the `lib/models/`, `lib/services/`, and `lib/api_config.dart` into your Flutter app's `lib/` folder.

### 3. Base URL Resolution
In `lib/api_config.dart`:
- **Android Emulator**: Automatically routes to `http://10.0.2.2:4000/api/v1`
- **iOS Simulator / Desktop**: Automatically routes to `http://localhost:4000/api/v1`
- **Physical Device**: Replace with your development machine's local Wi-Fi IP (e.g. `http://192.168.1.15:4000/api/v1`).

---

## 🛡️ Scam Shield Integration Flow in Flutter

Always invoke `BharatOnePayApi.analyzeScamRisk()` **before** asking the user for their UPI MPIN:

```dart
import 'package:flutter/material.dart';
import 'services/bharat_one_pay_api.dart';
import 'models/scam_shield_model.dart';

Future<void> onPayButtonPressed(BuildContext context, String vpa, double amount, String note) async {
  // Step 1: Pre-Payment Risk Assessment
  final result = await BharatOnePayApi.analyzeScamRisk(
    receiverVpa: vpa,
    amount: amount,
    remark: note,
  );

  // Step 2: Handle Risk Level
  if (result.recommendation == 'BLOCK') {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🚨 Scam Warning - Payment Blocked', style: TextStyle(color: Colors.red)),
        content: Text(result.warnings.join('\n\n')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
    return;
  }

  if (result.recommendation == 'REQUIRE_COOLING_OFF') {
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            const SizedBox(height: 10),
            Text('High Risk Payment (${result.riskScore}/100)', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(result.warnings.first),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('I Understand - Proceed Anyway'),
            ),
          ],
        ),
      ),
    );
    if (proceed != true) return;
  }

  // Step 3: Trigger MPIN Screen (NPCI Common Library or Simulator)
  promptMpinAndPay(context, vpa, amount, note);
}
```

---

## 🏛️ NPCI Common Library (CL) Integration Guide
In standard Indian UPI production:
1. The Flutter UI calls the native Android/iOS NPCI Common Library (`in.org.npci.commonlibrary.CLServices`).
2. The user inputs their 4/6-digit MPIN securely inside the NPCI-rendered view.
3. The Common Library returns an encrypted credential block: `{"credType": "PIN", "credBlock": "ENC_TOKEN_XYZ"}`.
4. Your Flutter app passes this encrypted token to `POST /api/v1/payments/pay`.
5. For local testing, our backend accepts `mpin: "123456"` directly.
