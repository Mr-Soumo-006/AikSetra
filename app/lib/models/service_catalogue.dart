import 'package:flutter/material.dart';

enum ServiceCategory {
  payments,
  bills,
  investments,
  insurance,
  taxes,
  tools,
  other,
}

class ServiceItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ServiceCategory category;
  final String? badge;
  final String routeKey;

  const ServiceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    this.badge,
    required this.routeKey,
  });
}

class ServiceCatalogue {
  static const List<ServiceItem> allServices = [
    // ----------------------------------------------------
    // PAYMENTS
    // ----------------------------------------------------
    ServiceItem(
      id: 'pay_scan',
      title: 'Scan & Pay',
      subtitle: 'Scan any UPI / BharatQR code',
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF046A38),
      category: ServiceCategory.payments,
      badge: 'CAMERA',
      routeKey: 'scan_qr',
    ),
    ServiceItem(
      id: 'pay_send',
      title: 'Send Money',
      subtitle: 'To any UPI ID or Mobile Number',
      icon: Icons.send_rounded,
      color: Color(0xFFFF671F),
      category: ServiceCategory.payments,
      routeKey: 'send_money',
    ),
    ServiceItem(
      id: 'pay_qr',
      title: 'My UPI QR',
      subtitle: 'Receive money into linked bank',
      icon: Icons.qr_code_2_rounded,
      color: Color(0xFF0F172A),
      category: ServiceCategory.payments,
      routeKey: 'my_qr',
    ),
    ServiceItem(
      id: 'pay_self',
      title: 'Self Transfer',
      subtitle: 'Between your own linked accounts',
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFF2563EB),
      category: ServiceCategory.payments,
      routeKey: 'self_transfer',
    ),
    ServiceItem(
      id: 'pay_add',
      title: 'Add Money',
      subtitle: 'Direct deposit into primary account',
      icon: Icons.add_circle_outline_rounded,
      color: Color(0xFF046A38),
      category: ServiceCategory.payments,
      routeKey: 'add_money',
    ),
    ServiceItem(
      id: 'pay_contacts',
      title: 'Contacts & Beneficiaries',
      subtitle: 'Manage saved recipients & payees',
      icon: Icons.contacts_rounded,
      color: Color(0xFF8B5CF6),
      category: ServiceCategory.payments,
      routeKey: 'contacts',
    ),
    ServiceItem(
      id: 'pay_cards',
      title: 'Credit & Debit Cards',
      subtitle: 'RuPay UPI, Visa & Mastercard',
      icon: Icons.credit_card_rounded,
      color: Color(0xFF4F46E5),
      category: ServiceCategory.payments,
      badge: 'RUPAY UPI',
      routeKey: 'cards',
    ),
    ServiceItem(
      id: 'pay_autopay',
      title: 'AutoPay Mandates',
      subtitle: 'Manage recurring e-Mandates & UMRN',
      icon: Icons.autorenew_rounded,
      color: Color(0xFF059669),
      category: ServiceCategory.payments,
      badge: 'NPCI',
      routeKey: 'autopay',
    ),
    ServiceItem(
      id: 'pay_escrow',
      title: 'Safe Escrow Pay',
      subtitle: 'Protected release after delivery',
      icon: Icons.verified_user_rounded,
      color: Color(0xFF0284C7),
      category: ServiceCategory.payments,
      badge: 'ESCROW',
      routeKey: 'safe_pay',
    ),

    // ----------------------------------------------------
    // BILLS & UTILITIES (BBPS)
    // ----------------------------------------------------
    ServiceItem(
      id: 'bill_electricity',
      title: 'Electricity',
      subtitle: 'State discoms & power boards',
      icon: Icons.bolt_rounded,
      color: Color(0xFFD97706),
      category: ServiceCategory.bills,
      badge: 'BBPS',
      routeKey: 'bill_ELECTRICITY',
    ),
    ServiceItem(
      id: 'bill_water',
      title: 'Water Bill',
      subtitle: 'Municipal water supply boards',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0284C7),
      category: ServiceCategory.bills,
      badge: 'BBPS',
      routeKey: 'bill_WATER',
    ),
    ServiceItem(
      id: 'bill_gas',
      title: 'Gas / LPG Cylinder',
      subtitle: 'Indane, Bharat Gas, HP & Piped Gas',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFDC2626),
      category: ServiceCategory.bills,
      badge: 'BBPS',
      routeKey: 'bill_GAS',
    ),
    ServiceItem(
      id: 'bill_broadband',
      title: 'Broadband Internet',
      subtitle: 'JioFiber, Airtel, BSNL, ACT Fibernet',
      icon: Icons.router_rounded,
      color: Color(0xFF059669),
      category: ServiceCategory.bills,
      badge: 'BBPS',
      routeKey: 'bill_BROADBAND',
    ),
    ServiceItem(
      id: 'bill_mobile',
      title: 'Mobile 5G Recharge',
      subtitle: 'Prepaid & Postpaid Jio, Airtel, Vi',
      icon: Icons.phone_android_rounded,
      color: Color(0xFF4F46E5),
      category: ServiceCategory.bills,
      badge: 'INSTANT',
      routeKey: 'bill_MOBILE',
    ),
    ServiceItem(
      id: 'bill_dth',
      title: 'DTH Satellite TV',
      subtitle: 'Tata Play, Airtel DTH, DishTV',
      icon: Icons.tv_rounded,
      color: Color(0xFF7C3AED),
      category: ServiceCategory.bills,
      routeKey: 'bill_DTH',
    ),
    ServiceItem(
      id: 'bill_fastag',
      title: 'FASTag Toll Recharge',
      subtitle: 'NHAI NETC all issuer banks',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF0F172A),
      category: ServiceCategory.bills,
      badge: 'NETC',
      routeKey: 'bill_FASTAG',
    ),

    // ----------------------------------------------------
    // INVESTMENTS & SAVINGS
    // ----------------------------------------------------
    ServiceItem(
      id: 'inv_sip',
      title: 'Bank Auto-SIP',
      subtitle: 'Nifty 50, Flexi Cap & Bluechip',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF046A38),
      category: ServiceCategory.investments,
      badge: 'HIGH CAGR',
      routeKey: 'invest_sip',
    ),
    ServiceItem(
      id: 'inv_gold',
      title: '24K Digital Gold',
      subtitle: 'MMTC-PAMP 99.9% Insured Vault',
      icon: Icons.shield_rounded,
      color: Color(0xFFD97706),
      category: ServiceCategory.investments,
      badge: '24K PURE',
      routeKey: 'invest_gold',
    ),
    ServiceItem(
      id: 'inv_fd',
      title: 'Fixed Deposits (FD)',
      subtitle: 'Guaranteed returns up to 7.5% p.a.',
      icon: Icons.lock_clock_rounded,
      color: Color(0xFF1E293B),
      category: ServiceCategory.investments,
      badge: 'DICGC INSURED',
      routeKey: 'invest_fd',
    ),
    ServiceItem(
      id: 'inv_rd',
      title: 'Recurring Deposits (RD)',
      subtitle: 'Monthly disciplined savings',
      icon: Icons.savings_rounded,
      color: Color(0xFF2563EB),
      category: ServiceCategory.investments,
      routeKey: 'invest_rd',
    ),
    ServiceItem(
      id: 'inv_stocks',
      title: 'Indian Stock Trading',
      subtitle: 'NSE & BSE Equities watchlist',
      icon: Icons.candlestick_chart_rounded,
      color: Color(0xFF0F172A),
      category: ServiceCategory.investments,
      routeKey: 'invest_stocks',
    ),

    // ----------------------------------------------------
    // INSURANCE & PROTECTION
    // ----------------------------------------------------
    ServiceItem(
      id: 'ins_health',
      title: 'Health Insurance',
      subtitle: 'Cashless hospitalization up to ₹1 Crore',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFFDC2626),
      category: ServiceCategory.insurance,
      badge: 'CASHLESS',
      routeKey: 'ins_health',
    ),
    ServiceItem(
      id: 'ins_life',
      title: 'Life Term Cover',
      subtitle: 'Protect your family future',
      icon: Icons.family_restroom_rounded,
      color: Color(0xFF4F46E5),
      category: ServiceCategory.insurance,
      routeKey: 'ins_life',
    ),
    ServiceItem(
      id: 'ins_vehicle',
      title: 'Motor & Bike Insurance',
      subtitle: 'Instant policy renewal with zero inspection',
      icon: Icons.two_wheeler_rounded,
      color: Color(0xFF0284C7),
      category: ServiceCategory.insurance,
      routeKey: 'ins_vehicle',
    ),
    ServiceItem(
      id: 'ins_travel',
      title: 'International Travel Cover',
      subtitle: 'Overseas medical & baggage loss protection',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF059669),
      category: ServiceCategory.insurance,
      routeKey: 'ins_travel',
    ),

    // ----------------------------------------------------
    // TAXES & GOVERNMENT
    // ----------------------------------------------------
    ServiceItem(
      id: 'tax_incometax',
      title: 'Income Tax (Challan 280)',
      subtitle: 'Self-assessment & Advance Tax',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF0F172A),
      category: ServiceCategory.taxes,
      badge: 'ITD GOV',
      routeKey: 'tax_income',
    ),
    ServiceItem(
      id: 'tax_gst',
      title: 'GST Payment (PMT-06)',
      subtitle: 'Monthly & quarterly GST challan dues',
      icon: Icons.receipt_rounded,
      color: Color(0xFF2563EB),
      category: ServiceCategory.taxes,
      badge: 'GSTN',
      routeKey: 'tax_gst',
    ),
    ServiceItem(
      id: 'tax_property',
      title: 'Municipal Property Tax',
      subtitle: 'City corporation urban dues',
      icon: Icons.apartment_rounded,
      color: Color(0xFFD97706),
      category: ServiceCategory.taxes,
      routeKey: 'tax_property',
    ),

    // ----------------------------------------------------
    // FINANCIAL TOOLS & CALCULATORS
    // ----------------------------------------------------
    ServiceItem(
      id: 'tool_hub',
      title: 'Calculator Centre',
      subtitle: 'All 10+ financial & tax calculators',
      icon: Icons.calculate_rounded,
      color: Color(0xFF8B5CF6),
      category: ServiceCategory.tools,
      badge: '10 TOOLS',
      routeKey: 'calculators',
    ),
    ServiceItem(
      id: 'tool_emi',
      title: 'EMI & Loan Calculator',
      subtitle: 'Home, car & personal loan monthly EMI',
      icon: Icons.payment_rounded,
      color: Color(0xFF046A38),
      category: ServiceCategory.tools,
      routeKey: 'calc_emi',
    ),
    ServiceItem(
      id: 'tool_sip',
      title: 'SIP Returns Calculator',
      subtitle: 'Calculate wealth compounding over time',
      icon: Icons.query_stats_rounded,
      color: Color(0xFFFF671F),
      category: ServiceCategory.tools,
      routeKey: 'calc_sip',
    ),
    ServiceItem(
      id: 'tool_gst',
      title: 'GST Calculator',
      subtitle: '5%, 12%, 18% & 28% CGST/SGST split',
      icon: Icons.percent_rounded,
      color: Color(0xFF2563EB),
      category: ServiceCategory.tools,
      routeKey: 'calc_gst',
    ),
    ServiceItem(
      id: 'tool_incometax',
      title: 'Income Tax Estimator',
      subtitle: 'New Regime FY 2024-25 / AY 2025-26',
      icon: Icons.summarize_rounded,
      color: Color(0xFF0F172A),
      category: ServiceCategory.tools,
      routeKey: 'calc_tax',
    ),
    ServiceItem(
      id: 'tool_currency',
      title: 'Live Currency Converter',
      subtitle: 'USD, EUR, GBP, AED, SGD live rates',
      icon: Icons.currency_exchange_rounded,
      color: Color(0xFF059669),
      category: ServiceCategory.tools,
      badge: 'LIVE RATES',
      routeKey: 'calc_fx',
    ),

    // ----------------------------------------------------
    // OTHER SUPER-APP SERVICES
    // ----------------------------------------------------
    ServiceItem(
      id: 'oth_business',
      title: 'AikSetra Business Mode',
      subtitle: 'Merchant QR, Invoicing & Daily Reports',
      icon: Icons.storefront_rounded,
      color: Color(0xFF0F172A),
      category: ServiceCategory.other,
      badge: 'MERCHANT',
      routeKey: 'business_mode',
    ),
    ServiceItem(
      id: 'oth_rewards',
      title: 'Rewards & Cashback',
      subtitle: 'AikSetra Coins, Scratch Cards & Coupons',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFD97706),
      category: ServiceCategory.other,
      badge: 'COINS',
      routeKey: 'rewards',
    ),
    ServiceItem(
      id: 'oth_travel',
      title: 'Travel Booking',
      subtitle: 'Flights, IRCTC Trains, Buses & Hotels',
      icon: Icons.airplane_ticket_rounded,
      color: Color(0xFF0284C7),
      category: ServiceCategory.other,
      routeKey: 'travel',
    ),
    ServiceItem(
      id: 'oth_open_acc',
      title: 'Open Bank Account',
      subtitle: 'Zero balance digital savings account',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF046A38),
      category: ServiceCategory.other,
      badge: 'ZERO BAL',
      routeKey: 'open_account',
    ),
    ServiceItem(
      id: 'oth_statements',
      title: 'Statements & Reports',
      subtitle: 'Combined financial statements & CSV/PDF',
      icon: Icons.description_rounded,
      color: Color(0xFF4F46E5),
      category: ServiceCategory.other,
      routeKey: 'statements',
    ),
    ServiceItem(
      id: 'oth_global_fx',
      title: 'Foreign FX Remittance',
      subtitle: 'RBI LRS compliant international wire transfer',
      icon: Icons.public_rounded,
      color: Color(0xFF312E81),
      category: ServiceCategory.other,
      badge: 'GLOBAL',
      routeKey: 'global_fx',
    ),
  ];

  static List<ServiceItem> getPopularServices() {
    return allServices
        .where((s) => [
              'pay_scan',
              'pay_send',
              'bill_electricity',
              'bill_mobile',
              'inv_sip',
              'pay_autopay',
              'tool_hub',
              'oth_business',
              'oth_rewards',
              'oth_travel',
              'tax_incometax',
              'oth_open_acc',
            ].contains(s.id))
        .toList();
  }

  static List<ServiceItem> getByCategory(ServiceCategory category) {
    return allServices.where((s) => s.category == category).toList();
  }
}
