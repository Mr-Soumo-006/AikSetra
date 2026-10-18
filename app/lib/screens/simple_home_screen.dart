import 'package:flutter/material.dart';
import '../services/bharat_one_pay_api.dart';
import '../models/scam_shield_model.dart';
import 'login_screen.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: InkWell(
          onTap: () => _showAccountModal(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFF671F),
                  radius: 18,
                  child: Text(
                    (BharatOnePayApi.currentUser?.fullName.isNotEmpty == true)
                        ? BharatOnePayApi.currentUser!.fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
                        : 'SN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          BharatOnePayApi.currentUser?.fullName ?? 'Simo Naskar',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 16),
                      ],
                    ),
                    Text(
                      '${BharatOnePayApi.currentAccount?.bankName ?? "SBI"} • ${BharatOnePayApi.currentAccount?.maskedAccountNumber.split(' ').last ?? "4519"} • ${BharatOnePayApi.currentUser?.primaryVpa ?? "simo@aiksetra"}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            onPressed: () => _showAccountModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Balance Card
            _buildBalanceCard(),
            const SizedBox(height: 16),

            // HERO SECTION: Giant QR on Left, Safe Pay & Abroad on Right
            _buildHeroQrAndActions(context),
            const SizedBox(height: 16),

            // 3 Quick Secondary Buttons
            _buildSecondaryActions(context),
            const SizedBox(height: 18),

            // Chillar Bachat (Gullak)
            _buildGullakCard(),
            const SizedBox(height: 18),

            // People You Know with Trust Badges
            _buildPeopleSection(context),
            const SizedBox(height: 18),

            // Recent Payments
            _buildRecentPayments(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF671F),
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        onTap: (idx) {
          if (idx == 4) {
            _showAccountModal(context);
          } else {
            setState(() => _currentIndex = idx);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: 'Safety'),
          BottomNavigationBarItem(icon: Icon(Icons.handshake_outlined), label: 'Safe Pay'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Abroad'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('State Bank of India (••• 4519)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              SizedBox(height: 4),
              Text('₹84,420.50', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('Digital Gullak 🐖', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('₹11,200', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // Hero Section: Giant QR on the left, Safe Pay and Abroad on the right
  Widget _buildHeroQrAndActions(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // GIANT QR SCAN BUTTON (Left Side)
        Expanded(
          flex: 6,
          child: InkWell(
            onTap: () => _showGiantQrModal(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF7ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFEDD5), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('FAST PAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFFF671F))),
                      Text('Giant QR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, size: 54, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: const [
                      Text('Scan Any QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text('Easy scan from distance', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // RIGHT SIDE TILES: Safe Pay & Send Abroad
        Expanded(
          flex: 6,
          child: Column(
            children: [
              // Safe Pay (Stranger Escrow)
              InkWell(
                onTap: () => _showSafePayDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('🤝 Safe Pay', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF581C87))),
                          SizedBox(height: 2),
                          Text('Hold for strangers', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFF7E22CE), size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Send Abroad
              InkWell(
                onTap: () => _showAbroadDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('🌍 Abroad', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF083344))),
                          SizedBox(height: 2),
                          Text('Rupee-first transfer', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFCFFAFE), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0891B2), size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Row(
      children: [
        _buildActionItem('Pay UPI', '💸', Colors.green, () => _showPayDialog(context)),
        const SizedBox(width: 8),
        _buildActionItem('Receive / My QR', '📲', Colors.orange, () => _showMyQrModal(context)),
        const SizedBox(width: 8),
        _buildActionItem('Gullak', '🐖', Colors.amber, () => _showGullakModal(context)),
      ],
    );
  }

  Widget _buildActionItem(String label, String icon, MaterialColor color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGullakCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: const [
          Text('🐖', style: TextStyle(fontSize: 26)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chillar Bachat is ON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E))),
                Text('Spare change rounds up automatically into your Goa Trip savings.', style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('People You Know', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildContactAvatar('Chai Point', 'CP', '✓ Verified', Colors.green),
            _buildContactAvatar('Ramesh', 'RS', 'Frequent', Colors.blue),
            _buildContactAvatar('Priya', 'PP', 'Friend', Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildContactAvatar(String name, String initials, String badge, MaterialColor color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.shade100,
          child: Text(initials, style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text(badge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.shade700)),
        ),
      ],
    );
  }

  Widget _buildRecentPayments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Recent Payments', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        SizedBox(height: 10),
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          leading: Text('☕', style: TextStyle(fontSize: 22)),
          title: Text('Chai Point Koramangala', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: Text('Today, 2:30 PM • RRN 429188', style: TextStyle(fontSize: 11)),
          trailing: Text('- ₹80.00', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      ],
    );
  }

  // Account Details Modal with Linked Banks and Logout
  void _showAccountModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Account & Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFF671F),
                    radius: 22,
                    child: Text(
                      (BharatOnePayApi.currentUser?.fullName.isNotEmpty == true)
                          ? BharatOnePayApi.currentUser!.fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join()
                          : 'SN',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(BharatOnePayApi.currentUser?.fullName ?? 'Simo Naskar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          (BharatOnePayApi.currentUser?.phone.isNotEmpty == true) ? '+91 ${BharatOnePayApi.currentUser!.phone}' : '+91 98765 43210',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        Text(
                          'UPI ID: ${BharatOnePayApi.currentUser?.primaryVpa ?? "simo@aiksetra"}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF046A38), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                    child: const Text('KYC Verified', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Linked Bank Accounts
            const Text('Linked Bank Accounts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(BharatOnePayApi.currentAccount?.bankName ?? 'State Bank of India', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${BharatOnePayApi.currentAccount?.maskedAccountNumber ?? "Savings A/C •••• 4519"} • Primary', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  Text(
                    '₹${(BharatOnePayApi.currentAccount?.balance ?? 84420.50).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF046A38)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // LOGOUT BUTTON
            ElevatedButton.icon(
              onPressed: () {
                BharatOnePayApi.logout();
                Navigator.pop(ctx);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out of AikSetra', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Giant QR Modal for Ultra-Easy Scanning
  void _showGiantQrModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Scan AikSetra UPI QR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A), width: 4),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 190, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            const Text('Scan any QR from a distance easily.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // My QR Modal
  void _showMyQrModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Receive Money / My QR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF671F), width: 3),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 170, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            const Text('simo@aiksetra', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF671F))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  // Safe Pay Modal with Giant QR option
  void _showSafePayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🤝 Safe Pay for Strangers', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Buying from OLX or an unknown shop? Funds stay locked in the bank until you confirm receipt!'),
            SizedBox(height: 12),
            Text('Use Giant QR to show the seller proof of secured bank escrow.', style: TextStyle(fontSize: 11, color: Color(0xFF7E22CE), fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
        ],
      ),
    );
  }

  // Gullak Modal
  void _showGullakModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🐖 Digital Gullak', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Total Saved: ₹11,200\n\nChillar Bachat automatically rounds up your everyday small payments into your savings goal.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showPayDialog(BuildContext context) {
    final vpaController = TextEditingController();
    final amtController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter UPI ID or Phone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: vpaController, decoration: const InputDecoration(labelText: 'UPI ID or Mobile Number', hintText: 'username@bank or 10-digit number')),
            TextField(controller: amtController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', hintText: 'Enter amount')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await BharatOnePayApi.analyzeScamRisk(
                  receiverVpa: vpaController.text,
                  amount: double.tryParse(amtController.text) ?? 0,
                  remark: 'Payment test',
                );
                if (!mounted) return;
                _showSurakshaCheckResult(this.context, res);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), minimumSize: const Size.fromHeight(46)),
              child: const Text('Check Safety & Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSurakshaCheckResult(BuildContext context, ScamShieldResult res) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(res.riskLevel == 'HIGH' ? '🚨 STOP! Known Fraud' : '✓ Safe Payee Verified'),
        content: Text(res.warnings.isNotEmpty ? res.warnings.first : 'This person is safe to pay.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showAbroadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🌍 Send Money Abroad'),
        content: const Text('Pay in Rupees from your Indian bank. The receiver gets their local currency (Dirhams, Euros, Dollars) with guaranteed 10-minute rate lock.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood'))],
      ),
    );
  }
}
