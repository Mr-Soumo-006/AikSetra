import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bharat_one_pay_api.dart';
import '../models/scam_shield_model.dart';
import '../models/cross_border_model.dart';
import '../models/protected_pay_model.dart';
import 'login_screen.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _syncDataFromBackend();
  }

  Future<void> _syncDataFromBackend() async {
    await BharatOnePayApi.getMe();
    await BharatOnePayApi.getVaults();
    await BharatOnePayApi.getTransactionHistory();
    await BharatOnePayApi.getMyEscrows();
    if (mounted) setState(() {});
  }

  void _loadFreshUserData() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userName = (BharatOnePayApi.currentUser?.fullName.isNotEmpty == true)
        ? BharatOnePayApi.currentUser!.fullName
        : 'Simo Naskar';
    final initials = userName
        .split(' ')
        .where((n) => n.isNotEmpty)
        .map((n) => n[0].toUpperCase())
        .take(2)
        .join();
    final bankName = BharatOnePayApi.currentAccount?.bankName ?? 'State Bank of India';
    final maskedAcc = BharatOnePayApi.currentAccount?.maskedAccountNumber.split(' ').last ?? '4519';
    final primaryVpa = BharatOnePayApi.currentUser?.primaryVpa ?? 'simo@aiksetra';

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
                    initials.isNotEmpty ? initials : 'SN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                              userName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 16),
                        ],
                      ),
                      Text(
                        '$bankName • $maskedAcc • $primaryVpa',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 20),
            tooltip: 'Sync Balance',
            onPressed: _syncDataFromBackend,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            onPressed: () => _showAccountModal(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _syncDataFromBackend,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bank Balance Card (Live)
              _buildBalanceCard(),
              const SizedBox(height: 16),

              // HERO SECTION: Giant QR on Left, Safe Pay & Abroad on Right
              _buildHeroQrAndActions(context),
              const SizedBox(height: 16),

              // 3 Quick Secondary Buttons
              _buildSecondaryActions(context),
              const SizedBox(height: 18),

              // Chillar Bachat (Gullak)
              InkWell(
                onTap: () => _showGullakModal(context),
                borderRadius: BorderRadius.circular(16),
                child: _buildGullakCard(),
              ),
              const SizedBox(height: 18),

              // People You Know with Trust Badges (Tap to Pay)
              _buildPeopleSection(context),
              const SizedBox(height: 18),

              // Recent Payments (Live)
              _buildRecentPayments(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF671F),
        unselectedItemColor: const Color(0xFF64748B),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 1) {
            _showScamShieldModal(context);
          } else if (idx == 2) {
            _showSafePayDialog(context);
          } else if (idx == 3) {
            _showAbroadDialog(context);
          } else if (idx == 4) {
            _showAccountModal(context);
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
    final bankName = BharatOnePayApi.currentAccount?.bankName ?? 'State Bank of India';
    final maskedAcc = BharatOnePayApi.currentAccount?.maskedAccountNumber.split(' ').last ?? '4519';
    final balance = BharatOnePayApi.currentAccount?.balance ?? 50000.0;
    final gullak = BharatOnePayApi.gullakBalance;

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
            children: [
              Text(
                '$bankName (••• $maskedAcc)',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          InkWell(
            onTap: () => _showGullakModal(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Digital Gullak 🐖',
                    style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${gullak.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hero Section: Fixed layout without unbounded CrossAxisAlignment.stretch
  Widget _buildHeroQrAndActions(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GIANT QR SCAN BUTTON (Left Side)
        Expanded(
          flex: 6,
          child: InkWell(
            onTap: () => _showGiantQrModal(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 176,
              padding: const EdgeInsets.all(14),
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
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, size: 50, color: Color(0xFF0F172A)),
                  ),
                  Column(
                    children: const [
                      Text('Scan Any QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text('Instant Merchant Pay', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
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
          child: SizedBox(
            height: 176,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Safe Pay (Stranger Escrow)
                InkWell(
                  onTap: () => _showSafePayDialog(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 82,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('🤝 Safe Pay', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF581C87))),
                              SizedBox(height: 2),
                              Text('Escrow for strangers', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
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

                // Send Abroad
                InkWell(
                  onTap: () => _showAbroadDialog(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 82,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('🌍 Abroad', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF083344))),
                              SizedBox(height: 2),
                              Text('Rupee-first transfer', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
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
        ),
      ],
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Row(
      children: [
        _buildActionItem('Pay UPI', '💸', Colors.green, () => _showPayDialog(context)),
        const SizedBox(width: 8),
        _buildActionItem('Receive / QR', '📲', Colors.orange, () => _showMyQrModal(context)),
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
        children: [
          const Text('🐖', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chillar Bachat is ON • Saved ₹${BharatOnePayApi.gullakBalance.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                ),
                const Text(
                  'Spare change rounds up automatically into your savings goal. Tap to Deposit/Withdraw.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF92400E)),
        ],
      ),
    );
  }

  Widget _buildPeopleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('People & Merchants (Tap to Pay)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildContactAvatar('Chai Point', 'CP', '✓ Merchant', Colors.green, 'chaipoint@aiksetra'),
            _buildContactAvatar('Ramesh', 'RS', 'Frequent', Colors.blue, 'ramesh@oksbi'),
            _buildContactAvatar('Priya', 'PP', 'Verified', Colors.purple, 'priya@okhdfcbank'),
            _buildContactAvatar('Scam Test', '⚠️', 'High Risk', Colors.red, 'fake.lottery@scam'),
          ],
        ),
      ],
    );
  }

  Widget _buildContactAvatar(String name, String initials, String badge, MaterialColor color, String vpa) {
    return InkWell(
      onTap: () => _showPayDialog(context, prefillVpa: vpa),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
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
        ),
      ),
    );
  }

  Widget _buildRecentPayments() {
    final txns = BharatOnePayApi.recentTransactions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Payments', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        ...txns.take(5).map((t) {
          final name = t['receiverName']?.toString() ?? t['receiverVpa']?.toString() ?? 'UPI Recipient';
          final rrn = t['upiRrn']?.toString() ?? '429188';
          final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Text('💸', style: TextStyle(fontSize: 18)),
              ),
              title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              subtitle: Text('RRN $rrn • ${t['remark'] ?? 'UPI Payment'}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              trailing: Text(
                '- ₹${amt.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================================
  // MODAL 1: Account & Security Details + UPI Lite
  // ==========================================================
  void _showAccountModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                const Text('Account & Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
                          ? BharatOnePayApi.currentUser!.fullName.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).take(2).join()
                          : 'SN',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BharatOnePayApi.currentUser?.fullName ?? 'Simo Naskar',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          (BharatOnePayApi.currentUser?.phone.isNotEmpty == true)
                              ? '+91 ${BharatOnePayApi.currentUser!.phone}'
                              : '+91 98765 43210',
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        BharatOnePayApi.currentAccount?.bankName ?? 'State Bank of India',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${BharatOnePayApi.currentAccount?.maskedAccountNumber ?? "Savings A/C •••• 4519"} • Primary',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Text(
                    '₹${(BharatOnePayApi.currentAccount?.balance ?? 50000.0).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF046A38)),
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

  // ==========================================================
  // MODAL 2: Giant QR Scanner & Instant Merchant Pay
  // ==========================================================
  void _showGiantQrModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📷 Giant QR Scanner', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFF671F), width: 4),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, size: 130, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select a detected NPCI Merchant QR to pay immediately:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 12),
            _buildQrMerchantTile(ctx, '☕ Chai Point Koramangala', 'chaipoint@aiksetra', 80),
            _buildQrMerchantTile(ctx, '🛒 Reliance Smart Bazaar', 'smartbazaar@okicici', 450),
            _buildQrMerchantTile(ctx, '💊 Apollo Pharmacy', 'apollo@oksbi', 220),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showPayDialog(context);
              },
              icon: const Icon(Icons.keyboard, color: Color(0xFFFF671F)),
              label: const Text('Enter Custom UPI ID Manually', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF334155)),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrMerchantTile(BuildContext modalCtx, String title, String vpa, double defaultAmt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(vpa, style: const TextStyle(color: Color(0xFF34D399), fontSize: 11)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF671F),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: () {
            Navigator.pop(modalCtx);
            _showPayDialog(context, prefillVpa: vpa, prefillAmount: defaultAmt.toStringAsFixed(0));
          },
          child: Text('Pay ₹${defaultAmt.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  // ==========================================================
  // MODAL 3: Receive Money / My QR
  // ==========================================================
  void _showMyQrModal(BuildContext context) {
    final vpa = BharatOnePayApi.currentUser?.primaryVpa ?? 'simo@aiksetra';
    final name = BharatOnePayApi.currentUser?.fullName ?? 'Simo Naskar';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
            const SizedBox(height: 12),
            Text(vpa, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFF671F))),
            const SizedBox(height: 6),
            const Text('Scan with any BHIM UPI app to pay directly', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: vpa));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied UPI ID: $vpa')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy UPI ID'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // ==========================================================
  // MODAL 4: Scam Shield Safety Checker & Fraud Reporter
  // ==========================================================
  void _showScamShieldModal(BuildContext context) {
    final vpaCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    ScamShieldResult? checkResult;
    bool isChecking = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setShieldState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🛡️ AI Scam Shield Scanner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Text(
                  'Verify any unknown UPI ID or payment request against the NPCI Fraud Registry before sending money.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: vpaCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Enter UPI ID or Mobile Number to Verify',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    hintText: 'e.g. lottery.winner@scam or chaipoint@aiksetra',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Payment Reason / Message (Optional)',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    hintText: 'e.g. Urgent electricity bill disconnection',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF671F),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isChecking
                            ? null
                            : () async {
                                if (vpaCtrl.text.trim().isEmpty) return;
                                setShieldState(() => isChecking = true);
                                final res = await BharatOnePayApi.analyzeScamRisk(
                                  receiverVpa: vpaCtrl.text.trim(),
                                  amount: 5000,
                                  remark: noteCtrl.text.trim(),
                                );
                                setShieldState(() {
                                  checkResult = res;
                                  isChecking = false;
                                });
                              },
                        icon: const Icon(Icons.radar, color: Colors.white),
                        label: Text(
                          isChecking ? 'Scanning...' : 'Scan Risk Score',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        minimumSize: const Size(120, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (vpaCtrl.text.trim().isEmpty) return;
                        final res = await BharatOnePayApi.reportScam(
                          vpa: vpaCtrl.text.trim(),
                          reason: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : 'Reported suspicious UPI ID',
                        );
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Reported to Fraud Registry')),
                        );
                      },
                      icon: const Icon(Icons.report_problem, color: Colors.redAccent, size: 18),
                      label: const Text('Report', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (checkResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: checkResult!.riskScore >= 50 ? Colors.redAccent : const Color(0xFF10B981),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Risk Level: ${checkResult!.riskLevel}',
                              style: TextStyle(
                                color: checkResult!.riskScore >= 50 ? Colors.redAccent : const Color(0xFF34D399),
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Score: ${checkResult!.riskScore}/100',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Registered Name: ${checkResult!.verifiedLegalName}',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        ...checkResult!.warnings.map(
                          (w) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(w, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MODAL 5: Safe Pay (Protected Pay Escrow for Strangers)
  // ==========================================================
  void _showSafePayDialog(BuildContext context) {
    final sellerVpaCtrl = TextEditingController(text: 'olx.seller@okaxis');
    final sellerNameCtrl = TextEditingController(text: 'Vikram Electronics');
    final itemCtrl = TextEditingController(text: 'Used iPad Air 5th Gen');
    final amtCtrl = TextEditingController(text: '2500');
    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setEscrowState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🤝 Safe Pay (Escrow Hold)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Text(
                  'Buying from OLX/Instagram? Money is locked in NPCI Escrow and only released when you confirm item delivery!',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: sellerVpaCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Seller UPI ID',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sellerNameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Seller Name',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: amtCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: itemCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Item / Service Description',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E22CE),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isCreating
                      ? null
                      : () async {
                          final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
                          if (amt <= 0) return;
                          setEscrowState(() => isCreating = true);
                          await BharatOnePayApi.initiateProtectedPay(
                            sellerVpa: sellerVpaCtrl.text.trim(),
                            sellerName: sellerNameCtrl.text.trim(),
                            amount: amt,
                            itemDescription: itemCtrl.text.trim(),
                          );
                          setEscrowState(() => isCreating = false);
                          _loadFreshUserData();
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF046A38),
                              content: Text('🔒 ₹${amt.toStringAsFixed(0)} locked in NPCI Escrow for ${sellerNameCtrl.text}!'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.lock_clock, color: Colors.white),
                  label: Text(
                    isCreating ? 'Locking Funds...' : 'Lock Funds in Protected Escrow',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (BharatOnePayApi.activeEscrows.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text('Active Escrow Holds', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...BharatOnePayApi.activeEscrows.take(3).map((ProtectedPayEscrowModel esc) {
                    final isHeld = esc.status == 'HELD_IN_ESCROW';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isHeld ? const Color(0xFFA855F7) : const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${esc.itemDescription} • ₹${esc.amount.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isHeld ? const Color(0xFF581C87) : const Color(0xFF064E3B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  esc.status,
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Seller: ${esc.sellerName} (${esc.sellerVpa})', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          if (isHeld) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                    ),
                                    onPressed: () async {
                                      await BharatOnePayApi.confirmDelivery(esc.id);
                                      setEscrowState(() {});
                                      _loadFreshUserData();
                                    },
                                    child: const Text('✓ Confirm Delivery', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.redAccent),
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                    ),
                                    onPressed: () async {
                                      await BharatOnePayApi.disputeEscrow(esc.id, 'Item not delivered as described');
                                      setEscrowState(() {});
                                      _loadFreshUserData();
                                    },
                                    child: const Text('⚠ Dispute / Refund', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MODAL 6: Digital Gullak (Micro-Savings Deposit & Withdraw)
  // ==========================================================
  void _showGullakModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setGullakState) {
          final saved = BharatOnePayApi.gullakBalance;
          final progress = (saved / 25000.0).clamp(0.0, 1.0);
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🐖 Digital Gullak (Chillar Bachat)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Gullak Savings', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          Text('Goal: ₹25,000', style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('₹${saved.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFF334155),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Every UPI payment automatically rounds up spare change to the nearest ₹10 into your Gullak.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          await BharatOnePayApi.depositVault(500);
                          setGullakState(() {});
                          _loadFreshUserData();
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(backgroundColor: Color(0xFF046A38), content: Text('🐖 Added ₹500 to your Digital Gullak!')),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Save ₹500', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF38BDF8)),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final ok = await BharatOnePayApi.withdrawVault(500);
                          setGullakState(() {});
                          _loadFreshUserData();
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: ok ? const Color(0xFF046A38) : Colors.red,
                              content: Text(ok ? '✓ ₹500 withdrawn back to your Bank Account!' : 'Insufficient Gullak balance'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.account_balance, color: Color(0xFF38BDF8), size: 18),
                        label: const Text('Withdraw ₹500', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // MODAL 7: Real UPI Send Money Flow with Scam Shield & MPIN
  // ==========================================================
  void _showPayDialog(BuildContext context, {String? prefillVpa, String? prefillAmount}) {
    final vpaController = TextEditingController(text: prefillVpa ?? '');
    final amtController = TextEditingController(text: prefillAmount ?? '');
    final remarkController = TextEditingController(text: 'UPI Payment');
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('💸 Send Money via UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: vpaController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Recipient UPI ID or Phone',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  hintText: 'e.g. chaipoint@aiksetra or 9876543210@upi',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFFFF671F)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  hintText: '0.00',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF34D399)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarkController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Add Note / Remark',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        final rawVpa = vpaController.text.trim();
                        final vpa = rawVpa.contains('@') ? rawVpa : '$rawVpa@aiksetra';
                        final amt = double.tryParse(amtController.text.trim()) ?? 0;
                        if (rawVpa.isEmpty || amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid recipient UPI ID and amount')),
                          );
                          return;
                        }

                        final nav = Navigator.of(ctx);
                        setModalState(() => isProcessing = true);
                        final safety = await BharatOnePayApi.analyzeScamRisk(
                          receiverVpa: vpa,
                          amount: amt,
                          remark: remarkController.text.trim(),
                        );
                        setModalState(() => isProcessing = false);

                        if (!mounted) return;
                        nav.pop();
                        if (!mounted) return;

                        _showPaymentConfirmation(vpa, amt, remarkController.text.trim(), safety);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF671F),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify & Proceed to Pay →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentConfirmation(String vpa, double amt, String remark, ScamShieldResult safety) {
    final pinController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setConfirmState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                safety.riskLevel == 'HIGH' ? '🚨 Scam Shield Alert!' : '🔒 Secure NPCI Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: safety.riskLevel == 'HIGH' ? const Color(0xFFEF4444) : const Color(0xFF34D399),
                ),
              ),
              const SizedBox(height: 8),
              if (safety.warnings.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: (safety.riskLevel == 'HIGH' ? Colors.red : Colors.amber).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: safety.riskLevel == 'HIGH' ? Colors.red : Colors.amber),
                  ),
                  child: Text(safety.warnings.first, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vpa, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Paying from: ${BharatOnePayApi.currentAccount?.bankName ?? "Bank"}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₹${amt.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'Enter 4 or 6-digit UPI MPIN',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF671F)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final pin = pinController.text.trim();
                        if (pin.length < 4) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your UPI MPIN')));
                          return;
                        }
                        final nav = Navigator.of(ctx);
                        setConfirmState(() => isSubmitting = true);
                        final payRes = await BharatOnePayApi.payUpi(
                          receiverVpa: vpa,
                          amount: amt,
                          mpin: pin,
                          remark: remark,
                          bypassScamWarning: true,
                        );
                        setConfirmState(() => isSubmitting = false);

                        if (!mounted) return;
                        nav.pop();

                        if (payRes['success'] == true) {
                          if (!mounted) return;
                          _showPaymentSuccess(amt, vpa, payRes['transaction']?['upiRrn']?.toString() ?? '4291882019');
                          _loadFreshUserData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(backgroundColor: Colors.red, content: Text(payRes['message'] ?? 'Payment failed. Check MPIN.')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Authorize & Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSuccess(double amt, String receiver, String rrn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFF10B981))),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Payment Successful!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paid: ₹${amt.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF34D399), fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('To: $receiver', style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 4),
            Text('UPI RRN: $rrn', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MODAL 8: Real-Time Live FX Cross-Border Money Transfer
  // ==========================================================
  void _showAbroadDialog(BuildContext context) {
    String selectedCurrency = 'USD';
    final amtController = TextEditingController(text: '100');
    final beneficiaryNameController = TextEditingController(text: 'John Smith');
    final beneficiaryIbanController = TextEditingController(text: 'US64SVBK000000123456789');
    CrossBorderQuoteModel? currentQuote;
    bool isLoadingQuote = false;
    bool isExecuting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setAbroadState) {
          void fetchQuote() async {
            final amt = double.tryParse(amtController.text.trim()) ?? 0;
            if (amt <= 0) return;
            setAbroadState(() => isLoadingQuote = true);
            try {
              final quote = await BharatOnePayApi.getCrossBorderQuote(
                targetCurrency: selectedCurrency,
                targetAmount: amt,
              );
              setAbroadState(() {
                currentQuote = quote;
                isLoadingQuote = false;
              });
            } catch (e) {
              setAbroadState(() => isLoadingQuote = false);
            }
          }

          if (currentQuote == null && !isLoadingQuote) {
            fetchQuote();
          }

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🌍 Send Money Abroad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Text('Live FX rates • Direct Rupee rail settlement', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCurrency,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 'USD', child: Text('🇺🇸 USD - US Dollar')),
                                DropdownMenuItem(value: 'AED', child: Text('🇦🇪 AED - UAE Dirham (Direct Rupee)')),
                                DropdownMenuItem(value: 'EUR', child: Text('🇪🇺 EUR - Eurozone')),
                                DropdownMenuItem(value: 'GBP', child: Text('🇬🇧 GBP - British Pound')),
                                DropdownMenuItem(value: 'SGD', child: Text('🇸🇬 SGD - Singapore PayNow')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setAbroadState(() {
                                    selectedCurrency = val;
                                    currentQuote = null;
                                  });
                                  fetchQuote();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: amtController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Amount to Receive in $selectedCurrency',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFFFF671F)),
                        onPressed: fetchQuote,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
                    ),
                    onSubmitted: (_) => fetchQuote(),
                  ),
                  const SizedBox(height: 14),

                  if (isLoadingQuote)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Color(0xFFFF671F))))
                  else if (currentQuote != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF046A38).withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Live FX Rate (INR/$selectedCurrency)', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF046A38), borderRadius: BorderRadius.circular(6)),
                                child: const Text('LIVE RATE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('1 $selectedCurrency = ₹${currentQuote!.exchangeRate.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 16)),
                          const Divider(color: Color(0xFF334155), height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Cost in INR:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('₹${currentQuote!.totalCostInr.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF671F), fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(currentQuote!.routeSimpleName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: beneficiaryNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Beneficiary Full Name',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: beneficiaryIbanController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Beneficiary IBAN / Account #',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF334155))),
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: isExecuting || currentQuote == null
                        ? null
                        : () async {
                            final name = beneficiaryNameController.text.trim();
                            final iban = beneficiaryIbanController.text.trim();
                            if (name.isEmpty || iban.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill in beneficiary name and IBAN/Account')),
                              );
                              return;
                            }

                            final nav = Navigator.of(ctx);
                            setAbroadState(() => isExecuting = true);
                            final res = await BharatOnePayApi.executeCrossBorder(
                              quoteId: currentQuote!.quoteId,
                              beneficiaryName: name,
                              beneficiaryAccountOrIban: iban,
                              totalCostInr: currentQuote!.totalCostInr,
                              targetAmount: currentQuote!.targetAmount,
                              targetCurrency: selectedCurrency,
                            );
                            setAbroadState(() => isExecuting = false);

                            nav.pop();
                            if (!mounted) return;

                            if (res['success'] == true) {
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    backgroundColor: const Color(0xFF0F172A),
                                    title: const Text('🎉 Remittance Settled!', style: TextStyle(color: Colors.white)),
                                    content: Text(
                                      'Paid ₹${res['amountPaidInr']} for ${res['amountReceivedForeign']} ${res['foreignCurrency']} to $name via ${res['rail']}.\nRef #${res['transferId']}',
                                      style: const TextStyle(color: Color(0xFF94A3B8)),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Done', style: TextStyle(color: Color(0xFF34D399)))),
                                    ],
                                  ),
                                );
                                _loadFreshUserData();
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isExecuting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Lock Rate & Send Remittance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
