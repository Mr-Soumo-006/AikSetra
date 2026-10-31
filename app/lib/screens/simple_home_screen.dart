import '../widgets/export_statement_pdf_modal.dart';
import '../services/theme_manager.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
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
import 'all_services_screen.dart';
import 'autopay_screen.dart';
import 'cards_screen.dart';
import 'calculators_screen.dart';
import 'travel_screen.dart';
import 'beneficiaries_screen.dart';
import 'rewards_screen.dart';
import 'business_dashboard_screen.dart';
import 'business_registration_screen.dart';
import 'tax_payments_screen.dart';
import 'bank_account_opening_screen.dart';
import 'statements_screen.dart';
import 'profile_screen.dart';
import 'universal_search_screen.dart';
import '../models/user_model.dart';
import '../widgets/bank_account_switcher_modal.dart';
import 'category_hub_screen.dart';
import '../widgets/language_location_selector_modal.dart';
import 'ai_assistant_screen.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  // ===========================================================================
  // THEME & DARK MODE SUPPORT
  // ===========================================================================
  bool get _isDark => ThemeManager.isDarkMode;
  Color get _bgScaffold => _isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
  Color get _cardBg => _isDark ? const Color(0xFF131B2E) : Colors.white;
  Color get _cardBorder => _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _textSecondary => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  // Stock search & live ticker state
  final TextEditingController _stockSearchCtrl = TextEditingController();
  String _stockSearchQuery = '';
  String _selectedStockSector = 'All';
  Timer? _stockTickerTimer;

  String _selectedLang = 'en-IN';
  late final PageController _adPageController;
  int _currentAdIndex = 0;
  Timer? _adAutoTimer;

  final List<Map<String, dynamic>> _adBanners = [
    {
      'title': 'AikSetra Invest',
      'pill': 'From the house of AikSetra',
      'badge': 'AI WEALTH • 0% COMMISSION',
      'logo': 'ऐ',
      'isLogoText': true,
      'gradient': [
        const Color(0xFF0F172A),
        const Color(0xFF1E3A8A),
        const Color(0xFF1E40AF),
      ],
      'glowColor': const Color(0xFF3B82F6),
      'tags': ['📈 Direct Mutual Funds', '🪙 24K Digital Gold', '⚡ Bank Auto-SIP'],
      'disclaimer':
          'Investments in securities market are subject to market risks, read all scheme related documents carefully.',
      'action': 'sip',
    },
    {
      'title': 'AikSetra 24K Gold',
      'pill': 'Daily SIP from ₹10 • 99.9% Pure',
      'badge': 'TRUSTED BY 1.5CR+ INDIANS',
      'logo': Icons.savings_rounded,
      'isLogoText': false,
      'gradient': [
        const Color(0xFF1C1917),
        const Color(0xFF78350F),
        const Color(0xFFB45309),
      ],
      'glowColor': const Color(0xFFF59E0B),
      'tags': ['🪙 Live ₹7,450/g', '🛡️ MMTC-PAMP Vault', '🚚 Doorstep Delivery'],
      'disclaimer':
          '100% pure 24K digital bullion stored in secure Brink\'s insured vaults. Zero storage fees.',
      'action': 'gold',
    },
    {
      'title': 'AikSetra Instant Credit',
      'pill': 'Pre-Approved up to ₹5,00,000',
      'badge': 'DISBURSAL IN 2 MINS',
      'logo': Icons.bolt_rounded,
      'isLogoText': false,
      'gradient': [
        const Color(0xFF0F172A),
        const Color(0xFF064E3B),
        const Color(0xFF047857),
      ],
      'glowColor': const Color(0xFF10B981),
      'tags': ['⚡ From 10.5% p.a.', '📄 100% Paperless', '💳 Zero Prepayment Penalty'],
      'disclaimer':
          'Instant credit powered by RBI regulated lending partners. Flexible tenures from 6-48 months.',
      'action': 'loan',
    },
    {
      'title': 'AikSetra Protection',
      'pill': 'Health & Vehicle Shield from ₹1.5/day',
      'badge': '10,000+ CASHLESS HOSPITALS',
      'logo': Icons.shield_rounded,
      'isLogoText': false,
      'gradient': [
        const Color(0xFF1E1B4B),
        const Color(0xFF4338CA),
        const Color(0xFF3730A3),
      ],
      'glowColor': const Color(0xFF6366F1),
      'tags': ['🏥 ₹1 Cr Life Cover', '🩺 Cashless Treatment', '🛵 Zero Inspection Bike'],
      'disclaimer':
          'IRDAI certified insurance partners. Quick 30-minute cashless claim processing.',
      'action': 'insurance',
    },
  ];
  String _t(String key) => AppTranslations.t(key, _selectedLang);
  int _bottomNavIndex = 0;
  String _historySearchQuery = '';
  String _historyFilterType = 'ALL';
  final TextEditingController _historySearchCtrl = TextEditingController();

  String _selectedNotificationFilter = 'ALL';
  final Set<String> _dismissedAlertIds = {};
  void Function(void Function())? _billsModalSetter;

  void _setBillState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    } else {
      fn();
    }
    _billsModalSetter?.call(() {});
  }

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
  final TextEditingController _fxForeignAmtCtrl = TextEditingController(
    text: '100',
  );
  final TextEditingController _fxBenNameCtrl = TextEditingController();
  final TextEditingController _fxBenIbanCtrl = TextEditingController();
  String _fxPurposeCode = 'S0301 - Family Maintenance & Savings';
  CrossBorderQuoteModel? _fxQuote;
  bool _isLoadingFxQuote = false;

  @override
  void initState() {
    super.initState();
    _adPageController = PageController();
    _startAdAutoPlay();
    _syncLiveState();
    ThemeManager.themeModeNotifier.addListener(_onThemeChanged);
    _startStockTickerTimer();
  }

  void _startAdAutoPlay() {
    _adAutoTimer?.cancel();
    _adAutoTimer = Timer.periodic(const Duration(milliseconds: 3800), (timer) {
      if (mounted && _adPageController.hasClients) {
        final next = (_currentAdIndex + 1) % _adBanners.length;
        _adPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _startStockTickerTimer() {
    _stockTickerTimer?.cancel();
    _stockTickerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      BharatOnePayApi.tickLivePrices();
      if (_bottomNavIndex == 2) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _stockTickerTimer?.cancel();
    ThemeManager.themeModeNotifier.removeListener(_onThemeChanged);
    _stockSearchCtrl.dispose();
    _adAutoTimer?.cancel();
    _adPageController.dispose();
    _consumerIdCtrl.dispose();
    _historySearchCtrl.dispose();
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
    await BharatOnePayApi.fetchLiveStockQuotes();
    if (!mounted) return;
    setState(() {
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

  String get _userName =>
      BharatOnePayApi.currentUser?.fullName ?? 'AikSetra User';
  String get _userVpa =>
      BharatOnePayApi.currentUser?.primaryVpa ?? 'user@aiksetra';
  String get _bankName =>
      BharatOnePayApi.currentAccount?.bankName ?? 'State Bank of India';
  String get _maskedAcc =>
      BharatOnePayApi.currentAccount?.maskedAccountNumber ?? '•••• •••• 0000';
  String get _ifsc => BharatOnePayApi.currentAccount?.ifsc ?? 'SBIN0001234';
  double get _bankBalance => BharatOnePayApi.currentAccount?.balance ?? 0.0;
  double get _gullakBalance => BharatOnePayApi.gullakBalance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScaffold,
      appBar: _buildTopAppBar(),
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          _buildHomeTab(),
          _buildAbroadTab(),
          _buildSipTab(),
          _buildNotificationsTab(),
          _buildHistoryTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFinemanFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Floating Fineman AI Assistant Button (Fixed in position above bottom nav bar)
  Widget _buildAiStockPill({
    required String symbol,
    required String name,
    required String strategy,
    required String target,
    required String support,
    required Color color,
    required bool isBullish,
  }) {
    final liveStock = BharatOnePayApi.indianStocks.firstWhere(
      (s) => s['symbol'] == symbol,
      orElse: () => {'price': 2500.0, 'changePct': 1.5},
    );
    final curPrice = (liveStock['price'] as num).toDouble();
    final pct = (liveStock['changePct'] as num?)?.toDouble() ?? 0.0;

    return Container(
      width: 210,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                symbol,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: pct >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: pct >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(name, style: TextStyle(fontSize: 10.5, color: _textSecondary)),
          const SizedBox(height: 4),
          Text(
            '₹${curPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const Divider(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Zone:', style: TextStyle(fontSize: 9.5, color: _textSecondary)),
              Text(target, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Support Level:', style: TextStyle(fontSize: 9.5, color: _textSecondary)),
              Text(support, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
            ],
          ),
        ],
      ),
    );
  }

  void _downloadDateWiseStatementPdf() {
    ExportStatementPdfModal.show(context, initialIsBusiness: BharatOnePayApi.isBusinessMode);
  }

  Widget _buildFinemanFloatingButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6, right: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF9933), // Saffron
            Color(0xFF8B5CF6), // AI Purple
            Color(0xFF046A38), // Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF671F).withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
            );
          },
          child: Tooltip(
            message: 'Fineman AI Assistant',
            child: SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          color: Color(0xFFFF9933),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildHomeTopBarAvatar() {
    if (BharatOnePayApi.isBusinessMode) {
      final bizLogo = BharatOnePayApi.businessProfile['logo'];
      if (bizLogo != null && bizLogo.toString().isNotEmpty) {
        final logoStr = bizLogo.toString();
        if (logoStr.startsWith('data:image')) {
          try {
            final b64 = logoStr.contains(',') ? logoStr.split(',').last : logoStr;
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00E676), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(base64Decode(b64.trim()), fit: BoxFit.cover),
              ),
            );
          } catch (_) {}
        }
      }
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF046A38),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF00E676), width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
      );
    }
    final avatar = BharatOnePayApi.currentUser?.profilePicture ?? BharatOnePayApi.savedLocalAvatar;
    if (avatar != null && avatar.isNotEmpty) {
      Widget? imageWidget;
      if (avatar.startsWith('data:image')) {
        try {
          final base64Str = avatar.contains(',') ? avatar.split(',').last : avatar;
          final bytes = base64Decode(base64Str.trim());
          imageWidget = Image.memory(
            bytes,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultHomeAvatarIcon(),
          );
        } catch (_) {}
      } else if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
        imageWidget = Image.network(
          avatar,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultHomeAvatarIcon(),
        );
      } else if (avatar.startsWith('/')) {
        imageWidget = Image.network(
          '${ApiConfig.baseUrl}$avatar',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultHomeAvatarIcon(),
        );
      } else if (File(avatar).existsSync()) {
        imageWidget = Image.file(
          File(avatar),
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultHomeAvatarIcon(),
        );
      } else if (avatar.length > 100) {
        try {
          final bytes = base64Decode(avatar.trim());
          imageWidget = Image.memory(
            bytes,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultHomeAvatarIcon(),
          );
        } catch (_) {}
      } else if (avatar.startsWith('preset:')) {
        final key = avatar.replaceFirst('preset:', '');
        IconData icon = Icons.person_rounded;
        List<Color> colors = const [Color(0xFFFF671F), Color(0xFF046A38)];
        switch (key) {
          case 'executive':
            icon = Icons.business_center_rounded;
            colors = const [Color(0xFF0F172A), Color(0xFF334155)];
            break;
          case 'fintech':
            icon = Icons.account_balance_wallet_rounded;
            colors = const [Color(0xFF046A38), Color(0xFF059669)];
            break;
          case 'techie':
            icon = Icons.laptop_chromebook_rounded;
            colors = const [Color(0xFF4338CA), Color(0xFF6366F1)];
            break;
          case 'scholar':
            icon = Icons.school_rounded;
            colors = const [Color(0xFF6B21A8), Color(0xFF9333EA)];
            break;
          case 'investor':
            icon = Icons.trending_up_rounded;
            colors = const [Color(0xFFD97706), Color(0xFFF59E0B)];
            break;
          case 'explorer':
            icon = Icons.rocket_launch_rounded;
            colors = const [Color(0xFFDC2626), Color(0xFFFF671F)];
            break;
          case 'wellness':
            icon = Icons.spa_rounded;
            colors = const [Color(0xFF0D9488), Color(0xFF14B8A6)];
            break;
          default:
            return _buildDefaultHomeAvatarIcon();
        }
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 20),
        );
      }

      if (imageWidget != null) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF671F), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageWidget,
          ),
        );
      }
    }
    return _buildDefaultHomeAvatarIcon();
  }

  Widget _buildDefaultHomeAvatarIcon() {
    return Container(
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
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(onRefreshParent: _syncLiveState),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _buildHomeTopBarAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            BharatOnePayApi.isBusinessMode
                                ? (BharatOnePayApi.businessProfile['companyName'] ?? 'Pentile')
                                : '${_t('namaste')}, ${_userName.split(' ').first}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (BharatOnePayApi.isBusinessMode) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF046A38),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'MERCHANT',
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      BharatOnePayApi.isBusinessMode
                          ? (BharatOnePayApi.businessProfile['merchantVpa'] ?? 'merchant@aiksetra')
                          : _userVpa,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'monospace',
                      ),
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
        // Mode Switcher Pill in Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (BharatOnePayApi.isBusinessMode) {
                      setState(() => BharatOnePayApi.isBusinessMode = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Switched to Personal Account'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Color(0xFF0F172A),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: !BharatOnePayApi.isBusinessMode ? const Color(0xFFFF671F) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Personal',
                      style: TextStyle(
                        color: !BharatOnePayApi.isBusinessMode ? Colors.white : const Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (!BharatOnePayApi.isBusinessMode) {
                      setState(() => BharatOnePayApi.isBusinessMode = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${BharatOnePayApi.businessProfile['companyName'] ?? 'Pentile'} Business Mode'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: const Color(0xFF046A38),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: BharatOnePayApi.isBusinessMode ? const Color(0xFF046A38) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Business',
                      style: TextStyle(
                        color: BharatOnePayApi.isBusinessMode ? Colors.white : const Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF671F), Color(0xFF046A38)],
              ),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          tooltip: 'AI Financial Assistant',
        ),
        IconButton(
          onPressed: () {
            _syncLiveState();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '🔄 Synced live bank balance, bills, SIPs & transactions',
                ),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.sync, color: Color(0xFF38BDF8), size: 20),
          tooltip: 'Sync with Bank Switch',
        ),
        IconButton(
          onPressed: () {
            ThemeManager.toggleTheme();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isDark ? '🌙 Dark Mode Activated' : '☀️ Light Mode Activated'),
                duration: const Duration(milliseconds: 900),
                backgroundColor: _isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              ),
            );
          },
          icon: Icon(
            _isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: _isDark ? const Color(0xFFFBBF24) : Colors.white,
            size: 22,
          ),
          tooltip: _isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        ),
        IconButton(
          onPressed: _openUniversalSearch,
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
          tooltip: 'Search Services, Billers & Payments',
        ),
      ],
    );
  }

  // ===========================================================================

  void _openUniversalSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalSearchScreen(
          onActionSelected: (key) {
            _handleSearchAction(key);
          },
          onRefreshParent: _syncLiveState,
        ),
      ),
    );
  }

  void _handleSearchAction(String key) {
    switch (key) {
      case 'scan_qr':
        _openRealCameraQrScanner();
        break;
      case 'send_money':
        _showSendMoneyDialog();
        break;
      case 'my_qr':
        _showReceiveQrModal();
        break;
      case 'self_transfer':
        _showSelfTransferModal();
        break;
      case 'add_money':
        _showAddMoneyAndSelfTransferModal(initialAddMoneyMode: true);
        break;
      case 'check_balance':
        _showCheckBalanceDialog();
        break;
      case 'bill_electricity':
        _openBillsModal(category: 'ELECTRICITY');
        break;
      case 'bill_water':
        _openBillsModal(category: 'WATER');
        break;
      case 'bill_gas':
        _openBillsModal(category: 'GAS');
        break;
      case 'bill_broadband':
        _openBillsModal(category: 'BROADBAND');
        break;
      case 'bill_mobile':
        _openBillsModal(category: 'MOBILE');
        break;
      case 'bill_fastag':
        _openBillsModal(category: 'FASTAG');
        break;
      case 'bill_dth':
        _openBillsModal(category: 'DTH');
        break;
      case 'wealth_sip':
        setState(() => _bottomNavIndex = 2);
        break;
      case 'wealth_gold':
        setState(() => _bottomNavIndex = 2);
        break;
      case 'gullak':
        _showGullakModal();
        break;
      case 'language':
        LanguageLocationSelectorModal.show(
          context,
          current: _selectedLang,
        ).then((v) {
          if (v != null && mounted) {
            setState(() => _selectedLang = v);
          }
        });
        break;
      case 'history':
        setState(() => _bottomNavIndex = 4);
        break;
      case 'cards':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CardsScreen()),
        );
        break;
      case 'server_config':
      case 'port':
        _showServerConfigDialog();
        break;
      case 'autopay':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AutoPayScreen()),
        );
        break;
      case 'statements':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatementsScreen()),
        );
        break;
      case 'beneficiaries':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BeneficiariesScreen()),
        );
        break;
      case 'rewards':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RewardsScreen()),
        );
        break;
      case 'business':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BharatOnePayApi.hasBusinessAccount
                ? const BusinessDashboardScreen()
                : const BusinessRegistrationScreen(),
          ),
        );
        break;
      case 'tax':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaxPaymentsScreen()),
        );
        break;
      case 'account_opening':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BankAccountOpeningScreen()),
        );
        break;
      case 'travel':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TravelScreen()),
        );
        break;
      case 'all_services':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AllServicesScreen(onSelectService: _handleServiceRoute),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(onRefreshParent: _syncLiveState),
          ),
        );
        break;
    }
  }

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
            _buildAikSetraInvestBanner(),
            const SizedBox(height: 16),
            _buildHeroQrAndActions(),
            const SizedBox(height: 16),
            _buildAIAssistantBanner(),
            const SizedBox(height: 20),
            _buildPhonePeCategorizedSections(),
            const SizedBox(height: 20),
            _buildWealthAndSafetyHighlights(),
            const SizedBox(height: 20),
            _buildQuickTransferBar(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // AI FINANCIAL ASSISTANT BANNER
  // ===========================================================================
  Widget _buildAIAssistantBanner() {
    final isDark = _isDark;
    const saffron = Color(0xFFFF671F);
    const emerald = Color(0xFF046A38);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0D1B2A), Color(0xFF1E293B)]
              : const [Color(0xFF0D1B2A), Color(0xFF1B2A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: saffron.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [saffron, emerald],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: saffron.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Fineman AI Assistant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: emerald.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: emerald, width: 0.8),
                                ),
                                child: const Text(
                                  'ON-DEVICE AI',
                                  style: TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Financial insights, calculators & stock analysis',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAIPill('💳 Total Balance', 'What is my total bank balance?'),
                      const SizedBox(width: 8),
                      _buildAIPill('📊 SIP of ₹5k', 'Calculate SIP of ₹5,000 at 12% for 10 years'),
                      const SizedBox(width: 8),
                      _buildAIPill('📈 Reliance Stock', 'Show Reliance stock quote'),
                      const SizedBox(width: 8),
                      _buildAIPill('🔄 Switch Accounts', 'How do I switch my primary bank account?'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIPill(String label, String prompt) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIAssistantScreen(initialPrompt: prompt),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 0.8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LIVE 3D / THREE.JS-INSPIRED PROMOTIONAL AD CAROUSEL
  // ===========================================================================
  Widget _buildAikSetraInvestBanner() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _adPageController,
            itemCount: _adBanners.length,
            onPageChanged: (idx) {
              setState(() => _currentAdIndex = idx);
            },
            itemBuilder: (context, idx) {
              final ad = _adBanners[idx];
              final gradient = ad['gradient'] as List<Color>;
              final glowColor = ad['glowColor'] as Color;
              final tags = ad['tags'] as List<String>;
              final isLogoText = ad['isLogoText'] as bool;
              final action = ad['action'] as String;

              return InkWell(
                onTap: () {
                  if (action == 'sip') {
                    setState(() => _bottomNavIndex = 2);
                  } else if (action == 'gold') {
                    _showGoldSilverVaultModal('Gold');
                  } else if (action == 'loan') {
                    _showLoanApplicationModal('loan_personal');
                  } else if (action == 'insurance') {
                    _showInsuranceDiscoveryModal('health_insurance');
                  }
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: glowColor.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Stack(
                      children: [
                        // Live 3D Mesh Particle Constellation (Three.js Style)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ThreeJsMeshParticlesPainter(
                              primaryColor: glowColor,
                            ),
                          ),
                        ),

                        // Card Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Top Bar: "AD" tag and Live Campaign Badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: const Text(
                                      'AD',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        ad['badge'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // 3D Circular Logo
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: isLogoText
                                    ? const Text(
                                        'ऐ',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                        ),
                                      )
                                    : Icon(
                                        ad['logo'] as IconData,
                                        size: 26,
                                        color: gradient[1],
                                      ),
                              ),
                              const SizedBox(height: 8),

                              // Title
                              Text(
                                ad['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Subtitle Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFACC15),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFACC15)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  ad['pill'] as String,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // 3 Tags
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: tags
                                    .map(
                                      (t) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        child: _buildInvestTag(t),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 6),

                              // Micro disclaimer
                              Text(
                                ad['disclaimer'] as String,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 8.5,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Live Carousel Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_adBanners.length, (i) {
            final isSel = _currentAdIndex == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSel ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSel
                    ? const Color(0xFFFF671F)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInvestTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
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
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 42,
                      color: Color(0xFF046A38),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'SCAN ANY UPI QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.4,
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                            Text(
                              'Send Money',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Any UPI ID or Mobile',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _showCheckBalanceDialog,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 79,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF334155)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Check Balance',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: Color(0xFFFF671F),
                                  size: 13,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '$_bankName (${_maskedAcc.isNotEmpty ? _maskedAcc : "••••"})',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    BankAccountSwitcherModal.show(
                                      context,
                                      onAccountSelected: (acc) async {
                                        await _syncLiveState();
                                        if (mounted) setState(() {});
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Switch', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
                                        Icon(Icons.arrow_drop_down, size: 12, color: Color(0xFF046A38)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
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

  // ===========================================================================
  // PHONEPE-STYLE CATEGORIZED FINANCIAL SERVICES SECTIONS
  // ===========================================================================
  Widget _buildPhonePeCategorizedSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. RECHARGE & BILLS
        _buildPhonePeSectionCard(
          categoryKey: 'recharge_bills',
          title: 'Recharge & Pay Bills',
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFF2563EB),
          offerText: '⚡ Instant Bharat Connect BBPS receipt with 0 fee',
          items: [
            {
              'label': 'Mobile\nRecharge',
              'icon': Icons.phone_android_rounded,
              'color': const Color(0xFF2563EB),
              'routeKey': 'mobile',
              'badge': 'Popular',
            },
            {
              'label': 'DTH /\nCable TV',
              'icon': Icons.tv_rounded,
              'color': const Color(0xFF7C3AED),
              'routeKey': 'dth',
              'badge': null,
            },
            {
              'label': 'Electricity\nBill',
              'icon': Icons.bolt_rounded,
              'color': const Color(0xFFF59E0B),
              'routeKey': 'electricity',
              'badge': 'BBPS',
            },
            {
              'label': 'FASTag\nRecharge',
              'icon': Icons.directions_car_rounded,
              'color': const Color(0xFF059669),
              'routeKey': 'fastag',
              'badge': null,
            },
          ],
        ),
        const SizedBox(height: 16),

        // 2. LOANS & CREDIT
        _buildPhonePeSectionCard(
          categoryKey: 'loans',
          title: 'Loans & Credit',
          icon: Icons.account_balance_rounded,
          iconColor: const Color(0xFF059669),
          offerText: '🌟 Pre-approved loan up to ₹5L in 2 mins • 10.5% p.a.',
          items: [
            {
              'label': 'Personal\nLoan',
              'icon': Icons.monetization_on_rounded,
              'color': const Color(0xFF2563EB),
              'routeKey': 'loan_personal',
              'badge': '₹5L Instant',
            },
            {
              'label': 'Mutual Funds\nLoan',
              'icon': Icons.trending_up_rounded,
              'color': const Color(0xFF10B981),
              'routeKey': 'loan_mf',
              'badge': '9.5%',
            },
            {
              'label': 'Gold\nLoan',
              'icon': Icons.shield_moon_rounded,
              'color': const Color(0xFFD97706),
              'routeKey': 'loan_gold',
              'badge': 'Instant',
            },
            {
              'label': 'Credit\nScore',
              'icon': Icons.speed_rounded,
              'color': const Color(0xFF8B5CF6),
              'routeKey': 'credit_score',
              'badge': 'Free',
            },
          ],
        ),
        const SizedBox(height: 16),

        // 3. SAVINGS AND INVESTMENT
        _buildPhonePeSectionCard(
          categoryKey: 'savings_investments',
          title: 'Savings and Investment',
          icon: Icons.savings_rounded,
          iconColor: const Color(0xFFD97706),
          offerText: '🪙 High return FDs up to 7.8% • 24K 99.9% Pure Gold & SIPs',
          items: [
            // In Front: Fixed Deposit, SIP, Mutual Funds, RD
            {
              'label': 'Fixed\nDeposit',
              'icon': Icons.lock_clock_rounded,
              'color': const Color(0xFF2563EB),
              'routeKey': 'fd',
              'badge': '7.8% p.a.',
            },
            {
              'label': 'SIP\nInvest',
              'icon': Icons.trending_up_rounded,
              'color': const Color(0xFF10B981),
              'routeKey': 'sip',
              'badge': '₹500/mo',
            },
            {
              'label': 'Mutual\nFunds',
              'icon': Icons.pie_chart_rounded,
              'color': const Color(0xFF7C3AED),
              'routeKey': 'mutual_funds',
              'badge': 'Direct',
            },
            {
              'label': 'Recurring\nDeposit (RD)',
              'icon': Icons.account_balance_wallet_rounded,
              'color': const Color(0xFF0284C7),
              'routeKey': 'rd',
              'badge': '7.1% p.a.',
            },
          ],
        ),

        const SizedBox(height: 16),

        // 4. INSURANCE
        _buildPhonePeSectionCard(
          categoryKey: 'insurance',
          title: 'Insurance & Protection',
          icon: Icons.shield_rounded,
          iconColor: const Color(0xFF0284C7),
          offerText: '🏥 Cashless claims across 10,000+ partnered hospitals',
          items: [
            {
              'label': 'Bike\nInsurance',
              'icon': Icons.two_wheeler_rounded,
              'color': const Color(0xFF2563EB),
              'routeKey': 'insurance',
              'badge': '₹1.5/day',
            },
            {
              'label': 'Car\nInsurance',
              'icon': Icons.directions_car_rounded,
              'color': const Color(0xFF0284C7),
              'routeKey': 'insurance',
              'badge': 'Instant',
            },
            {
              'label': 'Health\nInsurance',
              'icon': Icons.health_and_safety_rounded,
              'color': const Color(0xFFDC2626),
              'routeKey': 'insurance',
              'badge': 'Cashless',
            },
            {
              'label': 'Term Life\nInsurance',
              'icon': Icons.favorite_rounded,
              'color': const Color(0xFFE11D48),
              'routeKey': 'insurance',
              'badge': '₹1 Cr',
            },
          ],
        ),
        const SizedBox(height: 16),

        // AIKSETRA BUSINESS ACCOUNT SECTION BANNER
        _buildHomepageBusinessCard(),
        const SizedBox(height: 16),

        // 5. FINANCIAL TOOLS & CALCULATORS
        _buildPhonePeSectionCard(
          categoryKey: 'tools',
          title: 'Financial Tools & Calculators',
          icon: Icons.calculate_rounded,
          iconColor: const Color(0xFF7C3AED),
          offerText: '🧮 Normal calculation & comprehensive financial return modeling',
          items: [
            {
              'label': 'Normal\nCalculator',
              'icon': Icons.calculate_rounded,
              'color': const Color(0xFF0F172A),
              'routeKey': 'calculator',
              'badge': 'Standard',
            },
            {
              'label': 'SIP\nCalculator',
              'icon': Icons.trending_up_rounded,
              'color': const Color(0xFF059669),
              'routeKey': 'calc_sip',
              'badge': 'Wealth',
            },
            {
              'label': 'EMI\nCalculator',
              'icon': Icons.percent_rounded,
              'color': const Color(0xFF2563EB),
              'routeKey': 'calc_emi',
              'badge': 'Loans',
            },
            {
              'label': 'GST\nCalculator',
              'icon': Icons.receipt_rounded,
              'color': const Color(0xFF7C3AED),
              'routeKey': 'calc_gst',
              'badge': 'Tax',
            },
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // HOMEPAGE BUSINESS ACCOUNT BANNER (Positioned between Insurance & Calculators)
  // ===========================================================================
  Widget _buildHomepageBusinessCard() {
    final isBiz = BharatOnePayApi.isBusinessMode;
    final companyName = BharatOnePayApi.businessProfile['companyName'] ?? 'Pentile';
    final ownerName = BharatOnePayApi.businessProfile['ownerName'] ?? _userName;
    final website = (BharatOnePayApi.businessProfile['website'] ?? 'https://pentile.in').toString();
    final bizLogo = BharatOnePayApi.businessProfile['logo'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isBiz
              ? const [Color(0xFF046A38), Color(0xFF012B16)]
              : const [Color(0xFF046A38), Color(0xFF02361D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBiz ? const Color(0xFF00E676) : const Color(0xFF059669),
          width: isBiz ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF046A38).withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Business Logo or Store Icon
                Builder(builder: (_) {
                  if (bizLogo != null && bizLogo.toString().isNotEmpty) {
                    final logoStr = bizLogo.toString();
                    if (logoStr.startsWith('data:image')) {
                      try {
                        final b64 = logoStr.contains(',') ? logoStr.split(',').last : logoStr;
                        return Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00E676), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(base64Decode(b64.trim()), fit: BoxFit.cover),
                          ),
                        );
                      } catch (_) {}
                    }
                  }
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                }),
                const SizedBox(width: 12),
                // Center details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              companyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isBiz ? const Color(0xFF10B981) : const Color(0xFF065F46),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              isBiz ? 'LIVE' : 'VERIFIED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Owner: $ownerName • Tap for Ledger, Sheet & QR',
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (website.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.language_rounded, size: 11, color: Color(0xFF86EFAC)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                website,
                                style: const TextStyle(
                                  color: Color(0xFF86EFAC),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.dashboard_rounded, color: Colors.white70, size: 20),
                      tooltip: 'Business Dashboard',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (!isBiz) {
                          setState(() => BharatOnePayApi.isBusinessMode = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched to $companyName Business Mode'),
                              backgroundColor: const Color(0xFF046A38),
                              duration: const Duration(seconds: 1),
                            ),
                          );

                        } else {
                          setState(() => BharatOnePayApi.isBusinessMode = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Switched back to Personal Account mode'),
                              backgroundColor: Color(0xFF0F172A),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBiz ? Colors.white : const Color(0xFF0F172A),
                        foregroundColor: isBiz ? const Color(0xFF046A38) : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isBiz ? 'Personal' : 'Switch',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhonePeSectionCard({
    required String categoryKey,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String offerText,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ROW
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openCategoryHub(categoryKey),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 16, color: iconColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _openCategoryHub(categoryKey),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF671F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'More',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF671F),
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: Color(0xFFFF671F),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ICONS IN ROWS OF 4
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              children: [
                for (int rowIndex = 0; rowIndex < items.length; rowIndex += 4) ...[
                  if (rowIndex > 0) const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items
                        .skip(rowIndex)
                        .take(4)
                        .map((item) {
                          final color = item['color'] as Color;
                          final routeKey = item['routeKey'] as String;
                          final badge = item['badge'] as String?;
                          return Expanded(
                            child: InkWell(
                              onTap: () => _handleServiceRoute(routeKey),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: color.withValues(alpha: 0.25),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              item['icon'] as IconData,
                                              color: color,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        if (badge != null)
                                          Positioned(
                                            top: -5,
                                            right: -6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 1.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDC2626),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.15),
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                badge,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['label'] as String,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
          // FOOTER MICRO BANNER (Arrow only, no 'More' text, no click action)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(19),
              ),
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    offerText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _openCategoryHub(String categoryKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryHubScreen(
          categoryKey: categoryKey,
          onSelectService: _handleServiceRoute,
        ),
      ),
    );
  }

  void _handleServiceRoute(String routeKey) {
    switch (routeKey) {
      // 1. UPI & Direct Payments
      case 'scan_pay':
        _openRealCameraQrScanner();
        break;
      case 'send_money':
        _showSendMoneyDialog();
        break;
      case 'my_qr':
        _showReceiveQrModal();
        break;
      case 'self_transfer':
        _showSelfTransferModal();
        break;
      case 'add_money':
        _showAddMoneyAndSelfTransferModal(initialAddMoneyMode: true);
        break;
      case 'contacts':
      case 'beneficiaries':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BeneficiariesScreen(
              onSelectPayee: (vpa, name) {
                _showSendMoneyDialog(prefillVpa: vpa, prefillName: name);
              },
            ),
          ),
        );
        break;
      case 'cards':
      case 'credit_debit_cards':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CardsScreen()),
        );
        break;
      case 'server_config':
      case 'port':
        _showServerConfigDialog();
        break;
      case 'autopay':
      case 'mandates':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AutoPayScreen()),
        );
        break;
      case 'merchant_payments':
        _openRealCameraQrScanner();
        break;

      // 2. Bharat Connect (BBPS) Bills & Utilities
      case 'electricity':
        _selectBillCategoryAndOpen('ELECTRICITY');
        break;
      case 'water':
        _selectBillCategoryAndOpen('WATER');
        break;
      case 'gas':
        _selectBillCategoryAndOpen('GAS');
        break;
      case 'broadband':
        _selectBillCategoryAndOpen('BROADBAND');
        break;
      case 'mobile':
      case 'mobile_recharge':
      case 'postpaid':
        _selectBillCategoryAndOpen('MOBILE');
        break;
      case 'dth':
        _selectBillCategoryAndOpen('DTH');
        break;
      case 'cable':
        _selectBillCategoryAndOpen('CABLE');
        break;
      case 'fastag':
        _selectBillCategoryAndOpen('FASTAG');
        break;
      case 'housing_society':
        _selectBillCategoryAndOpen('HOUSING');
        break;
      case 'insurance_bill':
        _selectBillCategoryAndOpen('INSURANCE');
        break;
      case 'education_fees':
        _selectBillCategoryAndOpen('EDUCATION');
        break;
      case 'traffic_challan':
        _selectBillCategoryAndOpen('CHALLAN');
        break;
      case 'municipal_taxes':
      case 'municipal_tax':
        _selectBillCategoryAndOpen('MUNICIPAL');
        break;
      case 'landline':
        _selectBillCategoryAndOpen('BROADBAND');
        break;
      case 'subscriptions':
        _selectBillCategoryAndOpen('SUBSCRIPTION');
        break;
      case 'donation':
        _showDonationModal();
        break;

      // 3. Loans, Credit & Financial Assessments
      case 'loan_personal':
      case 'loan_mf':
      case 'loan_gold':
      case 'loan_home':
      case 'loan_auto':
      case 'loan_bike':
      case 'loan_business':
      case 'loan_education':
      case 'loan_credit_card':
      case 'loan_repayment':
      case 'loan_consumer':
      case 'working_capital':
      case 'kisan_credit':
        _showLoanApplicationModal(routeKey);
        break;
      case 'credit_score':
        _showCreditScoreModal();
        break;

      // 4. Investments, Savings & Precious Metals
      case 'investments':
      case 'stocks':
      case 'invest_stocks':
        setState(() => _bottomNavIndex = 2);
        break;
      case 'invest_gold':
      case 'gold_sip':
      case 'gold':
        _showGoldSilverVaultModal('Gold');
        break;
      case 'invest_silver':
      case 'silver_sip':
        _showGoldSilverVaultModal('Silver');
        break;
      case 'invest_platinum':
        _showGoldSilverVaultModal('Platinum');
        break;
      case 'sip':
      case 'sip_invest':
      case 'mutual_funds':
      case 'sip_mutual_funds':
      case 'invest_sip':
        _showMfInvestmentModal();
        break;
      case 'fd':
      case 'fixed_deposits':
      case 'invest_fd':
        _showFdInvestmentModal();
        break;
      case 'rd':
      case 'recurring_deposits':
      case 'invest_rd':
        _showRdInvestmentModal();
        break;
      case 'gullak':
      case 'savings_products':
        _showGullakModal();
        break;

      // 5. Insurance & Vehicle Protection (Direct Purchase + Discovery)
      case 'road_tax':
      case 'vahan_tax':
        _showRoadTaxModal();
        break;
      case 'ins_bike':
      case 'bike_insurance':
        _showDirectInsuranceModal(
          'Bike Insurance',
          'Comprehensive Own Damage + ₹15 Lakh PA Cover',
          '₹499/yr',
          Icons.two_wheeler_rounded,
          const Color(0xFF14B8A6),
        );
        break;
      case 'ins_car':
      case 'car_insurance':
        _showDirectInsuranceModal(
          'Car Insurance',
          'Zero Depreciation + Engine Protect + 24x7 Roadside Assist',
          '₹2,499/yr',
          Icons.directions_car_rounded,
          const Color(0xFF2563EB),
        );
        break;
      case 'ins_health':
      case 'health_insurance':
        _showDirectInsuranceModal(
          'Family Health Insurance',
          '₹10 Lakh Cashless Cover across 10,000+ Network Hospitals',
          '₹550/mo',
          Icons.local_hospital_rounded,
          const Color(0xFF10B981),
        );
        break;
      case 'ins_life':
      case 'life_insurance':
      case 'term_life_insurance':
        _showDirectInsuranceModal(
          '₹1 Crore Term Life Insurance',
          'Pure Life Protection with 99.3% Claim Settlement Ratio',
          '₹490/mo',
          Icons.family_restroom_rounded,
          const Color(0xFF8B5CF6),
        );
        break;
      case 'ins_travel':
      case 'travel_insurance':
        _showDirectInsuranceModal(
          'International Travel Insurance',
          'Emergency Medical, Baggage Loss & Flight Delay Cover',
          '₹299/trip',
          Icons.flight_rounded,
          const Color(0xFF0EA5E9),
        );
        break;
      case 'cyber_insurance':
        _showDirectInsuranceModal(
          'Cyber Fraud Shield',
          'UPI, Net Banking & Phishing Fraud Protection up to ₹5 Lakh',
          '₹199/yr',
          Icons.security_rounded,
          const Color(0xFF0284C7),
        );
        break;
      case 'insurance':
      case 'vehicle_insurance':
      case 'personal_accident':
        _showInsuranceDiscoveryModal(routeKey);
        break;

      // 6. Taxes & Official Portals
      case 'income_tax':
      case 'gst':
      case 'property_tax':
      case 'taxes':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaxPaymentsScreen(
              initialCategory: routeKey.contains('gst')
                  ? 'GST PMT-06'
                  : (routeKey.contains('property')
                        ? 'Property Tax'
                        : 'Income Tax'),
            ),
          ),
        );
        break;

      // 7. AI Financial Assistant
      case 'ai_assistant':
      case 'ai':
      case 'assistant':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
        );
        break;

      // 8. Financial Calculators (All 12 Precision Engines)
      case 'calculator':
      case 'calc_standard':
      case 'normal_calculator':
      case 'calculators':
      case 'calculator_centre':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CalculatorsScreen(initialTool: 'Standard')),
        );
        break;
      case 'calc_emi':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalculatorsScreen(initialTool: 'EMI Loan'),
          ),
        );
        break;
      case 'calc_sip':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalculatorsScreen(initialTool: 'SIP Return'),
          ),
        );
        break;
      case 'calc_gst':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalculatorsScreen(initialTool: 'GST Tax'),
          ),
        );
        break;
      case 'calc_tax':
      case 'calc_income_tax':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalculatorsScreen(initialTool: 'Income Tax'),
          ),
        );
        break;
      case 'calc_fx':
      case 'calc_currency':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalculatorsScreen(initialTool: 'Currency FX'),
          ),
        );
        break;
      case 'calc_fd':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalculatorsScreen(initialTool: 'FD Maturity'),
          ),
        );
        break;
      case 'calc_rd':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalculatorsScreen(initialTool: 'RD Maturity'),
          ),
        );
        break;
      case 'calc_compound':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalculatorsScreen(initialTool: 'Compound'),
          ),
        );
        break;
      case 'calc_inflation':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalculatorsScreen(initialTool: 'Inflation'),
          ),
        );
        break;
      case 'calc_goal':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CalculatorsScreen(initialTool: 'Goal Plan'),
          ),
        );
        break;

      // 9. Travel & Entertainment Ticketing
      case 'travel':
      case 'flights':
      case 'trains':
      case 'buses':
      case 'hotels':
      case 'movies':
      case 'movie_tickets':
      case 'entertainment':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TravelScreen(
              initialCategory: (routeKey == 'travel' || routeKey.isEmpty)
                  ? 'Flights'
                  : (routeKey.contains('movie') ? 'Movies' : (routeKey.substring(0, 1).toUpperCase() + routeKey.substring(1))),
            ),
          ),
        );
        break;

      // 10. Passbook, Statements & Business Account
      case 'rewards':
      case 'coupons':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RewardsScreen()),
        );
        break;
      case 'bank_account_opening':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BankAccountOpeningScreen()),
        );
        break;
      case 'statements':
      case 'documents':
      case 'expense_tracking':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatementsScreen()),
        );
        break;
      case 'business_account':
      case 'business':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BharatOnePayApi.hasBusinessAccount
                ? const BusinessDashboardScreen()
                : const BusinessRegistrationScreen(),
          ),
        );
        break;
      case 'forex':
      case 'global_fx':
      case 'remittance':
      case 'fx':
      case 'abroad':
        setState(() => _bottomNavIndex = 1);
        break;

      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Opening service: $routeKey')));
        break;
    }
  }

  void _showDirectInsuranceModal(
    String title,
    String desc,
    String price,
    IconData icon,
    Color color,
  ) {
    _showPolicyPurchaseModal(title, price, icon, color);
  }

  void _showDonationModal() {
    final trusts = [
      {
        'name': 'PM CARES Fund',
        'sub': 'Prime Minister Citizen Assistance & Relief in Emergency Situations',
        'vpa': 'pmcares@sbi',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF046A38),
        'exemption': '100% Tax Exemption u/s 80G',
        'regNo': 'DIT(E)/80G/PMCARES/2020',
      },
      {
        'name': 'Shri Ram Janmbhoomi Teerth Kshetra',
        'sub': 'Ayodhya Mandir Development & Pilgrim Welfare Trust',
        'vpa': 'shriramteerth@sbi',
        'icon': Icons.temple_hindu_rounded,
        'color': const Color(0xFFFF671F),
        'exemption': '50% Tax Exemption u/s 80G',
        'regNo': 'SRJBTK/80G/AYODHYA/2020',
      },
      {
        'name': 'The Akshaya Patra Foundation',
        'sub': 'Unlimited Food for Education (Mid-Day Meals for School Children)',
        'vpa': 'akshayapatra@icici',
        'icon': Icons.soup_kitchen_rounded,
        'color': const Color(0xFFD97706),
        'exemption': '50% Tax Exemption u/s 80G',
        'regNo': 'AAATA0123M/80G/2022',
      },
      {
        'name': 'CRY - Child Rights and You',
        'sub': 'Child Education, Healthcare & Protection against Child Labour',
        'vpa': 'cryindia@hdfcbank',
        'icon': Icons.volunteer_activism_rounded,
        'color': const Color(0xFFEC4899),
        'exemption': '50% Tax Exemption u/s 80G',
        'regNo': 'AAATC1979A/80G/2021',
      },
      {
        'name': 'Bharat Ke Veer Corpus Fund',
        'sub': 'Ministry of Home Affairs - Indian Armed Forces & CAPF Martyrs',
        'vpa': 'bharatkeveer@sbi',
        'icon': Icons.military_tech_rounded,
        'color': const Color(0xFF2563EB),
        'exemption': '100% Tax Exemption u/s 80G',
        'regNo': 'MHA/BKV/80G/2017',
      },
    ];

    Map<String, dynamic> selectedTrust = trusts.first;
    double donationAmount = 500.0;
    final panCtrl = TextEditingController(text: 'ABCDE1234F');
    final amountCtrl = TextEditingController(text: '500');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = _isDark;
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF046A38),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Donations & 80G Tax Exemption',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                              Text(
                                'Govt Recognized Trusts • Instant 80G Digital Certificate',
                                style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Verified Charitable Trust',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          ...trusts.map((t) {
                            final isSel = selectedTrust['name'] == t['name'];
                            return InkWell(
                              onTap: () => setModalState(() => selectedTrust = t),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFF046A38).withValues(alpha: 0.1)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF046A38) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: isSel ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: (t['color'] as Color).withValues(alpha: 0.15),
                                      child: Icon(t['icon'] as IconData, color: t['color'] as Color, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  t['name'] as String,
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF046A38),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w900)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            t['sub'] as String,
                                            style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            t['exemption'] as String,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isSel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                      color: isSel ? const Color(0xFF046A38) : const Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 14),
                          const Text(
                            'Donation Amount (INR)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [100, 250, 500, 1000, 2500].map((amt) {
                              final isSel = donationAmount == amt.toDouble();
                              return Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      donationAmount = amt.toDouble();
                                      amountCtrl.text = amt.toString();
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel ? const Color(0xFF046A38) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSel ? const Color(0xFF046A38) : Colors.transparent,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '₹$amt',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Custom Donation Amount',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (val) {
                              final p = double.tryParse(val);
                              if (p != null) setModalState(() => donationAmount = p);
                            },
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: panCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Donor PAN Number (for 80G Certificate)',
                              hintText: 'ABCDE1234F',
                              helperText: 'Mandatory for income tax exemption claim',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _processDonationPayment(selectedTrust, donationAmount, panCtrl.text.trim());
                              },
                              icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                              label: Text(
                                'Donate ₹${donationAmount.toStringAsFixed(0)} & Get 80G Certificate',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF046A38),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _processDonationPayment(Map<String, dynamic> trust, double amount, String pan) {
    final ref = 'DON-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    BharatOnePayApi.recordTransaction(
      title: 'Donation: ${trust['name']}',
      type: 'DEBIT',
      category: 'DONATION',
      amount: amount,
      reference: ref,
      status: 'SUCCESS',
    );

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF046A38), size: 28),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                '80G Donation Receipt',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF046A38), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Donation of ₹${amount.toStringAsFixed(2)} Successful!',
                      style: const TextStyle(color: Color(0xFF046A38), fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Beneficiary: ${trust['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('Registration No: ${trust['regNo']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            Text('Tax Exemption: ${trust['exemption']}', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11)),
            Text('Donor PAN: $pan', style: const TextStyle(fontSize: 11)),
            Text('Receipt Reference: $ref', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            const Text(
              'A digital 80G Certificate with QR code has been saved to your Statements and emailed to your registered address.',
              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(c),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // GOVT VAHAN ROAD TAX (MV TAX) ASSESSMENT & DIGITAL TOKEN
  // ===========================================================================
  void _showRoadTaxModal() {
    final vehicleCtrl = TextEditingController(text: 'WB02AK1234');
    String selectedClass = 'Private Car (LMV)';
    String selectedRto = 'West Bengal (WB RTO Kolkata)';
    String selectedTenure = '1 Year (Annual Tax)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double baseTax = 3200.0;
            if (selectedClass.contains('Two-Wheeler')) {
              baseTax = selectedTenure.contains('1 Year') ? 950.0 : (selectedTenure.contains('5 Years') ? 4200.0 : 8500.0);
            } else if (selectedClass.contains('Private Car')) {
              baseTax = selectedTenure.contains('1 Year') ? 3200.0 : (selectedTenure.contains('5 Years') ? 14500.0 : 32000.0);
            } else if (selectedClass.contains('Commercial')) {
              baseTax = selectedTenure.contains('1 Year') ? 5800.0 : (selectedTenure.contains('5 Years') ? 26000.0 : 58000.0);
            } else {
              baseTax = selectedTenure.contains('1 Year') ? 450.0 : (selectedTenure.contains('5 Years') ? 2000.0 : 4500.0);
            }
            const greenCess = 150.0;
            const roadSafetySurcharge = 100.0;
            final grandTotal = baseTax + greenCess + roadSafetySurcharge;

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF046A38),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.car_repair_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parivahan Road Tax (MV Tax)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Ministry of Road Transport & Highways • State RTO Tax Assessment',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF1E40AF), size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Authorized Vahan 4.0 Online Tax Collection Switch. Instant digital tax token and Form 23 clearance certificate.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '1. Vehicle Registration Number',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: vehicleCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'e.g. WB02AK1234 / MH01AB1234',
                              filled: true,
                              fillColor: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF046A38)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            '2. Vehicle Classification',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedClass,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'Two-Wheeler (Motorcycle / Scooter)', child: Text('🏍️ Two-Wheeler (Motorcycle / Scooter)')),
                                  DropdownMenuItem(value: 'Private Car (LMV)', child: Text('🚗 Private Car / SUV (LMV)')),
                                  DropdownMenuItem(value: 'Commercial Goods Carrier', child: Text('🚚 Commercial Goods Carrier')),
                                  DropdownMenuItem(value: 'Electric Vehicle (EV)', child: Text('⚡ Electric Vehicle (EV - Subsidized)')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setModalState(() => selectedClass = v);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            '3. State RTO Jurisdiction',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedRto,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'West Bengal (WB RTO Kolkata)', child: Text('🏛️ West Bengal (WB RTO Kolkata)')),
                                  DropdownMenuItem(value: 'Maharashtra (MH RTO Mumbai)', child: Text('🏛️ Maharashtra (MH RTO Mumbai)')),
                                  DropdownMenuItem(value: 'Delhi NCR (DL RTO Delhi)', child: Text('🏛️ Delhi NCR (DL RTO Delhi)')),
                                  DropdownMenuItem(value: 'Karnataka (KA RTO Bengaluru)', child: Text('🏛️ Karnataka (KA RTO Bengaluru)')),
                                  DropdownMenuItem(value: 'Tamil Nadu (TN RTO Chennai)', child: Text('🏛️ Tamil Nadu (TN RTO Chennai)')),
                                  DropdownMenuItem(value: 'Uttar Pradesh (UP RTO Lucknow)', child: Text('🏛️ Uttar Pradesh (UP RTO Lucknow)')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setModalState(() => selectedRto = v);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            '4. Road Tax Assessment Tenure',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildTenureChoiceChip('1 Year (Annual Tax)', selectedTenure, (v) => setModalState(() => selectedTenure = v)),
                              const SizedBox(width: 8),
                              _buildTenureChoiceChip('5 Years', selectedTenure, (v) => setModalState(() => selectedTenure = v)),
                              const SizedBox(width: 8),
                              _buildTenureChoiceChip('15 Years (Life Time Tax)', selectedTenure, (v) => setModalState(() => selectedTenure = v)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Base Motor Vehicle Tax:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    Text('₹${baseTax.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Green Environmental Cess:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    Text('₹${greenCess.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Road Safety Surcharge:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    Text('₹${roadSafetySurcharge.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Late Penalty / Arrears:', style: TextStyle(fontSize: 12, color: Color(0xFF046A38))),
                                    Text('₹0.00 (Nil)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF046A38))),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Tax Payable:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                    Text(
                                      '₹${grandTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF046A38)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF046A38),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.check_circle_rounded),
                              label: Text(
                                'Pay Road Tax ₹${grandTotal.toStringAsFixed(2)} via Bharat One Pay',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                final vNo = vehicleCtrl.text.trim().toUpperCase();
                                if (vNo.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter vehicle registration number')),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx);
                                _processRoadTaxPayment(
                                  vehicleNo: vNo,
                                  vehicleClass: selectedClass,
                                  rto: selectedRto,
                                  tenure: selectedTenure,
                                  amount: grandTotal,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTenureChoiceChip(String label, String currentVal, Function(String) onSelect) {
    final isSelected = currentVal == label;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(label),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF046A38) : (_isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF046A38) : _cardBorder,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : _textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _processRoadTaxPayment({
    required String vehicleNo,
    required String vehicleClass,
    required String rto,
    required String tenure,
    required double amount,
  }) {
    final receiptId = 'VAHAN-RT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final ref = 'UPI/VAHAN/${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

    BharatOnePayApi.recordTransaction(
      title: 'MoRTH Vahan Road Tax • $vehicleNo',
      type: 'DEBIT',
      category: 'GOVT_TAX',
      amount: amount,
      reference: ref,
      status: 'SUCCESS',
    );
    int validityYears = 1;
    if (tenure.contains('5 Years')) validityYears = 5;
    if (tenure.contains('15 Years')) validityYears = 15;
    final validUntil = '${DateTime.now().day} Oct ${DateTime.now().year + validityYears}';

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF046A38), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Road Tax Paid & Cleared',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GOVERNMENT OF INDIA • MoRTH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF166534))),
                  const Text('Form 23 Vahan Motor Vehicle Tax Token & Clearance', style: TextStyle(fontSize: 10, color: Color(0xFF046A38))),
                  const Divider(height: 12),
                  Text('Receipt No: $receiptId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  Text('Vehicle Reg: $vehicleNo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                  Text('RTO Circle: $rto', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  Text('Tax Tenure: $tenure', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  Text('Tax Valid Until: $validUntil', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF046A38))),
                  const SizedBox(height: 6),
                  Text('Amount Paid: ₹${amount.toStringAsFixed(2)} (BBPS Cleared)', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0D1B2A))),
                  Text('Ref / UTR: $ref', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Done & Save Receipt'),
          ),
        ],
      ),
    );
  }

  void _showInsuranceDiscoveryModal(String routeKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Insurance & Protection Plans',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Color(0xFF1D4ED8), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'IRDAI Certified Insurance Partners (HDFC ERGO, Star Health, LIC, Digit)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildInsuranceCard(
              'Health Insurance',
              '₹5 Lakh cashless cover in 10,000+ network hospitals',
              'Starting ₹380/mo',
              Icons.health_and_safety,
              const Color(0xFFDC2626),
            ),
            _buildInsuranceCard(
              'Term Life Insurance',
              '₹1 Crore financial shield for family with 99.3% claim settlement',
              'Starting ₹490/mo',
              Icons.family_restroom,
              const Color(0xFF046A38),
            ),
            _buildInsuranceCard(
              'Road Tax (Vahan RTO)',
              'State Motor Vehicle Tax assessment, Green Cess & instant digital tax token',
              'Govt Vahan 4.0 Portal',
              Icons.car_repair_rounded,
              const Color(0xFF046A38),
              onTap: () {
                Navigator.pop(ctx);
                _showRoadTaxModal();
              },
            ),
            _buildInsuranceCard(
              'Motor & Bike Insurance',
              'Zero inspection instant policy renewal with 24x7 roadside assist',
              'Starting ₹652/yr',
              Icons.directions_car,
              const Color(0xFF1D4ED8),
            ),
            _buildInsuranceCard(
              'Travel Insurance',
              'Medical emergencies abroad, flight delays & lost baggage protection',
              'Starting ₹299/trip',
              Icons.flight,
              const Color(0xFFFF9100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceCard(
    String title,
    String desc,
    String price,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onTap ?? () {
              Navigator.pop(context);
              _showPolicyPurchaseModal(title, price, icon, color);
            },
            child: const Text(
              'Buy Policy',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INTERACTIVE LOAN, CREDIT & PRECIOUS METALS MODALS
  // ===========================================================================
  void _showLoanApplicationModal(String routeKey) {
    String loanTitle = 'Personal Loan';
    int maxAmount = 500000;
    double rate = 10.5;
    if (routeKey == 'loan_mf') {
      loanTitle = 'Loan Against Mutual Funds';
      maxAmount = 1000000;
      rate = 9.5;
    } else if (routeKey == 'loan_gold') {
      loanTitle = 'Gold Loan (Doorstep)';
      maxAmount = 1500000;
      rate = 9.0;
    } else if (routeKey == 'loan_home') {
      loanTitle = 'Home Loan & Property Credit';
      maxAmount = 7500000;
      rate = 8.4;
    } else if (routeKey == 'loan_auto' || routeKey == 'loan_bike') {
      loanTitle = routeKey == 'loan_bike' ? 'Two-Wheeler Loan' : 'Vehicle / Auto Loan';
      maxAmount = routeKey == 'loan_bike' ? 250000 : 1200000;
      rate = 9.25;
    } else if (routeKey == 'loan_education') {
      loanTitle = 'Education & Study Loan';
      maxAmount = 2500000;
      rate = 8.85;
    } else if (routeKey == 'loan_consumer') {
      loanTitle = 'Consumer Durable Instant Loan';
      maxAmount = 250000;
      rate = 11.0;
    } else if (routeKey == 'loan_business' || routeKey == 'working_capital') {
      loanTitle = 'Business & Working Capital Loan';
      maxAmount = 5000000;
      rate = 11.5;
    } else if (routeKey == 'kisan_credit') {
      loanTitle = 'Kisan Credit / Agri Loan';
      maxAmount = 300000;
      rate = 7.0;
    } else if (routeKey == 'loan_repayment') {
      _selectBillCategoryAndOpen('LOAN');
      return;
    }

    int selectedAmount = (maxAmount > 200000) ? 200000 : maxAmount;
    int selectedTenure = 24;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final monthlyRate = rate / 12 / 100;
            final emi = (selectedAmount * monthlyRate * (1 + monthlyRate) * selectedTenure) /
                ((1 + monthlyRate) * selectedTenure - 1);
            final emiDisplay = emi.isFinite && emi > 0 ? emi.round() : (selectedAmount / selectedTenure).round();

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF2563EB), size: 22),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loanTitle,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const Text(
                                  'Pre-Approved • Instant Disbursal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Monthly EMI',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹$emiDisplay / mo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF671F),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Rate: $rate% p.a.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Select Loan Amount',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [50000, 100000, 200000, 300000, 500000].map((amt) {
                        final isSel = selectedAmount == amt;
                        return ChoiceChip(
                          label: Text('₹${amt ~/ 1000}K'),
                          selected: isSel,
                          onSelected: (_) => setModalState(() => selectedAmount = amt),
                          selectedColor: const Color(0xFF0F172A),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Select Tenure (Months)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [6, 12, 24, 36, 48].map((t) {
                        final isSel = selectedTenure == t;
                        return ChoiceChip(
                          label: Text('$t Mo'),
                          selected: isSel,
                          onSelected: (_) => setModalState(() => selectedTenure = t),
                          selectedColor: const Color(0xFFFF671F),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('100% Digital paperless KYC approval', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Zero prepayment penalty after 6 months', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF671F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          final res = BharatOnePayApi.disburseInstantLoan(
                            loanType: loanTitle,
                            amount: selectedAmount.toDouble(),
                            tenureMonths: selectedTenure,
                            interestRate: rate,
                          );
                          if (res['success'] == true) {
                            setState(() {});
                            showDialog(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.task_alt_rounded, color: Color(0xFF059669)),
                                    SizedBox(width: 8),
                                    Text('Loan Disbursed Instantly!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹$selectedAmount has been credited directly to your primary bank account (${res['loan']?['disbursedToBank'] ?? 'SBI ••••3038'})!',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF046A38)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Updated Account Balance: ₹${(res['newBalance'] as num?)?.toStringAsFixed(2) ?? ""}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text('Monthly EMI: ₹${(res['loan']?['monthlyEmi'] as num?)?.toStringAsFixed(0)} / mo for $selectedTenure months at $rate% p.a.', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    const SizedBox(height: 6),
                                    Text('Sanction ID: #${res['loan']?['loanId']}', style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx),
                                    child: const Text('View Available Balance', style: TextStyle(color: Color(0xFF046A38), fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'] ?? 'Disbursal failed')),
                            );
                          }
                        },
                        child: const Text(
                          'Apply Instantly & Disburse',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreditScoreModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed_rounded, color: Color(0xFF2563EB), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Credit Score & Health',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CIBIL CREDIT SCORE',
                      style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '785',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Excellent • Low Credit Risk',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('300', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            Text('Poor', style: TextStyle(color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('650', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            Text('Good', style: TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('750+', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                            Text('Excellent', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('900', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            Text('Max', style: TextStyle(color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Key Score Factors',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              _buildCreditFactorRow('Payment History', '100% on-time', Icons.check_circle_rounded, const Color(0xFF059669)),
              _buildCreditFactorRow('Credit Card Utilization', '14% (Ideal < 30%)', Icons.pie_chart_rounded, const Color(0xFF059669)),
              _buildCreditFactorRow('Credit Age', '4 Yrs 2 Mos', Icons.history_rounded, const Color(0xFF2563EB)),
              _buildCreditFactorRow('Hard Enquiries', '0 in last 6 months', Icons.search_rounded, const Color(0xFF059669)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF0F172A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading official CIBIL report PDF...')),
                        );
                      },
                      child: Text('Download PDF', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF671F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Credit score refreshed! Score remains healthy at 785.')),
                        );
                      },
                      child: const Text('Refresh Free', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreditFactorRow(String factor, String status, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(factor, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
          ),
          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showGoldSilverVaultModal(String metal) {
    final isGold = metal.toLowerCase().contains('gold');
    final isSilver = metal.toLowerCase().contains('silver');
    final ratePerGram = isGold ? 7450.0 : (isSilver ? 94.5 : 3120.0);
    final unit = isGold ? '24K 99.9% Pure Gold' : (isSilver ? '99.9% Fine Silver' : '95% Pure Platinum');
    int selectedAmt = 500;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final grams = (selectedAmt / ratePerGram).toStringAsFixed(4);

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isGold ? const Color(0xFFD97706) : const Color(0xFF64748B)).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isGold ? Icons.savings_rounded : Icons.generating_tokens_rounded,
                                color: isGold ? const Color(0xFFD97706) : const Color(0xFF64748B),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$metal Vault & SIP',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  unit,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isGold ? const Color(0xFFD97706) : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Live Buy Price', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                '₹$ratePerGram / g',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF046A38),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Insured Vault',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Investment Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [10, 50, 100, 500, 1000, 5000].map((amt) {
                        final isSel = selectedAmt == amt;
                        return ChoiceChip(
                          label: Text('₹$amt'),
                          selected: isSel,
                          onSelected: (_) => setModalState(() => selectedAmt = amt),
                          selectedColor: const Color(0xFFFF671F),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Equivalent Weight:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          Text(
                            '$grams grams',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF0F172A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Starting Daily ₹10 SIP in $metal...')),
                              );
                            },
                            child: const Text('Start Daily SIP', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF671F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
                                      SizedBox(width: 8),
                                      Text('Purchase Confirmed', style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                  content: Text(
                                    'Successfully added $grams grams of $unit (₹$selectedAmt) into your AikSetra Bullion Vault. Certificate ID #AK-BL-${DateTime.now().millisecondsSinceEpoch % 100000}.',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dCtx),
                                      child: const Text('OK', style: TextStyle(color: Color(0xFFFF671F), fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Buy Once', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _selectBillCategoryAndOpen(String category) {
    _openBillsModal(category: category);
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
                color: _isDark ? const Color(0xFF131B2E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _cardBorder),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(
                      Icons.auto_graph_rounded,
                      color: Color(0xFF046A38),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Auto-SIP',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Nifty 50 • Gold • Debt',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
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
            onTap: () => setState(() => _bottomNavIndex = 1),
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
                    child: Icon(
                      Icons.public_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foreign FX Pay',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'USD • GBP • EUR • SGD',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
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
              const Expanded(
                child: Text(
                  'Direct UPI Transfer & Safe Escrow',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _showSafePayDialog,
                child: const Text(
                  '🛡️ Safe Escrow',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
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
                  Icon(
                    Icons.search_rounded,
                    color: Color(0xFFFF671F),
                    size: 20,
                  ),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: const Color(0xFFFF671F),
                    child: const Icon(Icons.contacts_rounded, size: 12, color: Colors.white),
                  ),
                  backgroundColor: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  label: Text(
                    '+ Real Contacts',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  onPressed: _pickRealDeviceContact,
                ),
                ...recentPayees.take(5).map((p) {
                  return ActionChip(
                  backgroundColor: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  avatar: CircleAvatar(
                    backgroundColor: const Color(0xFFFF671F),
                    child: Text(
                      p['name']!.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: Text(
                    p['name']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  onPressed: () => _showSendMoneyDialog(
                    prefillVpa: p['vpa'],
                    prefillName: p['name'],
                  ),
                );
              }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openBillsModal({String? category}) {
    if (category != null) {
      _selectedBillCategory = category;
      final matching = BharatOnePayApi.bbpsBillers
          .where((b) => b['category'] == category)
          .toList();
      if (matching.isNotEmpty) {
        _selectedBiller = matching.first;
      }
      _fetchedBill = null;
      _consumerIdCtrl.clear();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            _billsModalSetter = setModalState;
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: BoxDecoration(
                color: _bgScaffold,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(
                        bottom: BorderSide(
                          color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bharat Connect (BBPS)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Instant bill fetch & receipt • NPCI Bharat Connect',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildBillsTab(),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _billsModalSetter = null;
      if (mounted) setState(() {});
    });
  }

  // TAB 1: BBPS UTILITY BILLS & RECHARGES (Electricity, Water, Gas, Broadband)
  // ===========================================================================
  Widget _buildBillsTab() {
    final categories = [
      {'id': 'ELECTRICITY', 'label': '⚡ Electricity'},
      {'id': 'MOBILE', 'label': '📱 Mobile 5G'},
      {'id': 'DTH', 'label': '📺 DTH TV'},
      {'id': 'FASTAG', 'label': '🚗 FASTag'},
      {'id': 'GAS', 'label': '🔥 Gas / LPG'},
      {'id': 'WATER', 'label': '💧 Water'},
      {'id': 'BROADBAND', 'label': '🌐 Broadband'},
      {'id': 'LOAN', 'label': '🏦 Loan EMI'},
      {'id': 'CREDIT_CARD', 'label': '💳 Credit Card'},
      {'id': 'INSURANCE', 'label': '🛡️ LIC / Insurance'},
      {'id': 'MUNICIPAL', 'label': '🏛️ Municipal Tax'},
      {'id': 'CHALLAN', 'label': '🚦 Traffic Challan'},
      {'id': 'EDUCATION', 'label': '🎓 Education Fees'},
      {'id': 'HOUSING', 'label': '🏢 Housing Society'},
      {'id': 'CABLE', 'label': '📡 Cable TV'},
      {'id': 'SUBSCRIPTION', 'label': '🎁 Play & OTT'},
    ];

    final filteredBillers = BharatOnePayApi.bbpsBillers
        .where((b) => b['category'] == _selectedBillCategory)
        .toList();

    if (filteredBillers.isNotEmpty && (_selectedBiller == null || _selectedBiller!['category'] != _selectedBillCategory)) {
      _selectedBiller = filteredBillers.first;
    }

    final billTxns = BharatOnePayApi.recentTransactions
        .where(
          (t) =>
              (t['metadata'] is Map && t['metadata']['isBbpsBill'] == true) ||
              (t['remark'] ?? '').toString().toLowerCase().contains('bill'),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
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
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFFF671F),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bharat BillPay (BBPS) Utility Hub',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Instant Electricity, Water, Piped Gas, Broadband & FASTag Bill Fetch & Settlement',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
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
                    final list = BharatOnePayApi.bbpsBillers
                        .where((b) => b['category'] == cat)
                        .toList();
                    _setBillState(() {
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
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Select Official Biller / Utility Board',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                if (filteredBillers.isEmpty)
                  const Text(
                    'Loading BBPS billers...',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filteredBillers.map((b) {
                      final isSel =
                          _selectedBiller != null &&
                          _selectedBiller!['id'] == b['id'];
                      return InkWell(
                        onTap: () {
                          _setBillState(() {
                            _selectedBiller = b;
                            _fetchedBill = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF046A38).withValues(alpha: 0.1)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFF046A38)
                                  : const Color(0xFFCBD5E1),
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
                                  color: isSel
                                      ? const Color(0xFF046A38)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                b['stateOrCircle'] ?? '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _consumerIdCtrl,
                        decoration: InputDecoration(
                          hintText:
                              'Enter ${_selectedBiller?['consumerIdLabel'] ?? 'Consumer ID'}',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isFetchingBill ? null : _handleFetchBbpsBill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isFetchingBill
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Fetch Bill',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF046A38),
                                letterSpacing: 0.6,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _fetchedBill!['alreadyPaid'] == true
                                    ? const Color(0xFF046A38)
                                    : const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _fetchedBill!['alreadyPaid'] == true
                                    ? 'PAID'
                                    : 'DUE: ${_fetchedBill!['dueDate']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        _buildBillRow(
                          'Consumer Name',
                          _fetchedBill!['consumerName'].toString(),
                        ),
                        _buildBillRow(
                          'Biller',
                          _fetchedBill!['billerName'].toString(),
                        ),
                        _buildBillRow(
                          'Bill Number',
                          _fetchedBill!['billNumber'].toString(),
                        ),
                        _buildBillRow(
                          'Billing Period',
                          _fetchedBill!['billPeriod'].toString(),
                        ),
                        _buildBillRow(
                          'Usage / Plan',
                          _fetchedBill!['planOrUsage'].toString(),
                        ),
                        if (_fetchedBill!['meterNumber'] != null)
                          _buildBillRow(
                            'Meter Number',
                            _fetchedBill!['meterNumber'].toString(),
                          ),
                        if (_fetchedBill!['unitsConsumed'] != null)
                          _buildBillRow(
                            'Units Consumed',
                            '${_fetchedBill!['unitsConsumed']} kWh',
                          ),
                        if (_fetchedBill!['energyCharges'] != null)
                          _buildBillRow(
                            'Energy Charges (Slabs)',
                            '₹${(_fetchedBill!['energyCharges'] as num).toStringAsFixed(2)}',
                          ),
                        if (_fetchedBill!['fixedCharge'] != null)
                          _buildBillRow(
                            'Demand / Fixed Charge',
                            '₹${(_fetchedBill!['fixedCharge'] as num).toStringAsFixed(2)}',
                          ),
                        if (_fetchedBill!['electricityDuty'] != null)
                          _buildBillRow(
                            'State Electricity Duty (6%)',
                            '₹${(_fetchedBill!['electricityDuty'] as num).toStringAsFixed(2)}',
                          ),
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
                                const Text(
                                  'Official SERC Slab Breakdown:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...((_fetchedBill!['breakdown'] as List).map(
                                  (b) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 1,
                                    ),
                                    child: Text(
                                      '• $b',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Bill Payable',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '₹${(_fetchedBill!['amount'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                color: Color(0xFF046A38),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handlePayBbpsBill(_fetchedBill!),
                            icon: const Icon(
                              Icons.verified_user_rounded,
                              size: 18,
                            ),
                            label: Text(
                              'Pay ₹${(_fetchedBill!['amount'] as num).toStringAsFixed(0)} via $_bankName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF046A38),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
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
            ...billTxns.map(
              (b) => InkWell(
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              (b['remark'] ?? '').toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${((b['amount'] as num?) ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Color(0xFF046A38),
                            ),
                          ),
                          const Text(
                            'BBPS PAID ✓',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
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
        const SnackBar(
          content: Text(
            'Please enter your Consumer / Account Number (at least 4 digits/chars)',
          ),
        ),
      );
      return;
    }
    _setBillState(() => _isFetchingBill = true);
    final res = await BharatOnePayApi.fetchBillDetails(
      billerId: _selectedBiller!['id'],
      consumerNumber: cid,
    );
    if (!mounted) return;
    _setBillState(() {
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
      subtitle:
          'Consumer: ${bill['consumerNumber']} • Amount: ₹${bill['amount']}',
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
      _setBillState(() {
        if (_fetchedBill != null) _fetchedBill!['alreadyPaid'] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF046A38),
          content: Text(
            '✅ Bill Paid! Ref: ${res['bbpsRef']} • Updated Bank Balance: ₹${_bankBalance.toStringAsFixed(2)}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(res['message'] ?? 'Bill payment failed'),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF046A38), Color(0xFF065F46)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'BANK AUTO-SIP & WEALTH',
                        style: TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Linked: $_bankName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${((portfolio['currentValue'] as num?) ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invested: ₹${((portfolio['totalInvested'] as num?) ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Gain: +₹${((portfolio['totalReturns'] as num?) ?? 0).toStringAsFixed(2)} (+${portfolio['returnPct'] ?? 0}%)',
                      style: const TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
                            Icon(
                              Icons.trending_up,
                              color: Color(0xFF4ADE80),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'NIFTY 50',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '24,852.15',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '+164.20 (+0.67%) ▲',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            Icon(
                              Icons.trending_up,
                              color: Color(0xFF4ADE80),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'BSE SENSEX',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '81,424.30',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '+528.10 (+0.65%) ▲',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            ...mySips.map(
              (sip) => Container(
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '₹${sip['monthlyAmount']}/mo • Day ${sip['debitDay']}',
                            style: const TextStyle(
                              color: Color(0xFF046A38),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UMRN: ${sip['umrn']} • Units: ${sip['unitsHeld']} • Installments: ${sip['installmentsPaid']}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invested',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '₹${sip['totalInvested']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Current Value',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '₹${sip['currentValue']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF046A38),
                              ),
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
                            child: const Text(
                              '+ Top-up Installment',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                            child: const Text(
                              'Redeem to Bank',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ===================================================================
          // INDIAN STOCK MARKET WATCHLIST & INSTANT BUY / STOCK SIP (NSE / BSE)
          // ===================================================================
          // Live Benchmark Indices (NIFTY 50 & SENSEX)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: BharatOnePayApi.marketIndices.map((idx) {
                final isPositive = (idx['change'] as num) >= 0;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              idx['name'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${(idx['price'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isPositive ? '+' : ''}${(idx['change'] as num).toStringAsFixed(2)} (${isPositive ? '+' : ''}${(idx['changePct'] as num).toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Live Real-Time Ticker Stream Banner
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE STREAMING (NSE & BSE)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '⚡ Real-Time Ticks',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF046A38),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stock Search & Filter Bar
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF131B2E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFFFF671F), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _stockSearchCtrl,
                    style: TextStyle(fontSize: 13, color: _textPrimary),
                    onChanged: (val) => setState(() => _stockSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search 24+ stocks (e.g. Reliance, Tata, SBI...)',
                      hintStyle: TextStyle(fontSize: 12, color: _textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                if (_stockSearchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    color: _textSecondary,
                    onPressed: () {
                      _stockSearchCtrl.clear();
                      setState(() => _stockSearchQuery = '');
                    },
                  ),
              ],
            ),
          ),

          // Sector Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Banking', 'IT & Tech', 'Energy', 'Auto', 'FMCG', 'Infra'].map((sec) {
                final isSel = _selectedStockSector == sec;
                return Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedStockSector = sec),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFFFF671F)
                            : (_isDark ? const Color(0xFF131B2E) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel
                              ? const Color(0xFFFF671F)
                              : (_isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        sec,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                          color: isSel ? Colors.white : _textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // LIVE FINEMAN AI STOCK MARKET RECOMMENDATIONS & PREDICTION CAROUSEL
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.psychology_rounded, color: Color(0xFF2563EB), size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fineman Live Market Intelligence',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.fiber_manual_record, color: Color(0xFF16A34A), size: 7),
                          SizedBox(width: 4),
                          Text(
                            'LIVE AUTO-REFRESH',
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily algorithmic predictions computed from live tick feeds, order-flow momentum, and technical breakout zones.',
                  style: TextStyle(fontSize: 11, color: _textSecondary),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAiStockPill(
                        symbol: 'RELIANCE',
                        name: 'Reliance Ind.',
                        strategy: 'Intraday Momentum',
                        target: '₹3,092 - ₹3,152',
                        support: '₹2,928',
                        color: const Color(0xFF046A38),
                        isBullish: true,
                      ),
                      const SizedBox(width: 10),
                      _buildAiStockPill(
                        symbol: 'HDFCBANK',
                        name: 'HDFC Bank',
                        strategy: 'Breakout Continuation',
                        target: '₹1,741 - ₹1,775',
                        support: '₹1,649',
                        color: const Color(0xFF1E3A8A),
                        isBullish: true,
                      ),
                      const SizedBox(width: 10),
                      _buildAiStockPill(
                        symbol: 'INFY',
                        name: 'Infosys',
                        strategy: 'Tech Deal Surge',
                        target: '₹1,958 - ₹1,996',
                        support: '₹1,854',
                        color: const Color(0xFF7C3AED),
                        isBullish: true,
                      ),
                      const SizedBox(width: 10),
                      _buildAiStockPill(
                        symbol: 'SBIN',
                        name: 'State Bank',
                        strategy: 'PSU Capex Wave',
                        target: '₹878 - ₹895',
                        support: '₹831',
                        color: const Color(0xFFD97706),
                        isBullish: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stocks Watchlist (${BharatOnePayApi.indianStocks.where((s) {
                  final q = _stockSearchQuery.toLowerCase().trim();
                  final symbol = (s['symbol'] as String).toLowerCase();
                  final name = (s['name'] as String).toLowerCase();
                  final sector = (s['sector'] ?? '').toString().toLowerCase();
                  final matchesQ = q.isEmpty || symbol.contains(q) || name.contains(q) || sector.contains(q);
                  final matchesS = _selectedStockSector == 'All' || sector.toLowerCase().contains(_selectedStockSector.toLowerCase());
                  return matchesQ && matchesS;
                }).length})',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      color: Color(0xFF046A38),
                      size: 8,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'NSE LIVE',
                      style: TextStyle(
                        color: Color(0xFF046A38),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...BharatOnePayApi.indianStocks.where((stock) {
            final q = _stockSearchQuery.toLowerCase().trim();
            final symbol = (stock['symbol'] as String).toLowerCase();
            final name = (stock['name'] as String).toLowerCase();
            final sector = (stock['sector'] ?? '').toString().toLowerCase();
            final matchesQ = q.isEmpty || symbol.contains(q) || name.contains(q) || sector.contains(q);
            final matchesS = _selectedStockSector == 'All' || sector.toLowerCase().contains(_selectedStockSector.toLowerCase());
            return matchesQ && matchesS;
          }).map((stock) {
            final isPositive = (stock['change'] as num) >= 0;
            return InkWell(
              onTap: () => _showStockChartModal(stock),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isDark ? 0.2 : 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: Text(
                        (stock['symbol'] as String).substring(0, 2),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                stock['symbol'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.bar_chart_rounded,
                                size: 14,
                                color: Color(0xFFFF671F),
                              ),
                            ],
                          ),
                          Text(
                            stock['name'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            stock['sector'] ?? '',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Mini Intraday Bars / Graph Preview
                    _buildStockMiniBars(stock),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (stock['tickDirection'] != null && stock['tickDirection'] != 0) ...[
                                Icon(
                                  stock['tickDirection'] == 1 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                  color: stock['tickDirection'] == 1 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  size: 16,
                                ),
                              ],
                              Text(
                                '₹${(stock['price'] as num).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${isPositive ? '+' : ''}${(stock['change'] as num).toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isPositive
                                    ? const Color(0xFF046A38)
                                    : const Color(0xFFDC2626),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Buy',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _handleStockSip(stock),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    border: Border.all(
                                      color: const Color(0xFF86EFAC),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SIP',
                                    style: TextStyle(
                                      color: Color(0xFF046A38),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
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
            );
          }),
          const SizedBox(height: 16),

          const Text(
            'Start a Direct Bank Auto-SIP (0% Commission)',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ...plans.map(
            (plan) => Container(
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${plan['cagr3Y']}% 3Y CAGR',
                          style: const TextStyle(
                            color: Color(0xFF046A38),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan['amcOrIssuer']} • ${plan['category']} • NAV: ₹${plan['navOrUnitPrice']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Min SIP: ₹${plan['minMonthlyAmount']}/mo • Risk: ${plan['riskLevel']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showStartSipDialog(plan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF671F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Start Bank SIP →',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🧮 Bank SIP Compounding Calculator (15.6% p.a.)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monthly Bank Debit:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '₹${_calcMonthlySip.toStringAsFixed(0)} / month',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFFFF671F),
                      ),
                    ),
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
                    const Text(
                      'Investment Duration:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${_calcYears.toStringAsFixed(0)} Years',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF046A38),
                      ),
                    ),
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
                        const Text(
                          'Total Invested',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '₹${totalInvestedCalc.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Est. Wealth Gain',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '+₹${wealthGainedCalc.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Maturity Value',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '₹${maturityVal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF046A38),
                          ),
                        ),
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
    final amtCtrl = TextEditingController(
      text: (plan['minMonthlyAmount'] ?? 500).toString(),
    );
    int selectedDay = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${plan['name']} (${plan['cagr3Y']}% 3Y CAGR)',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF046A38),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Monthly SIP Installment Amount (₹)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [500, 1000, 2500, 5000].map((preset) {
                  return ActionChip(
                    label: Text('₹$preset'),
                    onPressed: () =>
                        setSheetState(() => amtCtrl.text = preset.toString()),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monthly Auto-Debit Date:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<int>(
                    value: selectedDay,
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('1st of Every Month'),
                      ),
                      DropdownMenuItem(
                        value: 5,
                        child: Text('5th of Every Month'),
                      ),
                      DropdownMenuItem(
                        value: 10,
                        child: Text('10th of Every Month'),
                      ),
                      DropdownMenuItem(
                        value: 15,
                        child: Text('15th of Every Month'),
                      ),
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
                      subtitle:
                          '${plan['name']} • 1st Installment: ₹${amt.toStringAsFixed(0)}',
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
                          content: Text(
                            '🎉 SIP Active! 1st Installment of ₹${amt.toStringAsFixed(0)} invested.',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,
                          content: Text(res['message'] ?? 'Failed'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Authorize Mandate & Invest Now ($_bankName)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
        const SnackBar(
          backgroundColor: Color(0xFF046A38),
          content: Text('✅ Extra SIP Installment Invested!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(res['message'] ?? 'Failed'),
        ),
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
          content: Text(
            '🏦 ₹${res['creditedAmount']} credited back to $_bankName!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(res['message'] ?? 'Redemption failed'),
        ),
      );
    }
  }

  // ===========================================================================
  // TAB 3: GLOBAL FX (IMPROVED FOREIGN CURRENCY TRANSFER)
  // ===========================================================================
  Widget _buildAbroadTab() {
    final corridors = [
      {
        'code': 'USD',
        'flag': '🇺🇸',
        'country': 'USA',
        'rail': 'Fedwire / ACH',
      },
      {
        'code': 'GBP',
        'flag': '🇬🇧',
        'country': 'UK',
        'rail': 'Faster Payments',
      },
      {
        'code': 'EUR',
        'flag': '🇪🇺',
        'country': 'Europe',
        'rail': 'SEPA Instant',
      },
      {
        'code': 'SGD',
        'flag': '🇸🇬',
        'country': 'Singapore',
        'rail': 'UPI-PayNow Direct',
      },
      {
        'code': 'AED',
        'flag': '🇦🇪',
        'country': 'UAE',
        'rail': 'NPCI-AANI Rupee',
      },
      {
        'code': 'CAD',
        'flag': '🇨🇦',
        'country': 'Canada',
        'rail': 'Interac EFT',
      },
      {
        'code': 'AUD',
        'flag': '🇦🇺',
        'country': 'Australia',
        'rail': 'NPP PayID',
      },
    ];

    final fxTxns = BharatOnePayApi.recentTransactions
        .where(
          (t) =>
              (t['metadata'] is Map &&
                  t['metadata']['isCrossBorder'] == true) ||
              (t['remark'] ?? '').toString().toLowerCase().contains(
                'remittance',
              ),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              ),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Direct Rupee-to-Foreign Currency Settlement • RBI LRS Compliant (USD 250,000/yr limit)',
                        style: TextStyle(
                          color: Color(0xFFC7D2FE),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            '1. Select Destination Country & Corridor',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: _textPrimary,
            ),
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
                      color: isSel ? const Color(0xFF312E81) : _cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel
                            ? const Color(0xFF818CF8)
                            : _cardBorder,
                      ),
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
                            color: isSel
                                ? Colors.white
                                : _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c['rail']!,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSel
                                ? const Color(0xFFC7D2FE)
                                : _textSecondary,
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
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Recipient Gets ($_fxCurrency)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fxForeignAmtCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _refreshFxQuote(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Foreign Amount to Send',
                    prefixText: '$_fxCurrency ',
                    suffixText: _fxCurrency,
                    filled: true,
                    fillColor: _isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [50, 100, 250, 500, 1000]
                        .map(
                          (preset) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(
                                '$preset $_fxCurrency',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                              backgroundColor: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              onPressed: () {
                                _fxForeignAmtCtrl.text = preset.toString();
                                _refreshFxQuote();
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoadingFxQuote)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_fxQuote != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE)),
                    ),
                    child: Column(
                      children: [
                        _buildBillRow(
                          'Guaranteed Exchange Rate',
                          '1 $_fxCurrency = ₹${_fxQuote!.exchangeRate.toStringAsFixed(2)}',
                        ),
                        _buildSettlementRow(
                          'Base Converted Amount',
                          '₹${_fxQuote!.sourceAmountInr.toStringAsFixed(2)}',
                        ),
                        _buildSettlementRow(
                          'Bank Remittance Fee (0.15%)',
                          '₹${_fxQuote!.adBankFeeInr.toStringAsFixed(2)}',
                        ),
                        _buildSettlementRow(
                          'GST on Currency Conversion (Rule 32)',
                          '₹${_fxQuote!.gstInr.toStringAsFixed(2)}',
                        ),
                        _buildSettlementRow(
                          'RBI LRS TCS u/s 206C(1G)',
                          '₹0.00 (Nil up to ₹7 Lakhs)',
                        ),
                        _buildSettlementRow(
                          'Settlement Rail',
                          _fxQuote!.partnerRail,
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total INR Debit from Bank',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: _textPrimary,
                              ),
                            ),
                            Text(
                              '₹${_fxQuote!.totalCostInr.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: _isDark ? const Color(0xFF818CF8) : const Color(0xFF312E81),
                              ),
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
                    Text(
                      '3. International Beneficiary / Contacts',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: _textPrimary,
                      ),
                    ),
                    const Text(
                      'Saved Contacts',
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                            selectedColor: const Color(0xFF4F46E5),
                            backgroundColor: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSel
                                  ? Colors.white
                                  : _textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            label: Text(
                              '${contact['flag']} ${contact['label']}',
                            ),
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
                        backgroundColor: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        label: Text(
                          '+ Clear / Custom',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fxBenIbanCtrl,
                  decoration: InputDecoration(
                    labelText: 'IBAN / SWIFT / PayNow / Account Number',
                    hintText: 'Enter destination IBAN or Account No',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _fxPurposeCode,
                  decoration: InputDecoration(
                    labelText: 'RBI LRS Purpose Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'S0301 - Family Maintenance & Savings',
                      child: Text('S0301 - Family Maintenance'),
                    ),
                    DropdownMenuItem(
                      value: 'S0305 - Overseas University Tuition',
                      child: Text('S0305 - Overseas Education'),
                    ),
                    DropdownMenuItem(
                      value: 'S0304 - Medical Treatment Abroad',
                      child: Text('S0304 - Medical Treatment'),
                    ),
                    DropdownMenuItem(
                      value: 'S0306 - International Travel / Hotel',
                      child: Text('S0306 - International Travel'),
                    ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF312E81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (fxTxns.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Recent International Transfers',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textPrimary),
            ),
            const SizedBox(height: 10),
            ...fxTxns.map(
              (t) => InkWell(
                onTap: () => _showTransactionReceiptModal(t),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['receiverName']?.toString() ??
                                  'Foreign Transfer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                            Text(
                              t['remark']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '-₹${((t['amount'] as num?) ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Color(0xFF312E81),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
          Expanded(
            child: Text(
              k,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              v,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
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
        const SnackBar(
          content: Text(
            'Please enter Recipient Name and IBAN / Account Number',
          ),
        ),
      );
      return;
    }

    final mpin = await _promptForMpin(
      title: 'Confirm Foreign Remittance',
      subtitle:
          'Send ${_fxQuote!.targetAmount} $_fxCurrency (₹${_fxQuote!.totalCostInr.toStringAsFixed(2)}) to $benName',
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
          content: Text(
            '🌍 Remittance Settled! ${res['amountReceivedForeign']} $_fxCurrency sent to $benName',
          ),
        ),
      );
      _fxBenNameCtrl.clear();
      _fxBenIbanCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(res['message'] ?? 'Transfer failed'),
        ),
      );
    }
  }

  // ===========================================================================
  // TAB 4: BANK ACCOUNTS & PROFILE
  // ===========================================================================
  // ===========================================================================
  // TAB 4: COMPREHENSIVE TRANSACTION HISTORY (GROUPED BY DATE & TIME)
  // ===========================================================================
  String _formatTxnDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txnDate = DateTime(dt.year, dt.month, dt.day);

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (txnDate == today) {
      return 'Today • ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } else if (txnDate == yesterday) {
      return 'Yesterday • ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } else {
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }
  }

  String _formatTxnTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  // ===========================================================================
  // TAB 3: SMART NOTIFICATIONS & BILL REMINDERS
  // ===========================================================================
  Widget _buildNotificationsTab() {
    final isDark = _isDark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Monthly & Annual Recurring Dues Reminders
    final dueReminders = [
      {
        'id': 'due_elec_nov',
        'type': 'due',
        'title': 'Electricity Bill Due Soon',
        'provider': 'BESCOM Bangalore • Consumer #409281729',
        'amount': '₹1,420',
        'dueDate': 'Due in 3 days (Nov 2)',
        'dueUrgent': true,
        'category': 'ELECTRICITY',
        'icon': Icons.bolt_rounded,
        'iconBg': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFD97706),
        'actionLabel': 'Pay Bill',
        'action': 'pay_electricity',
      },
      {
        'id': 'due_mobile_nov',
        'type': 'due',
        'title': 'Mobile Recharge Expiring',
        'provider': 'Jio 5G Unlimited (98765 43210)',
        'amount': '₹349',
        'dueDate': 'Expires in 4 days (Nov 3)',
        'dueUrgent': true,
        'category': 'MOBILE',
        'icon': Icons.phone_android_rounded,
        'iconBg': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF2563EB),
        'actionLabel': 'Recharge',
        'action': 'recharge_mobile',
      },
      {
        'id': 'due_fastag_low',
        'type': 'due',
        'title': 'FASTag Low Balance Alert',
        'provider': 'NHAI NETC FASTag (KA-01-MJ-4029)',
        'amount': 'Bal: ₹140',
        'dueDate': 'Threshold: Min ₹200 required',
        'dueUrgent': true,
        'category': 'FASTAG',
        'icon': Icons.directions_car_rounded,
        'iconBg': const Color(0xFFFEE2E2),
        'iconColor': const Color(0xFFDC2626),
        'actionLabel': 'Top Up ₹500',
        'action': 'topup_fastag',
      },
      {
        'id': 'due_insurance_nov',
        'type': 'due',
        'title': 'Annual Term Life Insurance Due',
        'provider': 'HDFC Life Click 2 Protect (Policy #POL-882910)',
        'amount': '₹8,450 / yr',
        'dueDate': 'Due on Nov 28 (Annual Renewal)',
        'dueUrgent': false,
        'category': 'INSURANCE',
        'icon': Icons.shield_rounded,
        'iconBg': const Color(0xFFF3E8FF),
        'iconColor': const Color(0xFF7C3AED),
        'actionLabel': 'Review & Pay',
        'action': 'pay_insurance',
      },
      {
        'id': 'due_sip_nov',
        'type': 'due',
        'title': 'SIP AutoPay Execution Scheduled',
        'provider': 'Nifty 50 Index Fund • SBI Mandate',
        'amount': '₹2,000',
        'dueDate': 'Scheduled Nov 5 (Auto-Debit)',
        'dueUrgent': false,
        'category': 'SIP',
        'icon': Icons.trending_up_rounded,
        'iconBg': const Color(0xFFDCFCE7),
        'iconColor': const Color(0xFF16A34A),
        'actionLabel': 'View SIP',
        'action': 'view_sip',
      },
      {
        'id': 'due_water_nov',
        'type': 'due',
        'title': 'Quarterly Water & Sewerage Bill',
        'provider': 'BWSSB Bangalore Water Supply',
        'amount': '₹380',
        'dueDate': 'Due Nov 12',
        'dueUrgent': false,
        'category': 'WATER',
        'icon': Icons.water_drop_rounded,
        'iconBg': const Color(0xFFE0F2FE),
        'iconColor': const Color(0xFF0284C7),
        'actionLabel': 'Pay Bill',
        'action': 'pay_water',
      },
    ].where((a) => !_dismissedAlertIds.contains(a['id'])).toList();

    // Transactions / Payments live notifications
    final liveTxns = BharatOnePayApi.recentTransactions.map((t) {
      final isCredit = t['isCredit'] == true;
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final userOrPayee = t['user'] ?? t['payee'] ?? 'UPI Transfer';
      final remark = t['remark'] ?? (isCredit ? 'Payment received' : 'Payment sent');
      final date = t['date'] ?? 'Recently';
      return {
        'id': 'txn_${t['id'] ?? t.hashCode}',
        'type': 'activity',
        'title': isCredit ? 'Payment Received' : 'Money Sent',
        'subtitle': isCredit
            ? '₹${amt.toStringAsFixed(0)} credited from $userOrPayee'
            : '₹${amt.toStringAsFixed(0)} paid to $userOrPayee',
        'detail': '$remark • Ref #${t['id'] ?? 'UPI'}',
        'time': date,
        'isCredit': isCredit,
        'amount': amt,
        'rawTxn': t,
      };
    }).toList();

    final activeDuesCount = dueReminders.where((a) => !BharatOnePayApi.paidDueIds.contains(a['id'])).length;
    double totalDueAmount = 0.0;
    for (final d in dueReminders) {
      if (!BharatOnePayApi.paidDueIds.contains(d['id'])) {
        final raw = (d['amount'] as String).replaceAll(RegExp(r'[^0-9.]'), '');
        totalDueAmount += double.tryParse(raw) ?? 0.0;
      }
    }
    final paymentsCount = liveTxns.length;

    // Filtered items based on tab selection
    final showDues = _selectedNotificationFilter == 'ALL' || _selectedNotificationFilter == 'DUES';
    final showPayments = _selectedNotificationFilter == 'ALL' || _selectedNotificationFilter == 'PAYMENTS';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner summary card
          Container(
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
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF671F).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFFFF671F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Alerts & Due Reminders',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Monthly / annual payments & live transactions',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (dueReminders.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$activeDuesCount Due',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF38BDF8), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Total Due This Month:',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        '₹${totalDueAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildNotificationFilterChip(
                  label: 'All Alerts (${activeDuesCount + paymentsCount})',
                  filterKey: 'ALL',
                ),
                const SizedBox(width: 8),
                _buildNotificationFilterChip(
                  label: 'Due Reminders ($activeDuesCount)',
                  filterKey: 'DUES',
                  icon: Icons.access_time_rounded,
                ),
                const SizedBox(width: 8),
                _buildNotificationFilterChip(
                  label: 'Payments & Receipts ($paymentsCount)',
                  filterKey: 'PAYMENTS',
                  icon: Icons.payments_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 1. DUE REMINDERS SECTION
          if (showDues && dueReminders.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Dues & Renewals',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                Text(
                  '$activeDuesCount Pending',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF671F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...dueReminders.map((due) {
              final isUrgent = due['dueUrgent'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isUrgent ? const Color(0xFFFCA5A5) : borderColor,
                    width: isUrgent ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: due['iconBg'] as Color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            due['icon'] as IconData,
                            color: due['iconColor'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      due['title'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                  if (BharatOnePayApi.paidDueIds.contains(due['id']))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'PAID ✓',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    )
                                  else if (isUrgent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'URGENT',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                due['provider'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 13,
                                    color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    due['dueDate'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          color: subColor,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _dismissedAlertIds.add(due['id'] as String);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bill Amount',
                              style: TextStyle(fontSize: 10, color: subColor),
                            ),
                            Text(
                              due['amount'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                        Builder(builder: (ctx) {
                          final isPaid = BharatOnePayApi.paidDueIds.contains(due['id']);
                          if (isPaid) {
                            return OutlinedButton.icon(
                              onPressed: () => _showDueReceiptDialog(due),
                              icon: const Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF10B981)),
                              label: const Text(
                                'Receipt',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF10B981)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF10B981)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            );
                          }
                          final rawAmt = (due['amount'] as String).replaceAll(RegExp(r'[^0-9.]'), '');
                          final dueAmt = double.tryParse(rawAmt) ?? 500.0;
                          return ElevatedButton(
                            onPressed: () => _showPayDueConfirmDialog(due, dueAmt),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF671F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  due['actionLabel'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 14),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // 2. LIVE PAYMENT NOTIFICATIONS SECTION
          if (showPayments) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment & Transaction Activity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                Text(
                  'Live Feed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: subColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (liveTxns.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  'No recent transaction activity to show.',
                  style: TextStyle(color: subColor, fontSize: 13),
                ),
              )
            else
              ...liveTxns.map((act) {
                final isCredit = act['isCredit'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      final raw = act['rawTxn'] as Map<String, dynamic>;
                      _showTransactionReceiptModal(raw);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isCredit ? const Color(0xFF16A34A) : const Color(0xFF475569),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  act['title'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  act['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${act['detail']} • ${act['time']}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isCredit ? '+' : '-'} ₹${(act['amount'] as double).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: isCredit ? const Color(0xFF16A34A) : titleColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'View Receipt >',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF671F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],

          if (dueReminders.isEmpty && liveTxns.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 48, color: subColor),
                  const SizedBox(height: 12),
                  Text(
                    'All caught up!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No pending dues or unread notifications at this time.',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationFilterChip({
    required String label,
    required String filterKey,
    IconData? icon,
  }) {
    final isSelected = _selectedNotificationFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedNotificationFilter = filterKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF671F) : (_isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF671F) : (_isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : (_isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (_isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayDueConfirmDialog(Map<String, dynamic> due, double amount) {
    final isBiz = BharatOnePayApi.isBusinessMode;
    final debitSource = isBiz
        ? 'Pentile Business Settlement Pool (Bal: ₹${((BharatOnePayApi.businessProfile['balance'] as num?)?.toDouble() ?? 48250.0).toStringAsFixed(2)})'
        : 'State Bank of India •••• 3038 (Primary)';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (due['iconColor'] as Color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(due['icon'] as IconData, color: due['iconColor'] as Color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pay ${due['title']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              due['provider'] as String,
              style: TextStyle(
                fontSize: 12,
                color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount Due', style: TextStyle(fontSize: 12, color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Debit From', style: TextStyle(fontSize: 11, color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          debitSource,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF046A38)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF00E676)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bharat Connect BBPS Assured • 0% Convenience Fee',
                    style: TextStyle(fontSize: 10, color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF671F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              BharatOnePayApi.markDueAsPaid(
                dueId: due['id'] as String,
                amount: amount,
                provider: due['provider'] as String,
              );
              setState(() {});
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF046A38),
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Payment of ₹${amount.toStringAsFixed(0)} to ${due['provider']} Successful!',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Text('Confirm & Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDueReceiptDialog(Map<String, dynamic> due) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Bharat Connect Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                  SizedBox(width: 8),
                  Text('STATUS: PAID & SETTLED', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Biller: ${due['provider']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Amount: ${due['amount']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Reference: NPCI-BBPS-${DateTime.now().millisecondsSinceEpoch}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            const SizedBox(height: 4),
            const Text('Payment Mode: Digital Clearance / Instant Auto-Settlement', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleDueNotificationAction(String action) {
    switch (action) {
      case 'pay_electricity':
        _openBillsModal(category: 'ELECTRICITY');
        break;
      case 'recharge_mobile':
        _openBillsModal(category: 'MOBILE');
        break;
      case 'topup_fastag':
        _openBillsModal(category: 'FASTAG');
        break;
      case 'pay_water':
        _openBillsModal(category: 'WATER');
        break;
      case 'pay_insurance':
        _showInsuranceDiscoveryModal('health_insurance');
        break;
      case 'view_sip':
        setState(() => _bottomNavIndex = 2);
        break;
      default:
        _openBillsModal();
        break;
    }
  }

  Widget _buildHistoryTab() {
    final allTxns = BharatOnePayApi.recentTransactions;

    // Filter transactions
    final filteredTxns = allTxns.where((t) {
      final name = (t['receiverName'] ?? t['receiverVpa'] ?? '')
          .toString()
          .toLowerCase();
      final remark = (t['remark'] ?? '').toString().toLowerCase();
      final rrn = (t['upiRrn'] ?? t['txnRef'] ?? '').toString().toLowerCase();
      final q = _historySearchQuery.toLowerCase().trim();

      if (q.isNotEmpty &&
          !name.contains(q) &&
          !remark.contains(q) &&
          !rrn.contains(q)) {
        return false;
      }

      final isCredit =
          (t['metadata'] is Map && t['metadata']['isCredit'] == true) ||
          remark.contains('credited') ||
          remark.contains('self transfer') ||
          remark.contains('deposit');

      if (_historyFilterType == 'DEBIT' && isCredit) return false;
      if (_historyFilterType == 'CREDIT' && !isCredit) return false;
      if (_historyFilterType == 'BILLS' &&
          !remark.contains('bill') &&
          !name.contains('limited') &&
          !name.contains('power'))
        return false;
      if (_historyFilterType == 'TRANSFER' &&
          (remark.contains('bill') || name.contains('limited')))
        return false;

      return true;
    }).toList();

    // Calculate spends totals
    double totalDebits = 0;
    double totalCredits = 0;
    for (final t in allTxns) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final remark = (t['remark'] ?? '').toString().toLowerCase();
      final isCredit =
          (t['metadata'] is Map && t['metadata']['isCredit'] == true) ||
          remark.contains('credited') ||
          remark.contains('self transfer') ||
          remark.contains('deposit');
      if (isCredit) {
        totalCredits += amt;
      } else {
        totalDebits += amt;
      }
    }

    // Group filtered transactions by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final t in filteredTxns) {
      DateTime dt;
      final raw = t['createdAt'] ?? t['timestamp'] ?? t['date'];
      if (raw != null) {
        dt = DateTime.tryParse(raw.toString())?.toLocal() ?? DateTime.now();
      } else {
        dt = DateTime.now();
      }
      final dateKey = _formatTxnDateHeader(dt);
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }

    return RefreshIndicator(
      onRefresh: _syncLiveState,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. DATE-WISE AUDIT STATEMENT & LEDGER PDF EXPORT BAR
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF131B2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF671F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFFF671F), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BharatOnePayApi.isBusinessMode
                              ? 'Business Ledger & Audit PDF'
                              : 'Passbook & Statement PDF',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Date-wise ledger statement compliant with IT audits',
                          style: TextStyle(fontSize: 10.5, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _downloadDateWiseStatementPdf(),
                    icon: const Icon(Icons.download_rounded, size: 15),
                    label: const Text('Export PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // 1. Spends Summary Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF131B2E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.north_east_rounded,
                              color: Color(0xFFEF4444),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Total Debits',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '-₹${totalDebits.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF131B2E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.south_west_rounded,
                              color: Color(0xFF046A38),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Total Credits',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '+₹${totalCredits.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF046A38),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 2. Search Box
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF131B2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
              ),
              child: TextField(
                controller: _historySearchCtrl,
                style: TextStyle(fontSize: 13, color: _textPrimary),
                onChanged: (val) => setState(() => _historySearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by name, UPI ID, or RRN...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFFF671F),
                    size: 18,
                  ),
                  suffixIcon: _historySearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: () {
                            _historySearchCtrl.clear();
                            setState(() => _historySearchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Category Filter Chips
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildHistoryFilterChip('All (${allTxns.length})', 'ALL'),
                  const SizedBox(width: 8),
                  _buildHistoryFilterChip('Debits (-)', 'DEBIT'),
                  const SizedBox(width: 8),
                  _buildHistoryFilterChip('Credits (+)', 'CREDIT'),
                  const SizedBox(width: 8),
                  _buildHistoryFilterChip('Bills (BBPS)', 'BILLS'),
                  const SizedBox(width: 8),
                  _buildHistoryFilterChip('Transfers', 'TRANSFER'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Date & Time Grouped Transaction Sections
            if (filteredTxns.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF131B2E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 44,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No transactions found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _historySearchQuery.isNotEmpty
                          ? 'No matches for "$_historySearchQuery"'
                          : 'No transactions recorded under this category.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_historySearchQuery.isNotEmpty ||
                        _historyFilterType != 'ALL') ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          _historySearchCtrl.clear();
                          setState(() {
                            _historySearchQuery = '';
                            _historyFilterType = 'ALL';
                          });
                        },
                        child: const Text(
                          'Reset All Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              ...grouped.entries.map((entry) {
                final dateHeader = entry.key;
                final dayTxns = entry.value;

                // Calculate day spend
                double daySpend = 0;
                for (final t in dayTxns) {
                  final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
                  final remark = (t['remark'] ?? '').toString().toLowerCase();
                  final isCredit =
                      (t['metadata'] is Map &&
                          t['metadata']['isCredit'] == true) ||
                      remark.contains('credited') ||
                      remark.contains('self transfer') ||
                      remark.contains('deposit');
                  if (!isCredit) daySpend += amt;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day Section Header
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: Color(0xFFFF671F),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateHeader,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          if (daySpend > 0)
                            Text(
                              'Spent: -₹${daySpend.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Day Transactions List
                    ...dayTxns.map((t) {
                      final name =
                          (t['receiverName'] ??
                                  t['receiverVpa'] ??
                                  'UPI Payment')
                              .toString();
                      final remark = (t['remark'] ?? 'NPCI UPI Settlement')
                          .toString();
                      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
                      final rrn = (t['upiRrn'] ?? t['txnRef'] ?? '42910012')
                          .toString();
                      final isCredit =
                          (t['metadata'] is Map &&
                              t['metadata']['isCredit'] == true) ||
                          remark.toLowerCase().contains('credited') ||
                          remark.toLowerCase().contains('self transfer') ||
                          remark.toLowerCase().contains('deposit');

                      DateTime txnDt;
                      final rawDt =
                          t['createdAt'] ?? t['timestamp'] ?? t['date'];
                      if (rawDt != null) {
                        txnDt =
                            DateTime.tryParse(rawDt.toString())?.toLocal() ??
                            DateTime.now();
                      } else {
                        txnDt = DateTime.now();
                      }
                      final timeString = _formatTxnTime(txnDt);

                      return InkWell(
                        onTap: () => _showTransactionReceiptModal(t),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.015),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCredit
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isCredit
                                      ? Icons.south_west_rounded
                                      : Icons.north_east_rounded,
                                  color: isCredit
                                      ? const Color(0xFF046A38)
                                      : const Color(0xFF0F172A),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.access_time_rounded,
                                                size: 10,
                                                color: Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                timeString,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$remark • SBI (•••• 3038) • RRN: $rrn',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isCredit ? "+" : "-"}₹${amt.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: isCredit
                                          ? const Color(0xFF046A38)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _showSendMoneyDialog(
                                          prefillVpa: (t['receiverVpa'] ?? t['receiverName'])?.toString(),
                                          prefillName: (t['receiverName'] ?? t['receiverVpa'])?.toString(),
                                          prefillAmount: ((t['amount'] as num?) ?? 0).toStringAsFixed(0),
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF671F).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.replay_rounded, size: 9, color: Color(0xFFFF671F)),
                                              SizedBox(width: 2),
                                              Text(
                                                'Pay Again',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFFFF671F),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'SUCCESS',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF046A38),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryFilterChip(String label, String type) {
    final isSelected = _historyFilterType == type;
    return InkWell(
      onTap: () => setState(() => _historyFilterType = type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION BAR
  // ===========================================================================
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        selectedItemColor: const Color(0xFFFF671F),
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFF94A3B8),
        ),
        onTap: (idx) => setState(() => _bottomNavIndex = idx),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            activeIcon: const Icon(Icons.home_filled, color: Color(0xFFFF671F)),
            label: _t('tab_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.public_rounded),
            activeIcon: const Icon(Icons.public_rounded, color: Color(0xFFFF671F)),
            label: _t('tab_global'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.trending_up_rounded),
            activeIcon: const Icon(Icons.trending_up_rounded, color: Color(0xFFFF671F)),
            label: _t('tab_wealth'),
          ),
          BottomNavigationBarItem(
            icon: Builder(builder: (context) {
              final activeDues = [
                'due_elec_nov', 'due_mobile_nov', 'due_fastag_low', 'due_insurance_nov', 'due_sip_nov', 'due_water_nov'
              ].where((id) => !_dismissedAlertIds.contains(id) && !BharatOnePayApi.paidDueIds.contains(id)).toList();
              if (activeDues.isNotEmpty) {
                return Badge(
                  label: Text(
                    '${activeDues.length}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  child: const Icon(Icons.notifications_none_rounded),
                );
              }
              return const Icon(Icons.notifications_none_rounded);
            }),
            activeIcon: Builder(builder: (context) {
              final activeDues = [
                'due_elec_nov', 'due_mobile_nov', 'due_fastag_low', 'due_insurance_nov', 'due_sip_nov', 'due_water_nov'
              ].where((id) => !_dismissedAlertIds.contains(id) && !BharatOnePayApi.paidDueIds.contains(id)).toList();
              if (activeDues.isNotEmpty) {
                return Badge(
                  label: Text(
                    '${activeDues.length}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF671F)),
                );
              }
              return const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF671F));
            }),
            label: _t('tab_notifications'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            activeIcon: const Icon(
              Icons.history_rounded,
              color: Color(0xFFFF671F),
            ),
            label: _t('tab_history'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REAL HARDWARE CAMERA QR SCANNER (MobileScanner) & REAL QR GENERATOR
  // ===========================================================================
  Future<void> _openRealCameraQrScanner() async {
    final scannedRaw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _RealCameraQrScannerScreen()),
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
      final vpaMatch = RegExp(r'([a-zA-Z0-9.\-_]{2,64}@[a-zA-Z0-9]{2,32})')
          .firstMatch(cleaned);
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
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
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
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$_bankName • $_maskedAcc',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                // REAL ISO-18004 Scannable QR Code using qr_flutter
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0F172A),
                      width: 2,
                    ),
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
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF046A38),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Text(
                    'Demo Payment QR — No real money transferred',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  _userVpa,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF671F),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reqAmtCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Optional: Set Specific Amount to Receive (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                            const SnackBar(
                              content: Text(
                                '📋 UPI QR URI copied to clipboard!',
                              ),
                            ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                        ),
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
      text:
          prefillNote ?? (prefillName != null ? 'Payment to $prefillName' : ''),
    );
    bool useEscrow = false;
    String? selectedBankAccountId = BharatOnePayApi.primaryAccount?.id ??
        (BharatOnePayApi.linkedAccounts.isNotEmpty ? BharatOnePayApi.linkedAccounts.first.id : null);
    String? selectedCardId; // null = pay from selected Bank Account, non-null = pay from Linked Debit/Credit Card

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                Text(
                  prefillName != null
                      ? 'Pay $prefillName'
                      : 'Send Money via NPCI UPI / Card',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),

                // Payment Instrument Selector (Bank Account vs Linked Debit / Credit Cards)
                const Text(
                  'Pay Using:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...BharatOnePayApi.linkedAccounts.map((acc) {
                        final isSel = selectedCardId == null && selectedBankAccountId == acc.id;
                        final isCurrent = acc.accountType == 'CURRENT';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(
                              isCurrent ? Icons.business_center : Icons.account_balance,
                              size: 14,
                              color: isSel ? Colors.white : (isCurrent ? const Color(0xFF1D4ED8) : const Color(0xFF046A38)),
                            ),
                            label: Text(
                              '${acc.bankName} (${acc.accountType} • ${acc.maskedAccountNumber.replaceAll(RegExp(r'[^0-9]'), '')}) ₹${acc.balance.toStringAsFixed(0)}',
                            ),
                            selected: isSel,
                            selectedColor: isCurrent ? const Color(0xFF1E3A8A) : const Color(0xFF046A38),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setSheetState(() {
                              selectedBankAccountId = acc.id;
                              selectedCardId = null;
                            }),
                          ),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 14, color: Color(0xFF046A38)),
                        label: const Text(
                          '+ Add Bank',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF046A38),
                          ),
                        ),
                        onPressed: () {
                          BankAccountSwitcherModal.showAddAccountDialog(context).then((newAcc) {
                            if (newAcc != null) {
                              setSheetState(() {
                                selectedBankAccountId = newAcc.id;
                                selectedCardId = null;
                              });
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...BharatOnePayApi.linkedCards.map((c) {
                        final cid = c['id'].toString();
                        final isSel = selectedCardId == cid;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              '💳 ${c['network']} ${c['cardType']} (${c['last4']})',
                            ),
                            selected: isSel,
                            selectedColor: const Color(0xFF4F46E5),
                            labelStyle: TextStyle(
                              color: isSel
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setSheetState(() {
                              selectedCardId = cid;
                              selectedBankAccountId = null;
                            }),
                          ),
                        );
                      }),
                      ActionChip(
                        label: const Text(
                          '+ Add Card',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CardsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickRealDeviceContact();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF671F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF671F).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.contacts_rounded, size: 16, color: Color(0xFFFF671F)),
                        SizedBox(width: 6),
                        Text(
                          '📱 Choose from Real Contacts (Demo Pay)',
                          style: TextStyle(
                            color: Color(0xFFFF671F),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: vpaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Recipient UPI ID or 10-Digit Mobile No',
                    hintText: 'e.g. merchant@okaxis, shop@ybl, or 9830113038',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Remark / Purpose',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: useEscrow,
                  activeColor: const Color(0xFF2563EB),
                  title: const Text(
                    '🛡️ Hold in Safe Pay Escrow until delivery',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Money is locked safely and released only when you confirm receipt',
                    style: TextStyle(fontSize: 10),
                  ),
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
                          itemDescription: noteCtrl.text.trim().isEmpty
                              ? 'Escrow Purchase'
                              : noteCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF2563EB),
                            content: Text(
                              '🛡️ ₹${amt.toStringAsFixed(0)} locked in Safe Pay Escrow for $rawVpa',
                            ),
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
                        final proceed = await _showScamWarningConfirmation(
                          risk,
                          rawVpa,
                          amt,
                        );
                        if (proceed != true) return;
                      }

                      final chosenAcc = BharatOnePayApi.linkedAccounts.firstWhere(
                        (a) => a.id == selectedBankAccountId,
                        orElse: () => BharatOnePayApi.primaryAccount ?? BharatOnePayApi.linkedAccounts.first,
                      );
                      final mpin = await _promptForMpin(
                        title: selectedCardId != null
                            ? 'Authorize Card / RuPay UPI Payment'
                            : 'Authorize UPI Payment (${chosenAcc.bankName} ${chosenAcc.accountType})',
                        subtitle: 'Pay ₹${amt.toStringAsFixed(2)} to $rawVpa',
                      );
                      if (mpin == null || mpin.length < 4) return;

                      final payRes = await BharatOnePayApi.payUpi(
                        receiverVpa: rawVpa,
                        receiverName: prefillName ?? rawVpa.split('@').first,
                        amount: amt,
                        mpin: mpin,
                        senderAccountId: selectedCardId == null ? selectedBankAccountId : null,
                        cardId: selectedCardId,
                        remark: noteCtrl.text.trim().isEmpty
                            ? 'UPI Transfer'
                            : noteCtrl.text.trim(),
                        bypassScamWarning: true,
                      );

                      await _syncLiveState();

                      if (!mounted) return;
                      setState(() {});
                      if (payRes['success'] == true) {
                        final isSim =
                            payRes['isSimulated'] == true ||
                            (payRes['transaction'] is Map &&
                                payRes['transaction']['status'] ==
                                    'SIMULATED_SUCCESS');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF046A38),
                            duration: const Duration(seconds: 4),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '✅ Paid ₹${amt.toStringAsFixed(2)} to $rawVpa!',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isSim)
                                  const Text(
                                    'Demo payment — no real money transferred',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFBBF7D0),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              payRes['message'] ?? 'Payment declined',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCardId != null
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF046A38),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      selectedCardId != null
                          ? 'Pay Instantly with Linked Card & PIN →'
                          : 'Pay Instantly with AikSetra UPI PIN →',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                      final note = noteCtrl.text.trim().isEmpty
                          ? 'AikSetra UPI'
                          : noteCtrl.text.trim();
                      Navigator.pop(ctx);

                      final risk = await BharatOnePayApi.analyzeScamRisk(
                        receiverVpa: rawVpa,
                        amount: amt,
                        remark: note,
                      );
                      if (!mounted) return;
                      if (risk.riskLevel == 'HIGH' || risk.riskScore >= 60) {
                        final proceed = await _showScamWarningConfirmation(
                          risk,
                          rawVpa,
                          amt,
                        );
                        if (proceed != true) return;
                      }

                      final upiUri = Uri.parse(
                        'upi://pay?pa=$rawVpa&pn=${Uri.encodeComponent(payeeName)}&am=${amt.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(note)}',
                      );
                      try {
                        final launched = await launchUrl(
                          upiUri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No external UPI app (GPay/PhonePe/Paytm) found on this device.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not open external UPI app: $e',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text(
                      'Pay Real Money via Installed UPI App (GPay / PhonePe / BHIM)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: msg91Ctrl,
                decoration: InputDecoration(
                  labelText: 'MSG91 Auth Key (Optional)',
                  hintText: 'Paste MSG91 authkey',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: razorpayCtrl,
                decoration: InputDecoration(
                  labelText: 'Razorpay Key ID (rzp_live_... or rzp_test_...)',
                  hintText: 'rzp_test_XXXXXXXXXXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final res = await BharatOnePayApi.updateGatewayConfig(
                      fast2smsApiKey: fast2smsCtrl.text.trim().isNotEmpty
                          ? fast2smsCtrl.text.trim()
                          : null,
                      msg91AuthKey: msg91Ctrl.text.trim().isNotEmpty
                          ? msg91Ctrl.text.trim()
                          : null,
                      razorpayKeyId: razorpayCtrl.text.trim().isNotEmpty
                          ? razorpayCtrl.text.trim()
                          : null,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF046A38),
                        content: Text(
                          res['message'] ??
                              'Live Gateway API Keys updated on server!',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save Live API Keys to Backend',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
  void _showSelfTransferModal() {
    _showAddMoneyAndSelfTransferModal(initialAddMoneyMode: false);
  }

  void _showAddMoneyAndSelfTransferModal({bool initialAddMoneyMode = false}) {
    bool isAddMoney = initialAddMoneyMode;
    final amtCtrl = TextEditingController(
      text: initialAddMoneyMode ? '5000' : '',
    );
    BankAccountModel selectedTargetAcc = BharatOnePayApi.primaryAccount ??
        (BharatOnePayApi.linkedAccounts.isNotEmpty
            ? BharatOnePayApi.linkedAccounts.first
            : BankAccountModel(
                id: 'acc_def',
                bankName: _bankName,
                bankCode: 'SBIN',
                ifsc: _ifsc,
                maskedAccountNumber: _maskedAcc,
                balance: _bankBalance,
                isPrimary: true,
                accountType: 'SAVINGS',
              ));
    String fromBank = _bankName;
    String toBank =
        BharatOnePayApi.allIndianBanks.firstWhere(
          (b) => (b['bankName'] ?? b['name']) != _bankName,
          orElse: () => BharatOnePayApi.allIndianBanks.last,
        )['bankName'] ??
        'HDFC Bank';
    String fundingSource = 'HDFC NetBanking / Salary Account';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
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
                    Text(
                      isAddMoney
                          ? '📥 Add Money to Bank Account'
                          : '🔄 Transfer to Own Account',
                      style: const TextStyle(
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
                  isAddMoney
                      ? 'Instantly deposit funds into $_bankName ($_maskedAcc) for payments & transfers'
                      : 'Real-time transfer between your own linked bank accounts',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),

                // Mode Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                              color: isAddMoney
                                  ? const Color(0xFF046A38)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 16,
                                  color: isAddMoney
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Add Money',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isAddMoney
                                        ? Colors.white
                                        : const Color(0xFF475569),
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
                              color: !isAddMoney
                                  ? const Color(0xFF0F172A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 16,
                                  color: !isAddMoney
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Self Transfer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !isAddMoney
                                        ? Colors.white
                                        : const Color(0xFF475569),
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
                  const Text(
                    'Deposit Into Bank Account:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: BharatOnePayApi.linkedAccounts.map((acc) {
                        final isSel = acc.id == selectedTargetAcc.id;
                        final isCurrent = acc.accountType == 'CURRENT';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(
                              isCurrent ? Icons.business_center : Icons.account_balance,
                              size: 14,
                              color: isSel ? Colors.white : (isCurrent ? const Color(0xFF1D4ED8) : const Color(0xFF046A38)),
                            ),
                            label: Text(
                              '${acc.bankName} (${acc.accountType} • ${acc.maskedAccountNumber.replaceAll(RegExp(r'[^0-9]'), '')})',
                            ),
                            selected: isSel,
                            selectedColor: isCurrent ? const Color(0xFF1E3A8A) : const Color(0xFF046A38),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) setSheetState(() => selectedTargetAcc = acc);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedTargetAcc.accountType == 'CURRENT' ? const Color(0xFF1E3A8A) : const Color(0xFF046A38),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            selectedTargetAcc.accountType == 'CURRENT' ? Icons.business_center : Icons.account_balance,
                            color: Colors.white,
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
                                      'Crediting to ${selectedTargetAcc.bankName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF065F46),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: selectedTargetAcc.accountType == 'CURRENT' ? const Color(0xFFDBEAFE) : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      selectedTargetAcc.accountType,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: selectedTargetAcc.accountType == 'CURRENT' ? const Color(0xFF1D4ED8) : const Color(0xFF046A38),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Acc: ${selectedTargetAcc.maskedAccountNumber} • IFSC: ${selectedTargetAcc.ifsc}',
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
                            'Bal: ₹${selectedTargetAcc.balance.toStringAsFixed(0)}',
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
                  const SizedBox(height: 12),

                  const Text(
                    'Select Source / Funding Method:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: fundingSource,
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
                        value: 'Axis Bank NetBanking',
                        child: Text(
                          '🏦 Axis Bank NetBanking',
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
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 8),

                  // Quick preset chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [500, 1000, 2000, 5000, 10000, 25000]
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
                                onPressed: () => setSheetState(
                                  () => amtCtrl.text = preset.toString(),
                                ),
                              ),
                            ),
                          )
                          .toList(),
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
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                'Please enter a valid amount greater than 0',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        final res = await BharatOnePayApi.addMoneyToAccount(
                          amount: amt,
                          accountId: selectedTargetAcc.id,
                          sourceNote: 'Self Deposit from $fundingSource',
                        );
                        await _syncLiveState();
                        if (!mounted) return;
                        setState(() {});
                        if (res['success'] == true) {
                          final currentTargetBal = BharatOnePayApi.linkedAccounts.firstWhere(
                            (a) => a.id == selectedTargetAcc.id,
                            orElse: () => selectedTargetAcc,
                          ).balance;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF046A38),
                              duration: const Duration(seconds: 4),
                              content: Text(
                                '✅ ₹${amt.toStringAsFixed(2)} added to ${selectedTargetAcc.bankName} (${selectedTargetAcc.accountType} • ${selectedTargetAcc.maskedAccountNumber}) successfully! Balance: ₹${currentTargetBal.toStringAsFixed(2)}',
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
                        'Deposit ₹${amtCtrl.text.isEmpty ? "0" : amtCtrl.text} to ${selectedTargetAcc.bankName}',
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
                ] else ...[
                  // Transfer To Account:
                  const Text(
                    'Transfer From Account:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance,
                          color: Color(0xFF046A38),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$fromBank ($_maskedAcc)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Text(
                          'Primary',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF046A38),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Transfer To Account:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: toBank,
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
                    items: BharatOnePayApi.allIndianBanks
                        .where((b) => (b['bankName'] ?? b['name']) != fromBank)
                        .map((b) {
                          final bName = (b['bankName'] ?? b['name'] ?? 'Bank')
                              .toString();
                          final bIcon = (b['icon'] ?? '🏦').toString();
                          return DropdownMenuItem<String>(
                            value: bName,
                            child: Text(
                              '$bIcon $bName',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                          subtitle:
                              'Transfer ₹${amt.toStringAsFixed(2)} from $fromBank to $toBank',
                        );
                        if (pin == null || pin.isEmpty) return;
                        final res = await BharatOnePayApi.payUpi(
                          receiverVpa:
                              '${toBank.toLowerCase().replaceAll(' ', '')}@upi',
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
                              content: Text(
                                '✅ ₹${amt.toStringAsFixed(2)} transferred to $toBank successfully!',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                res['message'] ?? 'Transfer declined',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.swap_horiz, size: 20),
                      label: const Text(
                        'Transfer to Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                      ),
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
    BankAccountModel targetAccount = BharatOnePayApi.primaryAccount ??
        (BharatOnePayApi.linkedAccounts.isNotEmpty
            ? BharatOnePayApi.linkedAccounts.first
            : BankAccountModel(
                id: 'acc_def',
                bankName: _bankName,
                bankCode: 'SBIN',
                ifsc: _ifsc,
                maskedAccountNumber: _maskedAcc,
                balance: _bankBalance,
                isPrimary: true,
                accountType: 'SAVINGS',
              ));

    if (BharatOnePayApi.linkedAccounts.length > 1) {
      final selected = await showModalBottomSheet<BankAccountModel>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: BoxDecoration(
            color: ThemeManager.isDarkMode ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Check Account Balance', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Select bank account to check available balance via UPI', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 14),
              ...BharatOnePayApi.linkedAccounts.map((acc) {
                final isCurrent = acc.accountType == 'CURRENT';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? const Color(0xFF1E3A8A) : const Color(0xFF046A38),
                      child: Icon(isCurrent ? Icons.business_center : Icons.account_balance, color: Colors.white, size: 20),
                    ),
                    title: Row(
                      children: [
                        Flexible(child: Text(acc.bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFFDBEAFE) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            acc.accountType,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? const Color(0xFF1D4ED8) : const Color(0xFF046A38),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('${acc.maskedAccountNumber} • IFSC: ${acc.ifsc}'),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () => Navigator.pop(ctx, acc),
                  ),
                );
              }),
            ],
          ),
        ),
      );
      if (selected == null) return;
      targetAccount = selected;
    }

    final pin = await _promptForMpin(
      title: 'Check Bank Balance',
      subtitle: 'Enter 4-digit UPI MPIN for ${targetAccount.bankName} (${targetAccount.maskedAccountNumber})',
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

    await _syncLiveState();
    if (!mounted) return;

    // Refresh balance from linked accounts in case it changed
    final refreshedAcc = BharatOnePayApi.linkedAccounts.firstWhere(
      (a) => a.id == targetAccount.id,
      orElse: () => targetAccount,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
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
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${refreshedAcc.bankName} (${refreshedAcc.maskedAccountNumber})',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: refreshedAcc.accountType == 'CURRENT' ? const Color(0xFFDBEAFE) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    refreshedAcc.accountType,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: refreshedAcc.accountType == 'CURRENT' ? const Color(0xFF1D4ED8) : const Color(0xFF046A38),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${refreshedAcc.balance.toStringAsFixed(2)}',
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

  void _handleBuyStock(Map<String, dynamic> stock) {
    int qty = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                    Text(
                      'Buy ${stock['symbol']}',
                      style: const TextStyle(
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
                Text(
                  stock['name'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NSE Market Price:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '₹${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF046A38),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quantity (Shares):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: qty > 1
                              ? () => setModalState(() => qty--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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
                    const Text(
                      'Total Debit from Bank:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Color(0xFF0F172A),
                      ),
                    ),
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
                        subtitle:
                            'Authorize ₹${total.toStringAsFixed(2)} for $qty shares of ${stock['symbol']}',
                      );
                      if (pin == null || pin.isEmpty) return;
                      final res = await BharatOnePayApi.executeDemoStockBuy(
                        stock: stock,
                        qty: qty,
                        mpin: pin,
                      );
                      await _syncLiveState();
                      if (!mounted) return;
                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF046A38),
                            duration: const Duration(seconds: 3),
                            content: Text(
                              '🎉 Demo Order Executed! Bought $qty shares of ${stock['symbol']} @ ₹${price.toStringAsFixed(2)}. Added to your Portfolio!',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Confirm Buy (₹${total.toStringAsFixed(2)})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                  Text(
                    'Start Stock SIP: ${stock['symbol']}',
                    style: const TextStyle(
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
              const Text(
                'Automated regular equity investment via NPCI UPI Autopay mandate',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monthly Investment Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '₹${sipAmt.toStringAsFixed(0)} / mo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF046A38),
                    ),
                  ),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF046A38),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Autopay debit from $_bankName on 5th of every month',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF334155),
                        ),
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
                      subtitle:
                          'Mandate ₹${sipAmt.toStringAsFixed(0)}/mo for ${stock['symbol']}',
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
                        content: Text(
                          '✅ Stock SIP of ₹${sipAmt.toStringAsFixed(0)}/mo started for ${stock['symbol']}!',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Authorize UPI Autopay Mandate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGullakModal() {
    final customAmtCtrl = TextEditingController(text: '500');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              const Text(
                '🏺 Digital Gullak Micro-Savings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Saved Balance: ₹${_gullakBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: customAmtCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final amt =
                            double.tryParse(customAmtCtrl.text.trim()) ?? 500;
                        await BharatOnePayApi.depositVault(amt);
                        setSheetState(() {});
                        if (mounted) setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046A38),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('+ Save to Gullak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final amt =
                            double.tryParse(customAmtCtrl.text.trim()) ?? 500;
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
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final escrows = BharatOnePayApi.activeEscrows;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🛡️ Safe Pay Escrow Protection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const Text(
                  'Funds are held in NPCI Escrow and released only when you confirm delivery.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                if (escrows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No active escrow holds. Toggle "Hold in Safe Pay Escrow" inside Send Money to create one.',
                    ),
                  )
                else
                  ...escrows.map(
                    (e) => Container(
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
                          Text(
                            '${e.sellerName} • ₹${e.amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${e.itemDescription} • Status: ${e.status}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF046A38),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text(
                                    'Confirm Delivery & Release',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () async {
                                    await BharatOnePayApi.disputeEscrow(
                                      e.id,
                                      'Item not delivered',
                                    );
                                    setSheetState(() {});
                                    if (mounted) setState(() {});
                                  },
                                  child: const Text(
                                    'Dispute',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.wifi_tethering_rounded,
                color: Color(0xFF34D399),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Server Wi-Fi & IP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '192.168.29.218',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.laptop_chromebook_rounded,
                    color: Color(0xFF38BDF8),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Quick Select Presets:',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                        '192.168.29.218',
                        '192.168.29.90',
                        '192.168.137.1',
                        '10.0.2.2',
                        'https://aiksetra-npci-soumo.loca.lt',
                      ].map((preset) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(
                              preset.length > 20 ? 'Tunnel' : preset,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF046A38),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                ApiConfig.setCustomHost(ipCtrl.text);
                Navigator.pop(ctx);
                await _syncLiveState();
                if (!mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF046A38),
                    content: Text(
                      '✅ Connected to backend at ${ApiConfig.activeHost}:4000',
                    ),
                  ),
                );
              },
              child: const Text(
                'Connect & Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionReceiptModal(Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF046A38),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Official NPCI Transaction Receipt',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildBillRow(
              'Counterparty',
              (t['receiverName'] ?? t['receiverVpa'] ?? '').toString(),
            ),
            _buildBillRow(
              'UPI / Account Ref',
              (t['receiverVpa'] ?? '').toString(),
            ),
            _buildBillRow(
              'Amount',
              '₹${((t['amount'] as num?) ?? 0).toStringAsFixed(2)}',
            ),
            _buildBillRow(
              'NPCI RRN / UTR',
              (t['upiRrn'] ?? t['txnRef'] ?? '').toString(),
            ),
            _buildBillRow('Status', (t['status'] ?? 'SUCCESS').toString()),
            _buildBillRow('Remark', (t['remark'] ?? '').toString()),
            _buildBillRow(
              'Timestamp',
              (t['createdAt'] ?? '')
                  .toString()
                  .split('.')
                  .first
                  .replaceAll('T', ' '),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF671F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(
                  'Pay Again to ${(t['receiverName'] ?? t['receiverVpa'] ?? 'Payee')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showSendMoneyDialog(
                    prefillVpa: (t['receiverVpa'] ?? t['receiverName'])?.toString(),
                    prefillName: (t['receiverName'] ?? t['receiverVpa'])?.toString(),
                    prefillAmount: ((t['amount'] as num?) ?? 0).toStringAsFixed(0),
                    prefillNote: 'Repeat payment to ${t['receiverName'] ?? t['receiverVpa']}',
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF0F172A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Close Receipt', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showScamWarningConfirmation(
    ScamShieldResult risk,
    String vpa,
    double amt,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '⚠️ AI Scam Shield Alert',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'High Risk Score (${risk.riskScore}/100) detected for $vpa (₹$amt):',
            ),
            const SizedBox(height: 8),
            ...risk.warnings.map(
              (w) => Text('• $w', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel Payment'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed Anyway'),
          ),
        ],
      ),
    );
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

  // ===========================================================================
  // REAL DEVICE CONTACTS PICKER & DEMO PAYMENT INTEGRATION
  // ===========================================================================
  Future<void> _pickRealDeviceContact() async {
    try {
      const channel = MethodChannel('in.bharatonepay/contacts');
      final res = await channel.invokeMethod<Map>('pickContact');
      if (res != null) {
        final name = (res['name'] ?? '').toString().trim();
        final phone = (res['phone'] ?? '').toString().trim();
        if (phone.isNotEmpty) {
          final vpa = phone.length == 10 ? '$phone@aiksetra' : '$phone@upi';
          _showSendMoneyDialog(
            prefillVpa: vpa,
            prefillName: name.isNotEmpty ? name : 'Contact ($phone)',
            prefillNote: 'Demo Payment to $name',
          );
          return;
        }
      }
    } catch (_) {
      // Fallback if native platform channel is unavailable
    }
    _showDeviceContactFallbackModal();
  }

  void _showDeviceContactFallbackModal() {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.contacts_rounded, color: Color(0xFFFF671F), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Pay Real Contact (Demo)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select any phone number to test demo payments. No real funds are debited.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Contact Name',
                hintText: 'e.g. Soumo Naskar',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '10-Digit Mobile Number',
                hintText: 'e.g. 9830113038',
                prefixIcon: const Icon(Icons.phone_android_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF671F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final phone = phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                  final name = nameCtrl.text.trim();
                  if (phone.isEmpty) return;
                  Navigator.pop(ctx);
                  final vpa = phone.length == 10 ? '$phone@aiksetra' : '$phone@upi';
                  _showSendMoneyDialog(
                    prefillVpa: vpa,
                    prefillName: name.isNotEmpty ? name : 'Contact ($phone)',
                    prefillNote: 'Demo Payment to $name',
                  );
                },
                child: const Text('Continue to Demo Pay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // INTERACTIVE STOCK MARKET GRAPHS & CANDLESTICK BARS MODAL
  // ===========================================================================
  Widget _buildStockMiniBars(Map<String, dynamic> stock) {
    final isUp = (stock['change'] as num) >= 0;
    final color = isUp ? const Color(0xFF046A38) : const Color(0xFFDC2626);

    final miniBars = stock['miniBars'] as List?;
    List<double> heights;
    if (miniBars != null && miniBars.length >= 2) {
      final values = miniBars.map((v) => (v as num).toDouble()).toList();
      double min = values.reduce((a, b) => a < b ? a : b);
      double max = values.reduce((a, b) => a > b ? a : b);
      final range = (max - min).abs();
      heights = values.map((val) {
        if (range <= 0.001) return 14.0;
        final norm = (val - min) / range;
        return (6.0 + norm * 18.0).clamp(4.0, 24.0);
      }).toList();
    } else {
      final symbol = (stock['symbol'] as String);
      heights = List.generate(8, (i) {
        return 6.0 + ((symbol.codeUnitAt(i % symbol.length) * (i + 1) * 7) % 18).toDouble();
      });
    }

    return Container(
      width: 44,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: heights.map((h) {
          return Container(
            width: 3.5,
            height: h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showStockChartModal(Map<String, dynamic> stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RealStockChartModalSheet(
        stock: stock,
        onBuyStock: _handleBuyStock,
        onStockSip: _handleStockSip,
      ),
    );
  }

  // ================= FIXED DEPOSIT (FD) BOOKING FLOW =================
  void _showFdInvestmentModal() {
    String selectedBank = 'State Bank of India';
    double interestRate = 7.8;
    int selectedAmount = 50000;
    int selectedTenure = 12; // months
    String payoutOption = 'Cumulative at Maturity';

    final Map<String, double> bankRates = {
      'State Bank of India': 7.8,
      'HDFC Bank': 7.75,
      'ICICI Bank': 7.7,
      'AikSetra Smart Neo': 8.2,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          final maturityVal = selectedAmount + (selectedAmount * interestRate * selectedTenure / (12 * 100));
          final earnedInterest = maturityVal - selectedAmount;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_clock, color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 8),
                        Text('Open Fixed Deposit (FD)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                  child: const Text('🔒 DICGC Insured up to ₹5,00,000 per depositor • Zero penalty premature withdrawal', style: TextStyle(fontSize: 10, color: Color(0xFF1E40AF))),
                ),
                const SizedBox(height: 14),

                const Text('Select Partner Bank', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: bankRates.keys.map((bName) {
                      final isSel = selectedBank == bName;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$bName (${bankRates[bName]}%)'),
                          selected: isSel,
                          onSelected: (_) => setMState(() {
                            selectedBank = bName;
                            interestRate = bankRates[bName]!;
                          }),
                          selectedColor: const Color(0xFF2563EB),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Deposit Amount (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [10000, 25000, 50000, 100000, 200000].map((amt) {
                    final isSel = selectedAmount == amt;
                    return ChoiceChip(
                      label: Text('₹${amt ~/ 1000}K'),
                      selected: isSel,
                      onSelected: (_) => setMState(() => selectedAmount = amt),
                      selectedColor: const Color(0xFF0D1B2A),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                const Text('Tenure (Months)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [12, 24, 36, 60].map((m) {
                    final isSel = selectedTenure == m;
                    return ChoiceChip(
                      label: Text('${m ~/ 12} Yr (${m}M)'),
                      selected: isSel,
                      onSelected: (_) => setMState(() => selectedTenure = m),
                      selectedColor: const Color(0xFF046A38),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Calculation Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Maturity Value', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text('₹${maturityVal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
                          Text('+₹${earnedInterest.toStringAsFixed(0)} Guaranteed Interest', style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF046A38),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          final res = BharatOnePayApi.bookFixedDeposit(
                            amount: selectedAmount.toDouble(),
                            tenureMonths: selectedTenure,
                            interestRate: interestRate,
                            bankName: selectedBank,
                            payoutOption: payoutOption,
                          );
                          if (res['success'] == true) {
                            setState(() {});
                            _showFdSuccessDialog(res['fd']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'] ?? 'FD Booking Failed')),
                            );
                          }
                        },
                        child: const Text('Lock & Book FD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFdSuccessDialog(Map<String, dynamic> fd) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('FD Booked Successfully!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${fd['bankName']} Digital FD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Principal Deposited: ₹${(fd['principal'] as num).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
            Text('Interest Rate: ${fd['interestRate']}% p.a.', style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
            Text('Maturity Amount: ₹${(fd['maturityAmount'] as num).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
            Text('Maturity Date: ${fd['maturityDate']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
              child: Text('FD Receipt #: ${fd['fdNumber']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Digital FD Certificate downloaded to device storage!')),
              );
            },
            child: const Text('Download Certificate'),
          ),
        ],
      ),
    );
  }

  // ================= RECURRING DEPOSIT (RD) FLOW =================
  void _showRdInvestmentModal() {
    int monthlyAmount = 5000;
    int selectedTenure = 24;
    double interestRate = 7.4;
    String selectedBank = 'HDFC Bank';
    int debitDay = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          final totalInvested = monthlyAmount * selectedTenure;
          final estMaturity = totalInvested + (totalInvested * interestRate * 0.55 * (selectedTenure / 12) / 100);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Color(0xFF0284C7), size: 22),
                        SizedBox(width: 8),
                        Text('Start Monthly RD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Text('Build guaranteed wealth with disciplined monthly auto-debits at 7.4% p.a.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 14),

                const Text('Monthly Installment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1000, 2500, 5000, 10000].map((amt) {
                    final isSel = monthlyAmount == amt;
                    return ChoiceChip(
                      label: Text('₹$amt/mo'),
                      selected: isSel,
                      onSelected: (_) => setMState(() => monthlyAmount = amt),
                      selectedColor: const Color(0xFF0284C7),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                const Text('Tenure (Months)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [12, 24, 36].map((m) {
                    final isSel = selectedTenure == m;
                    return ChoiceChip(
                      label: Text('$m Mo'),
                      selected: isSel,
                      onSelected: (_) => setMState(() => selectedTenure = m),
                      selectedColor: const Color(0xFF0D1B2A),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Maturity Value', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text('₹${estMaturity.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
                          Text('Total Deposit: ₹$totalInvested', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF046A38),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          final res = BharatOnePayApi.startRecurringDeposit(
                            monthlyAmount: monthlyAmount.toDouble(),
                            tenureMonths: selectedTenure,
                            interestRate: interestRate,
                            bankName: selectedBank,
                            debitDay: debitDay,
                          );
                          if (res['success'] == true) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF046A38),
                                content: Text('Recurring Deposit started! 1st installment of ₹$monthlyAmount debited.'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'] ?? 'RD setup failed')),
                            );
                          }
                        },
                        child: const Text('Start RD Auto-Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= MUTUAL FUNDS & SIP INVESTMENT FLOW =================
  void _showMfInvestmentModal() {
    final funds = [
      {
        'name': 'Parag Parikh Flexi Cap Fund',
        'category': 'Flexi Cap Equity',
        'cagr': '21.4% (3Y CAGR)',
        'risk': 'Very High',
        'rating': '5★ Value Research',
      },
      {
        'name': 'SBI Bluechip Direct Fund',
        'category': 'Large Cap Equity',
        'cagr': '16.8% (3Y CAGR)',
        'risk': 'Moderate',
        'rating': '4★ Morningstar',
      },
      {
        'name': 'Nippon India Small Cap Fund',
        'category': 'Small Cap Equity',
        'cagr': '28.2% (3Y CAGR)',
        'risk': 'High',
        'rating': '5★ Crisil',
      },
      {
        'name': 'UTI Nifty 50 Index Fund',
        'category': 'Index Fund',
        'cagr': '15.2% (3Y CAGR)',
        'risk': 'Moderate',
        'rating': '0.18% Low Expense',
      },
    ];

    int selectedFundIdx = 0;
    bool isSip = true;
    int amount = 2500;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          final selFund = funds[selectedFundIdx];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pie_chart, color: Color(0xFF7C3AED), size: 22),
                        SizedBox(width: 8),
                        Text('Invest in Direct Mutual Funds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Text('0% Commission Direct Mutual Funds • Instant Folio Allocation', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 14),

                // SIP vs Lumpsum Toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setMState(() => isSip = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSip ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text('Monthly Auto-SIP', style: TextStyle(color: isSip ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setMState(() => isSip = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !isSip ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text('One-Time Lumpsum', style: TextStyle(color: !isSip ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text('Select Mutual Fund Scheme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 8),
                ...funds.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final f = entry.value;
                  final isSel = selectedFundIdx == idx;

                  return GestureDetector(
                    onTap: () => setMState(() => selectedFundIdx = idx),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF7C3AED).withValues(alpha: 0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(isSel ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: isSel ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D1B2A))),
                                Text('${f['category']} • ${f['rating']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Text(f['cagr']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF059669))),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),

                Text(isSip ? 'Monthly SIP Amount' : 'Investment Amount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [500, 1000, 2500, 5000].map((amt) {
                    final isSel = amount == amt;
                    return ChoiceChip(
                      label: Text('₹$amt'),
                      selected: isSel,
                      onSelected: (_) => setMState(() => amount = amt),
                      selectedColor: const Color(0xFF7C3AED),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      final res = BharatOnePayApi.investMutualFund(
                        fundName: selFund['name']!,
                        category: selFund['category']!,
                        amount: amount.toDouble(),
                        isSip: isSip,
                      );
                      if (res['success'] == true) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF046A38),
                            content: Text(
                              isSip
                                  ? 'Auto-SIP of ₹$amount/mo started in ${selFund['name']} (Folio: ${res['mutualFund']?['folioNumber']})'
                                  : 'Invested ₹$amount in ${selFund['name']} successfully!',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Investment failed')),
                        );
                      }
                    },
                    child: Text(
                      isSip ? 'Start Monthly Auto-SIP of ₹$amount' : 'Invest ₹$amount Lumpsum',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= INSURANCE POLICY CHECKOUT & ISSUANCE =================
  void _showPolicyPurchaseModal(String title, String price, IconData icon, Color color) {
    String nomineeName = 'Ruma Naskar';
    String nomineeRelation = 'Mother';
    double coverAmount = title.contains('Term') ? 10000000.0 : (title.contains('Health') ? 500000.0 : 200000.0);
    double premium = title.contains('Bike') ? 652.0 : (title.contains('Term') ? 4900.0 : 4560.0);
    String insurer = title.contains('Health') ? 'Star Health & Allied Insurance' : (title.contains('Term') ? 'LIC of India' : 'HDFC ERGO General');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 8),
                    Text('Buy $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 6),
            Text('Partner Insurer: $insurer', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
            Text('Sum Insured: ₹${(coverAmount ~/ 100000)} Lakhs Cashless Protection', style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
            Text('Registered Nominee: $nomineeName ($nomineeRelation)', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Annual Premium Payable', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text('₹${premium.toStringAsFixed(0)} / year', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                    ],
                  ),
                  const Text('Includes 18% GST', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  final res = BharatOnePayApi.purchaseInsurancePolicy(
                    planType: title,
                    insurer: insurer,
                    coverAmount: coverAmount,
                    premium: premium,
                    nominee: '$nomineeName ($nomineeRelation)',
                    registrationOrMember: 'IND-9830113038',
                  );
                  if (res['success'] == true) {
                    setState(() {});
                    _showPolicySuccessDialog(res['policy']);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'] ?? 'Policy purchase failed')),
                    );
                  }
                },
                child: Text('Pay ₹${premium.toStringAsFixed(0)} & Issue Policy', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPolicySuccessDialog(Map<String, dynamic> pol) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Policy Issued Instantly!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pol['planType'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Insurer: ${pol['insurer']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 6),
            Text('Policy Number: ${pol['policyNumber']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            Text('Cover Amount: ₹${(pol['coverAmount'] as num).toStringAsFixed(0)} Cashless', style: const TextStyle(fontSize: 12, color: Color(0xFF046A38), fontWeight: FontWeight.bold)),
            Text('Valid Till: ${pol['expiryDate']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            Text('Nominee: ${pol['nominee']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Digital Insurance Policy Certificate & Cashless Health Card downloaded!')),
              );
            },
            child: const Text('Download Policy Card'),
          ),
        ],
      ),
    );
  }


}

// =============================================================================
// REAL LIVE STOCK MARKET CANDLESTICK & CHART MODAL SHEET (NSE / BSE LIVE)
// =============================================================================
class _RealStockChartModalSheet extends StatefulWidget {
  final Map<String, dynamic> stock;
  final Function(Map<String, dynamic>) onBuyStock;
  final Function(Map<String, dynamic>) onStockSip;

  const _RealStockChartModalSheet({
    required this.stock,
    required this.onBuyStock,
    required this.onStockSip,
  });

  @override
  State<_RealStockChartModalSheet> createState() => _RealStockChartModalSheetState();
}

class _RealStockChartModalSheetState extends State<_RealStockChartModalSheet> {
  bool get _isDark => ThemeManager.isDarkMode;
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF0F172A);
  String _selectedTf = '1D';
  bool _isCandleMode = true;
  int? _activeCandleIdx;
  bool _isLoading = true;
  List<Map<String, dynamic>> _candles = [];

  @override
  void initState() {
    super.initState();
    _fetchCandles();
  }

  Future<void> _fetchCandles() async {
    setState(() => _isLoading = true);
    final symbol = widget.stock['symbol'] as String;
    final res = await BharatOnePayApi.fetchRealStockCandles(
      symbol: symbol,
      timeframe: _selectedTf,
    );
    if (mounted) {
      setState(() {
        _candles = res;
        _isLoading = false;
        _activeCandleIdx = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final symbol = stock['symbol'] as String;
    final name = stock['name'] as String;
    final sector = stock['sector'] ?? 'NSE / BSE Equity';
    final livePrice = (stock['price'] as num).toDouble();
    final isUp = (stock['change'] as num) >= 0;
    final changeVal = (stock['change'] as num).toDouble();
    final changePct = ((stock['changePct'] as num?) ?? 0.0).toDouble();

    final activeCandle = _activeCandleIdx != null && _activeCandleIdx! < _candles.length
        ? _candles[_activeCandleIdx!]
        : (_candles.isNotEmpty ? _candles.last : {
            'time': 'Live',
            'open': livePrice,
            'high': (stock['dayHigh'] as num?)?.toDouble() ?? livePrice,
            'low': (stock['dayLow'] as num?)?.toDouble() ?? livePrice,
            'close': livePrice,
            'volume': stock['volume'] ?? 50000,
          });

    final dayHigh = (stock['high52'] as num?)?.toDouble() ?? (livePrice * 1.05);
    final dayLow = (stock['low52'] as num?)?.toDouble() ?? (livePrice * 0.95);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                symbol,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fiber_manual_record, size: 7, color: Color(0xFF046A38)),
                                    SizedBox(width: 3),
                                    Text(
                                      'REAL NSE LIVE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF046A38),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          Text(sector, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${(activeCandle['close'] as num).toDouble().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${isUp ? '+' : ''}₹${changeVal.toStringAsFixed(2)} (${isUp ? '+' : ''}${changePct.toStringAsFixed(2)}%)',
                                style: TextStyle(
                                  color: isUp ? const Color(0xFF046A38) : const Color(0xFFDC2626),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Time: ${activeCandle['time']}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF0F172A)),
                            tooltip: 'Refresh Live Quotes',
                            onPressed: _fetchCandles,
                          ),
                          InkWell(
                            onTap: () => setState(() => _isCandleMode = !_isCandleMode),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isCandleMode ? Icons.candlestick_chart_rounded : Icons.show_chart_rounded,
                                    size: 16,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isCandleMode ? 'Candles' : 'Line',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['1D', '1W', '1M', '1Y', '5Y', 'ALL'].map((tf) {
                        final isSel = _selectedTf == tf;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              if (_selectedTf != tf) {
                                setState(() => _selectedTf = tf);
                                _fetchCandles();
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                tf,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                  color: isSel ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _isLoading
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: Color(0xFFFF671F),
                                    strokeWidth: 2.5,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Loading real NSE market candles...',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                final box = context.findRenderObject() as RenderBox?;
                                final width = box?.size.width ?? 320.0;
                                final pos = details.localPosition.dx.clamp(0.0, width);
                                final count = _candles.length;
                                if (count > 0) {
                                  final idx = ((pos / width) * count).floor().clamp(0, count - 1);
                                  setState(() => _activeCandleIdx = idx);
                                }
                              },
                              onHorizontalDragEnd: (_) {
                                setState(() => _activeCandleIdx = null);
                              },
                              onTapDown: (details) {
                                final box = context.findRenderObject() as RenderBox?;
                                final width = box?.size.width ?? 320.0;
                                final pos = details.localPosition.dx.clamp(0.0, width);
                                final count = _candles.length;
                                if (count > 0) {
                                  final idx = ((pos / width) * count).floor().clamp(0, count - 1);
                                  setState(() => _activeCandleIdx = idx);
                                }
                              },
                              child: CustomPaint(
                                painter: _StockCandleChartPainter(
                                  candles: _candles,
                                  isCandleMode: _isCandleMode,
                                  activeIdx: _activeCandleIdx,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildOhlcTag('Open', (activeCandle['open'] as num).toDouble().toStringAsFixed(1)),
                        _buildOhlcTag('High', (activeCandle['high'] as num).toDouble().toStringAsFixed(1)),
                        _buildOhlcTag('Low', (activeCandle['low'] as num).toDouble().toStringAsFixed(1)),
                        _buildOhlcTag('Close', (activeCandle['close'] as num).toDouble().toStringAsFixed(1)),
                        _buildOhlcTag('Vol', '${((activeCandle['volume'] as num).toInt() / 1000).toStringAsFixed(0)}K'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('52-Week Range', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${dayLow.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: LinearProgressIndicator(
                            value: ((livePrice - dayLow) / (dayHigh - dayLow)).clamp(0.05, 0.95),
                            backgroundColor: const Color(0xFFE2E8F0),
                            color: const Color(0xFF046A38),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Text('₹${dayHigh.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Fundamentals & Real NSE Market Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildMetricRow('Exchange', 'National Stock Exchange (NSE) & BSE'),
                        const Divider(height: 14),
                        _buildMetricRow('Market Capitalization', stock['marketCap'] ?? '₹10.5 Lakh Cr'),
                        const Divider(height: 14),
                        _buildMetricRow('Price to Earnings (P/E)', '${stock['pe'] ?? 24.5}x'),
                        const Divider(height: 14),
                        _buildMetricRow('Day High / Low', '₹${(stock['dayHigh'] ?? livePrice * 1.01).toStringAsFixed(1)} / ₹${(stock['dayLow'] ?? livePrice * 0.99).toStringAsFixed(1)}'),
                        const Divider(height: 14),
                        _buildMetricRow('Settlement Cycle', 'T+1 Instant Rolling Settlement'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onStockSip(stock);
                    },
                    child: Text('Start Stock SIP', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onBuyStock(stock);
                    },
                    child: const Text('Buy Share', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOhlcTag(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textPrimary)),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textPrimary)),
      ],
    );
  }
}


// =============================================================================
// REAL HARDWARE CAMERA QR SCANNER SCREEN (MobileScanner)
// =============================================================================
class _RealCameraQrScannerScreen extends StatefulWidget {
  const _RealCameraQrScannerScreen();

  @override
  State<_RealCameraQrScannerScreen> createState() =>
      _RealCameraQrScannerScreenState();
}

class _RealCameraQrScannerScreenState
    extends State<_RealCameraQrScannerScreen> {
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
        title: const Text(
          'Scan Any UPI / BharatQR Code',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
              final msg =
                  error.errorDetails?.message ?? error.errorCode.message;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_rounded,
                        color: Color(0xFF10B981),
                        size: 52,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Camera Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
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
                            icon: const Icon(
                              Icons.cameraswitch_rounded,
                              size: 16,
                            ),
                            label: const Text('Switch Lens'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF64748B)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Or enter UPI ID / mobile / upi://pay link...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: () {
        if (!_hasPopped) {
          _hasPopped = true;
          Navigator.of(context).pop(uri);
        }
      },
    );
  }

  }


// ===========================================================================
// THREE.JS-INSPIRED 3D MESH PARTICLE PAINTER FOR LIVE FINTECH ADS
// ===========================================================================
class _ThreeJsMeshParticlesPainter extends CustomPainter {
  final Color primaryColor;

  _ThreeJsMeshParticlesPainter({
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final points = [
      Offset(size.width * 0.12, size.height * 0.22),
      Offset(size.width * 0.28, size.height * 0.68),
      Offset(size.width * 0.44, size.height * 0.16),
      Offset(size.width * 0.58, size.height * 0.82),
      Offset(size.width * 0.74, size.height * 0.32),
      Offset(size.width * 0.86, size.height * 0.62),
      Offset(size.width * 0.92, size.height * 0.18),
      Offset(size.width * 0.08, size.height * 0.82),
    ];

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final dist = (points[i] - points[j]).distance;
        if (dist < size.width * 0.40) {
          canvas.drawLine(points[i], points[j], linePaint);
        }
      }
    }

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final radius = 2.0 + (i % 3) * 1.0;
      canvas.drawCircle(p, radius, particlePaint);

      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, radius * 2.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThreeJsMeshParticlesPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor;
}


// ===========================================================================
// FINANCIAL CANDLESTICK & VOLUME CHART PAINTER (OHLC + VOLUME)
// ===========================================================================
class _StockCandleChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> candles;
  final bool isCandleMode;
  final int? activeIdx;

  _StockCandleChartPainter({
    required this.candles,
    required this.isCandleMode,
    this.activeIdx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final n = candles.length;
    final candleWidth = size.width / n;

    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    int maxVol = 1;

    for (final c in candles) {
      final h = (c['high'] as num).toDouble();
      final l = (c['low'] as num).toDouble();
      final v = (c['volume'] as num).toInt();
      if (h > maxPrice) maxPrice = h;
      if (l < minPrice) minPrice = l;
      if (v > maxVol) maxVol = v;
    }

    final pricePad = (maxPrice - minPrice) * 0.1;
    minPrice -= pricePad;
    maxPrice += pricePad;
    final priceRange = (maxPrice - minPrice).clamp(1.0, double.infinity);

    final priceHeight = size.height * 0.72;
    final volHeight = size.height * 0.22;
    final volBaseY = size.height;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int g = 1; g <= 3; g++) {
      final y = priceHeight * (g / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const greenColor = Color(0xFF10B981);
    const redColor = Color(0xFFEF4444);

    if (isCandleMode) {
      for (int i = 0; i < n; i++) {
        final c = candles[i];
        final open = (c['open'] as num).toDouble();
        final close = (c['close'] as num).toDouble();
        final high = (c['high'] as num).toDouble();
        final low = (c['low'] as num).toDouble();
        final isBullish = close >= open;
        final barColor = isBullish ? greenColor : redColor;

        final centerX = i * candleWidth + (candleWidth / 2);
        final highY = priceHeight - ((high - minPrice) / priceRange * priceHeight);
        final lowY = priceHeight - ((low - minPrice) / priceRange * priceHeight);
        final openY = priceHeight - ((open - minPrice) / priceRange * priceHeight);
        final closeY = priceHeight - ((close - minPrice) / priceRange * priceHeight);

        final wickPaint = Paint()
          ..color = barColor
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), wickPaint);

        final bodyTop = openY < closeY ? openY : closeY;
        final bodyBottom = openY > closeY ? openY : closeY;
        final bodyHeight = (bodyBottom - bodyTop).clamp(2.0, double.infinity);
        final bodyRect = Rect.fromCenter(
          center: Offset(centerX, bodyTop + bodyHeight / 2),
          width: (candleWidth * 0.65).clamp(3.0, 14.0),
          height: bodyHeight,
        );

        final bodyPaint = Paint()
          ..color = barColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.5)), bodyPaint);

        final v = (c['volume'] as num).toInt();
        final vBarH = (v / maxVol) * volHeight;
        final volRect = Rect.fromLTWH(
          centerX - (candleWidth * 0.5) / 2,
          volBaseY - vBarH,
          candleWidth * 0.5,
          vBarH,
        );
        final volPaint = Paint()
          ..color = barColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawRect(volRect, volPaint);
      }
    } else {
      final linePath = Path();
      final areaPath = Path();

      for (int i = 0; i < n; i++) {
        final c = candles[i];
        final close = (c['close'] as num).toDouble();
        final x = i * candleWidth + (candleWidth / 2);
        final y = priceHeight - ((close - minPrice) / priceRange * priceHeight);

        if (i == 0) {
          linePath.moveTo(x, y);
          areaPath.moveTo(x, priceHeight);
          areaPath.lineTo(x, y);
        } else {
          linePath.lineTo(x, y);
          areaPath.lineTo(x, y);
        }

        if (i == n - 1) {
          areaPath.lineTo(x, priceHeight);
          areaPath.close();
        }
      }

      final isUpTotal = (candles.last['close'] as double) >= (candles.first['open'] as double);
      final strokeColor = isUpTotal ? greenColor : redColor;

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          colors: [strokeColor.withValues(alpha: 0.35), strokeColor.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, priceHeight))
        ..style = PaintingStyle.fill;
      canvas.drawPath(areaPath, gradientPaint);

      final strokePaint = Paint()
        ..color = strokeColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(linePath, strokePaint);
    }

    if (activeIdx != null && activeIdx! < n) {
      final crossX = activeIdx! * candleWidth + (candleWidth / 2);
      final cursorPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(crossX, 0), Offset(crossX, size.height), cursorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StockCandleChartPainter oldDelegate) => true;
}
