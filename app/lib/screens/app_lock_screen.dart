import 'package:flutter/material.dart';
import '../services/bharat_one_pay_api.dart';
import 'login_screen.dart';
import 'simple_home_screen.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  String? _pinError;

  void _onKeyPress(String val) {
    if (_enteredPin.length < 4) {
      setState(() {
        _pinError = null;
        _enteredPin += val;
      });
      if (_enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 150), () {
          _verifyAndUnlock();
        });
      }
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
      _pinError = null;
    });
  }

  void _verifyAndUnlock() {
    // If configured pin matches or standard dev pin 1234
    if (_enteredPin == BharatOnePayApi.configuredAppPin || _enteredPin == '1234' || BharatOnePayApi.configuredAppPin.isEmpty) {
      _unlockApp();
    } else {
      setState(() {
        _enteredPin = '';
        _pinError = 'Incorrect PIN. Try 1234 or your setup PIN.';
      });
    }
  }

  void _unlockApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SimpleHomeScreen()),
    );
  }

  void _goToLogin() {
    BharatOnePayApi.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = BharatOnePayApi.currentUser?.fullName.split(' ').first ?? 'Simo';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Logo & Info
              Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF671F), Color(0xFFFBBF24)],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF671F).withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('₹1', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(height: 14),
                  const Text('AikSetra', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('A shared financial space • Welcome back, $userName', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 20),

                  // 4 PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? const Color(0xFFFF671F) : Colors.transparent,
                          border: Border.all(
                            color: isFilled ? const Color(0xFFFF671F) : const Color(0xFF64748B),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_pinError != null) ...[
                    const SizedBox(height: 8),
                    Text(_pinError!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 14),

                  // Biometric Fingerprint Button
                  InkWell(
                    onTap: _unlockApp,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.fingerprint, color: Color(0xFF34D399), size: 22),
                          SizedBox(width: 8),
                          Text('Unlock with Fingerprint', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Keypad
              Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 10),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 10),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeyButton('Clear', onTap: _onClear, isText: true),
                      _buildKeyButton('0', onTap: () => _onKeyPress('0')),
                      _buildKeyButton('👆', onTap: _unlockApp, isIcon: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Enter 4-digit PIN (e.g. 1234) or tap Fingerprint', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),

                  // Switch Account / Register New User
                  Divider(color: const Color(0xFF334155).withValues(alpha: 0.6)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _goToLogin,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          child: const Text('Switch Account', style: TextStyle(color: Color(0xFFFF671F), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          onPressed: _goToLogin,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          child: const Text('New Registration?', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildKeyButton(k, onTap: () => _onKeyPress(k))).toList(),
    );
  }

  Widget _buildKeyButton(String label, {required VoidCallback onTap, bool isText = false, bool isIcon = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 80,
        height: 54,
        decoration: BoxDecoration(
          color: isIcon ? const Color(0xFF046A38).withValues(alpha: 0.3) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isIcon ? const Color(0xFF046A38) : const Color(0xFF334155)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: isText ? 13 : 20,
            fontWeight: FontWeight.bold,
            color: isText ? Colors.redAccent : Colors.white,
          ),
        ),
      ),
    );
  }
}
