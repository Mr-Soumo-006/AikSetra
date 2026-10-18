import 'package:flutter/material.dart';
import '../services/bharat_one_pay_api.dart';
import '../models/scam_shield_model.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({Key? key}) : super(key: key);

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFF671F),
              radius: 18,
              child: const Text('SN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Namaste, Simo 🙏', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text('SBI ••• 4519', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Balance Card
            _buildBalanceCard(),
            const SizedBox(height: 18),

            // 4 Big Simple Actions
            _buildQuickActions(context),
            const SizedBox(height: 20),

            // Chillar Bachat (Gullak)
            _buildGullakCard(),
            const SizedBox(height: 20),

            // People You Know with Trust Badges
            _buildPeopleSection(context),
            const SizedBox(height: 20),

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
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: 'Safety'),
          BottomNavigationBarItem(icon: Icon(Icons.handshake_outlined), label: 'Safe Pay'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Abroad'),
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
        mainAxisAlignment: MainAxisAlignment.between,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Bank Balance', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionItem('Scan QR', '📷', Colors.orange, () => _showPayDialog(context)),
        const SizedBox(width: 8),
        _buildActionItem('Pay UPI', '💸', Colors.emerald, () => _showPayDialog(context)),
        const SizedBox(width: 8),
        _buildActionItem('Safe Pay', '🤝', Colors.purple, () => _showSafePayExplanation(context)),
        const SizedBox(width: 8),
        _buildActionItem('Abroad', '🌍', Colors.cyan, () => _showAbroadDialog(context)),
      ],
    );
  }

  Widget _buildActionItem(String label, String icon, MaterialColor color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
            _buildContactAvatar('Chai Point', 'CP', '✓ Verified', Colors.emerald),
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
          margin: const EdgeInsets.top(2),
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
          subtitle: Text('Today, 2:30 PM', style: TextStyle(fontSize: 11)),
          trailing: Text('- ₹80.00', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      ],
    );
  }

  // Simple Safety Check Modal
  void _showPayDialog(BuildContext context) {
    final vpaController = TextEditingController(text: 'lotterywinner99@ybl');
    final amtController = TextEditingController(text: '5000');

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
            TextField(controller: vpaController, decoration: const InputDecoration(labelText: 'UPI ID')),
            TextField(controller: amtController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await BharatOnePayApi.analyzeScamRisk(
                  receiverVpa: vpaController.text,
                  amount: double.tryParse(amtController.text) ?? 0,
                  remark: 'Payment test',
                );
                _showSurakshaCheckResult(context, res);
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSafePayExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🤝 Safe Pay for Strangers'),
        content: const Text('Buying from OLX or Instagram? Your money stays locked in the bank. Only when you click "I Received My Item" does the seller get paid!'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it!'))],
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
