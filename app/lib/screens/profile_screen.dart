import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/bharat_one_pay_api.dart';
import '../services/biometric_service.dart';
import 'login_screen.dart';
import 'cards_screen.dart';
import 'autopay_screen.dart';
import 'statements_screen.dart';
import 'rewards_screen.dart';
import 'business_dashboard_screen.dart';
import 'bank_account_opening_screen.dart';
import 'calculators_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbeddedInTab;
  final VoidCallback? onRefreshParent;

  const ProfileScreen({
    super.key,
    this.isEmbeddedInTab = false,
    this.onRefreshParent,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isBiometricLockActive = true;

  String get _userName =>
      BharatOnePayApi.currentUser?.fullName ?? 'Soumo Naskar';
  String get _userVpa =>
      BharatOnePayApi.currentUser?.primaryVpa ?? 'soumonaska3038@aiksetra';
  String get _bankName =>
      BharatOnePayApi.currentAccount?.bankName ?? 'State Bank of India (SBI)';
  String get _maskedAcc =>
      BharatOnePayApi.currentAccount?.maskedAccountNumber ?? '•••• •••• 3038';
  String get _ifsc => BharatOnePayApi.currentAccount?.ifsc ?? 'SBIN0001234';
  double get _bankBalance => BharatOnePayApi.currentAccount?.balance ?? 0.0;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final bio = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricLockActive = bio;
      });
    }
  }

  Future<void> _syncData() async {
    setState(() => _isLoading = true);
    await BharatOnePayApi.getMe();
    await BharatOnePayApi.getTransactionHistory();
    await BharatOnePayApi.getVaults();
    if (widget.onRefreshParent != null) {
      widget.onRefreshParent!();
    }
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Synced profile, accounts and live bank balance'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF046A38),
        ),
      );
    }
  }

  Future<String?> _promptForMpin({
    required String title,
    required String subtitle,
  }) {
    final pinCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 10,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enter your 4-digit UPI MPIN',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
                Text(
                  'Demo PIN: 1234',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final authenticated = await BiometricService.authenticate(
                    reason: '$title - Scan fingerprint to authorize payment',
                  );
                  if (authenticated) {
                    Navigator.pop(
                      ctx,
                      BharatOnePayApi.configuredAppPin.isNotEmpty
                          ? BharatOnePayApi.configuredAppPin
                          : '1234',
                    );
                  }
                },
                icon: const Icon(
                  Icons.fingerprint_rounded,
                  color: Color(0xFF34D399),
                  size: 20,
                ),
                label: const Text(
                  '👆 Pay with Fingerprint',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF34D399)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, pinCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              foregroundColor: Colors.white,
            ),
            child: const Text('Authorize ✓'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkBalance() async {
    final pin = await _promptForMpin(
      title: 'Check Bank Balance',
      subtitle: 'Enter 4-digit UPI MPIN for $_bankName ($_maskedAcc)',
    );
    if (pin == null || pin.isEmpty) return;

    final validPin = BharatOnePayApi.configuredAppPin.isNotEmpty
        ? BharatOnePayApi.configuredAppPin
        : '1234';
    if (pin != validPin && pin != '1234') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Incorrect UPI MPIN'),
        ),
      );
      return;
    }

    await BharatOnePayApi.getMe();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF046A38),
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Available Balance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_bankName ($_maskedAcc)',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${_bankBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF046A38),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fetched live via NPCI UPI Switch',
              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddMoneyModal() {
    final amtCtrl = TextEditingController(text: '5000');
    String fundingSource = 'HDFC NetBanking / Salary Account';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📥 Add Money to Bank Account',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                Text(
                  'Instantly deposit funds into $_bankName ($_maskedAcc)',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        color: Color(0xFF046A38),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crediting to $_bankName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            Text(
                              'Acc: $_maskedAcc • IFSC: $_ifsc',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF046A38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Bal: ₹${_bankBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Funding Source:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: fundingSource,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'HDFC NetBanking / Salary Account',
                      child: Text(
                        '🏦 HDFC NetBanking / Salary Acct',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'State Bank of India NetBanking',
                      child: Text(
                        '🏦 State Bank of India NetBanking',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'ICICI Bank NetBanking',
                      child: Text(
                        '🏦 ICICI Bank NetBanking',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'External Debit Card / CBS Switch Simulator',
                      child: Text(
                        '💳 External Debit Card / CBS Switch',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setSheetState(() => fundingSource = v);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Deposit Amount (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [1000, 2000, 5000, 10000, 25000]
                        .map(
                          (preset) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(
                                '+₹$preset',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: const Color(0xFFF1F5F9),
                              onPressed: () {
                                setSheetState(
                                  () => amtCtrl.text = preset.toString(),
                                );
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
                      if (amt <= 0) return;
                      Navigator.pop(ctx);
                      final res = await BharatOnePayApi.addMoneyToAccount(
                        amount: amt,
                        sourceNote: 'Self Deposit from $fundingSource',
                      );
                      await _syncData();
                      if (!mounted) return;
                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF046A38),
                            content: Text(
                              '✅ ₹${amt.toStringAsFixed(2)} added to $_bankName successfully! Current Balance: ₹${_bankBalance.toStringAsFixed(2)}',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              res['message'] ?? 'Could not add money',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                    ),
                    label: Text(
                      'Deposit ₹${amtCtrl.text.isEmpty ? "0" : amtCtrl.text} to $_bankName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReceiveQrModal() {
    final upiUri =
        'upi://pay?pa=$_userVpa&pn=${Uri.encodeComponent(_userName)}&cu=INR';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Personal UPI QR',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: upiUri,
                    version: QrVersions.auto,
                    size: 200,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _userVpa,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _userVpa));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('UPI ID copied to clipboard!'),
                      backgroundColor: Color(0xFF046A38),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy UPI ID'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkAnotherBankModal() {
    Map<String, String> selectedBank = BharatOnePayApi.allIndianBanks.first;
    final ifscCtrl = TextEditingController(text: selectedBank['ifsc']);
    final accCtrl = TextEditingController(
      text:
          '9180${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Link Indian Bank Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, String>>(
                  initialValue: selectedBank,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select Bank',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: BharatOnePayApi.allIndianBanks.map((b) {
                    return DropdownMenuItem<Map<String, String>>(
                      value: b,
                      child: Text(
                        '${b['icon']} ${b['name']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setSheetState(() {
                        selectedBank = val;
                        ifscCtrl.text = val['ifsc'] ?? 'SBIN0001234';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ifscCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'IFSC Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final res = await BharatOnePayApi.linkBankAccount(
                        bankName: selectedBank['name'] ?? 'Bank',
                        accountNumber: accCtrl.text.trim(),
                        ifsc: ifscCtrl.text.trim().toUpperCase(),
                        setAsPrimary: false,
                      );
                      await _syncData();
                      if (!mounted) return;
                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF046A38),
                            content: Text(
                              '🎉 ${selectedBank['name']} linked successfully!',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Verify via NPCI & Link',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangeMpinDialog() {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Update 4-Digit UPI MPIN',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'New 4 Digits',
            hintStyle: const TextStyle(color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPin = pinCtrl.text.trim();
              if (newPin.length == 4) {
                Navigator.pop(ctx);
                final res = await BharatOnePayApi.setMpin(newPin);
                if (res['success'] == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('UPI MPIN successfully updated!'),
                      backgroundColor: Color(0xFF046A38),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = BharatOnePayApi.linkedAccounts;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: widget.isEmbeddedInTab
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0F172A),
              elevation: 0,
              foregroundColor: Colors.white,
              title: const Text(
                'Profile & Accounts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.sync,
                    color: Color(0xFF38BDF8),
                    size: 20,
                  ),
                  tooltip: 'Sync Live Data',
                  onPressed: _syncData,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'My UPI QR',
                  onPressed: _showReceiveQrModal,
                ),
              ],
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF046A38)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. USER PROFILE HEADER CARD
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFFF671F),
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified,
                                    color: Color(0xFF00E676),
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'UPI ID: $_userVpa',
                                style: const TextStyle(
                                  color: Color(0xFFFF671F),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mobile: +91 ${BharatOnePayApi.currentUser?.phone ?? "9830113038"}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showReceiveQrModal,
                          icon: const Icon(
                            Icons.qr_code_2_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. LINKED BANK ACCOUNTS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Linked Bank Accounts (48+ RBI Banks)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showLinkAnotherBankModal,
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text(
                          'Link New Bank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF671F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...accounts.map(
                    (acc) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: acc.isPrimary
                              ? const Color(0xFF046A38)
                              : const Color(0xFFE2E8F0),
                          width: acc.isPrimary ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF046A38)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: Color(0xFF046A38),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            acc.bankName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: Color(0xFF0F172A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (acc.isPrimary) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF046A38),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'PRIMARY',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${acc.maskedAccountNumber} • IFSC: ${acc.ifsc}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'BALANCE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${acc.balance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                        color: Color(0xFF046A38),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _checkBalance,
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'Check Balance',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFFF671F,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFFF671F),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _showAddMoneyModal,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        '+ Add Money',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF046A38,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. LINKED CARDS (RuPay UPI & DEBIT/CREDIT)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Linked Debit & Credit Cards',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CardsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_card_rounded, size: 16),
                        label: const Text(
                          'Manage Cards →',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF671F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...((BharatOnePayApi.linkedCards.isNotEmpty)
                          ? BharatOnePayApi.linkedCards
                          : [
                              {
                                'id': 'card_primary_debit',
                                'cardType': 'DEBIT',
                                'network': 'RuPay UPI',
                                'bankName': 'State Bank of India (SBI)',
                                'maskedCardNumber': '•••• •••• •••• 9130',
                                'expiry': '08/29',
                                'cardHolderName': _userName.toUpperCase(),
                                'balanceOrLimit': 0.0,
                              },
                              {
                                'id': 'card_hdfc_credit',
                                'cardType': 'CREDIT',
                                'network': 'RuPay UPI',
                                'bankName': 'HDFC Bank',
                                'maskedCardNumber': '•••• •••• •••• 8821',
                                'expiry': '08/29',
                                'cardHolderName': _userName.toUpperCase(),
                                'balanceOrLimit': 150000.0,
                              },
                            ])
                      .map((card) {
                        final isCredit = card['cardType'] == 'CREDIT';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCredit
                                  ? [
                                      const Color(0xFF1E1B4B),
                                      const Color(0xFF312E81),
                                    ]
                                  : [
                                      const Color(0xFF0F172A),
                                      const Color(0xFF1E293B),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${card['bankName']} • ${card['cardType']} CARD',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      card['network'] ?? 'RuPay UPI',
                                      style: const TextStyle(
                                        color: Color(0xFFFCD34D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                card['maskedCardNumber'] ??
                                    '•••• •••• •••• 9130',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'VALID THRU: ${card['expiry']} • ${card['cardHolderName']}',
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    'Limit/Bal: ₹${((card['balanceOrLimit'] as num?) ?? 0).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFF6EE7B7),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  const SizedBox(height: 20),

                  // 4. FINANCIAL SERVICES & TOOLS SHORTCUTS
                  const Text(
                    'Payment Management & Solutions',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildNavigationTile(
                    icon: Icons.autorenew_rounded,
                    title: 'AutoPay & Scheduled Mandates',
                    subtitle: 'Manage recurring bill mandates, SIP schedules & debits',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AutoPayScreen()),
                    ),
                  ),
                  _buildNavigationTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Combined Statements & Passbook',
                    subtitle:
                        'Multi-account transaction passbook, PDF & CSV export',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StatementsScreen(),
                      ),
                    ),
                  ),
                  _buildNavigationTile(
                    icon: Icons.stars_rounded,
                    title: 'Rewards, Cashback & Referral Ledger',
                    subtitle: 'View Coins, scratch cards, vouchers & referral bonuses',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RewardsScreen()),
                    ),
                  ),
                  _buildNavigationTile(
                    icon: Icons.storefront_rounded,
                    title: 'AikSetra Business Mode',
                    subtitle:
                        'Merchant Standee QR, Soundbox alerts & GST invoices',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BusinessDashboardScreen(),
                      ),
                    ),
                  ),
                  _buildNavigationTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Open Zero-Balance Digital Savings Account',
                    subtitle: '4-step digital KYC with partner banks (Kotak, HDFC, Axis)',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BankAccountOpeningScreen(),
                      ),
                    ),
                  ),
                  _buildNavigationTile(
                    icon: Icons.calculate_rounded,
                    title: 'Financial Calculator Centre',
                    subtitle: '10 tools: EMI, SIP, GST, New Tax Regime, Live FX, FD, RD',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CalculatorsScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. SECURITY & APP SETTINGS
                  const Text(
                    'Security, Privacy & Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Fingerprint & Biometric Lock',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        _isBiometricLockActive
                            ? 'Enabled for App Unlock & 1-Tap UPI Authorizations'
                            : 'Disabled (Tap to Enable)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      value: _isBiometricLockActive,
                      activeThumbColor: const Color(0xFF046A38),
                      onChanged: (v) async {
                        await BiometricService.setBiometricEnabled(v);
                        setState(() => _isBiometricLockActive = v);
                      },
                    ),
                  ),

                  _buildNavigationTile(
                    icon: Icons.lock_reset_rounded,
                    title: 'Change 4-Digit UPI MPIN',
                    subtitle: 'Update your NPCI transaction security PIN',
                    onTap: _showChangeMpinDialog,
                  ),

                  _buildNavigationTile(
                    icon: Icons.shield_outlined,
                    title: 'AI Scam Shield Directory',
                    subtitle: 'NPCI safety verification for unknown recipients',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'AI Scam Shield active. All UPI transactions verified under NPCI directory.',
                          ),
                        ),
                      );
                    },
                  ),

                  _buildNavigationTile(
                    icon: Icons.help_outline_rounded,
                    title: '24x7 Customer Support & Grievance',
                    subtitle: 'Direct helpdesk & RBI Ombudsman redressal',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('24x7 Help & Grievance Redressal'),
                          content: const Text(
                            'AikSetra Support Desk:\n• Email: support@aiksetra.in\n• Helpline: 1800-890-1234\n• RBI Ombudsman CMS Portal: cms.rbi.org.in',
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF046A38),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  _buildNavigationTile(
                    icon: Icons.logout_rounded,
                    title: 'Switch Account / Logout',
                    subtitle:
                        'Sign in with another mobile number or bank account',
                    isDestructive: true,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Log out of AikSetra?'),
                          content: const Text(
                            'You will need to verify your mobile number with OTP to sign in again.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Log Out'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await BharatOnePayApi.logout();
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isDestructive
              ? const Color(0xFFFEE2E2)
              : const Color(0xFFF1F5F9),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : const Color(0xFF0F172A),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDestructive ? Colors.red : const Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
