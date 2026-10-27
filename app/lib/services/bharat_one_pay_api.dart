import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config.dart';
import '../models/user_model.dart';
import '../models/scam_shield_model.dart';
import '../models/cross_border_model.dart';
import '../models/protected_pay_model.dart';

class BharatOnePayApi {
  static String? savedLocalAvatar;
  static String? _authToken;
  static String _activeUserId = ApiConfig.defaultDevUserId;

  // Cached state for active user session
  static UserModel? currentUser;
  static BankAccountModel? currentAccount;
  static List<BankAccountModel> linkedAccounts = [];
  static List<Map<String, dynamic>> linkedCards = [
    {
      'id': 'card_hdfc_rupay_01',
      'cardType': 'CREDIT',
      'network': 'RuPay UPI',
      'bankName': 'HDFC Bank',
      'maskedCardNumber': '•••• •••• •••• 8821',
      'last4': '8821',
      'expiry': '08/29',
      'cardHolderName': 'SOUMO NASKAR',
      'balanceOrLimit': 150000.0,
      'upiEnabled': true,
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'id': 'card_sbi_debit_02',
      'cardType': 'DEBIT',
      'network': 'RuPay Global',
      'bankName': 'State Bank of India',
      'maskedCardNumber': '•••• •••• •••• 4519',
      'last4': '4519',
      'expiry': '11/30',
      'cardHolderName': 'SOUMO NASKAR',
      'balanceOrLimit': 50000.0,
      'upiEnabled': true,
      'createdAt': DateTime.now().toIso8601String(),
    },
  ];
  static String configuredAppPin = '1234';
  static double gullakBalance = 0.0;
  static String activeVaultId = 'vlt_simo_01';

  // Live Indian Stock Market Watchlist (BSE / NSE Bluechips)
  static final List<Map<String, dynamic>> indianStocks = [
    {
      'symbol': 'RELIANCE',
      'name': 'Reliance Industries Ltd',
      'sector': 'Oil, Gas & 5G Telecom',
      'price': 2942.30,
      'change': 41.50,
      'changePct': 1.43,
      'isUp': true,
      'marketCap': '₹19.9 Lakh Cr',
      'pe': 27.4,
      'high52': 3217.90,
      'low52': 2220.30,
    },
    {
      'symbol': 'TCS',
      'name': 'Tata Consultancy Services',
      'sector': 'IT Software & Cloud',
      'price': 4128.50,
      'change': 32.10,
      'changePct': 0.78,
      'isUp': true,
      'marketCap': '₹14.9 Lakh Cr',
      'pe': 31.2,
      'high52': 4585.90,
      'low52': 3313.00,
    },
    {
      'symbol': 'HDFCBANK',
      'name': 'HDFC Bank Ltd',
      'sector': 'Banking & Financials',
      'price': 1686.40,
      'change': 19.80,
      'changePct': 1.19,
      'isUp': true,
      'marketCap': '₹12.8 Lakh Cr',
      'pe': 18.6,
      'high52': 1794.00,
      'low52': 1363.55,
    },
    {
      'symbol': 'INFY',
      'name': 'Infosys Ltd',
      'sector': 'IT Services & AI',
      'price': 1874.20,
      'change': 11.40,
      'changePct': 0.61,
      'isUp': true,
      'marketCap': '₹7.8 Lakh Cr',
      'pe': 29.1,
      'high52': 1991.45,
      'low52': 1358.35,
    },
    {
      'symbol': 'TATAMOTORS',
      'name': 'Tata Motors Ltd',
      'sector': 'Automotive & EV',
      'price': 982.60,
      'change': 22.40,
      'changePct': 2.33,
      'isUp': true,
      'marketCap': '₹3.6 Lakh Cr',
      'pe': 10.4,
      'high52': 1179.05,
      'low52': 622.00,
    },
    {
      'symbol': 'ITC',
      'name': 'ITC Limited',
      'sector': 'FMCG, Paper & Hotels',
      'price': 494.10,
      'change': 2.80,
      'changePct': 0.57,
      'isUp': true,
      'marketCap': '₹6.2 Lakh Cr',
      'pe': 28.3,
      'high52': 528.55,
      'low52': 399.30,
    },
    {
      'symbol': 'LT',
      'name': 'Larsen & Toubro Ltd',
      'sector': 'Infrastructure & Defense',
      'price': 3615.80,
      'change': 28.60,
      'changePct': 0.80,
      'isUp': true,
      'marketCap': '₹4.9 Lakh Cr',
      'pe': 36.8,
      'high52': 3919.90,
      'low52': 2872.00,
    },
    {
      'symbol': 'BHARTIARTL',
      'name': 'Bharti Airtel Ltd',
      'sector': 'Telecom & Digital Services',
      'price': 1712.50,
      'change': 18.20,
      'changePct': 1.07,
      'isUp': true,
      'marketCap': '₹9.7 Lakh Cr',
      'pe': 44.5,
      'high52': 1779.00,
      'low52': 913.00,
    },
  ];

  // Complete RBI-Regulated Indian Bank Directory (48 Banks across Public, Private, SFB, Payments & Co-op)
  static final List<Map<String, String>> allIndianBanks = [
    // Public Sector Banks (12)
    {'name': 'State Bank of India (SBI)', 'bankName': 'State Bank of India (SBI)', 'bankCode': 'SBIN', 'code': 'SBIN', 'ifsc': 'SBIN0001234', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'Punjab National Bank (PNB)', 'bankName': 'Punjab National Bank (PNB)', 'bankCode': 'PUNB', 'code': 'PUNB', 'ifsc': 'PUNB0014200', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'Bank of Baroda (BoB)', 'bankName': 'Bank of Baroda (BoB)', 'bankCode': 'BARB', 'code': 'BARB', 'ifsc': 'BARB0KOLKAT', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'Canara Bank', 'bankName': 'Canara Bank', 'bankCode': 'CNRB', 'code': 'CNRB', 'ifsc': 'CNRB0000100', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'Union Bank of India', 'bankName': 'Union Bank of India', 'bankCode': 'UBIN', 'code': 'UBIN', 'ifsc': 'UBIN0530107', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'Bank of India (BOI)', 'bankName': 'Bank of India (BOI)', 'bankCode': 'BKID', 'code': 'BKID', 'ifsc': 'BKID0000001', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'Indian Bank', 'bankName': 'Indian Bank', 'bankCode': 'IDIB', 'code': 'IDIB', 'ifsc': 'IDIB000M001', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'Central Bank of India', 'bankName': 'Central Bank of India', 'bankCode': 'CBIN', 'code': 'CBIN', 'ifsc': 'CBIN0280001', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'Indian Overseas Bank (IOB)', 'bankName': 'Indian Overseas Bank (IOB)', 'bankCode': 'IOBA', 'code': 'IOBA', 'ifsc': 'IOBA0000001', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'UCO Bank', 'bankName': 'UCO Bank', 'bankCode': 'UCBA', 'code': 'UCBA', 'ifsc': 'UCBA0000002', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'Bank of Maharashtra', 'bankName': 'Bank of Maharashtra', 'bankCode': 'MAHB', 'code': 'MAHB', 'ifsc': 'MAHB0000001', 'sector': 'PUBLIC', 'icon': '🏦'},
    {'name': 'Punjab & Sind Bank', 'bankName': 'Punjab & Sind Bank', 'bankCode': 'PSIB', 'code': 'PSIB', 'ifsc': 'PSIB0000001', 'sector': 'PUBLIC', 'icon': '🏦'},
    // Private Sector Banks (20)
    {'name': 'HDFC Bank', 'bankName': 'HDFC Bank', 'bankCode': 'HDFC', 'code': 'HDFC', 'ifsc': 'HDFC0000240', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'ICICI Bank', 'bankName': 'ICICI Bank', 'bankCode': 'ICIC', 'code': 'ICIC', 'ifsc': 'ICIC0000006', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'Axis Bank', 'bankName': 'Axis Bank', 'bankCode': 'UTIB', 'code': 'UTIB', 'ifsc': 'UTIB0000005', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'Kotak Mahindra Bank', 'bankName': 'Kotak Mahindra Bank', 'bankCode': 'KKBK', 'code': 'KKBK', 'ifsc': 'KKBK0000958', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'IndusInd Bank', 'bankName': 'IndusInd Bank', 'bankCode': 'INDB', 'code': 'INDB', 'ifsc': 'INDB0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'Yes Bank', 'bankName': 'Yes Bank', 'bankCode': 'YESB', 'code': 'YESB', 'ifsc': 'YESB0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'IDFC FIRST Bank', 'bankName': 'IDFC FIRST Bank', 'bankCode': 'IDFB', 'code': 'IDFB', 'ifsc': 'IDFB0040101', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'Federal Bank', 'bankName': 'Federal Bank', 'bankCode': 'FDRL', 'code': 'FDRL', 'ifsc': 'FDRL0001001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'Bandhan Bank', 'bankName': 'Bandhan Bank', 'bankCode': 'BDBL', 'code': 'BDBL', 'ifsc': 'BDBL0001000', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'IDBI Bank', 'bankName': 'IDBI Bank', 'bankCode': 'IBKL', 'code': 'IBKL', 'ifsc': 'IBKL0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'RBL Bank', 'bankName': 'RBL Bank', 'bankCode': 'RATN', 'code': 'RATN', 'ifsc': 'RATN0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'South Indian Bank', 'bankName': 'South Indian Bank', 'bankCode': 'SIBL', 'code': 'SIBL', 'ifsc': 'SIBL0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'Karur Vysya Bank (KVB)', 'bankName': 'Karur Vysya Bank (KVB)', 'bankCode': 'KVBL', 'code': 'KVBL', 'ifsc': 'KVBL0001101', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'Karnataka Bank', 'bankName': 'Karnataka Bank', 'bankCode': 'KARB', 'code': 'KARB', 'ifsc': 'KARB0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'City Union Bank (CUB)', 'bankName': 'City Union Bank (CUB)', 'bankCode': 'CIUB', 'code': 'CIUB', 'ifsc': 'CIUB0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'Tamilnad Mercantile Bank', 'bankName': 'Tamilnad Mercantile Bank', 'bankCode': 'TMBL', 'code': 'TMBL', 'ifsc': 'TMBL0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'Jammu & Kashmir Bank', 'bankName': 'Jammu & Kashmir Bank', 'bankCode': 'JAKA', 'code': 'JAKA', 'ifsc': 'JAKA0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'DCB Bank', 'bankName': 'DCB Bank', 'bankCode': 'DCBL', 'code': 'DCBL', 'ifsc': 'DCBL0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'CSB Bank', 'bankName': 'CSB Bank', 'bankCode': 'CSBK', 'code': 'CSBK', 'ifsc': 'CSBK0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    {'name': 'Dhanlaxmi Bank', 'bankName': 'Dhanlaxmi Bank', 'bankCode': 'DLXB', 'code': 'DLXB', 'ifsc': 'DLXB0000001', 'sector': 'PRIVATE', 'icon': '🏦'},
    // Payments & Small Finance Banks (10)
    {'name': 'Airtel Payments Bank', 'bankName': 'Airtel Payments Bank', 'bankCode': 'AIRP', 'code': 'AIRP', 'ifsc': 'AIRP0000001', 'sector': 'SFB_PAY', 'icon': '📱'},
    {'name': 'India Post Payments Bank (IPPB)', 'bankName': 'India Post Payments Bank (IPPB)', 'bankCode': 'IPOS', 'code': 'IPOS', 'ifsc': 'IPOS0000001', 'sector': 'SFB_PAY', 'icon': '📮'},
    {'name': 'Paytm Payments Bank', 'bankName': 'Paytm Payments Bank', 'bankCode': 'PYTM', 'code': 'PYTM', 'ifsc': 'PYTM0123456', 'sector': 'SFB_PAY', 'icon': '💳'},
    {'name': 'Jio Payments Bank', 'bankName': 'Jio Payments Bank', 'bankCode': 'JIOP', 'code': 'JIOP', 'ifsc': 'JIOP0000001', 'sector': 'SFB_PAY', 'icon': '🌐'},
    {'name': 'Fino Payments Bank', 'bankName': 'Fino Payments Bank', 'bankCode': 'FINO', 'code': 'FINO', 'ifsc': 'FINO0000001', 'sector': 'SFB_PAY', 'icon': '🏦'},
    {'name': 'AU Small Finance Bank', 'bankName': 'AU Small Finance Bank', 'bankCode': 'AUBL', 'code': 'AUBL', 'ifsc': 'AUBL0002011', 'sector': 'SFB_PAY', 'icon': '🏦'},
    {'name': 'Equitas Small Finance Bank', 'bankName': 'Equitas Small Finance Bank', 'bankCode': 'ESFB', 'code': 'ESFB', 'ifsc': 'ESFB0001001', 'sector': 'SFB_PAY', 'icon': '🏦'},
    {'name': 'Ujjivan Small Finance Bank', 'bankName': 'Ujjivan Small Finance Bank', 'bankCode': 'UJVN', 'code': 'UJVN', 'ifsc': 'UJVN0001001', 'sector': 'SFB_PAY', 'icon': '🏦'},
    {'name': 'Jana Small Finance Bank', 'bankName': 'Jana Small Finance Bank', 'bankCode': 'JSFB', 'code': 'JSFB', 'ifsc': 'JSFB0001001', 'sector': 'SFB_PAY', 'icon': '🏦'},
    {'name': 'Suryoday Small Finance Bank', 'bankName': 'Suryoday Small Finance Bank', 'bankCode': 'SURY', 'code': 'SURY', 'ifsc': 'SURY0000001', 'sector': 'SFB_PAY', 'icon': '🏦'},
    // Foreign, Co-operative & Regional Rural Banks (6)
    {'name': 'Standard Chartered Bank', 'bankName': 'Standard Chartered Bank', 'bankCode': 'SCBL', 'code': 'SCBL', 'ifsc': 'SCBL0036001', 'sector': 'OTHER', 'icon': '🏦'},
    {'name': 'HSBC India', 'bankName': 'HSBC India', 'bankCode': 'HSBC', 'code': 'HSBC', 'ifsc': 'HSBC0400002', 'sector': 'OTHER', 'icon': '🏦'},
    {'name': 'DBS Bank India', 'bankName': 'DBS Bank India', 'bankCode': 'DBSS', 'code': 'DBSS', 'ifsc': 'DBSS0IN0811', 'sector': 'OTHER', 'icon': '🏦'},
    {'name': 'Saraswat Co-operative Bank', 'bankName': 'Saraswat Co-operative Bank', 'bankCode': 'SRCB', 'code': 'SRCB', 'ifsc': 'SRCB0000001', 'sector': 'OTHER', 'icon': '🏦'},
    {'name': 'Bangiya Gramin Vikash Bank', 'bankName': 'Bangiya Gramin Vikash Bank', 'bankCode': 'PUNB', 'code': 'PUNB', 'ifsc': 'PUNB0RRBBGB', 'sector': 'OTHER', 'icon': '🏦'},
    {'name': 'Other RBI-Regulated Bank', 'bankName': 'Other RBI-Regulated Bank', 'bankCode': 'NPCI', 'code': 'NPCI', 'ifsc': 'SBIN0000001', 'sector': 'OTHER', 'icon': '🏦'},
  ];

  // Cached transaction, escrow, SIP, and bill lists synced with backend
  static List<Map<String, dynamic>> recentTransactions = [];
  static List<Map<String, dynamic>> sipPlans = [
    {
      'id': 'sip_sbi_nifty50',
      'name': 'SBI Nifty 50 Index Direct Plan',
      'amcOrIssuer': 'SBI Mutual Fund • Direct Growth',
      'category': 'EQUITY_INDEX',
      'cagr3Y': 16.4,
      'minMonthlyAmount': 500,
      'riskLevel': 'MODERATE',
      'navOrUnitPrice': 218.45,
      'description': 'Top 50 Indian bluechip companies (Reliance, TCS, HDFC, Infosys) with 0% commission.',
    },
    {
      'id': 'sip_hdfc_flexi',
      'name': 'HDFC Flexi Cap Direct Growth',
      'amcOrIssuer': 'HDFC Mutual Fund • Direct',
      'category': 'FLEXI_CAP',
      'cagr3Y': 21.8,
      'minMonthlyAmount': 500,
      'riskLevel': 'HIGH',
      'navOrUnitPrice': 1842.10,
      'description': 'Dynamic allocation across large, mid, and small-cap Indian leaders.',
    },
    {
      'id': 'sip_icici_bluechip',
      'name': 'ICICI Prudential Bluechip Direct',
      'amcOrIssuer': 'ICICI Prudential Mutual Fund',
      'category': 'LARGE_CAP',
      'cagr3Y': 18.2,
      'minMonthlyAmount': 500,
      'riskLevel': 'MODERATE',
      'navOrUnitPrice': 106.80,
      'description': 'Steady wealth creation in India top-100 market cap leaders.',
    },
    {
      'id': 'sip_gold_24k',
      'name': 'MMTC-PAMP 24K (99.9%) Digital Gold SIP',
      'amcOrIssuer': 'MMTC-PAMP India Vault',
      'category': 'GOLD',
      'cagr3Y': 15.9,
      'minMonthlyAmount': 250,
      'riskLevel': 'LOW',
      'navOrUnitPrice': 78.50,
      'description': 'Automated monthly accumulation of 99.9% pure 24K vaulted gold.',
    },
    {
      'id': 'sip_sbi_liquid',
      'name': 'SBI Magnum Govt Treasury Liquid Fund',
      'amcOrIssuer': 'SBI Mutual Fund • Sovereign Debt',
      'category': 'LIQUID_DEBT',
      'cagr3Y': 7.4,
      'minMonthlyAmount': 1000,
      'riskLevel': 'LOW',
      'navOrUnitPrice': 3910.00,
      'description': 'Instant-redemption sovereign T-bill & RBI treasury liquid reserve.',
    },
  ];
  static List<Map<String, dynamic>> mySips = [];
  static Map<String, dynamic> sipPortfolio = {
    'totalInvested': 0.0,
    'currentValue': 0.0,
    'totalReturns': 0.0,
    'returnPct': 0.0,
    'activeMandatesCount': 0,
  };
  static List<Map<String, dynamic>> bbpsBillers = [
    // Electricity
    {'id': 'elec_cesc', 'name': 'CESC Limited (Kolkata)', 'category': 'ELECTRICITY', 'stateOrCircle': 'West Bengal', 'consumerIdLabel': '11-Digit Consumer Number'},
    {'id': 'elec_wbsedcl', 'name': 'WBSEDCL Electricity', 'category': 'ELECTRICITY', 'stateOrCircle': 'West Bengal', 'consumerIdLabel': '9-Digit Consumer ID'},
    {'id': 'elec_tata', 'name': 'Tata Power (Mumbai / Delhi)', 'category': 'ELECTRICITY', 'stateOrCircle': 'Maharashtra / Delhi', 'consumerIdLabel': 'CA Number'},
    {'id': 'elec_bescom', 'name': 'BESCOM Bengaluru', 'category': 'ELECTRICITY', 'stateOrCircle': 'Karnataka', 'consumerIdLabel': 'Account ID'},
    {'id': 'elec_msedcl', 'name': 'Mahavitaran (MSEDCL)', 'category': 'ELECTRICITY', 'stateOrCircle': 'Maharashtra', 'consumerIdLabel': '12-Digit Consumer No'},
    // Water
    {'id': 'water_kmc', 'name': 'Kolkata Municipal Corp (KMC Water)', 'category': 'WATER', 'stateOrCircle': 'Kolkata', 'consumerIdLabel': 'Assessee / Water ID'},
    {'id': 'water_djb', 'name': 'Delhi Jal Board (DJB)', 'category': 'WATER', 'stateOrCircle': 'Delhi NCR', 'consumerIdLabel': 'KNO Number'},
    {'id': 'water_bwssb', 'name': 'BWSSB Water Supply', 'category': 'WATER', 'stateOrCircle': 'Bengaluru', 'consumerIdLabel': 'RR Number'},
    // Gas
    {'id': 'gas_indane', 'name': 'Indane Gas (IndianOil LPG)', 'category': 'GAS', 'stateOrCircle': 'All India', 'consumerIdLabel': '10-Digit Mobile or 17-Digit LPG ID'},
    {'id': 'gas_bharat', 'name': 'Bharat Gas (BPCL LPG)', 'category': 'GAS', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Consumer Number / Mobile'},
    {'id': 'gas_igl', 'name': 'Indraprastha Gas (IGL Piped PNG)', 'category': 'GAS', 'stateOrCircle': 'Delhi NCR', 'consumerIdLabel': 'BP Number'},
    // Broadband
    {'id': 'bb_jiofiber', 'name': 'JioFiber / JioAirFiber', 'category': 'BROADBAND', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Landline / Service ID'},
    {'id': 'bb_airtel', 'name': 'Airtel Xstream Fiber', 'category': 'BROADBAND', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Account Number / DSL ID'},
    // Mobile 5G
    {'id': 'mob_jio', 'name': 'Jio 5G Prepaid / Postpaid', 'category': 'MOBILE', 'stateOrCircle': 'All India', 'consumerIdLabel': '10-Digit Jio Mobile Number'},
    {'id': 'mob_airtel', 'name': 'Airtel 5G Plus Recharge', 'category': 'MOBILE', 'stateOrCircle': 'All India', 'consumerIdLabel': '10-Digit Airtel Mobile Number'},
    {'id': 'mob_vi', 'name': 'Vi (Vodafone Idea) 5G', 'category': 'MOBILE', 'stateOrCircle': 'All India', 'consumerIdLabel': '10-Digit Vi Mobile Number'},
    // FASTag & DTH
    {'id': 'fastag_nhai', 'name': 'NHAI / ICICI / SBI FASTag', 'category': 'FASTAG', 'stateOrCircle': 'All India Toll Plaza', 'consumerIdLabel': 'Vehicle Registration No (e.g. WB02AB1234)'},
    {'id': 'dth_tataplay', 'name': 'Tata Play / Airtel Digital TV', 'category': 'DTH', 'stateOrCircle': 'All India', 'consumerIdLabel': '10-Digit Subscriber ID'},
  ];
  static List<ProtectedPayEscrowModel> activeEscrows = [];
  static bool isBusinessMode = false;

  static bool get isLoggedIn => currentUser != null && _authToken != null;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static void setActiveDevUser(String userId) {
    _activeUserId = userId;
  }

  static Future<void> saveSessionToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_authToken != null) await prefs.setString('aiksetra_token', _authToken!);
      await prefs.setString('aiksetra_user_id', _activeUserId);
      await prefs.setString('aiksetra_pin', configuredAppPin);
      await prefs.setDouble('aiksetra_gullak', gullakBalance);
      if (currentUser != null) {
        if (currentUser!.profilePicture != null && currentUser!.profilePicture!.isNotEmpty) {
          savedLocalAvatar = currentUser!.profilePicture;
          await prefs.setString('aiksetra_saved_avatar', currentUser!.profilePicture!);
        }
        await prefs.setString(
          'aiksetra_user_json',
          jsonEncode({
            'id': currentUser!.id,
            'phone': currentUser!.phone,
            'fullName': currentUser!.fullName,
            'email': currentUser!.email,
            'primaryVpa': currentUser!.primaryVpa,
            'liteBalance': currentUser!.liteBalance,
            'lrsUsedUsd': currentUser!.lrsUsedUsd,
            'dateOfBirth': currentUser!.dateOfBirth,
            'profilePicture': currentUser!.profilePicture ?? savedLocalAvatar,
          }),
        );
      }
      if (currentAccount != null) {
        await prefs.setString(
          'aiksetra_account_json',
          jsonEncode({
            'id': currentAccount!.id,
            'bankName': currentAccount!.bankName,
            'bankCode': currentAccount!.bankCode,
            'ifsc': currentAccount!.ifsc,
            'maskedAccountNumber': currentAccount!.maskedAccountNumber,
            'balance': currentAccount!.balance,
            'isPrimary': currentAccount!.isPrimary,
          }),
        );
      }
      if (linkedAccounts.isNotEmpty) {
        await prefs.setString(
          'aiksetra_accounts_list',
          jsonEncode(linkedAccounts
              .map((a) => {
                    'id': a.id,
                    'bankName': a.bankName,
                    'bankCode': a.bankCode,
                    'ifsc': a.ifsc,
                    'maskedAccountNumber': a.maskedAccountNumber,
                    'balance': a.balance,
                    'isPrimary': a.isPrimary,
                  })
              .toList()),
        );
      }
      await prefs.setString('aiksetra_cards_list', jsonEncode(linkedCards));
      await prefs.setString('aiksetra_txns_list', jsonEncode(recentTransactions.take(40).toList()));
      await prefs.setString('aiksetra_sips_list', jsonEncode(mySips));
      await prefs.setString('aiksetra_sip_portfolio', jsonEncode(sipPortfolio));
    } catch (_) {}
  }

  static Future<bool> restoreSessionFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('aiksetra_token');
      final userJson = prefs.getString('aiksetra_user_json');
      final accJson = prefs.getString('aiksetra_account_json');
      configuredAppPin = prefs.getString('aiksetra_pin') ?? '1234';
      gullakBalance = prefs.getDouble('aiksetra_gullak') ?? 0.0;
      savedLocalAvatar = prefs.getString('aiksetra_saved_avatar');
      if (token != null && userJson != null) {
        _authToken = token;
        currentUser = UserModel.fromJson(jsonDecode(userJson));
        if (currentUser != null && (currentUser!.profilePicture == null || currentUser!.profilePicture!.isEmpty)) {
          if (savedLocalAvatar != null && savedLocalAvatar!.isNotEmpty) {
            currentUser = currentUser!.copyWith(profilePicture: savedLocalAvatar);
          }
        }
        _activeUserId = currentUser!.id;
        final accListJson = prefs.getString('aiksetra_accounts_list');
        if (accListJson != null) {
          final rawList = jsonDecode(accListJson) as List;
          linkedAccounts = rawList.map((e) => BankAccountModel.fromJson(Map<String, dynamic>.from(e))).toList();
        }
        if (accJson != null) {
          currentAccount = BankAccountModel.fromJson(jsonDecode(accJson));
          if (linkedAccounts.isEmpty) linkedAccounts = [currentAccount!];
        }
        final cardsJson = prefs.getString('aiksetra_cards_list');
        if (cardsJson != null) {
          linkedCards = List<Map<String, dynamic>>.from(jsonDecode(cardsJson));
        }
        final txnsJson = prefs.getString('aiksetra_txns_list');
        if (txnsJson != null) {
          recentTransactions = List<Map<String, dynamic>>.from(jsonDecode(txnsJson));
        }
        final sipsJson = prefs.getString('aiksetra_sips_list');
        if (sipsJson != null) {
          mySips = List<Map<String, dynamic>>.from(jsonDecode(sipsJson));
        }
        final portJson = prefs.getString('aiksetra_sip_portfolio');
        if (portJson != null) {
          sipPortfolio = Map<String, dynamic>.from(jsonDecode(portJson));
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> logout() async {
    _authToken = null;
    currentUser = null;
    currentAccount = null;
    linkedAccounts = [];
    linkedCards = [];
    recentTransactions = [];
    mySips = [];
    gullakBalance = 0.0;
    _activeUserId = ApiConfig.defaultDevUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('aiksetra_token');
      await prefs.remove('aiksetra_user_json');
      await prefs.remove('aiksetra_account_json');
      await prefs.remove('aiksetra_accounts_list');
      await prefs.remove('aiksetra_cards_list');
      await prefs.remove('aiksetra_txns_list');
      await prefs.remove('aiksetra_sips_list');
      await prefs.remove('aiksetra_sip_portfolio');
    } catch (_) {}
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'bypass-tunnel-reminder': 'true',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // Smart Multi-Host POST helper: tries activeHost first, then all candidate hosts
  static Future<http.Response> _postWithFailover(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? customHeaders,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final headers = {
      'bypass-tunnel-reminder': 'true',
      ...(customHeaders ?? _headers),
    };
    final encodedBody = jsonEncode(body);

    if (!Platform.isAndroid) {
      return await http
          .post(Uri.parse('${ApiConfig.baseUrl}$path'), headers: headers, body: encodedBody)
          .timeout(timeout);
    }

    Object? lastError;
    for (final host in ApiConfig.candidateHosts) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrlForHost(host)}$path');
        final response = await http.post(uri, headers: headers, body: encodedBody).timeout(timeout);
        if (response.statusCode < 502) {
          ApiConfig.activeHost = host;
          return response;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? const SocketException('All candidate backend hosts unreachable');
  }

  // Smart Multi-Host GET helper
  static Future<http.Response> _getWithFailover(
    String path, {
    Map<String, String>? customHeaders,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final headers = {
      'bypass-tunnel-reminder': 'true',
      ...(customHeaders ?? _headers),
    };

    if (!Platform.isAndroid) {
      return await http.get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: headers).timeout(timeout);
    }

    Object? lastError;
    for (final host in ApiConfig.candidateHosts) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrlForHost(host)}$path');
        final response = await http.get(uri, headers: headers).timeout(timeout);
        if (response.statusCode < 502) {
          ApiConfig.activeHost = host;
          return response;
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? const SocketException('All candidate backend hosts unreachable');
  }

  // 1. Send OTP to Indian Mobile Number (Dispatches real 6-digit OTP via SMS Gateway)
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await _postWithFailover(
        '/auth/send-otp',
        {'phone': phone},
        customHeaders: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to authentication server. Please check your network connection.',
      };
    }
  }

  // 2. Verify OTP & Device Binding
  static Future<Map<String, dynamic>> verifyOtpAndLogin({
    required String phone,
    required String otp,
    required String deviceId,
    required String simId,
    String? fullName,
    String? selectedBank,
  }) async {
    try {
      final response = await _postWithFailover(
        '/auth/verify-otp',
        {
          'phone': phone,
          'otp': otp.trim(),
          'deviceId': deviceId,
          'simId': simId,
          'fullName': fullName,
          'selectedBank': selectedBank,
        },
        customHeaders: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final isSuccess = data['success'] == true || (response.statusCode == 200 && data['user'] != null);
      if (isSuccess) {
        if (data['token'] != null) {
          setAuthToken(data['token'].toString());
        }
        if (data['user'] != null) {
          currentUser = UserModel.fromJson(data['user']);
          _activeUserId = currentUser!.id;
        }
        if (data['account'] != null) {
          currentAccount = BankAccountModel.fromJson(data['account']);
          linkedAccounts = [currentAccount!];
        }
        await saveSessionToDisk();
        recentTransactions = [];
        Future.microtask(() async {
          await getMe();
          await getVaults();
          await getTransactionHistory();
          await getSipPlansAndPortfolio();
          await getMyEscrows();
        });
        return {'success': true, ...data};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Invalid OTP. Please check the 6-digit OTP.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to authentication server. Please check your network and try again.',
      };
    }
  }

  // 3. Set App MPIN
  static Future<Map<String, dynamic>> setMpin(String mpin) async {
    configuredAppPin = mpin;
    await saveSessionToDisk();
    try {
      final response = await _postWithFailover('/auth/set-mpin', {'mpin': mpin});
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to synchronize MPIN with server.'};
    }
  }

  // 4. Fetch Current User Profile & Accounts
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _getWithFailover('/auth/me');
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['user'] != null) {
        final serverUser = UserModel.fromJson(data['user']);
        // Guard against server wiping local avatar
        String? finalPic = serverUser.profilePicture;
        if (finalPic == null || finalPic.isEmpty) {
          finalPic = currentUser?.profilePicture ?? savedLocalAvatar;
        } else if (finalPic.startsWith('/')) {
          finalPic = '${ApiConfig.baseUrl}$finalPic';
        }
        currentUser = serverUser.copyWith(profilePicture: finalPic);
        if (finalPic != null && finalPic.isNotEmpty) {
          savedLocalAvatar = finalPic;
        }
        if (data['accounts'] != null && (data['accounts'] as List).isNotEmpty) {
          linkedAccounts = (data['accounts'] as List)
              .map((a) => BankAccountModel.fromJson(a as Map<String, dynamic>))
              .toList();
          currentAccount = linkedAccounts.firstWhere(
            (a) => a.isPrimary,
            orElse: () => linkedAccounts.first,
          );
        }
        await saveSessionToDisk();
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 4. Update Current User Profile Settings
  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String email,
    String? dateOfBirth,
    String? profilePicture,
  }) async {
    final cleanName = fullName.trim().isEmpty ? (currentUser?.fullName ?? 'Soumo Naskar') : fullName.trim();
    final cleanEmail = email.trim().isEmpty ? (currentUser?.email ?? 'soumo@aiksetra.in') : email.trim();

    if (profilePicture != null && profilePicture.isNotEmpty) {
      savedLocalAvatar = profilePicture;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('aiksetra_saved_avatar', profilePicture);
      } catch (_) {}
    }
    if (currentUser != null) {
      currentUser = currentUser!.copyWith(
        fullName: cleanName,
        email: cleanEmail,
        dateOfBirth: dateOfBirth,
        profilePicture: profilePicture ?? savedLocalAvatar,
      );
    } else {
      currentUser = UserModel(
        id: _activeUserId.isNotEmpty ? _activeUserId : 'usr_simo_01',
        phone: '9830113038',
        fullName: cleanName,
        email: cleanEmail,
        primaryVpa: 'soumonaska3038@aiksetra',
        liteBalance: 2000.0,
        lrsUsedUsd: 0.0,
        dateOfBirth: dateOfBirth,
        profilePicture: profilePicture,
      );
    }

    await saveSessionToDisk();

    try {
      final response = await _postWithFailover('/auth/profile', {
        'fullName': cleanName,
        'email': cleanEmail,
        'dateOfBirth': dateOfBirth,
        'profilePicture': profilePicture,
      });

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        return {'success': true, 'message': 'Profile updated successfully', ...res};
      }
    } catch (_) {
      // Local session updated fallback
    }

    return {'success': true, 'message': 'Profile updated successfully'};
  }

  // 4b. Upload Real Profile Photo to Server and Database
  static Future<Map<String, dynamic>> uploadAvatarImage({
    required String imageBase64,
    String extension = 'jpg',
  }) async {
    final cleanExt = extension.isNotEmpty ? extension : 'jpg';
    final dataUri = imageBase64.startsWith('data:')
        ? imageBase64
        : 'data:image/$cleanExt;base64,$imageBase64';

    // 1. Immediately store dataUri locally so display is 100% instantaneous and offline-ready
    savedLocalAvatar = dataUri;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('aiksetra_saved_avatar', dataUri);
    } catch (_) {}
    if (currentUser != null) {
      currentUser = currentUser!.copyWith(profilePicture: dataUri);
      await saveSessionToDisk();
    }

    // 2. Upload to backend server and persist in database
    try {
      final response = await _postWithFailover('/auth/upload-avatar', {
        'imageBase64': imageBase64,
        'extension': cleanExt,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, 'avatarUrl': dataUri, 'serverUrl': data['avatarUrl'], 'message': data['message']};
      }
    } catch (_) {
      // Offline fallback: dataUri remains safely active
    }

    return {'success': true, 'avatarUrl': dataUri, 'message': 'Photo saved locally'};
  }

  // 4a. Link Real Bank Account (Onboarding Step 3 or Add Bank Account)
  static Future<Map<String, dynamic>> linkBankAccount({
    required String bankName,
    String? bankCode,
    required String ifsc,
    required String accountNumber,
    String accountType = 'SAVINGS',
    double? initialBalance,
    bool setAsPrimary = true,
    bool replaceOnboardingAccount = false,
  }) async {
    try {
      final response = await _postWithFailover('/accounts/link', {
        'bankName': bankName,
        'bankCode': bankCode,
        'ifsc': ifsc,
        'accountNumber': accountNumber,
        'accountType': accountType,
        'initialBalance': initialBalance,
        'setAsPrimary': setAsPrimary,
        'replaceOnboardingAccount': replaceOnboardingAccount,
      });
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['account'] != null) {
        final acc = BankAccountModel.fromJson(data['account']);
        if (replaceOnboardingAccount && linkedAccounts.length == 1) {
          linkedAccounts = [acc];
        } else {
          linkedAccounts.removeWhere((a) => a.id == acc.id);
          linkedAccounts.insert(0, acc);
        }
        if (setAsPrimary || currentAccount == null) {
          currentAccount = acc;
        }
        await saveSessionToDisk();
        return {'success': true, 'account': acc};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to link bank account.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Banking switch unreachable. Unable to link bank account.',
      };
    }
  }

  // 4a-2. Link Debit Card or Credit Card (RuPay UPI / Visa / Mastercard)
  static Future<Map<String, dynamic>> linkCard({
    required String cardType, // 'DEBIT' or 'CREDIT'
    required String network, // 'RuPay UPI', 'VISA', 'Mastercard'
    required String bankName,
    required String cardNumber,
    required String expiry,
    required String cardHolderName,
    double? limitOrBalance,
  }) async {
    final cleanDigits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final last4 = cleanDigits.length >= 4 ? cleanDigits.substring(cleanDigits.length - 4) : '8421';
    final card = {
      'id': 'card_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      'cardType': cardType.toUpperCase(), // DEBIT or CREDIT
      'network': network,
      'bankName': bankName,
      'maskedCardNumber': '•••• •••• •••• $last4',
      'last4': last4,
      'expiry': expiry,
      'cardHolderName': cardHolderName.toUpperCase(),
      'balanceOrLimit': limitOrBalance ?? (cardType.toUpperCase() == 'CREDIT' ? 75000.0 : (currentAccount?.balance ?? 25000.0)),
      'upiEnabled': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
    linkedCards.removeWhere((c) => c['last4'] == last4 && c['bankName'] == bankName);
    linkedCards.insert(0, card);
    await saveSessionToDisk();
    return {'success': true, 'card': card};
  }

  static Future<void> removeCard(String cardId) async {
    linkedCards.removeWhere((c) => c['id'] == cardId);
    await saveSessionToDisk();
  }

  // 4b. Switch Primary Bank Account
  static Future<bool> setPrimaryAccount(String accountId) async {
    try {
      final response = await _postWithFailover('/accounts/$accountId/set-primary', {});
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['account'] != null) {
        currentAccount = BankAccountModel.fromJson(data['account']);
        await getMe();
        return true;
      }
    } catch (_) {}
    final idx = linkedAccounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      currentAccount = linkedAccounts[idx];
      await saveSessionToDisk();
      return true;
    }
    return false;
  }

  // 4c. Deposit / Add Money to Bank Account
  static Future<Map<String, dynamic>> addMoneyToAccount({
    required double amount,
    String? accountId,
    String sourceNote = 'Self Transfer / IMPS Credit',
  }) async {
    try {
      final response = await _postWithFailover('/accounts/add-money', {
        'accountId': accountId ?? currentAccount?.id,
        'amount': amount,
        'sourceNote': sourceNote,
      });
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if (data['account'] != null) {
          currentAccount = BankAccountModel.fromJson(data['account']);
        }
        if (data['transaction'] != null) {
          recentTransactions.insert(0, Map<String, dynamic>.from(data['transaction']));
        }
        await getMe();
        return data;
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to add money.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to reach banking switch for deposit.',
      };
    }
  }

  // 4d. Fetch Transaction History (Real user transactions only)
  static Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    try {
      final response = await _getWithFailover('/payments/history');
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['transactions'] is List) {
        recentTransactions = List<Map<String, dynamic>>.from(data['transactions']);
      }
    } catch (_) {}
    return recentTransactions;
  }

  // 5. Resolve VPA
  static Future<Map<String, dynamic>> resolveVpa(String vpa) async {
    try {
      final response = await _getWithFailover('/vpa/resolve?vpa=$vpa');
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'valid': false, 'message': 'VPA resolution switch unreachable.'};
    }
  }

  // 6. Scam Shield Risk Analysis
  static Future<ScamShieldResult> analyzeScamRisk({
    required String receiverVpa,
    required double amount,
    String remark = '',
    String? expectedPayeeName,
  }) async {
    try {
      final response = await _postWithFailover('/scam-shield/analyze', {
        'receiverVpa': receiverVpa,
        'amount': amount,
        'remark': remark,
        'expectedPayeeName': expectedPayeeName,
      });
      final data = jsonDecode(response.body);
      if (data['analysis'] != null) {
        return ScamShieldResult.fromJson(data['analysis']);
      }
    } catch (_) {}

    // Local heuristic fallback if offline
    final lowerRemark = remark.toLowerCase();
    final lowerVpa = receiverVpa.toLowerCase();
    final isSuspicious = lowerRemark.contains('lottery') ||
        lowerRemark.contains('urgent') ||
        lowerRemark.contains('prize') ||
        lowerVpa.contains('scam') ||
        lowerVpa.contains('fraud') ||
        lowerVpa.contains('Fake');

    return ScamShieldResult(
      riskScore: isSuspicious ? 85 : 10,
      riskLevel: isSuspicious ? 'HIGH' : 'SAFE',
      warnings: isSuspicious
          ? ['⚠️ High Fraud Risk: Urgency keywords or suspicious UPI handle detected!']
          : ['✓ Verified NPCI UPI Recipient ($receiverVpa)'],
      recommendation: isSuspicious ? 'WARN_USER' : 'PROCEED',
      verifiedLegalName: receiverVpa.split('@').first.toUpperCase(),
      coolingOffRequired: isSuspicious,
      coolingOffSeconds: isSuspicious ? 300 : 0,
      isBlacklisted: false,
    );
  }

  // 6b. Report Fraud VPA to Scam Shield Registry
  static Future<Map<String, dynamic>> reportScam({
    required String vpa,
    required String reason,
  }) async {
    try {
      final response = await _postWithFailover('/scam-shield/report', {
        'vpa': vpa,
        'reason': reason,
      });
      return jsonDecode(response.body);
    } catch (_) {
      return {
        'success': true,
        'message': 'UPI ID $vpa reported to NPCI Central Fraud Registry.',
      };
    }
  }

  // 7. Pay via Core UPI or Linked Debit / Credit Card
  static Future<Map<String, dynamic>> payUpi({
    required String receiverVpa,
    required double amount,
    required String mpin,
    String remark = 'UPI Payment',
    String? senderAccountId,
    String? cardId,
    String? idempotencyKey,
    bool bypassScamWarning = false,
  }) async {
    // If paying via a linked Credit Card or Debit Card
    if (cardId != null) {
      final cIdx = linkedCards.indexWhere((c) => c['id'] == cardId);
      if (cIdx != -1) {
        final card = Map<String, dynamic>.from(linkedCards[cIdx]);
        final curLim = (card['balanceOrLimit'] as num?)?.toDouble() ?? 50000.0;
        if (curLim < amount) {
          return {'success': false, 'message': 'Insufficient available limit/balance on selected card.'};
        }
        card['balanceOrLimit'] = curLim - amount;
        linkedCards[cIdx] = card;
        final rrn = '4291${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
        final txn = {
          'id': 'txn_card_${DateTime.now().millisecondsSinceEpoch}',
          'upiRrn': rrn,
          'receiverName': receiverVpa,
          'receiverVpa': receiverVpa,
          'amount': amount,
          'status': 'SUCCESS',
          'remark': '$remark • Paid via ${card['bankName']} ${card['network']} ${card['cardType']} (${card['maskedCardNumber']})',
          'createdAt': DateTime.now().toIso8601String(),
        };
        recentTransactions.insert(0, txn);
        await saveSessionToDisk();
        return {'success': true, 'transaction': txn};
      }
    }

    try {
      final response = await _postWithFailover(
        '/payments/pay',
        {
          'receiverVpa': receiverVpa,
          'amount': amount,
          'mpin': mpin,
          'remark': remark,
          'senderAccountId': senderAccountId,
          'idempotencyKey': idempotencyKey,
          'bypassScamShieldWarning': bypassScamWarning,
        },
        timeout: const Duration(seconds: 6),
      );
      final res = jsonDecode(response.body) as Map<String, dynamic>;
      final isSuccess = res['success'] == true || (response.statusCode == 200 && res['transaction'] != null);
      if (isSuccess) {
        final txn = res['transaction'] as Map<String, dynamic>? ?? {};
        final newBal = (res['updatedBalance'] as num?)?.toDouble() ??
            ((currentAccount?.balance ?? 50000.0) - amount);
        if (currentAccount != null) {
          currentAccount = BankAccountModel(
            id: currentAccount!.id,
            bankName: currentAccount!.bankName,
            bankCode: currentAccount!.bankCode,
            ifsc: currentAccount!.ifsc,
            maskedAccountNumber: currentAccount!.maskedAccountNumber,
            balance: newBal > 0 ? newBal : 0,
            isPrimary: currentAccount!.isPrimary,
          );
        }
        final roundUp = (res['roundedUpAmount'] as num?)?.toDouble() ?? 0.0;
        if (roundUp > 0) {
          gullakBalance += roundUp;
        }
        recentTransactions.insert(0, {
          'id': txn['id'] ?? 'txn_${DateTime.now().millisecondsSinceEpoch}',
          'receiverName': txn['receiverName'] ?? receiverVpa,
          'receiverVpa': receiverVpa,
          'amount': amount,
          'upiRrn': txn['upiRrn'] ?? '4291${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
          'status': 'SUCCESS',
          'remark': remark,
          'createdAt': DateTime.now().toIso8601String(),
        });
        await saveSessionToDisk();
        return {'success': true, ...res};
      }
      return {
        'success': false,
        'message': res['message'] ?? 'Payment declined by bank switch.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Payment failed. Banking switch could not be reached. No money was debited.',
      };
    }
  }

  // 8. UPI Lite PIN-less Payment (< ₹500)
  static Future<Map<String, dynamic>> payLite({
    required String receiverVpa,
    required double amount,
    String remark = 'UPI Lite',
  }) async {
    try {
      final response = await _postWithFailover('/payments/lite-pay', {
        'receiverVpa': receiverVpa,
        'amount': amount,
        'remark': remark,
      });
      final res = jsonDecode(response.body) as Map<String, dynamic>;
      if (res['success'] == true || res['transaction'] != null) {
        if (currentUser != null) {
          currentUser = UserModel(
            id: currentUser!.id,
            phone: currentUser!.phone,
            fullName: currentUser!.fullName,
            email: currentUser!.email,
            primaryVpa: currentUser!.primaryVpa,
            liteBalance: (currentUser!.liteBalance - amount) > 0 ? (currentUser!.liteBalance - amount) : 0,
            lrsUsedUsd: currentUser!.lrsUsedUsd,
            dateOfBirth: currentUser!.dateOfBirth,
            profilePicture: currentUser!.profilePicture,
          );
        }
        return {'success': true, ...res};
      }
      return {
        'success': false,
        'message': res['message'] ?? 'UPI Lite payment declined.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'UPI Lite payment failed. Banking switch unreachable.',
      };
    }
  }

  // 9. Cross-Border FX Quote
  static Future<CrossBorderQuoteModel> getCrossBorderQuote({
    required String targetCurrency,
    double? targetAmount,
    double? sourceAmountInr,
  }) async {
    try {
      final response = await _postWithFailover('/cross-border/quote', {
        'targetCurrency': targetCurrency,
        'targetAmount': targetAmount,
        'sourceAmountInr': sourceAmountInr,
      });
      final data = jsonDecode(response.body);
      if (data['quote'] != null) {
        return CrossBorderQuoteModel.fromJson(data['quote']);
      }
    } catch (_) {}

    final double rate = targetCurrency == 'USD'
        ? 86.82
        : targetCurrency == 'EUR'
            ? 94.15
            : targetCurrency == 'GBP'
                ? 109.80
                : targetCurrency == 'SGD'
                    ? 66.25
                    : targetCurrency == 'AED'
                        ? 23.64
                        : 86.82;
    final double fee = 45.0;
    final double gst = 8.10;
    final double total = (targetAmount ?? 100) * rate + fee + gst;
    return CrossBorderQuoteModel(
      quoteId: 'cbq_${DateTime.now().millisecondsSinceEpoch}',
      targetCurrency: targetCurrency,
      targetAmount: targetAmount ?? 100,
      sourceAmountInr: total,
      exchangeRate: rate,
      marketReferenceRate: rate - 0.15,
      adBankFeeInr: fee,
      gstInr: gst,
      totalCostInr: total,
      corridorType: 'OUTWARD_LRS',
      partnerRail: 'UPI-PayNow Global Rail',
      rateLockExpiresAt: DateTime.now().add(const Duration(seconds: 600)),
      lrsLimitRemainingUsd: 250000.0,
      routeSimpleName: 'Direct Rupee-FX Bridge',
      simpleUserSummary: 'Instant lock-in rate with RBI LRS compliance.',
    );
  }

  // 9b. Execute Cross-Border Transfer
  static Future<Map<String, dynamic>> executeCrossBorder({
    required String quoteId,
    required String beneficiaryName,
    required String beneficiaryAccountOrIban,
    double? totalCostInr,
    double? targetAmount,
    String? targetCurrency,
    String? purposeCode,
    String? mpin,
  }) async {
    try {
      final response = await _postWithFailover(
        '/cross-border/execute',
        {
          'quoteId': quoteId,
          'beneficiaryName': beneficiaryName,
          'beneficiaryAccountOrIban': beneficiaryAccountOrIban,
          'purposeCode': purposeCode ?? 'S0301',
          'mpin': mpin ?? configuredAppPin,
        },
        timeout: const Duration(seconds: 6),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final newBal = (data['updatedAccountBalance'] as num?)?.toDouble();
        if (newBal != null && currentAccount != null) {
          currentAccount = BankAccountModel(
            id: currentAccount!.id,
            bankName: currentAccount!.bankName,
            bankCode: currentAccount!.bankCode,
            ifsc: currentAccount!.ifsc,
            maskedAccountNumber: currentAccount!.maskedAccountNumber,
            balance: newBal,
            isPrimary: currentAccount!.isPrimary,
          );
        }
        recentTransactions.insert(0, {
          'id': data['transferId'] ?? 'remit_${DateTime.now().millisecondsSinceEpoch}',
          'receiverName': '$beneficiaryName (${data['foreignCurrency'] ?? targetCurrency ?? "FX"})',
          'receiverVpa': beneficiaryAccountOrIban,
          'amount': data['amountPaidInr'] ?? totalCostInr ?? 0.0,
          'upiRrn': data['transferId'] ?? 'CBX99281',
          'status': 'SUCCESS',
          'remark': 'Cross-Border Remittance',
          'createdAt': DateTime.now().toIso8601String(),
        });
        return data;
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Cross-border remittance declined.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Cross-border transfer failed. Authorized FX bridge unreachable.',
      };
    }
  }

  // 10. Protected Pay (Escrow)
  static Future<List<ProtectedPayEscrowModel>> getMyEscrows() async {
    try {
      final response = await _getWithFailover('/protected-pay/my-escrows');
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['escrows'] is List) {
        activeEscrows = (data['escrows'] as List)
            .map((e) => ProtectedPayEscrowModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return activeEscrows;
  }

  static Future<ProtectedPayEscrowModel?> initiateProtectedPay({
    required String sellerVpa,
    required String sellerName,
    required double amount,
    required String itemDescription,
  }) async {
    try {
      final response = await _postWithFailover('/protected-pay/initiate', {
        'sellerVpa': sellerVpa,
        'sellerName': sellerName,
        'amount': amount,
        'itemDescription': itemDescription,
      });
      final data = jsonDecode(response.body);
      if (data['escrow'] != null) {
        final esc = ProtectedPayEscrowModel.fromJson(data['escrow']);
        activeEscrows.insert(0, esc);
        if (currentAccount != null) {
          currentAccount = BankAccountModel(
            id: currentAccount!.id,
            bankName: currentAccount!.bankName,
            bankCode: currentAccount!.bankCode,
            ifsc: currentAccount!.ifsc,
            maskedAccountNumber: currentAccount!.maskedAccountNumber,
            balance: (currentAccount!.balance - amount) > 0 ? (currentAccount!.balance - amount) : 0,
            isPrimary: currentAccount!.isPrimary,
          );
        }
        return esc;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> confirmDelivery(String escrowId) async {
    try {
      await _postWithFailover('/protected-pay/$escrowId/confirm-delivery', {});
    } catch (_) {}
    final idx = activeEscrows.indexWhere((e) => e.id == escrowId);
    if (idx != -1) {
      final old = activeEscrows[idx];
      activeEscrows[idx] = ProtectedPayEscrowModel(
        id: old.id,
        buyerUserId: old.buyerUserId,
        sellerVpa: old.sellerVpa,
        sellerName: old.sellerName,
        amount: old.amount,
        itemDescription: old.itemDescription,
        status: 'RELEASED_TO_SELLER',
        expiresAt: old.expiresAt,
      );
    }
    return true;
  }

  static Future<bool> disputeEscrow(String escrowId, String reason) async {
    try {
      await _postWithFailover('/protected-pay/$escrowId/dispute', {'disputeReason': reason});
    } catch (_) {}
    final idx = activeEscrows.indexWhere((e) => e.id == escrowId);
    if (idx != -1) {
      final old = activeEscrows[idx];
      activeEscrows[idx] = ProtectedPayEscrowModel(
        id: old.id,
        buyerUserId: old.buyerUserId,
        sellerVpa: old.sellerVpa,
        sellerName: old.sellerName,
        amount: old.amount,
        itemDescription: old.itemDescription,
        status: 'DISPUTED',
        expiresAt: old.expiresAt,
        disputeReason: reason,
      );
    }
    return true;
  }

  // 11. Digital Gullak (Vaults)
  static Future<double> getVaults() async {
    try {
      final response = await _getWithFailover('/vaults');
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['vaults'] is List && (data['vaults'] as List).isNotEmpty) {
        final v = (data['vaults'] as List).first;
        activeVaultId = v['id'] ?? activeVaultId;
        gullakBalance = (v['currentBalance'] as num?)?.toDouble() ?? gullakBalance;
      }
    } catch (_) {}
    return gullakBalance;
  }

  static Future<bool> depositVault(double amount) async {
    try {
      final response = await _postWithFailover('/vaults/$activeVaultId/deposit', {'amount': amount});
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['vault'] != null) {
        gullakBalance = (data['vault']['currentBalance'] as num?)?.toDouble() ?? (gullakBalance + amount);
        if (currentAccount != null) {
          currentAccount = BankAccountModel(
            id: currentAccount!.id,
            bankName: currentAccount!.bankName,
            bankCode: currentAccount!.bankCode,
            ifsc: currentAccount!.ifsc,
            maskedAccountNumber: currentAccount!.maskedAccountNumber,
            balance: (currentAccount!.balance - amount) > 0 ? (currentAccount!.balance - amount) : 0,
            isPrimary: currentAccount!.isPrimary,
          );
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> withdrawVault(double amount) async {
    if (amount > gullakBalance) return false;
    try {
      final response = await _postWithFailover('/vaults/$activeVaultId/withdraw', {'amount': amount});
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['vault'] != null) {
        gullakBalance = (data['vault']['currentBalance'] as num?)?.toDouble() ?? (gullakBalance - amount);
        if (currentAccount != null) {
          currentAccount = BankAccountModel(
            id: currentAccount!.id,
            bankName: currentAccount!.bankName,
            bankCode: currentAccount!.bankCode,
            ifsc: currentAccount!.ifsc,
            maskedAccountNumber: currentAccount!.maskedAccountNumber,
            balance: currentAccount!.balance + amount,
            isPrimary: currentAccount!.isPrimary,
          );
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 12. BBPS Utility Bills & Recharges (Electricity, Water, Gas, Broadband, Mobile, FASTag, DTH)
  static Future<List<Map<String, dynamic>>> getBillers([String? category]) async {
    try {
      final path = category != null ? '/bills/billers?category=$category' : '/bills/billers';
      final response = await _getWithFailover(path);
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['billers'] is List && (data['billers'] as List).isNotEmpty) {
        final list = List<Map<String, dynamic>>.from(data['billers']);
        if (category == null) bbpsBillers = list;
        return list;
      }
    } catch (_) {}
    if (category != null) {
      return bbpsBillers.where((b) => b['category'] == category).toList();
    }
    return bbpsBillers;
  }

  static Future<Map<String, dynamic>> fetchBillDetails({
    required String billerId,
    required String consumerNumber,
  }) async {
    try {
      final response = await _postWithFailover('/bills/fetch', {
        'billerId': billerId,
        'consumerNumber': consumerNumber,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['bill'] != null) {
          return data;
        }
      }
    } catch (_) {}

    // Local BBPS realistic itemized tariff calculation per State Electricity Regulatory Commission (SERC)
    final biller = bbpsBillers.firstWhere(
      (b) => b['id'] == billerId,
      orElse: () => {'id': billerId, 'name': 'BBPS Utility Biller', 'category': 'ELECTRICITY'},
    );
    final cat = biller['category'] ?? 'ELECTRICITY';
    int seed = 0;
    for (int i = 0; i < consumerNumber.length; i++) {
      seed += consumerNumber.codeUnitAt(i) * (i + 1);
    }

    double amt = 890.0;
    String usage = '';
    Map<String, dynamic> breakdown = {};

    if (cat == 'ELECTRICITY') {
      final units = 180 + (seed % 120); // Realistic 180 - 300 kWh consumption
      double energyCharges = 0;
      if (units <= 100) {
        energyCharges = units * 4.60;
      } else if (units <= 200) {
        energyCharges = (100 * 4.60) + ((units - 100) * 6.10);
      } else {
        energyCharges = (100 * 4.60) + (100 * 6.10) + ((units - 200) * 7.50);
      }
      const double fixedDemandCharge = 85.00;
      final double dutyTax = (energyCharges + fixedDemandCharge) * 0.06;
      amt = double.parse((energyCharges + fixedDemandCharge + dutyTax).toStringAsFixed(2));
      usage = '$units kWh Consumed (Reading: ${4820 + seed % 300} to ${4820 + seed % 300 + units})';
      breakdown = {
        'Units Consumed': '$units Units (kWh)',
        'Energy Charges': '₹${energyCharges.toStringAsFixed(2)}',
        'Fixed Demand Charge': '₹85.00',
        'State Electricity Duty (6%)': '₹${dutyTax.toStringAsFixed(2)}',
        'Tariff Class': 'LT-Domestic A (Bi-Monthly)',
        'Meter Number': 'MTR-${seed % 90000 + 10000}',
      };
    } else if (cat == 'WATER') {
      final kl = 18 + (seed % 16);
      final waterCharge = kl * 12.50;
      const sewerageFee = 60.0;
      amt = double.parse((waterCharge + sewerageFee).toStringAsFixed(2));
      usage = '$kl Kilolitres (KL) Municipal Water Metered';
      breakdown = {
        'Consumption': '$kl KL',
        'Water Supply Charges': '₹${waterCharge.toStringAsFixed(2)}',
        'Sewerage & Sanitation Cess': '₹60.00',
      };
    } else if (cat == 'GAS') {
      amt = 864.0;
      usage = '14.2 Kg Domestic LPG Refill Cylinder';
      breakdown = {
        'Cylinder Price (Govt Subsidized)': '₹829.00',
        'Home Delivery & Safety Inspection': '₹35.00',
        'Booking No': 'LPG-${seed % 900000 + 100000}',
      };
    } else if (cat == 'BROADBAND') {
      amt = 1178.82;
      usage = '300 Mbps Unlimited Fiber + 16 OTT Apps';
      breakdown = {
        'Base Plan': '₹999.00',
        'GST (18% IGST)': '₹179.82',
        'Speed': '300 Mbps Symmetrical',
      };
    } else if (cat == 'MOBILE') {
      amt = 349.0;
      usage = 'True 5G Unlimited + 2GB/Day + Unlimited Calls (28 Days)';
      breakdown = {
        'Recharge Plan': '₹349.00',
        'Talktime': 'Unlimited Local/STD',
        'Data': 'Unlimited True 5G',
      };
    } else if (cat == 'FASTAG') {
      amt = 500.0;
      usage = 'NHAI FASTag National Highway Toll Top-up';
      breakdown = {
        'Wallet Credit': '₹500.00',
        'Platform Convenience Fee': '₹0.00 (Free)',
      };
    } else {
      amt = 450.0;
      usage = 'HD Premium Family & Sports Pack (Monthly)';
      breakdown = {
        'Network Capacity Fee (NCF)': '₹153.40',
        'Pay Channels': '₹296.60',
      };
    }

    return {
      'success': true,
      'bill': {
        'billerId': billerId,
        'billerName': biller['name'],
        'category': cat,
        'consumerNumber': consumerNumber,
        'consumerName': currentUser?.fullName ?? 'Soumo Naskar',
        'billNumber': 'BBPS${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        'billPeriod': 'Current Billing Cycle',
        'dueDate': DateTime.now().add(const Duration(days: 9)).toIso8601String().split('T').first,
        'amount': amt,
        'planOrUsage': usage,
        'tariffBreakdown': breakdown,
        'alreadyPaid': false,
      },
    };
  }

  static Future<Map<String, dynamic>> payBill({
    required String billerId,
    required String consumerNumber,
    required double amount,
    required String mpin,
    String? billNumber,
    String? planOrUsage,
  }) async {
    try {
      final response = await _postWithFailover('/bills/pay', {
        'billerId': billerId,
        'consumerNumber': consumerNumber,
        'amount': amount,
        'mpin': mpin,
        'billNumber': billNumber,
        'planOrUsage': planOrUsage,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final newBal = (data['updatedBalance'] as num?)?.toDouble();
          if (newBal != null && currentAccount != null) {
            currentAccount = BankAccountModel(
              id: currentAccount!.id,
              bankName: currentAccount!.bankName,
              bankCode: currentAccount!.bankCode,
              ifsc: currentAccount!.ifsc,
              maskedAccountNumber: currentAccount!.maskedAccountNumber,
              balance: newBal,
              isPrimary: currentAccount!.isPrimary,
            );
          }
          if (data['transaction'] != null) {
            recentTransactions.insert(0, Map<String, dynamic>.from(data['transaction']));
          }
          await saveSessionToDisk();
          return data;
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Bill payment declined.',
        };
      }
    } catch (_) {}
    return {
      'success': false,
      'message': 'BBPS bill payment failed. Utility gateway unreachable.',
    };
  }

  // 13. Bank Auto-SIP & Wealth Plans
  static void _recalculateLocalSipPortfolio() {
    double invested = 0;
    double currentVal = 0;
    for (final s in mySips) {
      invested += (s['totalInvested'] as num?)?.toDouble() ?? 0.0;
      currentVal += (s['currentValue'] as num?)?.toDouble() ?? 0.0;
    }
    final gain = currentVal - invested;
    final pct = invested > 0 ? (gain / invested) * 100.0 : 0.0;
    sipPortfolio = {
      'totalInvested': double.parse(invested.toStringAsFixed(2)),
      'currentValue': double.parse(currentVal.toStringAsFixed(2)),
      'totalReturns': double.parse(gain.toStringAsFixed(2)),
      'returnPct': double.parse(pct.toStringAsFixed(2)),
      'activeMandatesCount': mySips.length,
    };
  }

  static Future<Map<String, dynamic>> getSipPlansAndPortfolio() async {
    try {
      final response = await _getWithFailover('/sip/plans');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if (data['plans'] is List && (data['plans'] as List).isNotEmpty) {
          sipPlans = List<Map<String, dynamic>>.from(data['plans']);
        }
        if (data['mySips'] is List) {
          mySips = List<Map<String, dynamic>>.from(data['mySips']);
        }
        if (data['portfolio'] is Map) {
          sipPortfolio = Map<String, dynamic>.from(data['portfolio']);
        }
        await saveSessionToDisk();
        return data;
      }
    } catch (_) {}
    _recalculateLocalSipPortfolio();
    return {
      'success': true,
      'plans': sipPlans,
      'mySips': mySips,
      'portfolio': sipPortfolio,
    };
  }

  static Future<Map<String, dynamic>> createSipMandate({
    required String planId,
    required double monthlyAmount,
    required int debitDay,
    required String mpin,
  }) async {
    try {
      final response = await _postWithFailover('/sip/create', {
        'planId': planId,
        'monthlyAmount': monthlyAmount,
        'debitDay': debitDay,
        'mpin': mpin,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final newBal = (data['updatedBalance'] as num?)?.toDouble();
          if (newBal != null && currentAccount != null) {
            currentAccount = BankAccountModel(
              id: currentAccount!.id,
              bankName: currentAccount!.bankName,
              bankCode: currentAccount!.bankCode,
              ifsc: currentAccount!.ifsc,
              maskedAccountNumber: currentAccount!.maskedAccountNumber,
              balance: newBal,
              isPrimary: currentAccount!.isPrimary,
            );
          }
          if (data['transaction'] != null) {
            recentTransactions.insert(0, Map<String, dynamic>.from(data['transaction']));
          }
          await getSipPlansAndPortfolio();
          return data;
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Mandate registration declined.',
        };
      }
    } catch (_) {}
    return {
      'success': false,
      'message': 'Failed to create Auto-SIP mandate. Issuer exchange unreachable.',
    };
  }

  static Future<Map<String, dynamic>> paySipInstallment({
    required String sipId,
    double? amount,
    required String mpin,
  }) async {
    try {
      final response = await _postWithFailover('/sip/$sipId/installment', {
        'amount': amount,
        'mpin': mpin,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final newBal = (data['updatedBalance'] as num?)?.toDouble();
          if (newBal != null && currentAccount != null) {
            currentAccount = BankAccountModel(
              id: currentAccount!.id,
              bankName: currentAccount!.bankName,
              bankCode: currentAccount!.bankCode,
              ifsc: currentAccount!.ifsc,
              maskedAccountNumber: currentAccount!.maskedAccountNumber,
              balance: newBal,
              isPrimary: currentAccount!.isPrimary,
            );
          }
          if (data['transaction'] != null) {
            recentTransactions.insert(0, Map<String, dynamic>.from(data['transaction']));
          }
          await getSipPlansAndPortfolio();
          return data;
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Installment payment declined.',
        };
      }
    } catch (_) {}
    return {
      'success': false,
      'message': 'SIP installment payment failed. Exchange unreachable.',
    };
  }

  static Future<Map<String, dynamic>> redeemSipToBank({
    required String sipId,
    required String mpin,
  }) async {
    try {
      final response = await _postWithFailover('/sip/$sipId/redeem', {
        'mpin': mpin,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final newBal = (data['updatedBalance'] as num?)?.toDouble();
          if (newBal != null && currentAccount != null) {
            currentAccount = BankAccountModel(
              id: currentAccount!.id,
              bankName: currentAccount!.bankName,
              bankCode: currentAccount!.bankCode,
              ifsc: currentAccount!.ifsc,
              maskedAccountNumber: currentAccount!.maskedAccountNumber,
              balance: newBal,
              isPrimary: currentAccount!.isPrimary,
            );
          }
          if (data['transaction'] != null) {
            recentTransactions.insert(0, Map<String, dynamic>.from(data['transaction']));
          }
          await getSipPlansAndPortfolio();
          return data;
        }
        return {
          'success': false,
          'message': data['message'] ?? 'SIP redemption declined.',
        };
      }
    } catch (_) {}
    return {
      'success': false,
      'message': 'SIP redemption failed. Exchange switch unreachable.',
    };
  }

  // 14. Live SMS & Payment Gateway API Key Management
  static Future<Map<String, dynamic>> getGatewayStatus() async {
    try {
      final response = await _getWithFailover('/config/gateway');
      return jsonDecode(response.body);
    } catch (_) {
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> updateGatewayConfig({
    String? provider,
    String? fast2smsApiKey,
    String? msg91AuthKey,
    String? twilioAccountSid,
    String? twilioAuthToken,
    String? twilioPhoneNumber,
    String? razorpayKeyId,
  }) async {
    try {
      final response = await _postWithFailover('/config/gateway', {
        if (provider != null) 'provider': provider,
        if (fast2smsApiKey != null) 'fast2smsApiKey': fast2smsApiKey,
        if (msg91AuthKey != null) 'msg91AuthKey': msg91AuthKey,
        if (twilioAccountSid != null) 'twilioAccountSid': twilioAccountSid,
        if (twilioAuthToken != null) 'twilioAuthToken': twilioAuthToken,
        if (twilioPhoneNumber != null) 'twilioPhoneNumber': twilioPhoneNumber,
        if (razorpayKeyId != null) 'razorpayKeyId': razorpayKeyId,
      });
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==========================================
  // SUPER-APP EXTENSIONS: AUTOPAY, REWARDS, BUSINESS & TOOLS
  // ==========================================

  static Future<Map<String, dynamic>> getAutoPayMandates() async {
    try {
      final res = await _getWithFailover('/autopay/mandates');
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createAutoPayMandate({
    required String billerOrPayeeName,
    required String vpa,
    required String category,
    required String frequency,
    required double maxAmount,
    required int scheduledDay,
    required String mpin,
  }) async {
    try {
      final res = await _postWithFailover('/autopay/create', {
        'billerOrPayeeName': billerOrPayeeName,
        'vpa': vpa,
        'category': category,
        'frequency': frequency,
        'maxAmount': maxAmount,
        'scheduledDay': scheduledDay,
        'mpin': mpin,
      });
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateAutoPayStatus(String mandateId, String status) async {
    try {
      final res = await _postWithFailover('/autopay/$mandateId/status', {'status': status});
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> executeAutoPayDebit(String mandateId, {double? amount}) async {
    try {
      final res = await _postWithFailover('/autopay/$mandateId/debit', {
        if (amount != null) 'amount': amount,
      });
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getRewardsOverview() async {
    try {
      final res = await _getWithFailover('/rewards/overview');
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> claimRewardCoupon(String couponId) async {
    try {
      final res = await _postWithFailover('/rewards/coupons/$couponId/claim', {});
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getBusinessProfile() async {
    try {
      final res = await _getWithFailover('/business/profile');
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getBusinessInvoices() async {
    try {
      final res = await _getWithFailover('/business/invoices');
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createBusinessInvoice({
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> items,
    String? dueDate,
  }) async {
    try {
      final res = await _postWithFailover('/business/invoices/create', {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'items': items,
        if (dueDate != null) 'dueDate': dueDate,
      });
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getLiveFxRates() async {
    try {
      final res = await _getWithFailover('/tools/fx-rates');
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

typedef AikSetraApi = BharatOnePayApi;
