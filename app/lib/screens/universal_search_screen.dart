import 'package:flutter/material.dart';

import 'all_services_screen.dart';
import 'autopay_screen.dart';
import 'cards_screen.dart';
import 'calculators_screen.dart';
import 'travel_screen.dart';
import 'beneficiaries_screen.dart';
import 'rewards_screen.dart';
import 'business_dashboard_screen.dart';
import 'business_registration_screen.dart';
import '../services/bharat_one_pay_api.dart';
import 'tax_payments_screen.dart';
import 'bank_account_opening_screen.dart';
import 'statements_screen.dart';
import 'profile_screen.dart';
import '../widgets/language_location_selector_modal.dart';

enum SearchActionType { navigation, callback }

class SearchItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color iconColor;
  final List<String> keywords;
  final String actionKey;

  const SearchItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    this.iconColor = const Color(0xFFFF671F),
    required this.keywords,
    required this.actionKey,
  });
}

class UniversalSearchScreen extends StatefulWidget {
  final Function(String actionKey)? onActionSelected;
  final VoidCallback? onRefreshParent;

  const UniversalSearchScreen({
    super.key,
    this.onActionSelected,
    this.onRefreshParent,
  });

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final List<SearchItem> _allItems = [
    // 1. PAYMENTS & TRANSFERS
    SearchItem(
      title: 'Scan Any UPI QR',
      subtitle: 'Scan GPay, PhonePe, BharatQR, Paytm or merchant standee',
      category: 'PAYMENTS',
      icon: Icons.qr_code_scanner_rounded,
      iconColor: const Color(0xFF046A38),
      keywords: ['scan', 'qr', 'camera', 'pay', 'merchant', 'soundbox'],
      actionKey: 'scan_qr',
    ),
    SearchItem(
      title: 'Send Money',
      subtitle: 'Transfer funds to any UPI ID, mobile number or bank account',
      category: 'PAYMENTS',
      icon: Icons.send_rounded,
      iconColor: const Color(0xFFFF671F),
      keywords: [
        'send',
        'transfer',
        'money',
        'upi',
        'mobile',
        'phone',
        'contact',
      ],
      actionKey: 'send_money',
    ),
    SearchItem(
      title: 'My UPI QR Standee',
      subtitle: 'Display your personal QR code to receive instant payments',
      category: 'PAYMENTS',
      icon: Icons.qr_code_2_rounded,
      iconColor: const Color(0xFF38BDF8),
      keywords: ['my qr', 'receive', 'qr code', 'standee', 'vpa'],
      actionKey: 'my_qr',
    ),
    SearchItem(
      title: 'Self Account Transfer',
      subtitle: 'Move money instantly between your linked bank accounts',
      category: 'PAYMENTS',
      icon: Icons.swap_horiz_rounded,
      iconColor: const Color(0xFF818CF8),
      keywords: ['self', 'transfer', 'inter-bank', 'own account', 'switch'],
      actionKey: 'self_transfer',
    ),
    SearchItem(
      title: 'Add Money to Bank Account',
      subtitle: 'Deposit money via net banking or external debit cards',
      category: 'PAYMENTS',
      icon: Icons.add_circle_outline_rounded,
      iconColor: const Color(0xFF34D399),
      keywords: ['add money', 'deposit', 'top up', 'fund', 'balance'],
      actionKey: 'add_money',
    ),
    SearchItem(
      title: 'Contacts & Beneficiaries',
      subtitle: 'Manage saved payees, frequent contacts and beneficiaries',
      category: 'PAYMENTS',
      icon: Icons.contacts_rounded,
      iconColor: const Color(0xFFA78BFA),
      keywords: ['contacts', 'beneficiaries', 'payees', 'friends', 'saved'],
      actionKey: 'beneficiaries',
    ),
    SearchItem(
      title: 'RuPay UPI & Debit/Credit Cards',
      subtitle: 'Link RuPay credit cards on UPI, view linked Visa/Mastercards',
      category: 'PAYMENTS',
      icon: Icons.credit_card_rounded,
      iconColor: const Color(0xFFF59E0B),
      keywords: [
        'cards',
        'credit card',
        'debit card',
        'rupay',
        'visa',
        'mastercard',
      ],
      actionKey: 'cards',
    ),
    SearchItem(
      title: 'Transaction History & Spends',
      subtitle:
          'View detailed bank spends, UPI transfers with date & time breakdown',
      category: 'PAYMENTS',
      icon: Icons.history_rounded,
      iconColor: const Color(0xFF38BDF8),
      keywords: [
        'history',
        'transactions',
        'spends',
        'passbook',
        'statement',
        'receipt',
        'spent',
      ],
      actionKey: 'history',
    ),

    // 2. BBPS UTILITIES & RECHARGES
    SearchItem(
      title: 'Electricity Bill',
      subtitle: 'CESC, Tata Power, BESCOM, Adani, WBSEDCL & 50+ discoms',
      category: 'BILLS & BBPS',
      icon: Icons.bolt_rounded,
      iconColor: const Color(0xFFFBBF24),
      keywords: [
        'electricity',
        'power',
        'cesc',
        'bijli',
        'tata power',
        'bescom',
        'bill',
      ],
      actionKey: 'bill_electricity',
    ),
    SearchItem(
      title: 'Water Bill',
      subtitle: 'Municipal corporations, water supply boards & meters',
      category: 'BILLS & BBPS',
      icon: Icons.water_drop_rounded,
      iconColor: const Color(0xFF38BDF8),
      keywords: ['water', 'municipal', 'pani', 'board', 'bill'],
      actionKey: 'bill_water',
    ),
    SearchItem(
      title: 'Gas & LPG Cylinder',
      subtitle: 'Indane, Bharat Gas, HP Gas booking & piped gas utility',
      category: 'BILLS & BBPS',
      icon: Icons.local_fire_department_rounded,
      iconColor: const Color(0xFFF87171),
      keywords: [
        'gas',
        'lpg',
        'cylinder',
        'indane',
        'hp gas',
        'bharat gas',
        'piped',
      ],
      actionKey: 'bill_gas',
    ),
    SearchItem(
      title: 'Broadband & Fiber',
      subtitle: 'Airtel Xstream, JioFiber, ACT, BSNL & regional ISPs',
      category: 'BILLS & BBPS',
      icon: Icons.wifi_rounded,
      iconColor: const Color(0xFF34D399),
      keywords: [
        'broadband',
        'wifi',
        'fiber',
        'airtel',
        'jiofiber',
        'internet',
      ],
      actionKey: 'bill_broadband',
    ),
    SearchItem(
      title: 'Mobile Recharge & 5G Postpaid',
      subtitle: 'Jio, Airtel, Vi, BSNL prepaid recharges and postpaid plans',
      category: 'BILLS & BBPS',
      icon: Icons.phone_android_rounded,
      iconColor: const Color(0xFF60A5FA),
      keywords: [
        'mobile',
        'recharge',
        'prepaid',
        'postpaid',
        'jio',
        'airtel',
        'vi',
      ],
      actionKey: 'bill_mobile',
    ),
    SearchItem(
      title: 'FASTag Toll Recharge',
      subtitle: 'Instant toll tag balance for NHAI, ICICI, SBI, Paytm & Axis',
      category: 'BILLS & BBPS',
      icon: Icons.directions_car_rounded,
      iconColor: const Color(0xFFFB923C),
      keywords: ['fastag', 'toll', 'highway', 'nhai', 'car', 'vehicle'],
      actionKey: 'bill_fastag',
    ),
    SearchItem(
      title: 'DTH Cable TV',
      subtitle: 'Tata Play, Airtel Digital TV, Dish TV, Sun Direct & D2H',
      category: 'BILLS & BBPS',
      icon: Icons.tv_rounded,
      iconColor: const Color(0xFFA855F7),
      keywords: ['dth', 'tv', 'tata play', 'dish tv', 'airtel dth', 'cable'],
      actionKey: 'bill_dth',
    ),
    SearchItem(
      title: 'Universal Service Catalogue',
      subtitle: 'Explore 30+ categorized fintech services and tools',
      category: 'SERVICES',
      icon: Icons.grid_view_rounded,
      iconColor: const Color(0xFFFF671F),
      keywords: ['all services', 'catalogue', 'more', 'category', 'explore'],
      actionKey: 'all_services',
    ),

    // 3. WEALTH & INVESTMENTS
    SearchItem(
      title: 'Bank Auto-SIP & Mutual Funds',
      subtitle: 'Nifty 50 Index, Bluechip & Flexi-cap zero commission plans',
      category: 'INVESTMENTS',
      icon: Icons.trending_up_rounded,
      iconColor: const Color(0xFF34D399),
      keywords: ['sip', 'mutual funds', 'stocks', 'invest', 'nifty', 'wealth'],
      actionKey: 'wealth_sip',
    ),
    SearchItem(
      title: '24K Digital Gold Vault',
      subtitle: '99.9% pure MMTC-PAMP digital gold accumulation & delivery',
      category: 'INVESTMENTS',
      icon: Icons.monetization_on_rounded,
      iconColor: const Color(0xFFFBBF24),
      keywords: ['gold', 'digital gold', '24k', 'mmtc-pamp', 'sona'],
      actionKey: 'wealth_gold',
    ),
    SearchItem(
      title: 'Gullak Digital Piggy Bank',
      subtitle: 'Daily micro-savings and automated round-up spare change',
      category: 'INVESTMENTS',
      icon: Icons.savings_rounded,
      iconColor: const Color(0xFFF59E0B),
      keywords: ['gullak', 'piggy bank', 'spare change', 'savings', 'roundup'],
      actionKey: 'gullak',
    ),
    SearchItem(
      title: 'Open Digital Savings Account',
      subtitle:
          'Instant zero-balance paperless account with virtual debit card',
      category: 'BANKING',
      icon: Icons.account_balance_rounded,
      iconColor: const Color(0xFF046A38),
      keywords: [
        'account opening',
        'bank account',
        'savings',
        'zero balance',
        'new account',
      ],
      actionKey: 'account_opening',
    ),
    SearchItem(
      title: 'Check Bank Balance',
      subtitle:
          'Verify live funds in linked bank account with 4-digit UPI MPIN',
      category: 'BANKING',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: const Color(0xFF38BDF8),
      keywords: ['balance', 'check balance', 'bank balance', 'inquiry', 'mpin'],
      actionKey: 'check_balance',
    ),

    // 4. MANDATES, STATEMENTS & COMMERCE
    SearchItem(
      title: 'AutoPay & Scheduled Mandates',
      subtitle: 'Manage recurring UPI autopay mandates, pauses and frequency',
      category: 'MANDATES',
      icon: Icons.autorenew_rounded,
      iconColor: const Color(0xFF6366F1),
      keywords: ['autopay', 'mandate', 'recurring', 'schedule', 'subscription'],
      actionKey: 'autopay',
    ),
    SearchItem(
      title: 'Statements & Tax Documents',
      subtitle:
          'Download monthly PDF statements, interest certificates and P&L',
      category: 'DOCUMENTS',
      icon: Icons.receipt_long_rounded,
      iconColor: const Color(0xFF0EA5E9),
      keywords: [
        'statement',
        'pdf',
        'tax',
        'certificate',
        'passbook',
        'history',
      ],
      actionKey: 'statements',
    ),
    SearchItem(
      title: 'Rewards, Coins & Coupons',
      subtitle: 'AikSetra coins, merchant coupons, scratch cards & cashback',
      category: 'REWARDS',
      icon: Icons.card_giftcard_rounded,
      iconColor: const Color(0xFFEC4899),
      keywords: ['rewards', 'coins', 'cashback', 'coupons', 'scratch card'],
      actionKey: 'rewards',
    ),
    SearchItem(
      title: 'Merchant Business Dashboard',
      subtitle:
          'Accept QR payments, instant soundbox notifications & invoicing',
      category: 'MERCHANT',
      icon: Icons.storefront_rounded,
      iconColor: const Color(0xFFFF9100),
      keywords: ['business', 'merchant', 'soundbox', 'invoice', 'gst billing'],
      actionKey: 'business',
    ),
    SearchItem(
      title: 'Tax & Government Dues',
      subtitle:
          'Direct Income Tax, Advance Tax, GST and Municipal property dues',
      category: 'GOVT & TAX',
      icon: Icons.account_balance_outlined,
      iconColor: const Color(0xFF10B981),
      keywords: [
        'tax',
        'income tax',
        'gst',
        'challan',
        'municipal',
        'government',
      ],
      actionKey: 'tax',
    ),
    SearchItem(
      title: 'Travel & Ticket Booking',
      subtitle:
          'IRCTC Trains, Domestic Flights, Inter-city Buses & Hotel stays',
      category: 'TRAVEL',
      icon: Icons.flight_takeoff_rounded,
      iconColor: const Color(0xFF0284C7),
      keywords: [
        'travel',
        'flight',
        'train',
        'irctc',
        'bus',
        'hotel',
        'ticket',
      ],
      actionKey: 'travel',
    ),

    // 5. CALCULATORS
    SearchItem(
      title: 'EMI Calculator',
      subtitle: 'Home, car and personal loan monthly installment calculator',
      category: 'CALCULATORS',
      icon: Icons.calculate_rounded,
      iconColor: const Color(0xFF6366F1),
      keywords: ['calculator', 'emi', 'loan', 'home loan', 'car loan'],
      actionKey: 'calc_emi',
    ),
    SearchItem(
      title: 'SIP & Wealth Calculator',
      subtitle: 'Calculate expected compounding returns over 5, 10, 20 years',
      category: 'CALCULATORS',
      icon: Icons.insights_rounded,
      iconColor: const Color(0xFF10B981),
      keywords: ['sip calculator', 'mutual fund returns', 'compounding'],
      actionKey: 'calc_sip',
    ),
    SearchItem(
      title: 'FD & RD Maturity Calculator',
      subtitle: 'Bank Fixed Deposit and Recurring Deposit maturity interest',
      category: 'CALCULATORS',
      icon: Icons.account_balance_rounded,
      iconColor: const Color(0xFFF59E0B),
      keywords: [
        'fd',
        'rd',
        'fixed deposit',
        'maturity',
        'interest calculator',
      ],
      actionKey: 'calc_fd',
    ),
    SearchItem(
      title: 'GST Tax Calculator',
      subtitle: '5%, 12%, 18%, 28% CGST + SGST tax breakdown calculator',
      category: 'CALCULATORS',
      icon: Icons.receipt_rounded,
      iconColor: const Color(0xFF38BDF8),
      keywords: ['gst', 'cgst', 'sgst', 'tax calculator'],
      actionKey: 'calc_gst',
    ),
    SearchItem(
      title: 'Income Tax Estimator',
      subtitle: 'New vs Old Tax Regime FY2026 calculation & rebate',
      category: 'CALCULATORS',
      icon: Icons.attach_money_rounded,
      iconColor: const Color(0xFFEC4899),
      keywords: ['income tax', 'tax regime', '80c', 'salary tax'],
      actionKey: 'calc_tax',
    ),
    SearchItem(
      title: 'Currency Converter',
      subtitle: 'Real-time live RBI exchange rates for USD, EUR, GBP, AED, SGD',
      category: 'CALCULATORS',
      icon: Icons.currency_exchange_rounded,
      iconColor: const Color(0xFF14B8A6),
      keywords: ['currency', 'fx', 'dollar', 'euro', 'forex', 'converter'],
      actionKey: 'calc_fx',
    ),

    // 6. SETTINGS & SECURITY
    SearchItem(
      title: 'App Language / भाषा बदलें',
      subtitle:
          'Select regional language according to location or manual choice',
      category: 'SETTINGS',
      icon: Icons.language_rounded,
      iconColor: const Color(0xFFFF671F),
      keywords: [
        'language',
        'bhasha',
        'hindi',
        'bengali',
        'tamil',
        'marathi',
        'gujarati',
        'settings',
      ],
      actionKey: 'language',
    ),
    SearchItem(
      title: 'Update 4-Digit UPI MPIN',
      subtitle:
          'Reset or update bank UPI security PIN for payment authorizations',
      category: 'SETTINGS',
      icon: Icons.pin_rounded,
      iconColor: const Color(0xFF38BDF8),
      keywords: ['mpin', 'pin', 'security', 'change pin', 'password'],
      actionKey: 'change_mpin',
    ),
    SearchItem(
      title: 'Biometric Fingerprint Lock',
      subtitle:
          'Enable or toggle biometric authorization for app unlock & payments',
      category: 'SETTINGS',
      icon: Icons.fingerprint_rounded,
      iconColor: const Color(0xFF34D399),
      keywords: ['biometric', 'fingerprint', 'face unlock', 'security lock'],
      actionKey: 'biometrics',
    ),
    SearchItem(
      title: 'AI Scam Shield Live Radar',
      subtitle:
          'Pre-payment safety checker against fraudulent VPAs and phishing',
      category: 'SETTINGS',
      icon: Icons.shield_rounded,
      iconColor: const Color(0xFFEF4444),
      keywords: ['scam', 'fraud', 'shield', 'safety', 'radar', 'security'],
      actionKey: 'scam_shield',
    ),
    SearchItem(
      title: '24x7 Support & Helpdesk',
      subtitle: 'Toll-free customer assistance, dispute tickets and live chat',
      category: 'SETTINGS',
      icon: Icons.support_agent_rounded,
      iconColor: const Color(0xFF38BDF8),
      keywords: [
        'help',
        'support',
        'contact us',
        'toll free',
        'dispute',
        'ticket',
      ],
      actionKey: 'support',
    ),
  ];

  List<SearchItem> get _filteredItems {
    if (_query.trim().isEmpty) return _allItems;
    final q = _query.toLowerCase().trim();
    return _allItems.where((item) {
      final inTitle = item.title.toLowerCase().contains(q);
      final inSubtitle = item.subtitle.toLowerCase().contains(q);
      final inCat = item.category.toLowerCase().contains(q);
      final inKeywords = item.keywords.any((k) => k.toLowerCase().contains(q));
      return inTitle || inSubtitle || inCat || inKeywords;
    }).toList();
  }

  void _handleItemTap(SearchItem item) {
    Navigator.pop(context); // Close search screen

    // If parent callback handles action
    if (widget.onActionSelected != null) {
      widget.onActionSelected!(item.actionKey);
      return;
    }

    // Default built-in routing
    _executeAction(item.actionKey);
  }

  void _executeAction(String actionKey) {
    switch (actionKey) {
      case 'all_services':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllServicesScreen(
              onSelectService: (routeKey) => _executeAction(routeKey),
            ),
          ),
        );
        break;
      case 'autopay':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AutoPayScreen()),
        );
        break;
      case 'cards':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CardsScreen()),
        );
        break;
      case 'calc_emi':
      case 'calc_sip':
      case 'calc_fd':
      case 'calc_gst':
      case 'calc_tax':
      case 'calc_fx':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CalculatorsScreen()),
        );
        break;
      case 'travel':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TravelScreen()),
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
      case 'statements':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatementsScreen()),
        );
        break;
      case 'language':
        LanguageLocationSelectorModal.show(context);
        break;
      default:
        // Other actions fall back to ProfileScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProfileScreen(onRefreshParent: widget.onRefreshParent),
          ),
        );
        break;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        onChanged: (val) => setState(() => _query = val),
                        decoration: InputDecoration(
                          hintText: 'Search services, billers, UPI, tools...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFFFF671F),
                            size: 20,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Category Filter Chips
            if (_query.isEmpty) ...[
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    _buildQuickChip('⚡ Scan QR', 'scan_qr'),
                    _buildQuickChip('💸 Send Money', 'send_money'),
                    _buildQuickChip('⚡ Electricity', 'bill_electricity'),
                    _buildQuickChip('📱 Mobile 5G', 'bill_mobile'),
                    _buildQuickChip('🚗 FASTag', 'bill_fastag'),
                    _buildQuickChip('📈 Mutual Funds', 'wealth_sip'),
                    _buildQuickChip('🛡️ Scam Shield', 'scam_shield'),
                    _buildQuickChip('🌐 Language', 'language'),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E293B), height: 1),
            ],

            // Search Results List
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No results found for "$_query"',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try searching for "Electricity", "Send Money", "Cards", "SIP" or "Language"',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: results.length,
                      itemBuilder: (ctx, idx) {
                        final item = results[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF334155)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: ListTile(
                            onTap: () => _handleItemTap(item),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: item.iconColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.icon,
                                color: item.iconColor,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
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
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              item.subtitle,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        side: const BorderSide(color: Color(0xFF334155)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          final matched = _allItems.firstWhere(
            (i) => i.actionKey == key,
            orElse: () => _allItems.first,
          );
          _handleItemTap(matched);
        },
      ),
    );
  }
}
