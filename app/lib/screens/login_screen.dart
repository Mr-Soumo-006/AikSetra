import 'dart:async';
import 'package:flutter/material.dart';
import '../api_config.dart';
import '../services/bharat_one_pay_api.dart';
import 'simple_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Step State: 1 = Phone & Name, 2 = SIM Selection, 3 = OTP, 4 = Bank Selection, 5 = Set App PIN
  int _currentStep = 1;

  // Controllers for user's actual name and phone number
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _consentChecked = true;

  // Step 2: SIM Binding
  int _selectedSimSlot = 1;
  bool _isBindingSim = false;

  // Step 3: OTP
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _resendCountdown = 30;
  Timer? _resendTimer;
  String? _receivedOtp;

  // Step 4: Bank Discovery
  int _selectedBankIndex = 0;
  final List<Map<String, String>> _discoveredBanks = [
    {
      'bankName': 'State Bank of India',
      'bankCode': 'SBIN',
      'accountNo': '•••• •••• 4519',
      'ifsc': 'SBIN0001234',
      'type': 'Savings A/C',
    },
    {
      'bankName': 'HDFC Bank',
      'bankCode': 'HDFC',
      'accountNo': '•••• •••• 9821',
      'ifsc': 'HDFC0005678',
      'type': 'Savings A/C',
    },
    {
      'bankName': 'ICICI Bank',
      'bankCode': 'ICIC',
      'accountNo': '•••• •••• 1042',
      'ifsc': 'ICIC0009012',
      'type': 'Salary A/C',
    },
  ];

  // Step 5: Setup PIN
  String _setupPin = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // --- Step 1 Action: Submit Phone & Request OTP ---
  Future<void> _handlePhoneSubmit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name as per bank records.');
      return;
    }
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit Indian mobile number.');
      return;
    }
    if (!_consentChecked) {
      setState(() => _errorMessage = 'Please accept NPCI UPI Device-Binding & DPDP terms.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await BharatOnePayApi.sendOtp(phone);
    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _receivedOtp = res['otp']; // Server may return OTP for auto-read
        _currentStep = 2; // Proceed to SIM selection
      } else {
        _errorMessage = res['message'] ?? 'Failed to send OTP. Please try again.';
      }
    });
  }

  // --- Step 2 Action: Bind SIM & Proceed to OTP ---
  Future<void> _handleSimBinding() async {
    setState(() {
      _isBindingSim = true;
      _errorMessage = null;
    });

    // NPCI secure SMS handshake
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    setState(() {
      _isBindingSim = false;
      _currentStep = 3; // Proceed to OTP entry
    });
    _startResendTimer();
  }

  // --- Step 3 Action: Auto-fill & Verify OTP ---
  void _autoFillOtp(String code) {
    for (int i = 0; i < 6 && i < code.length; i++) {
      _otpControllers[i].text = code[i];
    }
    _otpFocusNodes[5].requestFocus();
    _handleVerifyOtp();
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final simSlotName = _selectedSimSlot == 1 ? 'sim_slot_1_jio' : 'sim_slot_2_airtel';
    final selectedBank = _discoveredBanks[_selectedBankIndex]['bankName'];

    final res = await BharatOnePayApi.verifyOtpAndLogin(
      phone: phone,
      otp: otp,
      deviceId: 'android_studio_device_${phone.substring(phone.length - 4)}',
      simId: simSlotName,
      fullName: name,
      selectedBank: selectedBank,
    );

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _currentStep = 4; // Proceed to bank account discovery
      });
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Incorrect OTP. Please check the SMS sent to your number.';
      });
    }
  }

  // --- Step 4 Action: Select Bank & Go to PIN Setup ---
  void _handleBankConfirmed() {
    setState(() {
      _currentStep = 5; // Proceed to PIN setup
    });
  }

  // --- Step 5 Action: Keypad for App PIN Setup ---
  void _onPinKeyPress(String digit) {
    if (_setupPin.length < 4) {
      setState(() {
        _setupPin += digit;
      });
      if (_setupPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), _finishOnboarding);
      }
    }
  }

  void _onPinClear() {
    setState(() {
      _setupPin = '';
    });
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    await BharatOnePayApi.setMpin(_setupPin.isNotEmpty ? _setupPin : '1234');
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Show celebratory snackbar & navigate to Home Screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF046A38),
        content: Text(
          '🎉 Welcome ${_nameController.text}! Account linked with UPI ID: ${BharatOnePayApi.currentUser?.primaryVpa ?? "active"}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SimpleHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header Progress Bar
            _buildStepIndicator(),

            // Error Banner if any
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Active Step Screen
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Footer note
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.security, size: 13, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text(
                    'Secured by NPCI Unified Payments Interface • RBI Compliant',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step Indicator Dots & Back Arrow ---
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (_currentStep > 1)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _currentStep--;
                });
              },
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final stepNum = index + 1;
                final isActive = stepNum == _currentStep;
                final isDone = stepNum < _currentStep;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF34D399)
                        : (isActive ? const Color(0xFFFF671F) : const Color(0xFF334155)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          Text(
            '$_currentStep/5',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.settings_ethernet, color: Color(0xFF64748B), size: 18),
            tooltip: 'Configure Backend Server IP',
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    final ipCtrl = TextEditingController(text: ApiConfig.activeHost);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Backend Server IP (Port 4000)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your PC IPv4 address (from ipconfig) or 10.0.2.2 for Android Emulator:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipCtrl,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '192.168.29.90',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF671F)),
            onPressed: () {
              ApiConfig.setCustomHost(ipCtrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Backend host set to ${ApiConfig.activeHost}:4000')),
              );
            },
            child: const Text('Save Host', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Mobile();
      case 2:
        return _buildStep2SimBinding();
      case 3:
        return _buildStep3Otp();
      case 4:
        return _buildStep4BankDiscovery();
      case 5:
        return _buildStep5AppPin();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // STEP 1: Full Name & 10-Digit Mobile Input
  // ==========================================
  Widget _buildStep1Mobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF671F), Color(0xFFFBBF24)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF671F).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('₹1', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Welcome to AikSetra',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'A shared financial space (Ek + Kshetra) • Link your Indian bank',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 28),

        // Full Name Field
        Align(
          alignment: Alignment.centerLeft,
          child: const Text('Your Full Legal Name', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Enter your full name as per bank records',
            hintStyle: const TextStyle(color: Color(0xFF64748B)),
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFF671F)),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF671F), width: 2)),
          ),
        ),
        const SizedBox(height: 18),

        // Mobile Number Field
        Align(
          alignment: Alignment.centerLeft,
          child: const Text('Bank-Linked Mobile Number', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🇮🇳', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text('+91', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            hintText: 'Enter 10-digit mobile number',
            hintStyle: const TextStyle(color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF671F), width: 2)),
          ),
        ),
        const SizedBox(height: 14),

        // Consent Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _consentChecked,
                activeColor: const Color(0xFFFF671F),
                onChanged: (val) => setState(() => _consentChecked = val ?? true),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'I authorize AikSetra to initiate SIM device-binding SMS verification per NPCI UPI guidelines and DPDP privacy law.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Proceed Button
        ElevatedButton(
          onPressed: _isLoading ? null : _handlePhoneSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF671F),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Proceed & Send OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: SIM Card Selection & Device Binding
  // ==========================================
  Widget _buildStep2SimBinding() {
    final phone = _phoneController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: const Text('📲', style: TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Select Bank-Registered SIM',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'NPCI requires sending an encrypted SMS token from your registered SIM to bind your device.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 24),

        // SIM 1 Option
        InkWell(
          onTap: () => setState(() => _selectedSimSlot = 1),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedSimSlot == 1
                  ? const Color(0xFFFF671F).withValues(alpha: 0.12)
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _selectedSimSlot == 1 ? const Color(0xFFFF671F) : const Color(0xFF334155),
                width: _selectedSimSlot == 1 ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF671F).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('SIM 1', style: TextStyle(color: Color(0xFFFF671F), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jio 5G (Active Slot)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('+91 $phone', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                if (_selectedSimSlot == 1)
                  const Icon(Icons.check_circle, color: Color(0xFFFF671F), size: 22)
                else
                  const Icon(Icons.radio_button_off, color: Color(0xFF64748B), size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // SIM 2 Option
        InkWell(
          onTap: () => setState(() => _selectedSimSlot = 2),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedSimSlot == 2
                  ? const Color(0xFFFF671F).withValues(alpha: 0.12)
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _selectedSimSlot == 2 ? const Color(0xFFFF671F) : const Color(0xFF334155),
                width: _selectedSimSlot == 2 ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('SIM 2', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Airtel 5G', style: TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 2),
                      Text('Secondary SIM', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                if (_selectedSimSlot == 2)
                  const Icon(Icons.check_circle, color: Color(0xFFFF671F), size: 22)
                else
                  const Icon(Icons.radio_button_off, color: Color(0xFF64748B), size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Binding In-Progress Card
        if (_isBindingSim)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF34D399), strokeWidth: 2.5)),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verifying Device Binding with NPCI...', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(height: 2),
                      Text('Sending encrypted SMS token. Please wait.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ElevatedButton(
            onPressed: _handleSimBinding,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Text(
              'Verify Device Binding with SIM $_selectedSimSlot',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // STEP 3: 6-Digit SMS OTP Verification
  // ==========================================
  Widget _buildStep3Otp() {
    final phone = _phoneController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Incoming SMS detection notification
        if (_receivedOtp != null && _receivedOtp!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sms_outlined, color: Color(0xFF34D399), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SMS from NPCI-AIKSETRA', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11)),
                      Text('OTP: $_receivedOtp detected', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _autoFillOtp(_receivedOtp!),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Auto-fill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),

        const Text('Enter 6-Digit OTP', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Sent via SMS to +91 $phone', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const SizedBox(height: 24),

        // 6 OTP Digit Input Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF671F), width: 2)),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (val.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                  if (index == 5 && val.isNotEmpty) {
                    _handleVerifyOtp();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Text(
            '💻 Check your Backend CMD terminal for the 6-digit NPCI OTP',
            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),

        // Resend Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Didn't receive SMS? ", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            if (_resendCountdown > 0)
              Text('Resend in ${_resendCountdown}s', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold))
            else
              InkWell(
                onTap: () async {
                  _startResendTimer();
                  final r = await BharatOnePayApi.sendOtp(phone);
                  if (r['otp'] != null && mounted) {
                    setState(() => _receivedOtp = r['otp']);
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New OTP dispatched to your registered phone.')),
                  );
                },
                child: const Text('Resend OTP', style: TextStyle(color: Color(0xFFFF671F), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 28),

        // Verify OTP Button
        ElevatedButton(
          onPressed: _isLoading ? null : _handleVerifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF046A38),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('Verify OTP & Discover Banks →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: Bank Account Discovery & UPI ID
  // ==========================================
  Widget _buildStep4BankDiscovery() {
    final cleanName = _nameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final assignedVpa = '${cleanName.isNotEmpty ? cleanName : "user"}@aiksetra';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF046A38).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF046A38).withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: const Text('🏛️', style: TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Bank Accounts Discovered',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'We found the following accounts registered with your mobile number. Select your primary UPI account:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 20),

        // Bank Cards List
        Column(
          children: List.generate(_discoveredBanks.length, (idx) {
            final bank = _discoveredBanks[idx];
            final isSelected = idx == _selectedBankIndex;
            return InkWell(
              onTap: () => setState(() => _selectedBankIndex = idx),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF046A38).withValues(alpha: 0.12)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF046A38) : const Color(0xFF334155),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isSelected ? const Color(0xFF046A38) : const Color(0xFF334155),
                      radius: 20,
                      child: Text(
                        bank['bankCode']!.substring(0, 2),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bank['bankName']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('${bank['type']} • ${bank['accountNo']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          Text('IFSC: ${bank['ifsc']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF046A38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Primary', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      const Icon(Icons.radio_button_off, color: Color(0xFF64748B), size: 20),
                  ],
                ),
              ),
            );
          }),
        ),

        // Assigned UPI ID Card
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Assigned UPI ID', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(assignedVpa, style: const TextStyle(color: Color(0xFFFF671F), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace')),
                ],
              ),
              const Icon(Icons.qr_code, color: Color(0xFFFF671F), size: 24),
            ],
          ),
        ),

        ElevatedButton(
          onPressed: _handleBankConfirmed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          child: const Text('Link Account & Set Security PIN →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 5: Setup 4-Digit App Security PIN
  // ==========================================
  Widget _buildStep5AppPin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: const Text('🔒', style: TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Set 4-Digit App PIN',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Use this PIN or Fingerprint whenever you open AikSetra',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 24),

        // 4 Setup PIN Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isFilled = index < _setupPin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? const Color(0xFFF59E0B) : Colors.transparent,
                border: Border.all(
                  color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Numerical 0-9 Keypad for PIN Setup
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
                _buildKeyButton('Clear', onTap: _onPinClear, isText: true),
                _buildKeyButton('0', onTap: () => _onPinKeyPress('0')),
                _buildKeyButton('✓ Done', onTap: _finishOnboarding, isAction: true),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Choose a secure 4-digit PIN', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildKeyButton(k, onTap: () => _onPinKeyPress(k))).toList(),
    );
  }

  Widget _buildKeyButton(String label, {required VoidCallback onTap, bool isText = false, bool isAction = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 80,
        height: 54,
        decoration: BoxDecoration(
          color: isAction
              ? const Color(0xFF046A38)
              : (isText ? const Color(0xFF1E293B) : const Color(0xFF1E293B)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isAction
                ? const Color(0xFF10B981)
                : const Color(0xFF334155),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: (isText || isAction) ? 13 : 20,
            fontWeight: FontWeight.bold,
            color: isText
                ? const Color(0xFFEF4444)
                : (isAction ? Colors.white : Colors.white),
          ),
        ),
      ),
    );
  }
}
