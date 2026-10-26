import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/bharat_one_pay_api.dart';
import '../utils/app_translations.dart';
import '../services/biometric_service.dart';
import '../models/scam_shield_model.dart';
import '../models/cross_border_model.dart';
import '../api_config.dart';
import 'login_screen.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  String _selectedLang = 'en-IN';
  String _t(String key) => AppTranslations.t(key, _selectedLang);
  bool _showBalance = true;
  int _bottomNavIndex = 0;
  bool _isBiometricLockActive = true;

  // BBPS Bill Tab State
  String _selectedBillCategory = 'ELECTRICITY';
  Map<String, dynamic>? _selectedBiller;
  final TextEditingController _consumerIdCtrl = TextEditingController();
  Map<String, dynamic>? _fetchedBill;
  bool _isFetchingBill = false;

  // SIP Tab State
  double _calcMonthlySip = 2500;
  double _calcYears = 5;

  // Global FX Tab State
  String _fxCurrency = 'USD';
  final TextEditingController _fxForeignAmtCtrl = TextEditingController(text: '100');
  final TextEditingController _fxBenNameCtrl = TextEditingController();
  final TextEditingController _fxBenIbanCtrl = TextEditingController();
  String _fxPurposeCode = 'S0301 - Family Maintenance & Savings';
  CrossBorderQuoteModel? _fxQuote;
  bool _isLoadingFxQuote = false;

  final Map<String, String> _langNames = {
    'en-IN': 'English',
    'hi-IN': 'हिंदी',
    'bn-IN': 'বাংলা',
    'ta-IN': 'தமிழ்',
    'te-IN': 'తెలుగు',
  };

  @override
  void initState() {
    super.initState();
    _syncLiveState();
  }

  @override
  void dispose() {
    _consumerIdCtrl.dispose();
    _fxForeignAmtCtrl.dispose();
    _fxBenNameCtrl.dispose();
    _fxBenIbanCtrl.dispose();
    super.dispose();
  }

  Future<void> _syncLiveState() async {
    await BharatOnePayApi.getMe();
    await BharatOnePayApi.getVaults();
    await BharatOnePayApi.getTransactionHistory();
    await BharatOnePayApi.getBillers();
    await BharatOnePayApi.getSipPlansAndPortfolio();
    await BharatOnePayApi.getMyEscrows();
    final bioEnabled = await BiometricService.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _isBiometricLockActive = bioEnabled;
      final elecBillers = BharatOnePayApi.bbpsBillers
          .where((b) => b['category'] == _selectedBillCategory)
          .toList();
      if (elecBillers.isNotEmpty && _selectedBiller == null) {
        _selectedBiller = elecBillers.first;
      }
    });
    _refreshFxQuote();
  }

  Future<void> _refreshFxQuote() async {
    final amt = double.tryParse(_fxForeignAmtCtrl.text.trim()) ?? 100.0;
    if (amt <= 0) return;
    setState(() => _isLoadingFxQuote = true);
    final q = await BharatOnePayApi.getCrossBorderQuote(
      targetCurrency: _fxCurrency,
      targetAmount: amt,
    );
    if (!mounted) return;
    setState(() {
      _fxQuote = q;
      _isLoadingFxQuote = false;
    });
  }

  String get _userName => BharatOnePayApi.currentUser?.fullName ?? 'AikSetra User';
  String get _userVpa => BharatOnePayApi.currentUser?.primaryVpa ?? 'user@aiksetra';
  String get _bankName => BharatOnePayApi.currentAccount?.bankName ?? 'State Bank of India';
  String get _maskedAcc => BharatOnePayApi.currentAccount?.maskedAccountNumber ?? '•••• •••• 0000';
  String get _ifsc => BharatOnePayApi.currentAccount?.ifsc ?? 'SBIN0001234';
  double get _bankBalance => BharatOnePayApi.currentAccount?.balance ?? 0.0;
  double get _gullakBalance => BharatOnePayApi.gullakBalance;
  double get _sipTotalValue => (BharatOnePayApi.sipPortfolio['currentValue'] as num?)?.toDouble() ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildTopAppBar(),
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          _buildHomeTab(),
          _buildBillsTab(),
          _buildSipTab(),
          _buildAbroadTab(),
          _buildAccountTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ===========================================================================
  // TOP APP BAR
  // ===========================================================================
  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      titleSpacing: 16,
      title: InkWell(
        onTap: _showUserProfileDetailsModal,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF671F), Color(0xFF046A38)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'ऐ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_t('namaste')}, ${_userName.split(' ').first}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _userVpa,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
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
          onPressed: _showServerConfigDialog,
          icon: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF34D399), size: 20),
          tooltip: 'Configure Backend Server IP',
        ),
        IconButton(
          onPressed: () {
            _syncLiveState();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔄 Synced live bank balance, bills, SIPs & transactions'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.sync, color: Color(0xFF38BDF8), size: 20),
          tooltip: 'Sync with Bank Switch',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLang,
              dropdownColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.language, color: Color(0xFFFF671F), size: 16),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              items: _langNames.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLang = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 0: HOME SCREEN
  // ===========================================================================
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _syncLiveState,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrimaryBankCard(),
            const SizedBox(height: 16),
            _buildHeroQrAndActions(),
            const SizedBox(height: 20),
            _buildBillsAndUtilitiesQuickGrid(),
            const SizedBox(height: 20),
            _buildWealthAndSafetyHighlights(),
            const SizedBox(height: 20),
            _buildQuickTransferBar(),
            const SizedBox(height: 20),
            _buildRealTransactionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryBankCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF671F).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance, color: Color(0xFFFF671F), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bankName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$_maskedAcc • IFSC: $_ifsc',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showAddMoneyAndSelfTransferModal(initialAddMoneyMode: true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF046A38),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF046A38).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('+ Add Money', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _showSelfTransferModal,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz, color: Color(0xFF38BDF8), size: 14),
                          const SizedBox(width: 4),
                          Text(_t('self_transfer'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AVAILABLE BANK BALANCE',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _showBalance ? '₹${_bankBalance.toStringAsFixed(2)}' : '₹ ••••••',
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() => _showBalance = !_showBalance),
                        child: Icon(
                          _showBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _bottomNavIndex = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('📈 SIP Wealth', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('₹${_sipTotalValue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showGullakModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('🏺 Gullak', style: TextStyle(color: Color(0xFFFCD34D), fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('₹${_gullakBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroQrAndActions() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: InkWell(
            onTap: _openRealCameraQrScanner,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 170,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF046A38), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF046A38).withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, size: 42, color: Color(0xFF046A38)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'SCAN ANY UPI QR',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.4),
                  ),
                  const Text(
                    'Live Camera • GPay • PhonePe • BHIM',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              InkWell(
                onTap: () => _showSendMoneyDialog(),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 79,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF671F),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF671F).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 26),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Send Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                            Text('Any UPI ID or Mobile', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _showReceiveQrModal,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 79,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, color: Color(0xFF0F172A), size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('My UPI QR', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14)),
                            Text('Scannable by GPay/PhonePe', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                          ],
                        ),
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

  Widget _buildBillsAndUtilitiesQuickGrid() {
    final items = [
      {'label': 'Electricity', 'icon': Icons.bolt_rounded, 'color': const Color(0xFFD97706), 'cat': 'ELECTRICITY'},
      {'label': 'Water Bill', 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF0284C7), 'cat': 'WATER'},
      {'label': 'Gas / LPG', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFDC2626), 'cat': 'GAS'},
      {'label': 'Broadband', 'icon': Icons.router_rounded, 'color': const Color(0xFF059669), 'cat': 'BROADBAND'},
      {'label': 'Mobile 5G', 'icon': Icons.phone_android_rounded, 'color': const Color(0xFF4F46E5), 'cat': 'MOBILE'},
      {'label': 'FASTag', 'icon': Icons.directions_car_rounded, 'color': const Color(0xFF0F172A), 'cat': 'FASTAG'},
      {'label': 'DTH TV', 'icon': Icons.tv_rounded, 'color': const Color(0xFF7C3AED), 'cat': 'DTH'},
      {'label': 'Bank SIP', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF046A38), 'cat': 'SIP'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFFFF671F)),
                  SizedBox(width: 6),
                  Text(
                    'Bills, Utilities & Recharges (BBPS)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _bottomNavIndex = 1),
                child: const Text(
                  'All Bills →',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF671F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, idx) {
              final item = items[idx];
              final color = item['color'] as Color;
              return InkWell(
                onTap: () {
                  final cat = item['cat'] as String;
                  if (cat == 'SIP') {
                    setState(() => _bottomNavIndex = 2);
                  } else {
                    _selectBillCategoryAndOpen(cat);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item['icon'] as IconData, color: color, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _selectBillCategoryAndOpen(String category) {
    final matching = BharatOnePayApi.bbpsBillers.where((b) => b['category'] == category).toList();
    setState(() {
      _selectedBillCategory = category;
      _fetchedBill = null;
      _consumerIdCtrl.clear();
      if (matching.isNotEmpty) {
        _selectedBiller = matching.first;
      }
      _bottomNavIndex = 1;
    });
  }

  Widget _buildWealthAndSafetyHighlights() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _bottomNavIndex = 2),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.auto_graph_rounded, color: Color(0xFF046A38), size: 20),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bank Auto-SIP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                        Text('Nifty 50 • Gold • Debt', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _bottomNavIndex = 3),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE0E7FF),
                    child: Icon(Icons.public_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Foreign FX Pay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                        Text('USD • GBP • EUR • SGD', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTransferBar() {
    // Dynamically derive unique payees from user's real transaction history
    final seenVpas = <String>{};
    final recentPayees = <Map<String, String>>[];
    for (final t in BharatOnePayApi.recentTransactions) {
      final vpa = (t['receiverVpa'] ?? '').toString().trim();
      final name = (t['receiverName'] ?? vpa).toString().trim();
      if (vpa.isNotEmpty && vpa != _userVpa && seenVpas.add(vpa)) {
        recentPayees.add({'name': name, 'vpa': vpa});
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Direct UPI Transfer & Safe Escrow',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              InkWell(
                onTap: _showSafePayDialog,
                child: const Text(
                  '🛡️ Safe Escrow',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _showSendMoneyDialog(),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: Color(0xFFFF671F), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter any UPI ID (e.g. name@okaxis, @ybl, @aiksetra) or 10-digit mobile...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (recentPayees.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Recent Payees',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentPayees.take(5).map((p) {
                return ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: const Color(0xFFFF671F),
                    child: Text(
                      p['name']!.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  label: Text(p['name']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: () => _showSendMoneyDialog(
                    prefillVpa: p['vpa'],
                    prefillName: p['name'],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRealTransactionsSection() {
    final txns = BharatOnePayApi.recentTransactions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Real Bank Transactions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              '${txns.length} Recorded',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (txns.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text(
                  'No transactions yet on this account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                ),
                SizedBox(height: 4),
                Text(
                  'Scan any real UPI QR code, send money, pay a utility bill, or start a Bank SIP — every transaction is recorded here with an NPCI RRN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          ...txns.take(15).map((t) {
            final name = (t['receiverName'] ?? t['receiverVpa'] ?? 'UPI Payment').toString();
            final remark = (t['remark'] ?? 'NPCI UPI Settlement').toString();
            final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
            final rrn = (t['upiRrn'] ?? t['txnRef'] ?? '42910012').toString();
            final isCredit = (t['metadata'] is Map && t['metadata']['isCredit'] == true) ||
                remark.toLowerCase().contains('credited') ||
                remark.toLowerCase().contains('self transfer') ||
                remark.toLowerCase().contains('deposit');
            return InkWell(
              onTap: () => _showTransactionReceiptModal(t),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                        color: isCredit ? const Color(0xFF046A38) : const Color(0xFF0F172A),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$remark • RRN: $rrn',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isCredit ? "+" : "-"}₹${amt.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isCredit ? const Color(0xFF046A38) : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ===========================================================================
  // TAB 1: BBPS UTILITY BILLS & RECHARGES (Electricity, Water, Gas, Broadband)
  // ===========================================================================
  Widget _buildBillsTab() {
    final categories = [
      {'id': 'ELECTRICITY', 'label': '⚡ Electricity'},
      {'id': 'WATER', 'label': '💧 Water'},
      {'id': 'GAS', 'label': '🔥 Gas / LPG'},
      {'id': 'BROADBAND', 'label': '🌐 Broadband'},
      {'id': 'MOBILE', 'label': '📱 Mobile 5G'},
      {'id': 'FASTAG', 'label': '🚗 FASTag'},
      {'id': 'DTH', 'label': '📺 DTH TV'},
    ];

    final filteredBillers = BharatOnePayApi.bbpsBillers
        .where((b) => b['category'] == _selectedBillCategory)
        .toList();

    if (_selectedBiller == null && filteredBillers.isNotEmpty) {
      _selectedBiller = filteredBillers.first;
    }

    final billTxns = BharatOnePayApi.recentTransactions
        .where((t) => (t['metadata'] is Map && t['metadata']['isBbpsBill'] == true) ||
            (t['remark'] ?? '').toString().toLowerCase().contains('bill'))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF671F).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFFFF671F), size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bharat BillPay (BBPS) Utility Hub',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Instant Electricity, Water, Piped Gas, Broadband & FASTag Bill Fetch & Settlement',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category Selector Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final c = categories[idx];
                final isSelected = c['id'] == _selectedBillCategory;
                return ChoiceChip(
                  label: Text(c['label']!),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF671F),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    final cat = c['id']!;
                    final list = BharatOnePayApi.bbpsBillers.where((b) => b['category'] == cat).toList();
                    setState(() {
                      _selectedBillCategory = cat;
                      _fetchedBill = null;
                      _consumerIdCtrl.clear();
                      _selectedBiller = list.isNotEmpty ? list.first : null;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Biller Selection & Consumer Fetch Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Select Official Biller / Utility Board',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                if (filteredBillers.isEmpty)
                  const Text('Loading BBPS billers...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filteredBillers.map((b) {
                      final isSel = _selectedBiller != null && _selectedBiller!['id'] == b['id'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBiller = b;
                            _fetchedBill = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF046A38).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? const Color(0xFF046A38) : const Color(0xFFCBD5E1),
                              width: isSel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b['name'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSel ? const Color(0xFF046A38) : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                b['stateOrCircle'] ?? '',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                Text(
                  '2. Enter ${_selectedBiller?['consumerIdLabel'] ?? 'Consumer / Account Number'}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _consumerIdCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter ${_selectedBiller?['consumerIdLabel'] ?? 'Consumer ID'}',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isFetchingBill ? null : _handleFetchBbpsBill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isFetchingBill
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Fetch Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                // Fetched Bill Statement Card
                if (_fetchedBill != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'OFFICIAL BBPS BILL STATEMENT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF046A38), letterSpacing: 0.6),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _fetchedBill!['alreadyPaid'] == true ? const Color(0xFF046A38) : const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _fetchedBill!['alreadyPaid'] == true ? 'PAID' : 'DUE: ${_fetchedBill!['dueDate']}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        _buildBillRow('Consumer Name', _fetchedBill!['consumerName'].toString()),
                        _buildBillRow('Biller', _fetchedBill!['billerName'].toString()),
                        _buildBillRow('Bill Number', _fetchedBill!['billNumber'].toString()),
                        _buildBillRow('Billing Period', _fetchedBill!['billPeriod'].toString()),
                        _buildBillRow('Usage / Plan', _fetchedBill!['planOrUsage'].toString()),
                        if (_fetchedBill!['meterNumber'] != null)
                          _buildBillRow('Meter Number', _fetchedBill!['meterNumber'].toString()),
                        if (_fetchedBill!['unitsConsumed'] != null)
                          _buildBillRow('Units Consumed', '${_fetchedBill!['unitsConsumed']} kWh'),
                        if (_fetchedBill!['energyCharges'] != null)
                          _buildBillRow('Energy Charges (Slabs)', '₹${(_fetchedBill!['energyCharges'] as num).toStringAsFixed(2)}'),
                        if (_fetchedBill!['fixedCharge'] != null)
                          _buildBillRow('Demand / Fixed Charge', '₹${(_fetchedBill!['fixedCharge'] as num).toStringAsFixed(2)}'),
                        if (_fetchedBill!['electricityDuty'] != null)
                          _buildBillRow('State Electricity Duty (6%)', '₹${(_fetchedBill!['electricityDuty'] as num).toStringAsFixed(2)}'),
                        if (_fetchedBill!['breakdown'] is List) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Official SERC Slab Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF334155))),
                                const SizedBox(height: 4),
                                ...((_fetchedBill!['breakdown'] as List).map((b) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1),
                                  child: Text('• $b', style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                                ))),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Bill Payable', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text(
                              '₹${(_fetchedBill!['amount'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF046A38)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handlePayBbpsBill(_fetchedBill!),
                            icon: const Icon(Icons.verified_user_rounded, size: 18),
                            label: Text(
                              'Pay ₹${(_fetchedBill!['amount'] as num).toStringAsFixed(0)} via $_bankName',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF046A38),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Paid Utility Bills History
          const Text(
            'Your Paid Utility Bills & Receipts',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          if (billTxns.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No utility bills paid yet. Enter your Consumer / Account ID above to fetch and pay your bill.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            )
          else
            ...billTxns.map((b) => InkWell(
                  onTap: () => _showTransactionReceiptModal(b),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (b['receiverName'] ?? 'BBPS Bill').toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                (b['remark'] ?? '').toString(),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${((b['amount'] as num?) ?? 0).toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF046A38)),
                            ),
                            const Text('BBPS PAID ✓', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFetchBbpsBill() async {
    if (_selectedBiller == null) return;
    final cid = _consumerIdCtrl.text.trim();
    if (cid.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Consumer / Account Number (at least 4 digits/chars)')),
      );
      return;
    }
    setState(() => _isFetchingBill = true);
    final res = await BharatOnePayApi.fetchBillDetails(
      billerId: _selectedBiller!['id'],
      consumerNumber: cid,
    );
    if (!mounted) return;
    setState(() {
      _isFetchingBill = false;
      if (res['success'] == true && res['bill'] != null) {
        _fetchedBill = Map<String, dynamic>.from(res['bill']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to fetch bill')),
        );
      }
    });
  }

  Future<void> _handlePayBbpsBill(Map<String, dynamic> bill) async {
    final mpin = await _promptForMpin(
      title: 'Pay ${bill['billerName']}',
      subtitle: 'Consumer: ${bill['consumerNumber']} • Amount: ₹${bill['amount']}',
    );
    if (mpin == null || mpin.length < 4) return;

    final res = await BharatOnePayApi.payBill(
      billerId: bill['billerId'],
      consumerNumber: bill['consumerNumber'],
      amount: (bill['amount'] as num).toDouble(),
      mpin: mpin,
      billNumber: bill['billNumber'],
      planOrUsage: bill['planOrUsage'],
    );

    if (!mounted) return;
    if (res['success'] == true) {
      await _syncLiveState();
      if (!mounted) return;
      setState(() {
        if (_fetchedBill != null) _fetchedBill!['alreadyPaid'] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF046A38),
          content: Text('✅ Bill Paid! Ref: ${res['bbpsRef']} • Updated Bank Balance: ₹${_bankBalance.toStringAsFixed(2)}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Bill payment failed')),
      );
    }
  }

  // ===========================================================================
  // TAB 2: BANK AUTO-SIP & WEALTH (Mutual Funds, Nifty 50, Gold, Gullak)
  // ===========================================================================
  Widget _buildSipTab() {
    final plans = BharatOnePayApi.sipPlans;
    final mySips = BharatOnePayApi.mySips;
    final portfolio = BharatOnePayApi.sipPortfolio;

    final months = (_calcYears * 12).round();
    const monthlyRate = 0.156 / 12;
    double maturityVal = 0;
    for (int m = 0; m < months; m++) {
      maturityVal = (maturityVal + _calcMonthlySip) * (1 + monthlyRate);
    }
    final totalInvestedCalc = _calcMonthlySip * months;
    final wealthGainedCalc = maturityVal - totalInvestedCalc;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF046A38), Color(0xFF065F46)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BANK AUTO-SIP & WEALTH PORTFOLIO',
                      style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Linked: $_bankName',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${((portfolio['currentValue'] as num?) ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invested: ₹${((portfolio['totalInvested'] as num?) ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'Gain: +₹${((portfolio['totalReturns'] as num?) ?? 0).toStringAsFixed(2)} (+${portfolio['returnPct'] ?? 0}%)',
                      style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Live Indian Stock Market Indices (NSE & BSE)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Color(0xFF4ADE80), size: 14),
                            SizedBox(width: 4),
                            Text('NIFTY 50', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text('24,852.15', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                        Text('+164.20 (+0.67%) ▲', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Color(0xFF4ADE80), size: 14),
                            SizedBox(width: 4),
                            Text('BSE SENSEX', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text('81,424.30', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                        Text('+528.10 (+0.65%) ▲', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (mySips.isNotEmpty) ...[
            const Text(
              'Your Active Bank SIP Mandates',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            ...mySips.map((sip) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sip['planName'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '₹${sip['monthlyAmount']}/mo • Day ${sip['debitDay']}',
                              style: const TextStyle(color: Color(0xFF046A38), fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UMRN: ${sip['umrn']} • Units: ${sip['unitsHeld']} • Installments: ${sip['installmentsPaid']}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Invested', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text('₹${sip['totalInvested']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Current Value', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text(
                                '₹${sip['currentValue']}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF046A38)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handlePayExtraSipInstallment(sip),
                              child: const Text('+ Top-up Installment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleRedeemSip(sip),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Redeem to Bank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // ===================================================================
          // INDIAN STOCK MARKET WATCHLIST & INSTANT BUY / STOCK SIP (NSE / BSE)
          // ===================================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t('stocks_watchlist'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Color(0xFF046A38), size: 8),
                    SizedBox(width: 4),
                    Text('NSE LIVE', style: TextStyle(color: Color(0xFF046A38), fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...BharatOnePayApi.indianStocks.map((stock) {
            final isPositive = (stock['change'] as num) >= 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF1F5F9),
                    child: Text(
                      (stock['symbol'] as String).substring(0, 2),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock['symbol'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A))),
                        Text(stock['name'], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                        Text(stock['sector'] ?? '', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${(stock['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${(stock['change'] as num).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? const Color(0xFF046A38) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _handleBuyStock(stock),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Buy Share', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _handleStockSip(stock),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Stock SIP', style: TextStyle(color: Color(0xFF046A38), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          const Text(
            'Start a Direct Bank Auto-SIP (0% Commission)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          ...plans.map((plan) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            plan['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${plan['cagr3Y']}% 3Y CAGR',
                            style: const TextStyle(color: Color(0xFF046A38), fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan['amcOrIssuer']} • ${plan['category']} • NAV: ₹${plan['navOrUnitPrice']}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan['description'] ?? '',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Min SIP: ₹${plan['minMonthlyAmount']}/mo • Risk: ${plan['riskLevel']}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        ElevatedButton(
                          onPressed: () => _showStartSipDialog(plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF671F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Start Bank SIP →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🧮 Bank SIP Compounding Calculator (15.6% p.a.)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monthly Bank Debit:', style: TextStyle(fontSize: 12)),
                    Text('₹${_calcMonthlySip.toStringAsFixed(0)} / month', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFFFF671F))),
                  ],
                ),
                Slider(
                  value: _calcMonthlySip,
                  min: 500,
                  max: 25000,
                  divisions: 49,
                  activeColor: const Color(0xFFFF671F),
                  onChanged: (v) => setState(() => _calcMonthlySip = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Investment Duration:', style: TextStyle(fontSize: 12)),
                    Text('${_calcYears.toStringAsFixed(0)} Years', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF046A38))),
                  ],
                ),
                Slider(
                  value: _calcYears,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  activeColor: const Color(0xFF046A38),
                  onChanged: (v) => setState(() => _calcYears = v),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Invested', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text('₹${totalInvestedCalc.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Est. Wealth Gain', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text('+₹${wealthGainedCalc.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF059669))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Maturity Value', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text('₹${maturityVal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF046A38))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStartSipDialog(Map<String, dynamic> plan) {
    final amtCtrl = TextEditingController(text: (plan['minMonthlyAmount'] ?? 500).toString());
    int selectedDay = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start Bank Auto-SIP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              Text(
                '${plan['name']} (${plan['cagr3Y']}% 3Y CAGR)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF046A38), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Monthly SIP Installment Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [500, 1000, 2500, 5000].map((preset) {
                  return ActionChip(
                    label: Text('₹$preset'),
                    onPressed: () => setSheetState(() => amtCtrl.text = preset.toString()),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Auto-Debit Date:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  DropdownButton<int>(
                    value: selectedDay,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1st of Every Month')),
                      DropdownMenuItem(value: 5, child: Text('5th of Every Month')),
                      DropdownMenuItem(value: 10, child: Text('10th of Every Month')),
                      DropdownMenuItem(value: 15, child: Text('15th of Every Month')),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedDay = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amtCtrl.text.trim()) ?? 500.0;
                    Navigator.pop(ctx);
                    final mpin = await _promptForMpin(
                      title: 'Authorize Bank SIP Mandate',
                      subtitle: '${plan['name']} • 1st Installment: ₹${amt.toStringAsFixed(0)}',
                    );
                    if (mpin == null || mpin.length < 4) return;
                    final res = await BharatOnePayApi.createSipMandate(
                      planId: plan['id'],
                      monthlyAmount: amt,
                      debitDay: selectedDay,
                      mpin: mpin,
                    );
                    await _syncLiveState();
                    if (!mounted) return;
                    setState(() {});
                    if (res['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF046A38),
                          content: Text('🎉 SIP Active! 1st Installment of ₹${amt.toStringAsFixed(0)} invested.'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Failed')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Authorize Mandate & Invest Now ($_bankName)', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePayExtraSipInstallment(Map<String, dynamic> sip) async {
    final mpin = await _promptForMpin(
      title: 'SIP Top-up Installment',
      subtitle: '${sip['planName']} • Amount: ₹${sip['monthlyAmount']}',
    );
    if (mpin == null || mpin.length < 4) return;
    final res = await BharatOnePayApi.paySipInstallment(
      sipId: sip['id'],
      mpin: mpin,
    );
    if (!mounted) return;
    setState(() {});
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Color(0xFF046A38), content: Text('✅ Extra SIP Installment Invested!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Failed')),
      );
    }
  }

  Future<void> _handleRedeemSip(Map<String, dynamic> sip) async {
    final mpin = await _promptForMpin(
      title: 'Redeem SIP to $_bankName',
      subtitle: 'Credit ₹${sip['currentValue']} directly to your bank account',
    );
    if (mpin == null || mpin.length < 4) return;
    final res = await BharatOnePayApi.redeemSipToBank(
      sipId: sip['id'],
      mpin: mpin,
    );
    if (!mounted) return;
    setState(() {});
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF046A38),
          content: Text('🏦 ₹${res['creditedAmount']} credited back to $_bankName!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Redemption failed')),
      );
    }
  }

  // ===========================================================================
  // TAB 3: GLOBAL FX (IMPROVED FOREIGN CURRENCY TRANSFER)
  // ===========================================================================
  Widget _buildAbroadTab() {
    final corridors = [
      {'code': 'USD', 'flag': '🇺🇸', 'country': 'USA', 'rail': 'Fedwire / ACH'},
      {'code': 'GBP', 'flag': '🇬🇧', 'country': 'UK', 'rail': 'Faster Payments'},
      {'code': 'EUR', 'flag': '🇪🇺', 'country': 'Europe', 'rail': 'SEPA Instant'},
      {'code': 'SGD', 'flag': '🇸🇬', 'country': 'Singapore', 'rail': 'UPI-PayNow Direct'},
      {'code': 'AED', 'flag': '🇦🇪', 'country': 'UAE', 'rail': 'NPCI-AANI Rupee'},
      {'code': 'CAD', 'flag': '🇨🇦', 'country': 'Canada', 'rail': 'Interac EFT'},
      {'code': 'AUD', 'flag': '🇦🇺', 'country': 'Australia', 'rail': 'NPP PayID'},
    ];

    final fxTxns = BharatOnePayApi.recentTransactions
        .where((t) => (t['metadata'] is Map && t['metadata']['isCrossBorder'] == true) ||
            (t['remark'] ?? '').toString().toLowerCase().contains('remittance'))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(Icons.public_rounded, color: Color(0xFF818CF8), size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AikSetra Global FX & UPI International',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Direct Rupee-to-Foreign Currency Settlement • RBI LRS Compliant (USD 250,000/yr limit)',
                        style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            '1. Select Destination Country & Corridor',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: corridors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final c = corridors[idx];
                final isSel = c['code'] == _fxCurrency;
                return InkWell(
                  onTap: () {
                    setState(() => _fxCurrency = c['code']!);
                    _refreshFxQuote();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF312E81) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${c['flag']} ${c['code']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isSel ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c['rail']!,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSel ? const Color(0xFFC7D2FE) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Recipient Gets ($_fxCurrency)',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fxForeignAmtCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _refreshFxQuote(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                  decoration: InputDecoration(
                    labelText: 'Foreign Amount to Send',
                    prefixText: '$_fxCurrency ',
                    suffixText: _fxCurrency,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [50, 100, 250, 500, 1000].map((preset) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('$preset $_fxCurrency', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onPressed: () {
                              _fxForeignAmtCtrl.text = preset.toString();
                              _refreshFxQuote();
                            },
                          ),
                        )).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoadingFxQuote)
                  const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                else if (_fxQuote != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Column(
                      children: [
                        _buildBillRow('Guaranteed Exchange Rate', '1 $_fxCurrency = ₹${_fxQuote!.exchangeRate.toStringAsFixed(2)}'),
                        _buildSettlementRow('Base Converted Amount', '₹${_fxQuote!.sourceAmountInr.toStringAsFixed(2)}'),
                        _buildSettlementRow('Bank Remittance Fee (0.15%)', '₹${_fxQuote!.adBankFeeInr.toStringAsFixed(2)}'),
                        _buildSettlementRow('GST on Currency Conversion (Rule 32)', '₹${_fxQuote!.gstInr.toStringAsFixed(2)}'),
                        _buildSettlementRow('RBI LRS TCS u/s 206C(1G)', '₹0.00 (Nil up to ₹7 Lakhs)'),
                        _buildSettlementRow('Settlement Rail', _fxQuote!.partnerRail),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total INR Debit from Bank', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            Text(
                              '₹${_fxQuote!.totalCostInr.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF312E81)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('3. International Beneficiary / Contacts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const Text('Saved Contacts', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                // Beneficiary Contacts Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...[
                        {
                          'name': 'Soumo Naskar',
                          'flag': '🇺🇸',
                          'corridor': 'USD',
                          'rail': 'Fedwire / ACH',
                          'iban': 'US64CHAS12345678901234',
                          'purpose': 'S0301 - Family Maintenance & Savings',
                          'label': 'Soumo (US Chase)',
                        },
                        {
                          'name': 'University of Oxford',
                          'flag': '🇬🇧',
                          'corridor': 'GBP',
                          'rail': 'Faster Payments',
                          'iban': 'GB29BARC20041538291044',
                          'purpose': 'S0305 - Overseas University Tuition',
                          'label': 'Oxford (UK Tuition)',
                        },
                        {
                          'name': 'Priya Sharma',
                          'flag': '🇸🇬',
                          'corridor': 'SGD',
                          'rail': 'UPI-PayNow Direct',
                          'iban': 'SG12DBS992817293',
                          'purpose': 'S0301 - Family Maintenance & Savings',
                          'label': 'Priya (PayNow SG)',
                        },
                        {
                          'name': 'Emirates Living Trust',
                          'flag': '🇦🇪',
                          'corridor': 'AED',
                          'rail': 'NPCI-AANI Rupee',
                          'iban': 'AE070330000000001234567',
                          'purpose': 'S0306 - International Travel / Hotel',
                          'label': 'Dubai Living (UAE)',
                        },
                        {
                          'name': 'Toronto Family Care',
                          'flag': '🇨🇦',
                          'corridor': 'CAD',
                          'rail': 'Interac EFT',
                          'iban': 'CA040001000000009876543',
                          'purpose': 'S0301 - Family Maintenance & Savings',
                          'label': 'Toronto Care (CA)',
                        },
                      ].map((contact) {
                        final isSel = _fxBenNameCtrl.text == contact['name'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            selected: isSel,
                            selectedColor: const Color(0xFF312E81),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            label: Text('${contact['flag']} ${contact['label']}'),
                            onSelected: (_) {
                              setState(() {
                                _fxBenNameCtrl.text = contact['name']!;
                                _fxBenIbanCtrl.text = contact['iban']!;
                                _fxPurposeCode = contact['purpose']!;
                                _fxCurrency = contact['corridor']!;
                              });
                              _refreshFxQuote();
                            },
                          ),
                        );
                      }),
                      ActionChip(
                        label: const Text('+ Clear / Custom', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setState(() {
                            _fxBenNameCtrl.clear();
                            _fxBenIbanCtrl.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fxBenNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Recipient Full Legal Name',
                    hintText: 'Enter beneficiary name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fxBenIbanCtrl,
                  decoration: InputDecoration(
                    labelText: 'IBAN / SWIFT / PayNow / Account Number',
                    hintText: 'Enter destination IBAN or Account No',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _fxPurposeCode,
                  decoration: InputDecoration(
                    labelText: 'RBI LRS Purpose Code',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'S0301 - Family Maintenance & Savings', child: Text('S0301 - Family Maintenance')),
                    DropdownMenuItem(value: 'S0305 - Overseas University Tuition', child: Text('S0305 - Overseas Education')),
                    DropdownMenuItem(value: 'S0304 - Medical Treatment Abroad', child: Text('S0304 - Medical Treatment')),
                    DropdownMenuItem(value: 'S0306 - International Travel / Hotel', child: Text('S0306 - International Travel')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _fxPurposeCode = v);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleExecuteForeignRemittance,
                    icon: const Icon(Icons.flight_takeoff_rounded),
                    label: Text(
                      'Send ${_fxForeignAmtCtrl.text} $_fxCurrency Now',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF312E81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (fxTxns.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Recent International Transfers', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 10),
            ...fxTxns.map((t) => InkWell(
                  onTap: () => _showTransactionReceiptModal(t),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['receiverName']?.toString() ?? 'Foreign Transfer', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(t['remark']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Text(
                          '-₹${((t['amount'] as num?) ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF312E81)),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSettlementRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
          Flexible(child: Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Future<void> _handleExecuteForeignRemittance() async {
    if (_fxQuote == null) {
      await _refreshFxQuote();
    }
    if (_fxQuote == null) return;
    final benName = _fxBenNameCtrl.text.trim();
    final benIban = _fxBenIbanCtrl.text.trim();
    if (benName.isEmpty || benIban.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Recipient Name and IBAN / Account Number')),
      );
      return;
    }

    final mpin = await _promptForMpin(
      title: 'Confirm Foreign Remittance',
      subtitle: 'Send ${_fxQuote!.targetAmount} $_fxCurrency (₹${_fxQuote!.totalCostInr.toStringAsFixed(2)}) to $benName',
    );
    if (mpin == null || mpin.length < 4) return;

    final res = await BharatOnePayApi.executeCrossBorder(
      quoteId: _fxQuote!.quoteId,
      beneficiaryName: benName,
      beneficiaryAccountOrIban: benIban,
      totalCostInr: _fxQuote!.totalCostInr,
      targetAmount: _fxQuote!.targetAmount,
      targetCurrency: _fxCurrency,
      purposeCode: _fxPurposeCode.split(' ').first,
      mpin: mpin,
    );

    if (!mounted) return;
    setState(() {});
    if (res['success'] == true) {
      await _syncLiveState();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF046A38),
          content: Text('🌍 Remittance Settled! ${res['amountReceivedForeign']} $_fxCurrency sent to $benName'),
        ),
      );
      _fxBenNameCtrl.clear();
      _fxBenIbanCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Transfer failed')),
      );
    }
  }

  // ===========================================================================
  // TAB 4: BANK ACCOUNTS & PROFILE
  // ===========================================================================
  Widget _buildAccountTab() {
    final accounts = BharatOnePayApi.linkedAccounts;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _showUserProfileDetailsModal,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFFF671F),
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                        Text('UPI ID: $_userVpa', style: const TextStyle(color: Color(0xFFFF671F), fontSize: 12, fontFamily: 'monospace')),
                        Text(
                          'Mobile: +91 ${BharatOnePayApi.currentUser?.phone ?? ""}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showReceiveQrModal,
                    icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Linked Bank Accounts (48+ RBI Banks)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              TextButton.icon(
                onPressed: _showLinkAnotherBankModal,
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Link New Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...accounts.map((acc) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: acc.isPrimary ? const Color(0xFF046A38) : const Color(0xFFE2E8F0),
                    width: acc.isPrimary ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(acc.bankName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                        if (acc.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF046A38), borderRadius: BorderRadius.circular(6)),
                            child: const Text('PRIMARY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          )
                        else
                          TextButton(
                            onPressed: () async {
                              await BharatOnePayApi.setPrimaryAccount(acc.id);
                              if (mounted) setState(() {});
                            },
                            child: const Text('Set Primary', style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                    Text(
                      '${acc.maskedAccountNumber} • IFSC: ${acc.ifsc}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Balance: ₹${acc.balance.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF046A38)),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _showCheckBalanceDialog,
                              icon: const Icon(Icons.account_balance_wallet_outlined, size: 14),
                              label: Text(_t('check_balance'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddMoneyAndSelfTransferModal(initialAddMoneyMode: true),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                              label: const Text('+ Add Money', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showSelfTransferModal,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                              icon: const Icon(Icons.swap_horiz, size: 14),
                              label: Text(_t('self_transfer'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 14),

          // ===================================================================
          // LINKED DEBIT CARDS & CREDIT CARDS (RuPay Credit on UPI / VISA / MC)
          // ===================================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Linked Debit & Credit Cards',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              TextButton.icon(
                onPressed: _showLinkCardModal,
                icon: const Icon(Icons.add_card_rounded, size: 16),
                label: const Text('Add Debit / Credit Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                        'network': 'RuPay Global',
                        'bankName': _bankName,
                        'maskedCardNumber': '•••• •••• •••• ${_maskedAcc.replaceAll(RegExp(r'\D'), '').isEmpty ? '4519' : _maskedAcc.replaceAll(RegExp(r'\D'), '')}',
                        'last4': _maskedAcc.replaceAll(RegExp(r'\D'), '').isEmpty ? '4519' : _maskedAcc.replaceAll(RegExp(r'\D'), ''),
                        'expiry': '12/29',
                        'cardHolderName': _userName.toUpperCase(),
                        'balanceOrLimit': _bankBalance,
                        'upiEnabled': true,
                      }
                    ])
              .map((card) {
                final isCredit = card['cardType'] == 'CREDIT';
                final bName = (card['bankName'] ?? _bankName).toString();
                final cType = (card['cardType'] ?? 'DEBIT').toString();
                final cExp = (card['expiry'] ?? '12/29').toString();
                final cHolder = (card['cardHolderName'] ?? _userName).toString().toUpperCase();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCredit
                          ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                          : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$bName • $cType CARD',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              card['network'] ?? 'RuPay UPI',
                              style: const TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.w900, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        card['maskedCardNumber'] ?? '•••• •••• •••• 4821',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'VALID THRU: $cExp • $cHolder',
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontFamily: 'monospace'),
                          ),
                          Text(
                            'Limit/Bal: ₹${((card['balanceOrLimit'] as num?) ?? _bankBalance).toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showLinkCardModal,
              icon: const Icon(Icons.add_card_rounded, size: 16),
              label: const Text('+ Link Another Debit or Credit Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFF4F46E5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('Account, Security & Live Gateways', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          _buildToolTile(
            icon: Icons.fingerprint_rounded,
            title: 'Fingerprint & Biometric Lock',
            subtitle: _isBiometricLockActive ? 'Enabled for App Unlock & 1-Tap UPI Payments' : 'Disabled (Tap to Enable)',
            trailing: Switch(
              value: _isBiometricLockActive,
              activeColor: const Color(0xFF046A38),
              onChanged: (v) async {
                await BiometricService.setBiometricEnabled(v);
                setState(() => _isBiometricLockActive = v);
              },
            ),
            onTap: () async {
              final next = !_isBiometricLockActive;
              await BiometricService.setBiometricEnabled(next);
              setState(() => _isBiometricLockActive = next);
            },
          ),

          _buildToolTile(
            icon: Icons.lock_reset_rounded,
            title: 'Change 4-Digit UPI MPIN',
            subtitle: 'Update your NPCI transaction security PIN',
            onTap: _showChangeMpinDialog,
          ),
          _buildToolTile(
            icon: Icons.verified_user_outlined,
            title: 'Safe Pay Escrow Holds (${BharatOnePayApi.activeEscrows.length})',
            subtitle: 'Release or refund merchant escrow payments',
            onTap: _showSafePayDialog,
          ),
          _buildToolTile(
            icon: Icons.shield_outlined,
            title: 'AI Scam Shield Lookup',
            subtitle: 'Verify unknown UPI IDs before sending money',
            onTap: _showScamShieldModal,
          ),
          _buildToolTile(
            icon: Icons.wifi_tethering_rounded,
            title: 'Backend Server Wi-Fi & IP',
            subtitle: 'Host: ${ApiConfig.activeHost}:4000 (Tap to change IP)',
            onTap: _showServerConfigDialog,
          ),
          _buildToolTile(
            icon: Icons.logout_rounded,
            title: 'Switch Account / Logout',
            subtitle: 'Sign in with another mobile number or bank account',
            isDestructive: true,
            onTap: () async {
              await BharatOnePayApi.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
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
          backgroundColor: isDestructive ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
          child: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF0F172A), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDestructive ? Colors.red : const Color(0xFF0F172A)),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION BAR
  // ===========================================================================
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      selectedItemColor: const Color(0xFFFF671F),
      unselectedItemColor: const Color(0xFF64748B),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      onTap: (idx) => setState(() => _bottomNavIndex = idx),
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: _t('tab_home')),
        BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_rounded), label: _t('tab_bills')),
        BottomNavigationBarItem(icon: const Icon(Icons.trending_up_rounded), label: _t('tab_wealth')),
        BottomNavigationBarItem(icon: const Icon(Icons.public_rounded), label: _t('tab_global')),
        BottomNavigationBarItem(icon: const Icon(Icons.account_balance_rounded), label: _t('tab_bank')),
      ],
    );
  }

  // ===========================================================================
  // REAL HARDWARE CAMERA QR SCANNER (MobileScanner) & REAL QR GENERATOR
  // ===========================================================================
  Future<void> _openRealCameraQrScanner() async {
    final scannedRaw = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const _RealCameraQrScannerScreen(),
      ),
    );
    if (scannedRaw != null && scannedRaw.trim().isNotEmpty && mounted) {
      HapticFeedback.mediumImpact();
      _parseUpiUriAndPay(scannedRaw.trim());
    }
  }

  void _parseUpiUriAndPay(String raw) {
    final cleaned = raw.trim();
    String vpa = cleaned;
    String? name;
    String? amount;
    String? note;

    // 1. Universal Query Parameter Extractor (works even if pn=... has unencoded spaces or uppercase keys)
    String? extractParam(String key) {
      final reg = RegExp('(?:[?&]|^)$key=([^&]+)', caseSensitive: false);
      final m = reg.firstMatch(cleaned);
      if (m != null && m.group(1) != null) {
        try {
          return Uri.decodeComponent(m.group(1)!.replaceAll('+', ' ')).trim();
        } catch (_) {
          return m.group(1)!.trim();
        }
      }
      return null;
    }

    final paParam = extractParam('pa');
    if (paParam != null && paParam.isNotEmpty) {
      vpa = paParam;
      name = extractParam('pn');
      amount = extractParam('am');
      note = extractParam('tn') ?? extractParam('tr');
    } else {
      // 2. Check if BharatQR EMVCo string or arbitrary QR payload embeds a UPI VPA (e.g. merchant@ybl)
      final vpaMatch = RegExp(r'([a-zA-Z0-9.\-_]{2,64}@[a-zA-Z0-9]{2,32})').firstMatch(cleaned);
      if (vpaMatch != null) {
        vpa = vpaMatch.group(1)!;
      } else {
        // 3. Check if QR encodes a 10-digit Indian phone number
        final phoneMatch = RegExp(r'\b([6-9][0-9]{9})\b').firstMatch(cleaned);
        if (phoneMatch != null) {
          vpa = '${phoneMatch.group(1)}@aiksetra';
        }
      }
    }

    _showSendMoneyDialog(
      prefillVpa: vpa,
      prefillName: name,
      prefillAmount: amount,
      prefillNote: note,
    );
  }

  void _showReceiveQrModal() {
    final reqAmtCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final amt = reqAmtCtrl.text.trim();
          final upiUri =
              'upi://pay?pa=$_userVpa&pn=${Uri.encodeComponent(_userName)}${amt.isNotEmpty ? "&am=$amt" : ""}&cu=INR';
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text('$_bankName • $_maskedAcc', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                // REAL ISO-18004 Scannable QR Code using qr_flutter
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0F172A), width: 2),
                  ),
                  child: QrImageView(
                    data: upiUri,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Scannable with Google Pay, PhonePe, Paytm, BHIM & AikSetra',
                  style: TextStyle(fontSize: 10, color: Color(0xFF046A38), fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Text(
                    'Demo Payment QR — No real money transferred',
                    style: TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  _userVpa,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFFF671F), fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reqAmtCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Optional: Set Specific Amount to Receive (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: upiUri));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📋 UPI QR URI copied to clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy UPI Link'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                        child: const Text('Done'),
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

  // ===========================================================================
  // SEND MONEY DIALOG (BANK ACCOUNT / DEBIT CARD / CREDIT CARD + UPI INTENT)
  // ===========================================================================
  void _showSendMoneyDialog({
    String? prefillVpa,
    String? prefillName,
    String? prefillAmount,
    String? prefillNote,
  }) {
    final vpaCtrl = TextEditingController(text: prefillVpa ?? '');
    final amtCtrl = TextEditingController(text: prefillAmount ?? '');
    final noteCtrl = TextEditingController(
      text: prefillNote ?? (prefillName != null ? 'Payment to $prefillName' : ''),
    );
    bool useEscrow = false;
    String? selectedCardId; // null = pay from Primary Bank Account, non-null = pay from Linked Debit/Credit Card

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
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
                Text(
                  prefillName != null ? 'Pay $prefillName' : 'Send Money via NPCI UPI / Card',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),

                // Payment Instrument Selector (Bank Account vs Linked Debit / Credit Cards)
                const Text('Pay Using:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('🏦 $_bankName (₹${_bankBalance.toStringAsFixed(0)})'),
                        selected: selectedCardId == null,
                        selectedColor: const Color(0xFF046A38),
                        labelStyle: TextStyle(
                          color: selectedCardId == null ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setSheetState(() => selectedCardId = null),
                      ),
                      const SizedBox(width: 8),
                      ...BharatOnePayApi.linkedCards.map((c) {
                        final cid = c['id'].toString();
                        final isSel = selectedCardId == cid;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('💳 ${c['network']} ${c['cardType']} (${c['last4']})'),
                            selected: isSel,
                            selectedColor: const Color(0xFF4F46E5),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setSheetState(() => selectedCardId = cid),
                          ),
                        );
                      }),
                      ActionChip(
                        label: const Text('+ Add Card', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showLinkCardModal();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: vpaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Recipient UPI ID or 10-Digit Mobile No',
                    hintText: 'e.g. merchant@okaxis, shop@ybl, or 9830113038',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Remark / Purpose',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: useEscrow,
                  activeColor: const Color(0xFF2563EB),
                  title: const Text('🛡️ Hold in Safe Pay Escrow until delivery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Money is locked safely and released only when you confirm receipt', style: TextStyle(fontSize: 10)),
                  onChanged: (v) => setSheetState(() => useEscrow = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      String rawVpa = vpaCtrl.text.trim();
                      final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                      if (rawVpa.isEmpty || amt <= 0) return;
                      if (!rawVpa.contains('@')) {
                        rawVpa = '$rawVpa@aiksetra';
                      }
                      Navigator.pop(ctx);

                      if (useEscrow) {
                        await BharatOnePayApi.initiateProtectedPay(
                          sellerVpa: rawVpa,
                          sellerName: prefillName ?? rawVpa.split('@').first,
                          amount: amt,
                          itemDescription: noteCtrl.text.trim().isEmpty ? 'Escrow Purchase' : noteCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF2563EB),
                            content: Text('🛡️ ₹${amt.toStringAsFixed(0)} locked in Safe Pay Escrow for $rawVpa'),
                          ),
                        );
                        return;
                      }

                      final risk = await BharatOnePayApi.analyzeScamRisk(
                        receiverVpa: rawVpa,
                        amount: amt,
                        remark: noteCtrl.text.trim(),
                      );
                      if (!mounted) return;
                      if (risk.riskLevel == 'HIGH' || risk.riskScore >= 60) {
                        final proceed = await _showScamWarningConfirmation(risk, rawVpa, amt);
                        if (proceed != true) return;
                      }

                      final mpin = await _promptForMpin(
                        title: selectedCardId != null ? 'Authorize Card / RuPay UPI Payment' : 'Authorize UPI Payment',
                        subtitle: 'Pay ₹${amt.toStringAsFixed(2)} to $rawVpa',
                      );
                      if (mpin == null || mpin.length < 4) return;

                      final payRes = await BharatOnePayApi.payUpi(
                        receiverVpa: rawVpa,
                        amount: amt,
                        mpin: mpin,
                        cardId: selectedCardId,
                        remark: noteCtrl.text.trim().isEmpty ? 'UPI Transfer' : noteCtrl.text.trim(),
                        bypassScamWarning: true,
                      );

                      await _syncLiveState();

                      if (!mounted) return;
                      setState(() {});
                      if (payRes['success'] == true) {
                        final isSim = payRes['isSimulated'] == true ||
                            (payRes['transaction'] is Map && payRes['transaction']['status'] == 'SIMULATED_SUCCESS');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF046A38),
                            duration: const Duration(seconds: 4),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('✅ Paid ₹${amt.toStringAsFixed(2)} to $rawVpa!', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (isSim)
                                  const Text(
                                    'Demo payment — no real money transferred',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFBBF7D0)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: Colors.red, content: Text(payRes['message'] ?? 'Payment declined')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCardId != null ? const Color(0xFF4F46E5) : const Color(0xFF046A38),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      selectedCardId != null
                          ? 'Pay Instantly with Linked Card & PIN →'
                          : 'Pay Instantly with AikSetra UPI PIN →',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Real Android UPI App Deep-Link Button (GPay / PhonePe / Paytm / BHIM)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      String rawVpa = vpaCtrl.text.trim();
                      final amt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                      if (rawVpa.isEmpty || amt <= 0) return;
                      if (!rawVpa.contains('@')) {
                        rawVpa = '$rawVpa@upi';
                      }
                      final payeeName = prefillName ?? rawVpa.split('@').first;
                      final note = noteCtrl.text.trim().isEmpty ? 'AikSetra UPI' : noteCtrl.text.trim();
                      Navigator.pop(ctx);

                      final risk = await BharatOnePayApi.analyzeScamRisk(
                        receiverVpa: rawVpa,
                        amount: amt,
                        remark: note,
                      );
                      if (!mounted) return;
                      if (risk.riskLevel == 'HIGH' || risk.riskScore >= 60) {
                        final proceed = await _showScamWarningConfirmation(risk, rawVpa, amt);
                        if (proceed != true) return;
                      }

                      final upiUri = Uri.parse(
                        'upi://pay?pa=$rawVpa&pn=${Uri.encodeComponent(payeeName)}&am=${amt.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(note)}',
                      );
                      try {
                        final launched = await launchUrl(upiUri, mode: LaunchMode.externalApplication);
                        if (!launched && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No external UPI app (GPay/PhonePe/Paytm) found on this device.')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not open external UPI app: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text(
                      'Pay Real Money via Installed UPI App (GPay / PhonePe / BHIM)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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

  // ===========================================================================
  // LIVE SMS & PAYMENT GATEWAY API KEY CONFIGURATION MODAL
  // ===========================================================================
  // ignore: unused_element
  // ignore: unused_element
  void _showGatewayConfigModal() {
    final fast2smsCtrl = TextEditingController();
    final msg91Ctrl = TextEditingController();
    final razorpayCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
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
              const Text(
                '🔑 Live SMS & Payment Gateway API Keys',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter your Fast2SMS or MSG91 API key to dispatch real carrier SMS OTPs to any phone, and Razorpay Key ID for live gateway checkout.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: fast2smsCtrl,
                decoration: InputDecoration(
                  labelText: 'Fast2SMS API Key (Real Indian SMS OTP)',
                  hintText: 'Paste Fast2SMS authorization key',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: msg91Ctrl,
                decoration: InputDecoration(
                  labelText: 'MSG91 Auth Key (Optional)',
                  hintText: 'Paste MSG91 authkey',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: razorpayCtrl,
                decoration: InputDecoration(
                  labelText: 'Razorpay Key ID (rzp_live_... or rzp_test_...)',
                  hintText: 'rzp_test_XXXXXXXXXXXXXX',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final res = await BharatOnePayApi.updateGatewayConfig(
                      fast2smsApiKey: fast2smsCtrl.text.trim().isNotEmpty ? fast2smsCtrl.text.trim() : null,
                      msg91AuthKey: msg91Ctrl.text.trim().isNotEmpty ? msg91Ctrl.text.trim() : null,
                      razorpayKeyId: razorpayCtrl.text.trim().isNotEmpty ? razorpayCtrl.text.trim() : null,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF046A38),
                        content: Text(res['message'] ?? 'Live Gateway API Keys updated on server!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save Live API Keys to Backend', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ADD MONEY / LINK BANK / MPIN / GULLAK / ESCROW / RECEIPT MODALS
  // ===========================================================================
  void _showUserProfileDetailsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFF0F172A),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _userName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Color(0xFF046A38), size: 14),
                    SizedBox(width: 4),
                    Text('NPCI Full KYC Verified (UIDAI + PAN)', style: TextStyle(color: Color(0xFF046A38), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Primary UPI VPA', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Row(
                          children: [
                            Text(_userVpa, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16, color: Color(0xFF046A38)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _userVpa));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('UPI ID copied to clipboard!'), duration: Duration(seconds: 1)),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bank Account', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text('$_bankName ($_maskedAcc)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bank IFSC Code', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(_ifsc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ],
                    ),
                    const Divider(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daily UPI Limit', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text('₹1,00,000 / day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: 'upi://pay?pa=$_userVpa&pn=${Uri.encodeComponent(_userName)}&cu=INR',
                      version: QrVersions.auto,
                      size: 150.0,
                    ),
                    const SizedBox(height: 6),
                    const Text('Scan to Pay into your Primary Bank', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCheckBalanceDialog();
                      },
                      icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                      label: Text(_t('check_balance'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  void _showSelfTransferModal() {
    _showAddMoneyAndSelfTransferModal(initialAddMoneyMode: false);
  }

  void _showAddMoneyAndSelfTransferModal({bool initialAddMoneyMode = false}) {
    bool isAddMoney = initialAddMoneyMode;
    final amtCtrl = TextEditingController(text: initialAddMoneyMode ? '5000' : '');
    String fromBank = _bankName;
    String toBank = BharatOnePayApi.allIndianBanks.firstWhere(
      (b) => (b['bankName'] ?? b['name']) != _bankName,
      orElse: () => BharatOnePayApi.allIndianBanks.last,
    )['bankName'] ?? 'HDFC Bank';
    String fundingSource = 'HDFC NetBanking / Salary Account';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                    Text(
                      isAddMoney ? '📥 Add Money to Bank Account' : '🔄 Transfer to Own Account',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                Text(
                  isAddMoney
                      ? 'Instantly deposit funds into $_bankName ($_maskedAcc) for payments & transfers'
                      : 'Real-time transfer between your own linked bank accounts',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                // Mode Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setSheetState(() {
                            isAddMoney = true;
                            if (amtCtrl.text.isEmpty) amtCtrl.text = '5000';
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isAddMoney ? const Color(0xFF046A38) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, size: 16, color: isAddMoney ? Colors.white : const Color(0xFF475569)),
                                const SizedBox(width: 6),
                                Text(
                                  'Add Money',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isAddMoney ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () => setSheetState(() => isAddMoney = false),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !isAddMoney ? const Color(0xFF0F172A) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.swap_horiz_rounded, size: 16, color: !isAddMoney ? Colors.white : const Color(0xFF475569)),
                                const SizedBox(width: 6),
                                Text(
                                  'Self Transfer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !isAddMoney ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (isAddMoney) ...[
                  // Target Account Badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance, color: Color(0xFF046A38), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Crediting to $_bankName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46))),
                              Text('Acc: $_maskedAcc • IFSC: $_ifsc', style: const TextStyle(fontSize: 11, color: Color(0xFF047857))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF046A38), borderRadius: BorderRadius.circular(8)),
                          child: Text('Bal: ₹${_bankBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Select Source / Funding Method:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: fundingSource,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'HDFC NetBanking / Salary Account', child: Text('🏦 HDFC NetBanking / Salary Acct', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'State Bank of India NetBanking', child: Text('🏦 State Bank of India NetBanking', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'ICICI Bank NetBanking', child: Text('🏦 ICICI Bank NetBanking', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Axis Bank NetBanking', child: Text('🏦 Axis Bank NetBanking', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'External Debit Card / CBS Switch Simulator', child: Text('💳 External Debit Card / CBS Switch', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => fundingSource = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      labelText: 'Deposit Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick preset chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [500, 1000, 2000, 5000, 10000, 25000].map((preset) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text('+₹$preset', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onPressed: () => setSheetState(() => amtCtrl.text = preset.toString()),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(backgroundColor: Colors.red, content: Text('Please enter a valid amount greater than 0')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        final res = await BharatOnePayApi.addMoneyToAccount(
                          amount: amt,
                          sourceNote: 'Self Deposit from $fundingSource',
                        );
                        await _syncLiveState();
                        if (!mounted) return;
                        setState(() {});
                        if (res['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF046A38),
                              duration: const Duration(seconds: 4),
                              content: Text('✅ ₹${amt.toStringAsFixed(2)} added to $_bankName successfully! Current Balance: ₹${_bankBalance.toStringAsFixed(2)}'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Could not add money')),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: Text('Deposit ₹${amtCtrl.text.isEmpty ? "0" : amtCtrl.text} to $_bankName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
                    ),
                  ),
                ] else ...[
                  // Transfer To Account:
                  const Text('Transfer From Account:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance, color: Color(0xFF046A38), size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text('$fromBank ($_maskedAcc)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        const Text('Primary', style: TextStyle(fontSize: 11, color: Color(0xFF046A38), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Transfer To Account:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: toBank,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: BharatOnePayApi.allIndianBanks
                        .where((b) => (b['bankName'] ?? b['name']) != fromBank)
                        .map((b) {
                          final bName = (b['bankName'] ?? b['name'] ?? 'Bank').toString();
                          final bIcon = (b['icon'] ?? '🏦').toString();
                          return DropdownMenuItem<String>(
                            value: bName,
                            child: Text('$bIcon $bName', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          );
                        })
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => toBank = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
                        if (amt <= 0) return;
                        Navigator.pop(ctx);
                        final pin = await _promptForMpin(
                          title: 'Authorize Self Transfer',
                          subtitle: 'Transfer ₹${amt.toStringAsFixed(2)} from $fromBank to $toBank',
                        );
                        if (pin == null || pin.isEmpty) return;
                        final res = await BharatOnePayApi.payUpi(
                          receiverVpa: '${toBank.toLowerCase().replaceAll(' ', '')}@upi',
                          amount: amt,
                          mpin: pin,
                          remark: 'Self Transfer: $fromBank to $toBank',
                        );
                        await _syncLiveState();
                        if (!mounted) return;
                        if (res['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF046A38),
                              content: Text('✅ ₹${amt.toStringAsFixed(2)} transferred to $toBank successfully!'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Transfer declined')),
                          );
                        }
                      },
                      icon: const Icon(Icons.swap_horiz, size: 20),
                      label: const Text('Transfer to Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
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

  Future<void> _showCheckBalanceDialog() async {
    final pin = await _promptForMpin(
      title: 'Check Bank Balance',
      subtitle: 'Enter 4-digit UPI MPIN for $_bankName ($_maskedAcc)',
    );
    if (pin == null || pin.isEmpty) return;

    final validPin = BharatOnePayApi.configuredAppPin.isNotEmpty ? BharatOnePayApi.configuredAppPin : '1234';
    if (pin != validPin && pin != '1234') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Incorrect UPI MPIN')),
      );
      return;
    }

    await _syncLiveState();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF046A38), size: 28),
            SizedBox(width: 10),
            Text('Available Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_bankName ($_maskedAcc)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Text(
              '₹${_bankBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF046A38)),
            ),
            const SizedBox(height: 6),
            const Text('Fetched live via NPCI UPI Switch', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleBuyStock(Map<String, dynamic> stock) {
    int qty = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final price = (stock['price'] as num).toDouble();
          final total = price * qty;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 22,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Buy ${stock['symbol']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                Text(stock['name'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('NSE Market Price:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('₹${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF046A38))),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity (Shares):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: qty > 1 ? () => setModalState(() => qty--) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        IconButton(
                          onPressed: () => setModalState(() => qty++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Debit from Bank:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final pin = await _promptForMpin(
                        title: 'Confirm Stock Purchase',
                        subtitle: 'Authorize ₹${total.toStringAsFixed(2)} for $qty shares of ${stock['symbol']}',
                      );
                      if (pin == null || pin.isEmpty) return;
                      final res = await BharatOnePayApi.payUpi(
                        receiverVpa: 'nse.clearing@upi',
                        amount: total,
                        mpin: pin,
                        remark: 'Buy $qty shares of ${stock['symbol']}',
                      );
                      await _syncLiveState();
                      if (!mounted) return;
                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF046A38),
                            content: Text('✅ Bought $qty shares of ${stock['symbol']}! Order executed on NSE.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
                    child: Text('Confirm Buy (₹${total.toStringAsFixed(2)})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleStockSip(Map<String, dynamic> stock) {
    double sipAmt = (stock['price'] as num).toDouble();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 22,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Start Stock SIP: ${stock['symbol']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Text('Automated regular equity investment via NPCI UPI Autopay mandate', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Investment Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('₹${sipAmt.toStringAsFixed(0)} / mo', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF046A38))),
                ],
              ),
              Slider(
                value: sipAmt,
                min: 500,
                max: 25000,
                divisions: 49,
                activeColor: const Color(0xFF046A38),
                onChanged: (v) => setModalState(() => sipAmt = v),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF046A38), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Autopay debit from $_bankName on 5th of every month',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final pin = await _promptForMpin(
                      title: 'Set UPI Autopay Mandate',
                      subtitle: 'Mandate ₹${sipAmt.toStringAsFixed(0)}/mo for ${stock['symbol']}',
                    );
                    if (pin == null || pin.isEmpty) return;
                    await BharatOnePayApi.createSipMandate(
                      planId: 'sip_bluechip',
                      monthlyAmount: sipAmt,
                      debitDay: 5,
                      mpin: pin,
                    );
                    await _syncLiveState();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF046A38),
                        content: Text('✅ Stock SIP of ₹${sipAmt.toStringAsFixed(0)}/mo started for ${stock['symbol']}!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
                  child: const Text('Authorize UPI Autopay Mandate', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLinkAnotherBankModal() {
    Map<String, String> selectedBank = BharatOnePayApi.allIndianBanks.first;
    final searchCtrl = TextEditingController();
    final accNoCtrl = TextEditingController();
    final ifscCtrl = TextEditingController(text: selectedBank['ifsc'] ?? 'SBIN0001024');
    final holderCtrl = TextEditingController(text: _userName);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filteredBanks = BharatOnePayApi.allIndianBanks.where((b) {
            if (searchQuery.isEmpty) return true;
            final q = searchQuery.toLowerCase();
            return (b['name'] ?? '').toLowerCase().contains(q) ||
                (b['code'] ?? '').toLowerCase().contains(q) ||
                (b['ifsc'] ?? '').toLowerCase().contains(q);
          }).toList();

          return Padding(
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
                  const Text('🏦 Link Any Indian Bank Account (48+ Banks)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Search Public, Private, Small Finance, Payments, or Co-operative Banks', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (v) => setSheetState(() => searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search bank name or IFSC (e.g. SBI, HDFC, Bandhan, UCO...)',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: filteredBanks.length,
                      itemBuilder: (ctx, idx) {
                        final bank = filteredBanks[idx];
                        final isSelected = selectedBank['code'] == bank['code'];
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFECFDF5),
                          leading: Text(bank['icon'] ?? '🏦', style: const TextStyle(fontSize: 20)),
                          title: Text(bank['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('IFSC: ${bank['ifsc']} • @${bank['handle']}', style: const TextStyle(fontSize: 11)),
                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF046A38)) : null,
                          onTap: () {
                            setSheetState(() {
                              selectedBank = bank;
                              ifscCtrl.text = bank['ifsc'] ?? 'SBIN0001024';
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 20),
                  TextField(
                    controller: holderCtrl,
                    decoration: InputDecoration(
                      labelText: 'Account Holder Full Name',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: accNoCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Account Number (or Last 4 Digits)',
                            hintText: 'e.g. 4829',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: ifscCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'IFSC Code',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final acc = accNoCtrl.text.trim();
                        if (acc.length < 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(backgroundColor: Colors.red, content: Text('Enter at least the last 4 digits of your account number.')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        await BharatOnePayApi.linkBankAccount(
                          bankName: selectedBank['bankName'] ?? selectedBank['name'] ?? 'State Bank of India',
                          bankCode: selectedBank['code'] ?? selectedBank['bankCode'],
                          ifsc: ifscCtrl.text.trim().isNotEmpty ? ifscCtrl.text.trim() : (selectedBank['ifsc'] ?? 'SBIN0001024'),
                          accountNumber: acc,
                          setAsPrimary: true,
                        );
                        if (!mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF046A38),
                            content: Text('✅ Linked ${selectedBank['bankName'] ?? selectedBank['name']} (•••• ${acc.substring(acc.length - 4)}) as Primary Bank!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified_rounded),
                      label: const Text('Link Bank Account & Set Primary', style: TextStyle(fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

    void _showLinkCardModal() {
    String cardType = 'DEBIT';
    String network = 'RuPay UPI';
    String defaultBank = BharatOnePayApi.allIndianBanks.firstWhere(
      (b) => (b['bankName'] ?? b['name']) == _bankName,
      orElse: () => BharatOnePayApi.allIndianBanks.first,
    )['bankName'] ?? BharatOnePayApi.allIndianBanks.first['name'] ?? 'State Bank of India (SBI)';
    String issuerBank = defaultBank;
    final cardNumCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    final holderCtrl = TextEditingController(text: _userName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💳 Link Debit or Credit Card for UPI & Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Supports RuPay Credit Card on UPI, Debit Cards, VISA & Mastercard', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('💳 Debit / ATM Card', style: TextStyle(fontWeight: FontWeight.bold)),
                        selected: cardType == 'DEBIT',
                        selectedColor: const Color(0xFFDBEAFE),
                        onSelected: (_) => setSheetState(() => cardType = 'DEBIT'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('✨ Credit Card (UPI)', style: TextStyle(fontWeight: FontWeight.bold)),
                        selected: cardType == 'CREDIT',
                        selectedColor: const Color(0xFFEDE9FE),
                        onSelected: (_) => setSheetState(() {
                          cardType = 'CREDIT';
                          network = 'RuPay UPI';
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['RuPay UPI', 'VISA', 'Mastercard'].map((net) {
                    return ChoiceChip(
                      label: Text(net, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: network == net,
                      onSelected: (_) => setSheetState(() => network = net),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: BharatOnePayApi.allIndianBanks.any((b) => (b['bankName'] ?? b['name']) == issuerBank)
                      ? issuerBank
                      : (BharatOnePayApi.allIndianBanks.first['bankName'] ?? BharatOnePayApi.allIndianBanks.first['name']),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Issuing Bank',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: BharatOnePayApi.allIndianBanks
                      .map((b) {
                        final bName = (b['bankName'] ?? b['name'] ?? 'Bank').toString();
                        final bIcon = (b['icon'] ?? '🏦').toString();
                        return DropdownMenuItem<String>(
                          value: bName,
                          child: Text('$bIcon $bName', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        );
                      })
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => issuerBank = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cardNumCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  decoration: InputDecoration(
                    labelText: 'Card Number (16 Digits or Last 6 Digits)',
                    hintText: '4591 •••• •••• 8821',
                    counterText: '',
                    prefixIcon: const Icon(Icons.credit_card_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expiryCtrl,
                        keyboardType: TextInputType.datetime,
                        maxLength: 5,
                        decoration: InputDecoration(
                          labelText: 'Expiry (MM/YY)',
                          hintText: '08/29',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cvvCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 3,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: '•••',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: holderCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name on Card',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final digits = cardNumCtrl.text.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(backgroundColor: Colors.red, content: Text('Please enter at least the last 4 digits of your card.')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      
                      // 3D Secure / Verified by Visa / RuPay handshake
                      final otpCtrl = TextEditingController(text: '482910');
                      final verified = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (dCtx) => AlertDialog(
                          title: Row(
                            children: [
                              const Icon(Icons.security, color: Color(0xFF046A38), size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('$issuerBank 3D Secure', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A one-time password (OTP) was sent to your registered mobile for tokenizing $issuerBank $network $cardType Card (•••• ${digits.substring(digits.length - 4)}).',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: otpCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(letterSpacing: 6, fontWeight: FontWeight.bold, fontSize: 20),
                                decoration: const InputDecoration(
                                  labelText: 'Bank SMS OTP',
                                  hintText: '482910',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
                              child: const Text('Verify & Tokenize'),
                            ),
                          ],
                        ),
                      );

                      if (verified != true) return;

                      await BharatOnePayApi.linkCard(
                        cardType: cardType,
                        network: network,
                        bankName: issuerBank,
                        cardNumber: digits,
                        expiry: expiryCtrl.text.trim().isNotEmpty ? expiryCtrl.text.trim() : '08/29',
                        cardHolderName: holderCtrl.text.trim(),
                      );
                      if (!mounted) return;
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF046A38),
                          content: Text('💳 Linked $issuerBank $network $cardType Card (•••• ${digits.substring(digits.length - 4)})!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_card_rounded),
                    label: Text('Verify & Link $cardType Card', style: const TextStyle(fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
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
        title: const Text('Set New 4-Digit UPI MPIN'),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter new 4-digit MPIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final pin = pinCtrl.text.trim();
              if (pin.length != 4) return;
              Navigator.pop(ctx);
              await BharatOnePayApi.setMpin(pin);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(backgroundColor: Color(0xFF046A38), content: Text('🔐 UPI MPIN updated!')),
              );
            },
            child: const Text('Update MPIN'),
          ),
        ],
      ),
    );
  }

  void _showGullakModal() {
    final customAmtCtrl = TextEditingController(text: '500');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏺 Digital Gullak Micro-Savings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Saved Balance: ₹${_gullakBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
              const SizedBox(height: 12),
              TextField(
                controller: customAmtCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final amt = double.tryParse(customAmtCtrl.text.trim()) ?? 500;
                        await BharatOnePayApi.depositVault(amt);
                        setSheetState(() {});
                        if (mounted) setState(() {});
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
                      child: const Text('+ Save to Gullak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final amt = double.tryParse(customAmtCtrl.text.trim()) ?? 500;
                        await BharatOnePayApi.withdrawVault(amt);
                        setSheetState(() {});
                        if (mounted) setState(() {});
                      },
                      child: const Text('Withdraw to Bank'),
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

  void _showSafePayDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final escrows = BharatOnePayApi.activeEscrows;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🛡️ Safe Pay Escrow Protection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const Text('Funds are held in NPCI Escrow and released only when you confirm delivery.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 14),
                if (escrows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No active escrow holds. Toggle "Hold in Safe Pay Escrow" inside Send Money to create one.'),
                  )
                else
                  ...escrows.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e.sellerName} • ₹${e.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${e.itemDescription} • Status: ${e.status}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            if (e.status == 'HELD_IN_ESCROW') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      await BharatOnePayApi.confirmDelivery(e.id);
                                      setSheetState(() {});
                                      if (mounted) setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
                                    child: const Text('Confirm Delivery & Release', style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () async {
                                      await BharatOnePayApi.disputeEscrow(e.id, 'Item not delivered');
                                      setSheetState(() {});
                                      if (mounted) setState(() {});
                                    },
                                    child: const Text('Dispute', style: TextStyle(fontSize: 11, color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showScamShieldModal() {
    final checkCtrl = TextEditingController();
    ScamShieldResult? res;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🛡️ AI Scam Shield Lookup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              TextField(
                controller: checkCtrl,
                decoration: InputDecoration(
                  labelText: 'Enter UPI ID or Suspicious Message',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final r = await BharatOnePayApi.analyzeScamRisk(
                    receiverVpa: checkCtrl.text.trim(),
                    amount: 1000,
                    remark: checkCtrl.text.trim(),
                  );
                  setSheetState(() => res = r);
                },
                child: const Text('Scan Risk Score'),
              ),
              if (res != null) ...[
                const SizedBox(height: 12),
                Text('Risk Level: ${res!.riskLevel} (Score: ${res!.riskScore}/100)', style: const TextStyle(fontWeight: FontWeight.bold)),
                ...res!.warnings.map((w) => Text('• $w', style: const TextStyle(fontSize: 12))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showServerConfigDialog() {
    final ipCtrl = TextEditingController(text: ApiConfig.activeHost);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.wifi_tethering_rounded, color: Color(0xFF34D399), size: 22),
              SizedBox(width: 8),
              Text('Server Wi-Fi & IP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'When you change Wi-Fi networks, update your PC IPv4 address below (port 4000):',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ipCtrl,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '192.168.29.218',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.laptop_chromebook_rounded, color: Color(0xFF38BDF8), size: 20),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Quick Select Presets:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    '192.168.29.218',
                    '192.168.29.90',
                    '192.168.137.1',
                    '10.0.2.2',
                    'https://aiksetra-npci-soumo.loca.lt',
                  ].map((preset) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(preset.length > 20 ? 'Tunnel' : preset, style: const TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: const Color(0xFF0F172A),
                        onPressed: () {
                          ipCtrl.text = preset;
                          setDlgState(() {});
                        },
                      ),
                    );
                  }).toList(),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
              onPressed: () async {
                ApiConfig.setCustomHost(ipCtrl.text);
                Navigator.pop(ctx);
                await _syncLiveState();
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF046A38),
                    content: Text('✅ Connected to backend at ${ApiConfig.activeHost}:4000'),
                  ),
                );
              },
              child: const Text('Connect & Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionReceiptModal(Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF046A38), size: 24),
                SizedBox(width: 8),
                Text('Official NPCI Transaction Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
            const Divider(height: 24),
            _buildBillRow('Counterparty', (t['receiverName'] ?? t['receiverVpa'] ?? '').toString()),
            _buildBillRow('UPI / Account Ref', (t['receiverVpa'] ?? '').toString()),
            _buildBillRow('Amount', '₹${((t['amount'] as num?) ?? 0).toStringAsFixed(2)}'),
            _buildBillRow('NPCI RRN / UTR', (t['upiRrn'] ?? t['txnRef'] ?? '').toString()),
            _buildBillRow('Status', (t['status'] ?? 'SUCCESS').toString()),
            _buildBillRow('Remark', (t['remark'] ?? '').toString()),
            _buildBillRow('Timestamp', (t['createdAt'] ?? '').toString().split('.').first.replaceAll('T', ' ')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                child: const Text('Close Receipt'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showScamWarningConfirmation(ScamShieldResult risk, String vpa, double amt) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ AI Scam Shield Alert', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('High Risk Score (${risk.riskScore}/100) detected for $vpa (₹$amt):'),
            const SizedBox(height: 8),
            ...risk.warnings.map((w) => Text('• $w', style: const TextStyle(fontSize: 12))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel Payment')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Proceed Anyway'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptForMpin({required String title, required String subtitle}) {
    final pinCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 14),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Enter your 4-digit UPI MPIN', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                Text('Demo PIN: 1234', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
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
                    Navigator.pop(ctx, BharatOnePayApi.configuredAppPin.isNotEmpty ? BharatOnePayApi.configuredAppPin : '1234');
                  }
                },
                icon: const Icon(Icons.fingerprint_rounded, color: Color(0xFF34D399), size: 20),
                label: const Text('👆 Pay with Fingerprint', style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF34D399)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, pinCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
            child: const Text('Authorize ✓'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REAL HARDWARE CAMERA QR SCANNER SCREEN (MobileScanner)
// =============================================================================
class _RealCameraQrScannerScreen extends StatefulWidget {
  const _RealCameraQrScannerScreen();

  @override
  State<_RealCameraQrScannerScreen> createState() => _RealCameraQrScannerScreenState();
}

class _RealCameraQrScannerScreenState extends State<_RealCameraQrScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _hasPopped = false;
  final TextEditingController _manualUriCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualUriCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Scan Any UPI / BharatQR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _scannerController.toggleTorch(),
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Toggle Flashlight',
          ),
          IconButton(
            onPressed: () => _scannerController.switchCamera(),
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            errorBuilder: (context, error, child) {
              final msg = error.errorDetails?.message ?? error.errorCode.message;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_rounded, color: Color(0xFF10B981), size: 52),
                      const SizedBox(height: 12),
                      const Text(
                        'Camera Access',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await _scannerController.stop();
                                await _scannerController.start();
                              } catch (_) {}
                              if (mounted) setState(() {});
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF046A38),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await _scannerController.switchCamera();
                              } catch (_) {}
                              if (mounted) setState(() {});
                            },
                            icon: const Icon(Icons.cameraswitch_rounded, size: 16),
                            label: const Text('Switch Lens'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF64748B)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            onDetect: (capture) {
              if (_hasPopped) return;
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue ?? barcode.displayValue;
                if (raw != null && raw.trim().isNotEmpty) {
                  _hasPopped = true;
                  Navigator.of(context).pop(raw.trim());
                  return;
                }
              }
            },
          ),
          // Scanner Target Reticle Overlay
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF10B981), width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xF20F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Point camera at any Google Pay, PhonePe, Paytm, BHIM, or Shop BharatQR code',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickQrPreset(
                          label: '🏪 Sharma Kirana QR (₹85)',
                          uri: 'upi://pay?pa=sharmakirana@okaxis&pn=Sharma%20Kirana%20Store&am=85&tn=Groceries',
                        ),
                        const SizedBox(width: 8),
                        _buildQuickQrPreset(
                          label: '☕ Chai Point QR (₹20)',
                          uri: 'upi://pay?pa=chaipoint@ybl&pn=Raju%20Tea%20Stall&am=20&tn=Masala%20Chai',
                        ),
                        const SizedBox(width: 8),
                        _buildQuickQrPreset(
                          label: '🚕 Metro Auto QR (₹120)',
                          uri: 'upi://pay?pa=autowala@paytm&pn=Kolkata%20Metro%20Auto&am=120&tn=Auto%20Fare',
                        ),
                        const SizedBox(width: 8),
                        _buildQuickQrPreset(
                          label: '⚠️ Test Scam QR Alert',
                          uri: 'upi://pay?pa=lotterywinner2026@okicici&pn=Prize%20Claim%20Refund&am=4999&tn=Lottery%20KYC%20Fee',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualUriCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Or enter UPI ID / mobile / upi://pay link...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final v = _manualUriCtrl.text.trim();
                          if (v.isNotEmpty && !_hasPopped) {
                            _hasPopped = true;
                            Navigator.of(context).pop(v);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF671F),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Proceed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQrPreset({required String label, required String uri}) {
    return ActionChip(
      backgroundColor: const Color(0xFF1E293B),
      side: const BorderSide(color: Color(0xFF334155)),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      onPressed: () {
        if (!_hasPopped) {
          _hasPopped = true;
          Navigator.of(context).pop(uri);
        }
      },
    );
  }
}
