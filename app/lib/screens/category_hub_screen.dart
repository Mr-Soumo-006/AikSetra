import 'package:flutter/material.dart';

class CategoryHubScreen extends StatefulWidget {
  final String categoryKey;
  final Function(String routeKey) onSelectService;

  const CategoryHubScreen({
    super.key,
    required this.categoryKey,
    required this.onSelectService,
  });

  @override
  State<CategoryHubScreen> createState() => _CategoryHubScreenState();
}

class _CategoryHubScreenState extends State<CategoryHubScreen> {
  late String _activeCategory;

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.categoryKey;
  }

  String get _title {
    switch (_activeCategory) {
      case 'recharge_bills':
      case 'bills':
        return 'Recharge & Bills';
      case 'loans':
      case 'credit':
        return 'Loans & Credit';
      case 'savings_investments':
      case 'gold_wealth':
      case 'gold':
      case 'wealth':
        return 'Savings and Investment';
      case 'insurance':
        return 'Insurance & Protection';
      case 'tools':
      case 'calculators':
        return 'Financial Tools & Calculators';
      default:
        return 'Financial Services';
    }
  }

  // SUGGESTED FOR YOU (4 circular items matching Photo 3)
  List<Map<String, dynamic>> get _suggestedItems {
    switch (_activeCategory) {
      case 'recharge_bills':
      case 'bills':
        return [
          {
            'label': 'FASTag Recharge',
            'icon': Icons.directions_car_rounded,
            'color': const Color(0xFF7C3AED),
            'routeKey': 'fastag',
            'badge': null,
          },
          {
            'label': 'LIC / Insurance',
            'icon': Icons.shield_rounded,
            'color': const Color(0xFF2563EB),
            'routeKey': 'insurance',
            'badge': null,
          },
          {
            'label': 'Fees via Credit Card',
            'icon': Icons.menu_book_rounded,
            'color': const Color(0xFF6B21A8),
            'routeKey': 'cards',
            'badge': 'Instant',
          },
          {
            'label': 'Credit Card Bill',
            'icon': Icons.credit_card_rounded,
            'color': const Color(0xFF4F46E5),
            'routeKey': 'cards',
            'badge': null,
          },
        ];
      case 'loans':
      case 'credit':
        return [
          {
            'label': 'Pre-Approved ₹5L',
            'icon': Icons.verified_rounded,
            'color': const Color(0xFF10B981),
            'routeKey': 'loan_personal',
            'badge': 'Instant',
          },
          {
            'label': 'Free Credit Score',
            'icon': Icons.speed_rounded,
            'color': const Color(0xFF3B82F6),
            'routeKey': 'credit_score',
            'badge': '785 CIBIL',
          },
          {
            'label': 'Loan Repayment',
            'icon': Icons.currency_rupee_rounded,
            'color': const Color(0xFFF59E0B),
            'routeKey': 'loan_repayment',
            'badge': null,
          },
          {
            'label': 'Gold Loan 9.5%',
            'icon': Icons.shield_moon_rounded,
            'color': const Color(0xFFD97706),
            'routeKey': 'loan_gold',
            'badge': 'Low Rate',
          },
        ];
      case 'gold_wealth':
      case 'gold':
      case 'wealth':
        return [
          {
            'label': '24K Gold Vault',
            'icon': Icons.savings_rounded,
            'color': const Color(0xFFF59E0B),
            'routeKey': 'invest_gold',
            'badge': '99.9%',
          },
          {
            'label': 'Daily Silver ₹10',
            'icon': Icons.auto_awesome_rounded,
            'color': const Color(0xFF94A3B8),
            'routeKey': 'invest_silver',
            'badge': 'Popular',
          },
          {
            'label': 'Mutual Funds SIP',
            'icon': Icons.trending_up_rounded,
            'color': const Color(0xFF10B981),
            'routeKey': 'invest_sip',
            'badge': '18% CAGR',
          },
          {
            'label': 'Fixed Deposit 7.5%',
            'icon': Icons.lock_clock_rounded,
            'color': const Color(0xFF6366F1),
            'routeKey': 'invest_fd',
            'badge': 'Safe',
          },
        ];
      case 'insurance':
        return [
          {
            'label': 'Comprehensive Bike',
            'icon': Icons.two_wheeler_rounded,
            'color': const Color(0xFF14B8A6),
            'routeKey': 'ins_bike',
            'badge': '₹499/yr',
          },
          {
            'label': 'Zero-Dep Car',
            'icon': Icons.directions_car_rounded,
            'color': const Color(0xFF2563EB),
            'routeKey': 'ins_car',
            'badge': 'Cashless',
          },
          {
            'label': 'Health ₹10 Lakh',
            'icon': Icons.local_hospital_rounded,
            'color': const Color(0xFF10B981),
            'routeKey': 'ins_health',
            'badge': 'No Copay',
          },
          {
            'label': '₹1 Cr Term Life',
            'icon': Icons.family_restroom_rounded,
            'color': const Color(0xFF8B5CF6),
            'routeKey': 'ins_life',
            'badge': 'Tax Saver',
          },
        ];
      default: // tools
        return [
          {
            'label': 'SIP Calculator',
            'icon': Icons.trending_up_rounded,
            'color': const Color(0xFF046A38),
            'routeKey': 'calc_sip',
            'badge': 'Popular',
          },
          {
            'label': 'Home Loan EMI',
            'icon': Icons.calculate_rounded,
            'color': const Color(0xFF1D4ED8),
            'routeKey': 'calc_emi',
            'badge': null,
          },
          {
            'label': 'GST 18% Estimator',
            'icon': Icons.percent_rounded,
            'color': const Color(0xFFD97706),
            'routeKey': 'calc_gst',
            'badge': null,
          },
          {
            'label': 'Income Tax 2026',
            'icon': Icons.account_balance_rounded,
            'color': const Color(0xFFFF671F),
            'routeKey': 'calc_income_tax',
            'badge': 'New Slab',
          },
        ];
    }
  }

  // GROUPED SECTIONS (matching Photo 3 structure)
  List<Map<String, dynamic>> get _sections {
    switch (_activeCategory) {
      case 'recharge_bills':
      case 'bills':
        return [
          {
            'title': 'Telecom & Recharges',
            'items': [
              {'label': 'Mobile Recharge', 'icon': Icons.phone_android_rounded, 'color': const Color(0xFF38BDF8), 'routeKey': 'mobile_recharge'},
              {'label': 'DTH TV', 'icon': Icons.tv_rounded, 'color': const Color(0xFFA855F7), 'routeKey': 'dth'},
              {'label': 'Mobile Postpaid', 'icon': Icons.receipt_rounded, 'color': const Color(0xFF34D399), 'routeKey': 'postpaid'},
              {'label': 'Google Play', 'icon': Icons.shop_two_rounded, 'color': const Color(0xFFFB7185), 'routeKey': 'subscriptions'},
              {'label': 'Cable TV', 'icon': Icons.live_tv_rounded, 'color': const Color(0xFFFBBF24), 'routeKey': 'dth'},
              {'label': 'International Roaming', 'icon': Icons.flight_takeoff_rounded, 'color': const Color(0xFF60A5FA), 'routeKey': 'mobile_recharge'},
              {'label': 'Get SIM', 'icon': Icons.sim_card_rounded, 'color': const Color(0xFFFF671F), 'routeKey': 'mobile_recharge', 'badge': 'Prepaid'},
              {'label': 'App Store Code', 'icon': Icons.apple_rounded, 'color': Colors.white70, 'routeKey': 'subscriptions'},
            ],
          },
          {
            'title': 'Utilities',
            'items': [
              {'label': 'Electricity', 'icon': Icons.bolt_rounded, 'color': const Color(0xFFF59E0B), 'routeKey': 'electricity'},
              {'label': 'Piped Gas', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFEF4444), 'routeKey': 'gas'},
              {'label': 'Water Bill', 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF06B6D4), 'routeKey': 'water'},
              {'label': 'LPG Cylinder', 'icon': Icons.propane_tank_rounded, 'color': const Color(0xFFF97316), 'routeKey': 'gas'},
              {'label': 'Broadband', 'icon': Icons.router_rounded, 'color': const Color(0xFF10B981), 'routeKey': 'broadband'},
              {'label': 'Municipal Tax', 'icon': Icons.domain_rounded, 'color': const Color(0xFF8B5CF6), 'routeKey': 'municipal_taxes'},
              {'label': 'Housing Society', 'icon': Icons.apartment_rounded, 'color': const Color(0xFF3B82F6), 'routeKey': 'electricity'},
              {'label': 'Hospital & Labs', 'icon': Icons.local_hospital_rounded, 'color': const Color(0xFFEC4899), 'routeKey': 'water'},
            ],
          },
          {
            'title': 'Financial Services & Taxes',
            'items': [
              {'label': 'Loan Repayment', 'icon': Icons.currency_rupee_rounded, 'color': const Color(0xFF10B981), 'routeKey': 'loan_repayment'},
              {'label': 'Credit Card Bill', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFF6366F1), 'routeKey': 'cards'},
              {'label': 'Insurance Premium', 'icon': Icons.shield_rounded, 'color': const Color(0xFF0EA5E9), 'routeKey': 'insurance'},
              {'label': 'Education Fees', 'icon': Icons.school_rounded, 'color': const Color(0xFFF43F5E), 'routeKey': 'cards'},
              {'label': 'Traffic Challan', 'icon': Icons.traffic_rounded, 'color': const Color(0xFFEF4444), 'routeKey': 'property_tax'},
              {'label': 'Recurring Deposit', 'icon': Icons.savings_rounded, 'color': const Color(0xFF046A38), 'routeKey': 'rd'},
              {'label': 'Donation & Trust', 'icon': Icons.volunteer_activism_rounded, 'color': const Color(0xFFEC4899), 'routeKey': 'send_money'},
              {'label': 'NPS Contribution', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFFFF671F), 'routeKey': 'sip_mutual_funds'},
            ],
          },
        ];
      case 'loans':
      case 'credit':
        return [
          {
            'title': 'Instant & Personal Loans',
            'items': [
              {'label': 'Personal Loan', 'icon': Icons.person_rounded, 'color': const Color(0xFFF43F5E), 'routeKey': 'loan_personal', 'badge': 'Up to ₹5L'},
              {'label': 'Credit Score', 'icon': Icons.speed_rounded, 'color': const Color(0xFF3B82F6), 'routeKey': 'credit_score', 'badge': 'Free'},
              {'label': 'Home Loan', 'icon': Icons.home_rounded, 'color': const Color(0xFF10B981), 'routeKey': 'loan_home', 'badge': '8.35%'},
              {'label': 'Auto / Car Loan', 'icon': Icons.directions_car_rounded, 'color': const Color(0xFFF59E0B), 'routeKey': 'loan_auto'},
              {'label': 'Two-Wheeler Loan', 'icon': Icons.two_wheeler_rounded, 'color': const Color(0xFF06B6D4), 'routeKey': 'loan_bike'},
              {'label': 'Education Loan', 'icon': Icons.school_rounded, 'color': const Color(0xFF8B5CF6), 'routeKey': 'loan_education'},
              {'label': 'Consumer Loan', 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFEC4899), 'routeKey': 'loan_consumer'},
              {'label': 'Loan Repayment', 'icon': Icons.receipt_long_rounded, 'color': const Color(0xFF34D399), 'routeKey': 'loan_repayment'},
            ],
          },
          {
            'title': 'Secured & Business Credit',
            'items': [
              {'label': 'Gold Loan', 'icon': Icons.shield_moon_rounded, 'color': const Color(0xFFD97706), 'routeKey': 'loan_gold', 'badge': 'Zero Docs'},
              {'label': 'Mutual Funds Loan', 'icon': Icons.insert_chart_rounded, 'color': const Color(0xFF10B981), 'routeKey': 'loan_mf', 'badge': '10% p.a.'},
              {'label': 'Business Loan', 'icon': Icons.storefront_rounded, 'color': const Color(0xFFFF671F), 'routeKey': 'business'},
              {'label': 'Loan vs Property', 'icon': Icons.domain_rounded, 'color': const Color(0xFF6366F1), 'routeKey': 'loan_home'},
              {'label': 'Working Capital', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF0EA5E9), 'routeKey': 'business'},
              {'label': 'Kisan Agri Credit', 'icon': Icons.agriculture_rounded, 'color': const Color(0xFF84CC16), 'routeKey': 'loan_personal'},
            ],
          },
        ];
      case 'gold_wealth':
      case 'gold':
      case 'wealth':
        return [
          {
            'title': '24K Digital Gold & Silver',
            'items': [
              {'label': 'Daily Gold ₹10', 'icon': Icons.savings_rounded, 'color': const Color(0xFFF59E0B), 'routeKey': 'invest_gold', 'badge': 'Auto-SIP'},
              {'label': 'Buy 24K Gold', 'icon': Icons.shield_rounded, 'color': const Color(0xFFFF671F), 'routeKey': 'invest_gold', 'badge': '99.9%'},
              {'label': 'Daily Silver ₹10', 'icon': Icons.auto_awesome_rounded, 'color': const Color(0xFF94A3B8), 'routeKey': 'invest_silver'},
              {'label': 'Buy Pure Silver', 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFCBD5E1), 'routeKey': 'invest_silver'},
              {'label': 'Home Delivery Coins', 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFFD97706), 'routeKey': 'invest_gold'},
              {'label': 'Gold SIP Mandate', 'icon': Icons.autorenew_rounded, 'color': const Color(0xFF10B981), 'routeKey': 'autopay'},
              {'label': 'Sell Gold / Cash', 'icon': Icons.currency_exchange_rounded, 'color': const Color(0xFF38BDF8), 'routeKey': 'invest_gold'},
              {'label': 'Vault Statements', 'icon': Icons.receipt_long_rounded, 'color': const Color(0xFF8B5CF6), 'routeKey': 'statements'},
            ],
          },
          {
            'title': 'Wealth & Mutual Funds',
            'items': [
              {'label': 'Bank Auto-SIP', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF046A38), 'routeKey': 'invest_sip', 'badge': 'Top Pick'},
              {'label': 'Nifty 50 Index', 'icon': Icons.show_chart_rounded, 'color': const Color(0xFF2563EB), 'routeKey': 'invest_sip'},
              {'label': 'Flexi Cap Funds', 'icon': Icons.pie_chart_rounded, 'color': const Color(0xFF7C3AED), 'routeKey': 'invest_sip'},
              {'label': 'Fixed Deposit 7.5%', 'icon': Icons.lock_clock_rounded, 'color': const Color(0xFF1E293B), 'routeKey': 'invest_fd', 'badge': 'DICGC'},
              {'label': 'Recurring Deposit', 'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFF059669), 'routeKey': 'invest_rd'},
              {'label': 'Stock Trading', 'icon': Icons.candlestick_chart_rounded, 'color': const Color(0xFFEF4444), 'routeKey': 'invest_stocks'},
              {'label': 'NPS Pension', 'icon': Icons.elderly_rounded, 'color': const Color(0xFFFF9100), 'routeKey': 'invest_sip'},
              {'label': 'Sovereign Gold', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFFF59E0B), 'routeKey': 'invest_gold'},
            ],
          },
        ];
      case 'insurance':
        return [
          {
            'title': 'Vehicle & Motor Insurance',
            'items': [
              {'label': 'Bike Insurance', 'icon': Icons.two_wheeler_rounded, 'color': const Color(0xFF14B8A6), 'routeKey': 'ins_bike', 'badge': '₹499/yr'},
              {'label': 'Car Insurance', 'icon': Icons.directions_car_rounded, 'color': const Color(0xFF2563EB), 'routeKey': 'ins_car', 'badge': 'Zero Dep'},
              {'label': 'Commercial Vehicle', 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFFF59E0B), 'routeKey': 'ins_car'},
              {'label': 'EV Insurance', 'icon': Icons.electric_car_rounded, 'color': const Color(0xFF10B981), 'routeKey': 'ins_car'},
            ],
          },
          {
            'title': 'Health & Life Protection',
            'items': [
              {'label': 'Family Health', 'icon': Icons.local_hospital_rounded, 'color': const Color(0xFF10B981), 'routeKey': 'ins_health', 'badge': '₹10 Lakh'},
              {'label': '₹1 Cr Term Life', 'icon': Icons.family_restroom_rounded, 'color': const Color(0xFF8B5CF6), 'routeKey': 'ins_life', 'badge': '₹550/mo'},
              {'label': 'Personal Accident', 'icon': Icons.healing_rounded, 'color': const Color(0xFFF43F5E), 'routeKey': 'ins_health'},
              {'label': 'International Travel', 'icon': Icons.flight_rounded, 'color': const Color(0xFF0EA5E9), 'routeKey': 'ins_travel'},
              {'label': 'Cancer Care Shield', 'icon': Icons.favorite_rounded, 'color': const Color(0xFFEC4899), 'routeKey': 'ins_health'},
              {'label': 'Super Top-up Health', 'icon': Icons.add_moderator_rounded, 'color': const Color(0xFF046A38), 'routeKey': 'ins_health'},
            ],
          },
        ];
      default: // tools
        return [
          {
            'title': 'Investment & Savings Calculators',
            'items': [
              {'label': 'SIP Calculator', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF046A38), 'routeKey': 'calc_sip', 'badge': 'Popular'},
              {'label': 'Lump Sum Wealth', 'icon': Icons.monetization_on_rounded, 'color': const Color(0xFF10B981), 'routeKey': 'calc_sip'},
              {'label': 'FD Maturity', 'icon': Icons.lock_clock_rounded, 'color': const Color(0xFF2563EB), 'routeKey': 'calc_fd'},
              {'label': 'RD Return', 'icon': Icons.savings_rounded, 'color': const Color(0xFF7C3AED), 'routeKey': 'calc_rd'},
              {'label': 'Compound Interest', 'icon': Icons.stacked_line_chart_rounded, 'color': const Color(0xFF06B6D4), 'routeKey': 'calc_compound'},
              {'label': 'Inflation Estimator', 'icon': Icons.bubble_chart_rounded, 'color': const Color(0xFFF59E0B), 'routeKey': 'calc_inflation'},
              {'label': 'Savings Goal', 'icon': Icons.flag_rounded, 'color': const Color(0xFFEC4899), 'routeKey': 'calc_goal'},
              {'label': 'Currency Converter', 'icon': Icons.currency_exchange_rounded, 'color': const Color(0xFFFF671F), 'routeKey': 'calc_currency'},
            ],
          },
          {
            'title': 'Loans, EMI & Taxes',
            'items': [
              {'label': 'Home / Car EMI', 'icon': Icons.calculate_rounded, 'color': const Color(0xFF1D4ED8), 'routeKey': 'calc_emi', 'badge': 'Exact'},
              {'label': 'GST 18% Estimator', 'icon': Icons.percent_rounded, 'color': const Color(0xFFD97706), 'routeKey': 'calc_gst'},
              {'label': 'Income Tax 2026', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFFFF671F), 'routeKey': 'calc_income_tax', 'badge': 'New Slab'},
              {'label': 'HRA Exemption', 'icon': Icons.home_work_rounded, 'color': const Color(0xFF059669), 'routeKey': 'calc_income_tax'},
              {'label': 'Gratuity Estimator', 'icon': Icons.card_giftcard_rounded, 'color': const Color(0xFF8B5CF6), 'routeKey': 'calc_goal'},
              {'label': 'Standard Calculator', 'icon': Icons.dialpad_rounded, 'color': Colors.white70, 'routeKey': 'calc_standard'},
            ],
          },
        ];
    }
  }

  void _triggerAction(String routeKey) {
    widget.onSelectService(routeKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onSelectService('history');
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 14, color: Colors.white),
              label: const Text(
                'My Bills',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF334155)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('24x7 Help Desk • All transactions NPCI & BBPS certified'),
                  backgroundColor: Color(0xFF0F172A),
                ),
              );
            },
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SUGGESTED FOR YOU (Matching Photo 3 top dark rounded card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suggested for you',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _suggestedItems.map((item) {
                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _triggerAction(item['routeKey'] as String);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          (item['color'] as Color).withValues(alpha: 0.25),
                                          (item['color'] as Color).withValues(alpha: 0.10),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: (item['color'] as Color).withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      color: item['color'] as Color,
                                      size: 26,
                                    ),
                                  ),
                                  if (item['badge'] != null)
                                    Positioned(
                                      top: -6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item['badge'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. SUB-CATEGORY SECTIONS
            ..._sections.asMap().entries.map((entry) {
              final idx = entry.key;
              final sec = entry.value;
              final items = sec['items'] as List<Map<String, dynamic>>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sec['title'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 18,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final s = items[i];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _triggerAction(s['routeKey'] as String);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF1E293B),
                                    border: Border.all(
                                      color: const Color(0xFF334155),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    s['icon'] as IconData,
                                    color: s['color'] as Color,
                                    size: 24,
                                  ),
                                ),
                                if (s['badge'] != null)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: s['badge'] == 'Prepaid' || s['badge'] == 'Up to ₹5L'
                                            ? const Color(0xFF046A38)
                                            : const Color(0xFFDC2626),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        s['badge'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s['label'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // IN-BETWEEN PROMOTIONAL MICRO-BANNER (Matching Photo 3)
                  if (idx == 0) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF671F).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF671F).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.savings_rounded, color: Color(0xFFFF671F), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Save ₹10 in 24K gold daily!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Trusted by over 1.5Cr Indians • 99.9% Pure',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF671F), size: 12),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }),

            const SizedBox(height: 10),

            // 3. POWERED BY BHARAT CONNECT (BBPS) FOOTER BADGE
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Powered by ',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                    Icon(Icons.bolt_rounded, color: Color(0xFFFF671F), size: 14),
                    SizedBox(width: 2),
                    Text(
                      'Bharat Connect (BBPS)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
