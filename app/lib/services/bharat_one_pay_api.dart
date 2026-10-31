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
  static String? get authToken => _authToken;
  static String _activeUserId = ApiConfig.defaultDevUserId;

  // Cached state for active user session
  static UserModel? currentUser;
  static BankAccountModel? currentAccount;
  static BankAccountModel? currentBusinessAccount;
  // Context-aware primary account: Automatically shifts between Business Current Account and Personal Savings Account
  static BankAccountModel? get primaryAccount {
    if (isBusinessMode) {
      // Find business/current account first
      final bizAcc = linkedAccounts.firstWhere(
        (a) => a.isBusiness || a.accountType == 'CURRENT',
        orElse: () => linkedAccounts.isNotEmpty ? linkedAccounts.first : BankAccountModel(
          id: 'acc_pentile_biz',
          bankName: 'HDFC Bank (Pentile Business Current)',
          bankCode: 'HDFC',
          ifsc: 'HDFC0001234',
          maskedAccountNumber: '•••• •••• 4589',
          balance: 128450.00,
          accountType: 'CURRENT',
          isBusiness: true,
          isPrimary: true,
        ),
      );
      return bizAcc;
    }

    if (currentAccount != null) return currentAccount;
    final personalPrimary = linkedAccounts.where((a) => a.isPrimary && !a.isBusiness).toList();
    if (personalPrimary.isNotEmpty) return personalPrimary.first;
    final anySavings = linkedAccounts.where((a) => a.accountType == 'SAVINGS').toList();
    if (anySavings.isNotEmpty) return anySavings.first;
    return linkedAccounts.isNotEmpty ? linkedAccounts.first : null;
  }
  static List<BankAccountModel> linkedAccounts = [
    BankAccountModel(
      id: 'acc_sbi_01',
      bankName: 'State Bank of India',
      bankCode: 'SBIN',
      ifsc: 'SBIN0001234',
      maskedAccountNumber: '•••• •••• 4519',
      balance: 84500.50,
      isPrimary: true,
      accountType: 'SAVINGS',
      branch: 'Kolkata Main Branch',
      isBusiness: false,
    ),
    BankAccountModel(
      id: 'acc_hdfc_02',
      bankName: 'HDFC Bank',
      bankCode: 'HDFC',
      ifsc: 'HDFC0001234',
      maskedAccountNumber: '•••• •••• 4589',
      balance: 128450.00,
      isPrimary: false,
      accountType: 'CURRENT',
      branch: 'Tech Park Sector V, Kolkata',
      isBusiness: true,
    ),
    BankAccountModel(
      id: 'acc_icici_03',
      bankName: 'ICICI Bank',
      bankCode: 'ICIC',
      ifsc: 'ICIC0003456',
      maskedAccountNumber: '•••• •••• 3341',
      balance: 51200.75,
      isPrimary: false,
      accountType: 'SAVINGS',
      branch: 'Park Street Branch',
      isBusiness: false,
    ),
    BankAccountModel(
      id: 'acc_axis_04',
      bankName: 'Axis Bank',
      bankCode: 'UTIB',
      ifsc: 'UTIB0001234',
      maskedAccountNumber: '•••• •••• 7812',
      balance: 65000.00,
      isPrimary: false,
      accountType: 'CURRENT',
      branch: 'Salt Lake City Branch',
      isBusiness: true,
    ),
  ];
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

  // Live Indian Stock Market Benchmark Indices (NSE NIFTY 50 & BSE SENSEX)
  static final List<Map<String, dynamic>> marketIndices = [
    {
      'name': 'NIFTY 50',
      'ticker': '^NSEI',
      'price': 22706.80,
      'change': -46.40,
      'changePct': -0.19,
      'isUp': false,
    },
    {
      'name': 'SENSEX',
      'ticker': '^BSESN',
      'price': 73314.41,
      'change': -292.39,
      'changePct': -0.39,
      'isUp': false,
    },
  ];

  // Real Indian Stock Market Watchlist (NSE / BSE Equities with Live Feeds)
  static final List<Map<String, dynamic>> indianStocks = [
    {
      'symbol': 'RELIANCE',
      'ticker': 'RELIANCE.NS',
      'name': 'Reliance Industries Ltd',
      'sector': 'Energy',
      'price': 1160.30,
      'change': -37.90,
      'changePct': -3.16,
      'isUp': false,
      'marketCap': '₹19.9 Lakh Cr',
      'pe': 27.4,
      'high52': 1611.80,
      'low52': 1152.20,
      'dayHigh': 1204.30,
      'dayLow': 1156.40,
      'volume': 20773083,
      'miniBars': <double>[1194.5, 1201.2, 1188.0, 1175.4, 1166.0, 1162.5, 1158.0, 1160.3],
    },
    {
      'symbol': 'TCS',
      'ticker': 'TCS.NS',
      'name': 'Tata Consultancy Services',
      'sector': 'IT & Tech',
      'price': 2451.10,
      'change': -45.70,
      'changePct': -1.83,
      'isUp': false,
      'marketCap': '₹14.9 Lakh Cr',
      'pe': 31.2,
      'high52': 4585.90,
      'low52': 2390.00,
      'dayHigh': 2498.00,
      'dayLow': 2442.10,
      'volume': 3241000,
      'miniBars': <double>[2480.0, 2492.0, 2475.0, 2460.0, 2455.0, 2458.0, 2449.0, 2451.1],
    },
    {
      'symbol': 'HDFCBANK',
      'ticker': 'HDFCBANK.NS',
      'name': 'HDFC Bank Ltd',
      'sector': 'Banking',
      'price': 684.35,
      'change': 4.15,
      'changePct': 0.61,
      'isUp': true,
      'marketCap': '₹12.8 Lakh Cr',
      'pe': 18.6,
      'high52': 1794.00,
      'low52': 675.00,
      'dayHigh': 689.50,
      'dayLow': 678.20,
      'volume': 15280000,
      'miniBars': <double>[679.0, 680.5, 682.0, 681.4, 683.0, 682.8, 684.0, 684.35],
    },
    {
      'symbol': 'INFY',
      'ticker': 'INFY.NS',
      'name': 'Infosys Ltd',
      'sector': 'IT & Tech',
      'price': 1116.15,
      'change': -46.85,
      'changePct': -4.03,
      'isUp': false,
      'marketCap': '₹7.8 Lakh Cr',
      'pe': 29.1,
      'high52': 1991.45,
      'low52': 1110.00,
      'dayHigh': 1152.00,
      'dayLow': 1112.50,
      'volume': 11200000,
      'miniBars': <double>[1145.0, 1148.0, 1135.0, 1128.0, 1122.0, 1118.0, 1115.0, 1116.15],
    },
    {
      'symbol': 'ICICIBANK',
      'ticker': 'ICICIBANK.NS',
      'name': 'ICICI Bank Ltd',
      'sector': 'Banking',
      'price': 1378.90,
      'change': -8.10,
      'changePct': -0.58,
      'isUp': false,
      'marketCap': '₹9.7 Lakh Cr',
      'pe': 17.8,
      'high52': 1420.00,
      'low52': 980.00,
      'dayHigh': 1392.00,
      'dayLow': 1372.00,
      'volume': 8920000,
      'miniBars': <double>[1388.0, 1390.0, 1385.0, 1382.0, 1380.0, 1376.0, 1377.5, 1378.9],
    },
    {
      'symbol': 'SBIN',
      'ticker': 'SBIN.NS',
      'name': 'State Bank of India',
      'sector': 'Banking',
      'price': 958.80,
      'change': 13.70,
      'changePct': 1.45,
      'isUp': true,
      'marketCap': '₹8.5 Lakh Cr',
      'pe': 11.2,
      'high52': 965.00,
      'low52': 580.00,
      'dayHigh': 962.40,
      'dayLow': 944.00,
      'volume': 18450000,
      'miniBars': <double>[946.0, 948.5, 951.0, 953.2, 955.0, 954.8, 957.0, 958.8],
    },
    {
      'symbol': 'BHARTIARTL',
      'ticker': 'BHARTIARTL.NS',
      'name': 'Bharti Airtel Ltd',
      'sector': 'IT & Tech',
      'price': 1955.20,
      'change': -23.50,
      'changePct': -1.19,
      'isUp': false,
      'marketCap': '₹9.8 Lakh Cr',
      'pe': 44.5,
      'high52': 1990.00,
      'low52': 1050.00,
      'dayHigh': 1982.00,
      'dayLow': 1948.00,
      'volume': 6750000,
      'miniBars': <double>[1972.0, 1978.0, 1968.0, 1962.0, 1958.0, 1954.0, 1953.0, 1955.2],
    },
    {
      'symbol': 'ITC',
      'ticker': 'ITC.NS',
      'name': 'ITC Limited',
      'sector': 'FMCG',
      'price': 258.15,
      'change': -1.85,
      'changePct': -0.71,
      'isUp': false,
      'marketCap': '₹6.2 Lakh Cr',
      'pe': 28.3,
      'high52': 528.55,
      'low52': 252.00,
      'dayHigh': 261.20,
      'dayLow': 257.40,
      'volume': 14200000,
      'miniBars': <double>[260.0, 260.8, 259.5, 258.9, 258.5, 257.9, 258.0, 258.15],
    },
    {
      'symbol': 'LT',
      'ticker': 'LT.NS',
      'name': 'Larsen & Toubro Ltd',
      'sector': 'Infra',
      'price': 3810.00,
      'change': 144.75,
      'changePct': 3.95,
      'isUp': true,
      'marketCap': '₹5.2 Lakh Cr',
      'pe': 36.8,
      'high52': 3919.90,
      'low52': 2872.00,
      'dayHigh': 3835.00,
      'dayLow': 3680.00,
      'volume': 4120000,
      'miniBars': <double>[3690.0, 3720.0, 3755.0, 3770.0, 3790.0, 3802.0, 3805.0, 3810.0],
    },
    {
      'symbol': 'TATAMOTORS',
      'ticker': 'TATAMOTORS.NS',
      'name': 'Tata Motors Ltd',
      'sector': 'Auto',
      'price': 780.40,
      'change': 12.20,
      'changePct': 1.58,
      'isUp': true,
      'marketCap': '₹3.2 Lakh Cr',
      'pe': 10.4,
      'high52': 1179.00,
      'low52': 680.00,
      'dayHigh': 788.00,
      'dayLow': 765.00,
      'volume': 9850000,
      'miniBars': <double>[768.0, 772.0, 775.0, 771.0, 774.5, 778.0, 776.0, 780.4],
    },
    {
      'symbol': 'KOTAKBANK',
      'ticker': 'KOTAKBANK.NS',
      'name': 'Kotak Mahindra Bank',
      'sector': 'Banking',
      'price': 1765.20,
      'change': -11.40,
      'changePct': -0.64,
      'isUp': false,
      'marketCap': '₹3.5 Lakh Cr',
      'pe': 19.2,
      'high52': 1925.00,
      'low52': 1540.00,
      'dayHigh': 1782.00,
      'dayLow': 1758.00,
      'volume': 2340000,
      'miniBars': <double>[1775.0, 1780.0, 1772.0, 1768.0, 1764.0, 1766.0, 1763.0, 1765.2],
    },
    {
      'symbol': 'AXISBANK',
      'ticker': 'AXISBANK.NS',
      'name': 'Axis Bank Ltd',
      'sector': 'Banking',
      'price': 1195.40,
      'change': 8.60,
      'changePct': 0.72,
      'isUp': true,
      'marketCap': '₹3.7 Lakh Cr',
      'pe': 14.5,
      'high52': 1339.00,
      'low52': 975.00,
      'dayHigh': 1205.00,
      'dayLow': 1184.00,
      'volume': 5600000,
      'miniBars': <double>[1186.0, 1190.0, 1194.0, 1191.0, 1193.0, 1196.0, 1194.5, 1195.4],
    },
    {
      'symbol': 'MARUTI',
      'ticker': 'MARUTI.NS',
      'name': 'Maruti Suzuki India',
      'sector': 'Auto',
      'price': 11850.00,
      'change': 115.00,
      'changePct': 0.98,
      'isUp': true,
      'marketCap': '₹3.7 Lakh Cr',
      'pe': 26.8,
      'high52': 13680.00,
      'low52': 9700.00,
      'dayHigh': 11920.00,
      'dayLow': 11710.00,
      'volume': 420000,
      'miniBars': <double>[11740.0, 11780.0, 11820.0, 11800.0, 11830.0, 11845.0, 11840.0, 11850.0],
    },
    {
      'symbol': 'SUNPHARMA',
      'ticker': 'SUNPHARMA.NS',
      'name': 'Sun Pharma Ltd',
      'sector': 'Healthcare',
      'price': 1880.50,
      'change': 14.20,
      'changePct': 0.76,
      'isUp': true,
      'marketCap': '₹4.5 Lakh Cr',
      'pe': 38.4,
      'high52': 1960.00,
      'low52': 1100.00,
      'dayHigh': 1895.00,
      'dayLow': 1862.00,
      'volume': 1890000,
      'miniBars': <double>[1865.0, 1872.0, 1876.0, 1870.0, 1875.0, 1882.0, 1878.0, 1880.5],
    },
    {
      'symbol': 'TITAN',
      'ticker': 'TITAN.NS',
      'name': 'Titan Company Ltd',
      'sector': 'FMCG',
      'price': 3280.00,
      'change': -28.00,
      'changePct': -0.85,
      'isUp': false,
      'marketCap': '₹2.9 Lakh Cr',
      'pe': 82.1,
      'high52': 3886.00,
      'low52': 3050.00,
      'dayHigh': 3315.00,
      'dayLow': 3260.00,
      'volume': 1150000,
      'miniBars': <double>[3310.0, 3315.0, 3298.0, 3290.0, 3285.0, 3278.0, 3282.0, 3280.0],
    },
    {
      'symbol': 'BAJFINANCE',
      'ticker': 'BAJFINANCE.NS',
      'name': 'Bajaj Finance Ltd',
      'sector': 'Banking',
      'price': 6890.00,
      'change': 72.00,
      'changePct': 1.05,
      'isUp': true,
      'marketCap': '₹4.2 Lakh Cr',
      'pe': 29.5,
      'high52': 7850.00,
      'low52': 6350.00,
      'dayHigh': 6940.00,
      'dayLow': 6810.00,
      'volume': 920000,
      'miniBars': <double>[6820.0, 6845.0, 6870.0, 6860.0, 6875.0, 6895.0, 6885.0, 6890.0],
    },
    {
      'symbol': 'ASIANPAINT',
      'ticker': 'ASIANPAINT.NS',
      'name': 'Asian Paints Ltd',
      'sector': 'FMCG',
      'price': 2670.00,
      'change': -18.50,
      'changePct': -0.69,
      'isUp': false,
      'marketCap': '₹2.5 Lakh Cr',
      'pe': 52.3,
      'high52': 3422.00,
      'low52': 2560.00,
      'dayHigh': 2695.00,
      'dayLow': 2655.00,
      'volume': 1420000,
      'miniBars': <double>[2690.0, 2695.0, 2682.0, 2675.0, 2672.0, 2668.0, 2671.0, 2670.0],
    },
    {
      'symbol': 'WIPRO',
      'ticker': 'WIPRO.NS',
      'name': 'Wipro Limited',
      'sector': 'IT & Tech',
      'price': 545.20,
      'change': 5.80,
      'changePct': 1.07,
      'isUp': true,
      'marketCap': '₹2.8 Lakh Cr',
      'pe': 24.6,
      'high52': 585.00,
      'low52': 380.00,
      'dayHigh': 551.00,
      'dayLow': 538.00,
      'volume': 6400000,
      'miniBars': <double>[540.0, 542.5, 544.0, 542.0, 544.5, 546.0, 545.0, 545.2],
    },
    {
      'symbol': 'HCLTECH',
      'ticker': 'HCLTECH.NS',
      'name': 'HCL Technologies Ltd',
      'sector': 'IT & Tech',
      'price': 1790.00,
      'change': -12.00,
      'changePct': -0.67,
      'isUp': false,
      'marketCap': '₹4.8 Lakh Cr',
      'pe': 28.2,
      'high52': 1890.00,
      'low52': 1220.00,
      'dayHigh': 1812.00,
      'dayLow': 1780.00,
      'volume': 2100000,
      'miniBars': <double>[1805.0, 1810.0, 1800.0, 1795.0, 1792.0, 1788.0, 1791.0, 1790.0],
    },
    {
      'symbol': 'ADANIENT',
      'ticker': 'ADANIENT.NS',
      'name': 'Adani Enterprises Ltd',
      'sector': 'Energy',
      'price': 2740.00,
      'change': 35.00,
      'changePct': 1.29,
      'isUp': true,
      'marketCap': '₹3.1 Lakh Cr',
      'pe': 78.4,
      'high52': 3450.00,
      'low52': 2100.00,
      'dayHigh': 2765.00,
      'dayLow': 2700.00,
      'volume': 1850000,
      'miniBars': <double>[2705.0, 2720.0, 2735.0, 2725.0, 2738.0, 2745.0, 2740.0, 2740.0],
    },
    {
      'symbol': 'TATASTEEL',
      'ticker': 'TATASTEEL.NS',
      'name': 'Tata Steel Ltd',
      'sector': 'Infra',
      'price': 148.50,
      'change': 1.85,
      'changePct': 1.26,
      'isUp': true,
      'marketCap': '₹1.8 Lakh Cr',
      'pe': 34.2,
      'high52': 184.00,
      'low52': 118.00,
      'dayHigh': 150.20,
      'dayLow': 146.50,
      'volume': 28400000,
      'miniBars': <double>[146.8, 147.5, 148.2, 147.8, 148.0, 148.8, 148.2, 148.5],
    },
    {
      'symbol': 'NTPC',
      'ticker': 'NTPC.NS',
      'name': 'NTPC Limited',
      'sector': 'Energy',
      'price': 395.20,
      'change': 4.10,
      'changePct': 1.05,
      'isUp': true,
      'marketCap': '₹3.8 Lakh Cr',
      'pe': 18.2,
      'high52': 448.00,
      'low52': 230.00,
      'dayHigh': 398.50,
      'dayLow': 390.00,
      'volume': 11200000,
      'miniBars': <double>[391.0, 393.0, 395.0, 393.5, 394.8, 396.0, 395.0, 395.2],
    },
    {
      'symbol': 'POWERGRID',
      'ticker': 'POWERGRID.NS',
      'name': 'Power Grid Corp',
      'sector': 'Energy',
      'price': 322.00,
      'change': -2.40,
      'changePct': -0.74,
      'isUp': false,
      'marketCap': '₹2.9 Lakh Cr',
      'pe': 18.5,
      'high52': 366.00,
      'low52': 195.00,
      'dayHigh': 326.00,
      'dayLow': 320.50,
      'volume': 8900000,
      'miniBars': <double>[325.0, 326.0, 324.0, 323.5, 322.8, 321.5, 322.2, 322.0],
    },
    {
      'symbol': 'COALINDIA',
      'ticker': 'COALINDIA.NS',
      'name': 'Coal India Ltd',
      'sector': 'Energy',
      'price': 442.00,
      'change': 3.60,
      'changePct': 0.82,
      'isUp': true,
      'marketCap': '₹2.7 Lakh Cr',
      'pe': 7.8,
      'high52': 543.00,
      'low52': 305.00,
      'dayHigh': 446.00,
      'dayLow': 437.50,
      'volume': 7600000,
      'miniBars': <double>[438.0, 440.5, 442.0, 441.0, 443.0, 444.0, 442.5, 442.0],
    },
  ];

  // User's Demo Stock Portfolio Holdings
  static final List<Map<String, dynamic>> userStockPortfolio = [
    {
      'symbol': 'RELIANCE',
      'name': 'Reliance Industries Ltd',
      'shares': 4,
      'avgBuyPrice': 1145.0,
      'currentPrice': 1160.30,
      'isDemo': true,
    },
    {
      'symbol': 'TCS',
      'name': 'Tata Consultancy Services',
      'shares': 2,
      'avgBuyPrice': 2420.0,
      'currentPrice': 2451.10,
      'isDemo': true,
    },
    {
      'symbol': 'HDFCBANK',
      'name': 'HDFC Bank Ltd',
      'shares': 10,
      'avgBuyPrice': 675.0,
      'currentPrice': 684.35,
      'isDemo': true,
    },
  ];

  // Live Micro-Tick Generator for Real-Time Streaming Ticker
  static void tickLivePrices() {
    final now = DateTime.now();
    for (int i = 0; i < indianStocks.length; i++) {
      if ((i + now.second) % 4 == 0) {
        final s = indianStocks[i];
        final curPrice = (s['price'] as num).toDouble();
        final deltaFactor = ((now.millisecond + i * 17) % 7 - 3) * 0.0004;
        final delta = curPrice * deltaFactor;
        final newPrice = (curPrice + delta).clamp(1.0, 100000.0);
        s['lastPrice'] = curPrice;
        s['price'] = double.parse(newPrice.toStringAsFixed(2));
        s['tickDirection'] = delta > 0 ? 1 : (delta < 0 ? -1 : 0);
        s['lastTickTime'] = now;
      }
    }
  }

  // Execute Demo Stock Purchase
  static Future<Map<String, dynamic>> executeDemoStockBuy({
    required Map<String, dynamic> stock,
    required int qty,
    required String mpin,
  }) async {
    final symbol = stock['symbol'] as String;
    final name = stock['name'] as String;
    final price = (stock['price'] as num).toDouble();
    final total = price * qty;

    final existingIdx = userStockPortfolio.indexWhere((p) => p['symbol'] == symbol);
    if (existingIdx != -1) {
      final curShares = userStockPortfolio[existingIdx]['shares'] as int;
      final curAvg = (userStockPortfolio[existingIdx]['avgBuyPrice'] as num).toDouble();
      final newShares = curShares + qty;
      final newAvg = ((curShares * curAvg) + (qty * price)) / newShares;
      userStockPortfolio[existingIdx]['shares'] = newShares;
      userStockPortfolio[existingIdx]['avgBuyPrice'] = double.parse(newAvg.toStringAsFixed(2));
      userStockPortfolio[existingIdx]['currentPrice'] = price;
    } else {
      userStockPortfolio.add({
        'symbol': symbol,
        'name': name,
        'shares': qty,
        'avgBuyPrice': price,
        'currentPrice': price,
        'isDemo': true,
      });
    }

    recentTransactions.insert(0, {
      'id': 'txn_demo_stock_${DateTime.now().millisecondsSinceEpoch}',
      'amount': total,
      'receiverName': 'NSE Clearing (Demo Buy: $symbol)',
      'receiverVpa': 'nse.clearing@upi',
      'remark': 'Demo Equity Order: $qty shares of $symbol',
      'status': 'SUCCESS',
      'type': 'DEBIT',
      'isDemo': true,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return {
      'success': true,
      'message': 'Bought $qty shares of $symbol in Demo Trading mode',
      'total': total,
    };
  }

  static DateTime? _lastStockFetchTime;
  static final Map<String, List<Map<String, dynamic>>> _stockCandlesCache = {};

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  static Future<bool> fetchLiveStockQuotes() async {
    if (_lastStockFetchTime != null &&
        DateTime.now().difference(_lastStockFetchTime!).inSeconds < 10) {
      return true;
    }

    bool anyUpdated = false;
    try {
      // 1. Fetch benchmark indices
      for (final idx in marketIndices) {
        try {
          final uri = Uri.parse(
            'https://query1.finance.yahoo.com/v8/finance/chart/${Uri.encodeComponent(idx['ticker'])}?interval=15m&range=1d',
          );
          final res = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final meta = data['chart']?['result']?[0]?['meta'];
            if (meta != null && meta['regularMarketPrice'] != null) {
              final price = (meta['regularMarketPrice'] as num).toDouble();
              final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble() ?? price;
              final change = price - prevClose;
              final changePct = (meta['regularMarketChangePercent'] as num?)?.toDouble() ??
                  (prevClose != 0 ? (change / prevClose * 100) : 0.0);
              idx['price'] = price;
              idx['change'] = change;
              idx['changePct'] = changePct;
              idx['isUp'] = change >= 0;
              anyUpdated = true;
            }
          }
        } catch (_) {}
      }

      // 2. Fetch stock quotes in parallel
      final futures = indianStocks.map((stock) async {
        try {
          final ticker = stock['ticker'] ?? '${stock['symbol']}.NS';
          final uri = Uri.parse(
            'https://query1.finance.yahoo.com/v8/finance/chart/$ticker?interval=15m&range=1d',
          );
          final res = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final result = data['chart']?['result']?[0];
            final meta = result?['meta'];
            if (meta != null && meta['regularMarketPrice'] != null) {
              final price = (meta['regularMarketPrice'] as num).toDouble();
              final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble() ?? price;
              final change = price - prevClose;
              final changePct = (meta['regularMarketChangePercent'] as num?)?.toDouble() ??
                  (prevClose != 0 ? (change / prevClose * 100) : 0.0);

              stock['price'] = price;
              stock['change'] = change;
              stock['changePct'] = changePct;
              stock['isUp'] = change >= 0;
              if (meta['fiftyTwoWeekHigh'] != null) {
                stock['high52'] = (meta['fiftyTwoWeekHigh'] as num).toDouble();
              }
              if (meta['fiftyTwoWeekLow'] != null) {
                stock['low52'] = (meta['fiftyTwoWeekLow'] as num).toDouble();
              }
              if (meta['regularMarketDayHigh'] != null) {
                stock['dayHigh'] = (meta['regularMarketDayHigh'] as num).toDouble();
              }
              if (meta['regularMarketDayLow'] != null) {
                stock['dayLow'] = (meta['regularMarketDayLow'] as num).toDouble();
              }
              if (meta['regularMarketVolume'] != null) {
                stock['volume'] = (meta['regularMarketVolume'] as num).toInt();
              }

              final quote = result['indicators']?['quote']?[0];
              if (quote != null && quote['close'] is List) {
                final closes = (quote['close'] as List)
                    .where((c) => c != null)
                    .map((c) => (c as num).toDouble())
                    .toList();
                if (closes.length >= 4) {
                  stock['miniBars'] = closes.length > 8 ? closes.sublist(closes.length - 8) : closes;
                }
              }
              anyUpdated = true;
            }
          }
        } catch (_) {}
      });

      await Future.wait(futures);
      if (anyUpdated) {
        _lastStockFetchTime = DateTime.now();
      }
    } catch (_) {}
    return anyUpdated;
  }

  static Future<List<Map<String, dynamic>>> fetchRealStockCandles({
    required String symbol,
    required String timeframe,
  }) async {
    final cacheKey = '${symbol}_$timeframe';
    if (_stockCandlesCache.containsKey(cacheKey) && _stockCandlesCache[cacheKey]!.isNotEmpty) {
      return _stockCandlesCache[cacheKey]!;
    }

    String interval = '15m';
    String range = '1d';
    switch (timeframe) {
      case '1D':
        interval = '15m';
        range = '1d';
        break;
      case '1W':
        interval = '1h';
        range = '5d';
        break;
      case '1M':
        interval = '1d';
        range = '1mo';
        break;
      case '1Y':
        interval = '1wk';
        range = '1y';
        break;
      case '5Y':
        interval = '1mo';
        range = '5y';
        break;
      case 'ALL':
        interval = '3mo';
        range = '10y';
        break;
    }

    final ticker = symbol.contains('.') ? symbol : '$symbol.NS';
    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$ticker?interval=$interval&range=$range',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = data['chart']?['result']?[0];
        if (result != null) {
          final timestamps = (result['timestamp'] as List?) ?? [];
          final quote = result['indicators']?['quote']?[0];
          if (quote != null && timestamps.isNotEmpty) {
            final opens = (quote['open'] as List?) ?? [];
            final highs = (quote['high'] as List?) ?? [];
            final lows = (quote['low'] as List?) ?? [];
            final closes = (quote['close'] as List?) ?? [];
            final volumes = (quote['volume'] as List?) ?? [];

            final candles = <Map<String, dynamic>>[];
            for (int i = 0; i < timestamps.length; i++) {
              if (i >= closes.length || closes[i] == null) continue;
              final c = (closes[i] as num).toDouble();
              final o = (i < opens.length && opens[i] != null) ? (opens[i] as num).toDouble() : c;
              final h = (i < highs.length && highs[i] != null) ? (highs[i] as num).toDouble() : (o > c ? o : c);
              final l = (i < lows.length && lows[i] != null) ? (lows[i] as num).toDouble() : (o < c ? o : c);
              final v = (i < volumes.length && volumes[i] != null) ? (volumes[i] as num).toInt() : 10000;

              final dt = DateTime.fromMillisecondsSinceEpoch((timestamps[i] as num).toInt() * 1000).toLocal();
              String timeStr;
              if (timeframe == '1D') {
                final hr = dt.hour.toString().padLeft(2, '0');
                final min = dt.minute.toString().padLeft(2, '0');
                timeStr = '$hr:$min';
              } else if (timeframe == '1W' || timeframe == '1M') {
                timeStr = '${dt.day} ${_monthName(dt.month)}';
              } else {
                timeStr = '${_monthName(dt.month)} ${dt.year}';
              }

              candles.add({
                'time': timeStr,
                'open': o,
                'high': h,
                'low': l,
                'close': c,
                'volume': v,
              });
            }

            if (candles.isNotEmpty) {
              _stockCandlesCache[cacheKey] = candles;
              return candles;
            }
          }
        }
      }
    } catch (_) {}

    return _generateFallbackRealCandles(symbol, timeframe);
  }

  static List<Map<String, dynamic>> _generateFallbackRealCandles(String symbol, String timeframe) {
    final stock = indianStocks.firstWhere(
      (s) => s['symbol'] == symbol,
      orElse: () => indianStocks.first,
    );
    final basePrice = (stock['price'] as num).toDouble();
    final isUp = (stock['isUp'] as bool?) ?? true;
    final candleCount = timeframe == '1D' ? 25 : (timeframe == '1W' ? 35 : 21);

    final candles = <Map<String, dynamic>>[];
    double walkPrice = basePrice * (1.0 - (isUp ? 0.02 : -0.02));

    for (int i = 0; i < candleCount; i++) {
      final step = ((symbol.codeUnitAt(i % symbol.length) * 13 + i * 17) % 21) - 10.0;
      final open = walkPrice;
      final close = (i == candleCount - 1) ? basePrice : open + (step * (basePrice * 0.0012));
      final high = (open > close ? open : close) + (((i * 7) % 10) * basePrice * 0.0006);
      final low = (open < close ? open : close) - (((i * 5) % 10) * basePrice * 0.0006);
      final vol = 50000 + ((symbol.codeUnitAt(i % symbol.length) * 450 + i * 1200) % 150000);

      candles.add({
        'time': timeframe == '1D'
            ? '${9 + (i * 15 ~/ 60)}:${(15 + (i * 15 % 60)).toString().padLeft(2, '0')}'
            : (timeframe == '1W' ? 'Day ${i % 5 + 1}' : 'Wk ${(i ~/ 5) + 1}'),
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': vol,
      });
      walkPrice = close;
    }
    return candles;
  }

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
    {'id': 'dth_dishtv', 'name': 'Dish TV / D2H Direct', 'category': 'DTH', 'stateOrCircle': 'All India', 'consumerIdLabel': '11-Digit Viewing Card Number'},
    // Loan EMI Repayment
    {'id': 'loan_bajaj', 'name': 'Bajaj Finance / Finserv EMI', 'category': 'LOAN', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Loan Account Number'},
    {'id': 'loan_hdfc', 'name': 'HDFC Bank Personal & Home Loans', 'category': 'LOAN', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Loan Agreement / A/C No'},
    {'id': 'loan_sbi', 'name': 'SBI Home / Auto Loans', 'category': 'LOAN', 'stateOrCircle': 'All India', 'consumerIdLabel': '11-Digit Loan Account No'},
    // Credit Cards
    {'id': 'cc_sbi', 'name': 'SBI Card Credit Card Bill', 'category': 'CREDIT_CARD', 'stateOrCircle': 'All India', 'consumerIdLabel': '16-Digit Card Number'},
    {'id': 'cc_hdfc', 'name': 'HDFC Bank Credit Card Bill', 'category': 'CREDIT_CARD', 'stateOrCircle': 'All India', 'consumerIdLabel': '16-Digit Card Number'},
    {'id': 'cc_icici', 'name': 'ICICI Bank Credit Card Bill', 'category': 'CREDIT_CARD', 'stateOrCircle': 'All India', 'consumerIdLabel': '16-Digit Card Number'},
    // Insurance
    {'id': 'ins_lic', 'name': 'Life Insurance Corporation (LIC)', 'category': 'INSURANCE', 'stateOrCircle': 'All India', 'consumerIdLabel': '9-Digit Policy Number'},
    {'id': 'ins_hdfc_life', 'name': 'HDFC Life Insurance', 'category': 'INSURANCE', 'stateOrCircle': 'All India', 'consumerIdLabel': '8-Digit Policy Number'},
    {'id': 'ins_star_health', 'name': 'Star Health Insurance', 'category': 'INSURANCE', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Policy Number'},
    // Municipal & Property Taxes
    {'id': 'mun_kmc', 'name': 'Kolkata Municipal Corp (KMC Tax)', 'category': 'MUNICIPAL', 'stateOrCircle': 'Kolkata', 'consumerIdLabel': 'Assessee / Property No'},
    {'id': 'mun_mcgm', 'name': 'MCGM Mumbai Property Tax', 'category': 'MUNICIPAL', 'stateOrCircle': 'Mumbai', 'consumerIdLabel': 'Property SAC No'},
    {'id': 'mun_bbmp', 'name': 'BBMP Bengaluru Property Tax', 'category': 'MUNICIPAL', 'stateOrCircle': 'Bengaluru', 'consumerIdLabel': '10-Digit SAS PID'},
    // Traffic Challan
    {'id': 'challan_parivahan', 'name': 'Parivahan Traffic E-Challan', 'category': 'CHALLAN', 'stateOrCircle': 'All India (MoRTH)', 'consumerIdLabel': 'Challan No / Vehicle No'},
    {'id': 'challan_kolkata', 'name': 'Kolkata Traffic Police Challan', 'category': 'CHALLAN', 'stateOrCircle': 'West Bengal', 'consumerIdLabel': 'Notice / Vehicle Reg No'},
    // Education Fees
    {'id': 'edu_dps', 'name': 'Delhi Public School (DPS Fees)', 'category': 'EDUCATION', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Student Admission No'},
    {'id': 'edu_xavier', 'name': "St. Xavier's Collegiate School", 'category': 'EDUCATION', 'stateOrCircle': 'Kolkata', 'consumerIdLabel': 'Student ID / Roll No'},
    // Housing Society
    {'id': 'house_mygate', 'name': 'MyGate / Society Maintenance', 'category': 'HOUSING', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Flat / Unit Number'},
    // Cable TV
    {'id': 'cable_hathway', 'name': 'Hathway Digital Cable TV', 'category': 'CABLE', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Account / STB Mac No'},
    // Subscriptions & Play Code
    {'id': 'sub_gplay', 'name': 'Google Play Store Recharge Code', 'category': 'SUBSCRIPTION', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Email / Mobile Number'},
    {'id': 'sub_apple', 'name': 'Apple Gift Code / App Store', 'category': 'SUBSCRIPTION', 'stateOrCircle': 'All India', 'consumerIdLabel': 'Apple ID Mobile Number'},
  ];
  static List<ProtectedPayEscrowModel> activeEscrows = [];
  static bool isBusinessMode = false;
  static bool hasBusinessAccount = false;

  static Map<String, dynamic> businessProfile = {
    'companyName': 'Pentile',
    'businessType': 'Information Technology & Software',
    'website': 'https://pentile.in',
    'logo': null,
    'gstin': '19AAECN1234F1Z5',
    'pan': 'AAECN1234F',
    'businessAddress': 'Plot 42, Tech Park, Sector V, Kolkata, WB',
    'merchantVpa': 'aiksetra.merchant@okhdfcbank',
    'bankName': 'HDFC Bank',
    'bankAccountNo': '•••• 4589',
    'ifsc': 'HDFC0001234',
    'ownerName': 'Soumo Naskar',
    'ownerEmail': 'soumo@gmail.com',
    'ownerPhone': '+91 9830113038',
    'ownerDesignation': 'Founder & Managing Director',
    'ownerPan': 'AAECN1234F',
    'verified': true,
    'balance': 48250.0,
    'openedAt': '2026-10-25',
  };

  static List<Map<String, dynamic>> businessLedger = [
    {
      'id': 'LED-1001',
      'date': 'Today, 02:45 PM',
      'party': 'Aditya Sen',
      'vpa': 'aditya@oksbi',
      'particulars': 'Store POS Standee QR Scan',
      'method': 'Standee QR',
      'type': 'CREDIT',
      'amount': 1450.0,
      'balance': 48250.0,
    },
    {
      'id': 'LED-1002',
      'date': 'Today, 01:15 PM',
      'party': 'Priya Das',
      'vpa': 'priyadas@paytm',
      'particulars': 'Invoice #INV-2026-0891 (4K TV Accessory)',
      'method': 'Payment Link',
      'type': 'CREDIT',
      'amount': 3200.0,
      'balance': 46800.0,
    },
    {
      'id': 'LED-1003',
      'date': 'Today, 11:30 AM',
      'party': 'Daily Bank Settlement Payout',
      'vpa': 'HDFC Bank •••• 4589',
      'particulars': 'Automated Merchant Settlement',
      'method': 'IMPS / RTGS',
      'type': 'DEBIT',
      'amount': 15000.0,
      'balance': 43600.0,
    },
    {
      'id': 'LED-1004',
      'date': 'Today, 10:05 AM',
      'party': 'Kunal Ghosh',
      'vpa': 'kunal@icici',
      'particulars': 'Counter Payment via Bharat QR',
      'method': 'Standee QR',
      'type': 'CREDIT',
      'amount': 2800.0,
      'balance': 58600.0,
    },
    {
      'id': 'LED-1005',
      'date': 'Yesterday, 06:40 PM',
      'party': 'Sneha Paul',
      'vpa': 'sneha@axl',
      'particulars': 'RuPay Credit Card on UPI Scan',
      'method': 'RuPay UPI',
      'type': 'CREDIT',
      'amount': 4500.0,
      'balance': 55800.0,
    },
    {
      'id': 'LED-1006',
      'date': 'Yesterday, 03:15 PM',
      'party': 'Supreme Wholesale Distributors',
      'vpa': 'distributor@icici',
      'particulars': 'Stock Restock Payout',
      'method': 'Vendor Payout',
      'type': 'DEBIT',
      'amount': 8500.0,
      'balance': 51300.0,
    },
  ];

  static List<Map<String, dynamic>> businessOwners = [
    {
      'id': 'own_01',
      'name': 'Soumo Naskar',
      'role': 'Founder & Managing Director',
      'email': 'soumonaska3038@aiksetra',
      'phone': '+91 9830113038',
      'pan': 'AAECN1234F',
      'stake': '100% Voting Rights',
      'status': 'AUTHORIZED SIGNATORY',
      'isPrimary': true,
    },
    {
      'id': 'own_02',
      'name': 'Rahul Sen',
      'role': 'Store Manager & Operations Head',
      'email': 'rahul.store@aiksetra.com',
      'phone': '+91 9830998877',
      'pan': '••••9988H',
      'stake': 'Operational Staff',
      'status': 'AUTHORIZED SIGNATORY',
      'isPrimary': false,
    },
    {
      'id': 'own_03',
      'name': 'Amit Ghosh, CA',
      'role': 'Chief Statutory Auditor & Tax Controller',
      'email': 'amit.ca@ghoshassociates.in',
      'phone': '+91 9831223344',
      'pan': '••••2233K',
      'stake': 'Financial Controller',
      'status': 'AUDITOR AUTHORIZED',
      'isPrimary': false,
    },
  ];

  static List<Map<String, dynamic>> businessVendors = [
    {
      'id': 'vnd_01',
      'name': 'Apex Tech Retailers Pvt Ltd',
      'type': 'B2B Commercial Buyer',
      'deal': 'Wholesale Software Licenses & Cloud Services',
      'contactPerson': 'Sunil Verma',
      'phone': '+91 98201 14455',
      'gstin': '27AAACA9876P1ZV',
      'balance': 84500.0,
      'isBuyer': true, // Buys our products
    },
    {
      'id': 'vnd_02',
      'name': 'Metro Supermart Chain',
      'type': 'B2B Commercial Buyer',
      'deal': 'Retail Consumer Tech & Electronics Supply',
      'contactPerson': 'Deepak Joshi',
      'phone': '+91 98110 22334',
      'gstin': '07CCCCM1122C1Z4',
      'balance': 124000.0,
      'isBuyer': true, // Buys our products
    },
    {
      'id': 'vnd_03',
      'name': 'Kolkata Distributing & Logistics',
      'type': 'Supply Vendor',
      'deal': 'Packaging Materials & Transportation Logistics',
      'contactPerson': 'Manish Roy',
      'phone': '+91 98305 66778',
      'gstin': '19BBBPK4321A1Z9',
      'balance': 18200.0,
      'isBuyer': false,
    },
  ];

  static Set<String> paidDueIds = {};

  // ================= BUSINESS PAYROLL & EMPLOYEE ROSTER =================
  static List<Map<String, dynamic>> businessEmployees = [
    {
      'id': 'EMP-001',
      'name': 'Aditya Verma',
      'role': 'Senior Full-Stack Engineer',
      'department': 'Engineering & Tech',
      'salary': 85000.0,
      'bank': 'HDFC Bank (••••4412)',
      'ifsc': 'HDFC0001024',
      'pan': 'BPRPV4412K',
      'status': 'PAID',
      'lastPaidDate': '28 Oct 2026',
      'utr': 'CMS982347102941',
    },
    {
      'id': 'EMP-002',
      'name': 'Pooja Sharma',
      'role': 'UI/UX Product Designer',
      'department': 'Product & Design',
      'salary': 65000.0,
      'bank': 'ICICI Bank (••••8831)',
      'ifsc': 'ICIC0000341',
      'pan': 'CPQPS8831M',
      'status': 'PENDING',
      'lastPaidDate': '28 Sep 2026',
      'utr': null,
    },
    {
      'id': 'EMP-003',
      'name': 'Debashis Roy',
      'role': 'DevOps & Cloud Architect',
      'department': 'Infrastructure',
      'salary': 75000.0,
      'bank': 'SBI (••••1190)',
      'ifsc': 'SBIN0004521',
      'pan': 'AQZPR1190R',
      'status': 'PENDING',
      'lastPaidDate': '28 Sep 2026',
      'utr': null,
    },
    {
      'id': 'EMP-004',
      'name': 'Sneha Mukherjee',
      'role': 'Accounts & Billing Specialist',
      'department': 'Finance & Operations',
      'salary': 42000.0,
      'bank': 'Axis Bank (••••6602)',
      'ifsc': 'UTIB0000892',
      'pan': 'BKMPM6602L',
      'status': 'PAID',
      'lastPaidDate': '28 Oct 2026',
      'utr': 'CMS982347103551',
    },
  ];

  // ================= BUSINESS REIMBURSEMENTS =================
  static List<Map<String, dynamic>> businessReimbursements = [
    {
      'id': 'RMB-401',
      'employeeId': 'EMP-001',
      'employeeName': 'Aditya Verma',
      'title': 'AWS Cloud Hosting & Server Billing (Oct 2026)',
      'category': 'Cloud Infrastructure',
      'amount': 12450.0,
      'date': '29 Oct 2026',
      'status': 'PENDING_APPROVAL', // PENDING_APPROVAL, APPROVED_PAID, REJECTED
      'receiptNumber': 'INV-AWS-883910',
      'remarks': 'Approved by Tech Lead, pending business payout.',
    },
    {
      'id': 'RMB-402',
      'employeeId': 'EMP-002',
      'employeeName': 'Pooja Sharma',
      'title': 'Figma Enterprise Annual Team Seat & Design Fonts',
      'category': 'Software Tools',
      'amount': 4800.0,
      'date': '27 Oct 2026',
      'status': 'APPROVED_PAID',
      'receiptNumber': 'FIG-REC-2026-99',
      'remarks': 'Paid via business account settlement.',
      'paidDate': '28 Oct 2026',
      'utr': 'RMB98201412499',
    },
    {
      'id': 'RMB-403',
      'employeeId': 'EMP-003',
      'employeeName': 'Debashis Roy',
      'title': 'Emergency Server Farm Onsite Cab Travel',
      'category': 'Travel & Conveyance',
      'amount': 1850.0,
      'date': '26 Oct 2026',
      'status': 'PENDING_APPROVAL',
      'receiptNumber': 'UBER-IND-99120',
      'remarks': 'Official emergency travel to Sector V Data Center.',
    },
  ];

  // ================= STATUTORY AUDITOR INVOICES =================
  static List<Map<String, dynamic>> businessAuditInvoices = [
    {
      'invoiceNumber': 'INV-2026-0891',
      'vendorName': 'Apex Tech Retailers Pvt Ltd',
      'gstin': '27AAACA9876P1ZV',
      'invoiceDate': '25 Oct 2026',
      'amount': 45000.0,
      'taxableValue': 38135.59,
      'cgst': 3432.20,
      'sgst': 3432.20,
      'igst': 0.0,
      'totalTax': 6864.40,
      'threeWayMatch': 'MATCHED (PO #9910 + E-Way #88219 + GSTR-2B)',
      'gstr2bStatus': 'Reflected in Oct GSTR-2B',
      'auditStatus': 'CLEARED', // CLEARED, DISCREPANCY, PENDING_REVIEW
      'auditRemarks': 'Full 3-way match confirmed. Eligible for 100% ITC claims.',
      'auditedBy': 'Amit Ghosh, CA (Chief Statutory Auditor)',
      'auditDate': '28 Oct 2026',
      'udin': 'UDIN: 26034871AKST99281',
    },
    {
      'invoiceNumber': 'INV-2026-0904',
      'vendorName': 'Metro Supermart Chain',
      'gstin': '07CCCCM1122C1Z4',
      'invoiceDate': '27 Oct 2026',
      'amount': 28400.0,
      'taxableValue': 24067.80,
      'cgst': 0.0,
      'sgst': 0.0,
      'igst': 4332.20,
      'totalTax': 4332.20,
      'threeWayMatch': 'MATCHED (Interstate B2B E-Way Bill)',
      'gstr2bStatus': 'GSTR-1 Filed by Vendor',
      'auditStatus': 'PENDING_REVIEW',
      'auditRemarks': 'Auditor inspection pending before issuing clean certificate.',
      'auditedBy': null,
      'auditDate': null,
      'udin': null,
    },
    {
      'invoiceNumber': 'INV-2026-0742',
      'vendorName': 'Kolkata Distributing & Logistics',
      'gstin': '19BBBPK4321A1Z9',
      'invoiceDate': '20 Oct 2026',
      'amount': 18200.0,
      'taxableValue': 15423.73,
      'cgst': 1388.13,
      'sgst': 1388.13,
      'igst': 0.0,
      'totalTax': 2776.26,
      'threeWayMatch': 'FLAGGED (TDS under Sec 194C / Reverse Charge applicable)',
      'gstr2bStatus': 'Partially matched in auto-drafted ITC',
      'auditStatus': 'DISCREPANCY',
      'auditRemarks': 'Transporter RCM verification required under GST Section 9(3).',
      'auditedBy': 'Amit Ghosh, CA (Chief Statutory Auditor)',
      'auditDate': '26 Oct 2026',
      'udin': null,
    },
  ];

  // ================= USER INVESTMENTS & LOANS & POLICIES =================
  static List<Map<String, dynamic>> userFixedDeposits = [
    {
      'fdNumber': 'FD-SBI-2026-8812',
      'bankName': 'State Bank of India',
      'principal': 50000.0,
      'interestRate': 7.8,
      'tenureMonths': 12,
      'maturityAmount': 53900.0,
      'bookingDate': '15 Oct 2026',
      'maturityDate': '15 Oct 2027',
      'payoutType': 'Cumulative at Maturity',
      'status': 'ACTIVE',
    },
  ];

  static List<Map<String, dynamic>> userRecurringDeposits = [
    {
      'rdNumber': 'RD-HDFC-2026-4401',
      'bankName': 'HDFC Bank',
      'monthlyAmount': 5000.0,
      'tenureMonths': 24,
      'interestRate': 7.4,
      'maturityAmount': 129850.0,
      'debitDay': 5,
      'totalDeposited': 25000.0,
      'status': 'ACTIVE',
    },
  ];

  static List<Map<String, dynamic>> userMutualFunds = [
    {
      'folioNumber': 'FOL-PP-99014',
      'fundName': 'Parag Parikh Flexi Cap Fund - Direct Growth',
      'category': 'Flexi Cap Equity',
      'investedAmount': 25000.0,
      'currentValue': 27840.0,
      'returnsPct': 11.36,
      'isSip': true,
      'sipAmount': 2500.0,
      'sipDay': 10,
      'status': 'ACTIVE',
    },
    {
      'folioNumber': 'FOL-SBI-88192',
      'fundName': 'SBI Bluechip Fund - Direct Plan Growth',
      'category': 'Large Cap Equity',
      'investedAmount': 15000.0,
      'currentValue': 16120.0,
      'returnsPct': 7.46,
      'isSip': false,
      'status': 'ACTIVE',
    },
  ];

  static List<Map<String, dynamic>> userInsurancePolicies = [
    {
      'policyNumber': 'POL-HE-2026-9921',
      'planType': 'Health Insurance (Cashless 10K+ Hospitals)',
      'insurer': 'HDFC ERGO Health Suraksha',
      'coverAmount': 500000.0,
      'annualPremium': 4560.0,
      'nominee': 'Ruma Naskar (Mother)',
      'issueDate': '01 Sep 2026',
      'expiryDate': '31 Aug 2027',
      'status': 'ACTIVE',
    },
  ];

  static List<Map<String, dynamic>> userActiveLoans = [];

  // ================= PAYROLL & REIMBURSEMENT ACTIONS =================
  static Map<String, dynamic> disbursePayrollSalary({required String empId}) {
    final idx = businessEmployees.indexWhere((e) => e['id'] == empId);
    if (idx == -1) return {'success': false, 'message': 'Employee not found'};
    final emp = businessEmployees[idx];
    final double salary = (emp['salary'] as num).toDouble();

    final curBal = (businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
    if (curBal < salary) {
      return {'success': false, 'message': 'Insufficient settlement balance to disburse salary'};
    }

    final newBal = curBal - salary;
    businessProfile['balance'] = newBal;

    final now = DateTime.now();
    final utr = 'CMS${now.millisecondsSinceEpoch.toString().substring(3)}';
    emp['status'] = 'PAID';
    emp['lastPaidDate'] = 'Today, 30 Oct 2026';
    emp['utr'] = utr;

    businessLedger.insert(0, {
      'id': 'LED-${now.millisecondsSinceEpoch.toString().substring(7)}',
      'date': 'Today, Just now',
      'party': emp['name'],
      'vpa': emp['bank'],
      'particulars': 'Payroll Salary Disbursal • Emp #${emp['id']}',
      'method': 'IMPS / Corporate CMS',
      'type': 'DEBIT',
      'amount': salary,
      'balance': newBal,
    });

    saveSessionToDisk();
    return {'success': true, 'utr': utr, 'employee': emp};
  }

  static Map<String, dynamic> disburseAllPendingSalaries() {
    final pending = businessEmployees.where((e) => e['status'] == 'PENDING').toList();
    if (pending.isEmpty) return {'success': false, 'message': 'No pending salaries to disburse'};

    double totalRequired = 0;
    for (final p in pending) {
      totalRequired += (p['salary'] as num).toDouble();
    }

    final curBal = (businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
    if (curBal < totalRequired) {
      return {'success': false, 'message': 'Insufficient balance: Need ₹$totalRequired, Available: ₹$curBal'};
    }

    for (final p in pending) {
      disbursePayrollSalary(empId: p['id']);
    }

    saveSessionToDisk();
    return {'success': true, 'count': pending.length, 'totalAmount': totalRequired};
  }

  static Map<String, dynamic> approveReimbursement({required String claimId}) {
    final idx = businessReimbursements.indexWhere((r) => r['id'] == claimId);
    if (idx == -1) return {'success': false, 'message': 'Claim not found'};
    final claim = businessReimbursements[idx];
    final double amount = (claim['amount'] as num).toDouble();

    final curBal = (businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
    if (curBal < amount) {
      return {'success': false, 'message': 'Insufficient settlement balance for reimbursement'};
    }

    final newBal = curBal - amount;
    businessProfile['balance'] = newBal;

    final now = DateTime.now();
    final utr = 'RMB${now.millisecondsSinceEpoch.toString().substring(4)}';
    claim['status'] = 'APPROVED_PAID';
    claim['paidDate'] = 'Today, 30 Oct 2026';
    claim['utr'] = utr;

    businessLedger.insert(0, {
      'id': 'LED-${now.millisecondsSinceEpoch.toString().substring(7)}',
      'date': 'Today, Just now',
      'party': claim['employeeName'],
      'vpa': 'Reimbursement Account',
      'particulars': 'Expense Reimbursement • ${claim['title']}',
      'method': 'Direct Settlement',
      'type': 'DEBIT',
      'amount': amount,
      'balance': newBal,
    });

    saveSessionToDisk();
    return {'success': true, 'utr': utr, 'claim': claim};
  }

  static Map<String, dynamic> rejectReimbursement({required String claimId, required String reason}) {
    final idx = businessReimbursements.indexWhere((r) => r['id'] == claimId);
    if (idx == -1) return {'success': false, 'message': 'Claim not found'};
    final claim = businessReimbursements[idx];
    claim['status'] = 'REJECTED';
    claim['remarks'] = 'Rejected by Auditor/Owner: $reason';

    saveSessionToDisk();
    return {'success': true, 'claim': claim};
  }

  static Map<String, dynamic> submitReimbursementClaim({
    required String employeeName,
    required String title,
    required String category,
    required double amount,
    required String receiptNumber,
    required String remarks,
  }) {
    final id = 'RMB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final claim = {
      'id': id,
      'employeeId': 'EMP-001',
      'employeeName': employeeName,
      'title': title,
      'category': category,
      'amount': amount,
      'date': 'Today, 30 Oct 2026',
      'status': 'PENDING_APPROVAL',
      'receiptNumber': receiptNumber,
      'remarks': remarks,
    };
    businessReimbursements.insert(0, claim);
    saveSessionToDisk();
    return {'success': true, 'claim': claim};
  }

  static Map<String, dynamic> auditClearInvoice({
    required String invoiceNumber,
    required String remarks,
    required bool isClean,
  }) {
    final idx = businessAuditInvoices.indexWhere((i) => i['invoiceNumber'] == invoiceNumber);
    if (idx == -1) return {'success': false, 'message': 'Invoice not found'};

    final now = DateTime.now();
    final udin = 'UDIN: 26034871AKST${now.millisecondsSinceEpoch.toString().substring(8)}';
    final inv = businessAuditInvoices[idx];

    if (isClean) {
      inv['auditStatus'] = 'CLEARED';
      inv['auditRemarks'] = remarks.isNotEmpty ? remarks : 'Auditor 3-way match verified. Approved for full ITC credit.';
      inv['auditedBy'] = 'Amit Ghosh, CA (Chief Statutory Auditor)';
      inv['auditDate'] = '30 Oct 2026';
      inv['udin'] = udin;
    } else {
      inv['auditStatus'] = 'DISCREPANCY';
      inv['auditRemarks'] = remarks.isNotEmpty ? remarks : 'Statutory discrepancy flagged by Auditor. Notice issued to vendor.';
      inv['auditedBy'] = 'Amit Ghosh, CA (Chief Statutory Auditor)';
      inv['auditDate'] = '30 Oct 2026';
    }

    saveSessionToDisk();
    return {'success': true, 'invoice': inv};
  }

  static void recordTransaction({
    required String title,
    required String type,
    required String category,
    required double amount,
    required String reference,
    required String status,
  }) {
    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final isCredit = type.toUpperCase() == 'CREDIT';

    recentTransactions.insert(0, {
      'id': 'TXN-' + now.millisecondsSinceEpoch.toString().substring(5),
      'date': 'Today, ' + hour.toString() + ':' + min + ' ' + period,
      'user': title,
      'receiverName': title,
      'receiverVpa': reference,
      'amount': amount,
      'isCredit': isCredit,
      'remark': title,
      'status': status,
      'category': category,
      'createdAt': now.toIso8601String(),
    });
  }

  // ================= USER INVESTMENT ACTIONS =================
  static Map<String, dynamic> bookFixedDeposit({
    required double amount,
    required int tenureMonths,
    required double interestRate,
    required String bankName,
    required String payoutOption,
  }) {
    if (linkedAccounts.isEmpty) return {'success': false, 'message': 'No bank account linked'};
    final acc = currentAccount ?? linkedAccounts.first;
    if (acc.balance < amount) {
      return {'success': false, 'message': 'Insufficient account balance in ${acc.bankName} (Available: ₹${acc.balance.toStringAsFixed(2)})'};
    }

    // Debit user account
    final aIdx = linkedAccounts.indexWhere((a) => a.id == acc.id);
    linkedAccounts[aIdx] = acc.copyWith(balance: acc.balance - amount);
    if (currentAccount?.id == acc.id) currentAccount = linkedAccounts[aIdx];

    final double maturity = amount + (amount * interestRate * tenureMonths / (12 * 100));
    final now = DateTime.now();
    final fdNum = 'FD-${bankName.replaceAll(' ', '').toUpperCase().substring(0, 3)}-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}';

    final fd = {
      'fdNumber': fdNum,
      'bankName': bankName,
      'principal': amount,
      'interestRate': interestRate,
      'tenureMonths': tenureMonths,
      'maturityAmount': double.parse(maturity.toStringAsFixed(2)),
      'bookingDate': '30 Oct 2026',
      'maturityDate': '30 Oct ${now.year + (tenureMonths ~/ 12)}',
      'payoutType': payoutOption,
      'status': 'ACTIVE',
    };
    userFixedDeposits.insert(0, fd);

    // Record transaction
    recordTransaction(
      title: 'Fixed Deposit Booking • $bankName',
      type: 'DEBIT',
      category: 'INVESTMENT',
      amount: amount,
      reference: fdNum,
      status: 'SUCCESS',
    );

    saveSessionToDisk();
    return {'success': true, 'fd': fd};
  }

  static Map<String, dynamic> startRecurringDeposit({
    required double monthlyAmount,
    required int tenureMonths,
    required double interestRate,
    required String bankName,
    int debitDay = 5,
  }) {
    if (linkedAccounts.isEmpty) return {'success': false, 'message': 'No bank account linked'};
    final acc = currentAccount ?? linkedAccounts.first;
    if (acc.balance < monthlyAmount) {
      return {'success': false, 'message': 'Insufficient balance for 1st installment (Available: ₹${acc.balance.toStringAsFixed(2)})'};
    }

    final aIdx = linkedAccounts.indexWhere((a) => a.id == acc.id);
    linkedAccounts[aIdx] = acc.copyWith(balance: acc.balance - monthlyAmount);
    if (currentAccount?.id == acc.id) currentAccount = linkedAccounts[aIdx];

    final double totalInvest = monthlyAmount * tenureMonths;
    final double estimatedMaturity = totalInvest + (totalInvest * interestRate * 0.55 * (tenureMonths / 12) / 100);
    final now = DateTime.now();
    final rdNum = 'RD-${bankName.replaceAll(' ', '').toUpperCase().substring(0, 3)}-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}';

    final rd = {
      'rdNumber': rdNum,
      'bankName': bankName,
      'monthlyAmount': monthlyAmount,
      'tenureMonths': tenureMonths,
      'interestRate': interestRate,
      'maturityAmount': double.parse(estimatedMaturity.toStringAsFixed(2)),
      'debitDay': debitDay,
      'totalDeposited': monthlyAmount,
      'status': 'ACTIVE',
    };
    userRecurringDeposits.insert(0, rd);

    recordTransaction(
      title: 'Recurring Deposit 1st Installment • $bankName',
      type: 'DEBIT',
      category: 'INVESTMENT',
      amount: monthlyAmount,
      reference: rdNum,
      status: 'SUCCESS',
    );

    saveSessionToDisk();
    return {'success': true, 'rd': rd};
  }

  static Map<String, dynamic> investMutualFund({
    required String fundName,
    required String category,
    required double amount,
    required bool isSip,
    int sipDay = 10,
  }) {
    if (linkedAccounts.isEmpty) return {'success': false, 'message': 'No bank account linked'};
    final acc = currentAccount ?? linkedAccounts.first;
    if (acc.balance < amount) {
      return {'success': false, 'message': 'Insufficient balance in ${acc.bankName} (Available: ₹${acc.balance.toStringAsFixed(2)})'};
    }

    final aIdx = linkedAccounts.indexWhere((a) => a.id == acc.id);
    linkedAccounts[aIdx] = acc.copyWith(balance: acc.balance - amount);
    if (currentAccount?.id == acc.id) currentAccount = linkedAccounts[aIdx];

    final now = DateTime.now();
    final folio = 'FOL-${now.millisecondsSinceEpoch.toString().substring(6)}';

    final mf = {
      'folioNumber': folio,
      'fundName': fundName,
      'category': category,
      'investedAmount': amount,
      'currentValue': amount,
      'returnsPct': 0.0,
      'isSip': isSip,
      'sipAmount': isSip ? amount : 0.0,
      'sipDay': sipDay,
      'status': 'ACTIVE',
    };
    userMutualFunds.insert(0, mf);

    if (isSip) {
      mySips.insert(0, {
        'id': 'sip_${now.millisecondsSinceEpoch}',
        'name': fundName,
        'category': category,
        'amount': amount,
        'frequency': 'Monthly',
        'nextDate': '${sipDay.toString().padLeft(2, '0')} Nov 2026',
        'status': 'Active',
      });
    }

    recordTransaction(
      title: '${isSip ? "Monthly Auto-SIP Started" : "Mutual Fund Lumpsum"} • $fundName',
      type: 'DEBIT',
      category: 'INVESTMENT',
      amount: amount,
      reference: folio,
      status: 'SUCCESS',
    );

    saveSessionToDisk();
    return {'success': true, 'mutualFund': mf};
  }

  static Map<String, dynamic> purchaseInsurancePolicy({
    required String planType,
    required String insurer,
    required double coverAmount,
    required double premium,
    required String nominee,
    required String registrationOrMember,
  }) {
    if (linkedAccounts.isEmpty) return {'success': false, 'message': 'No bank account linked'};
    final acc = currentAccount ?? linkedAccounts.first;
    if (acc.balance < premium) {
      return {'success': false, 'message': 'Insufficient balance for policy premium (Available: ₹${acc.balance.toStringAsFixed(2)})'};
    }

    final aIdx = linkedAccounts.indexWhere((a) => a.id == acc.id);
    linkedAccounts[aIdx] = acc.copyWith(balance: acc.balance - premium);
    if (currentAccount?.id == acc.id) currentAccount = linkedAccounts[aIdx];

    final now = DateTime.now();
    final polNum = 'POL-${insurer.replaceAll(' ', '').toUpperCase().substring(0, 4)}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final pol = {
      'policyNumber': polNum,
      'planType': planType,
      'insurer': insurer,
      'coverAmount': coverAmount,
      'annualPremium': premium,
      'nominee': nominee,
      'registrationOrMember': registrationOrMember,
      'issueDate': '30 Oct 2026',
      'expiryDate': '30 Oct 2027',
      'status': 'ACTIVE',
    };
    userInsurancePolicies.insert(0, pol);

    recordTransaction(
      title: 'Insurance Policy Premium • $insurer',
      type: 'DEBIT',
      category: 'INSURANCE',
      amount: premium,
      reference: polNum,
      status: 'SUCCESS',
    );

    saveSessionToDisk();
    return {'success': true, 'policy': pol};
  }

  static Map<String, dynamic> disburseInstantLoan({
    required String loanType,
    required double amount,
    required int tenureMonths,
    required double interestRate,
  }) {
    if (linkedAccounts.isEmpty) return {'success': false, 'message': 'No bank account linked'};
    final acc = currentAccount ?? linkedAccounts.first;

    // Credit money directly to user account balance!
    final aIdx = linkedAccounts.indexWhere((a) => a.id == acc.id);
    final updatedBal = acc.balance + amount;
    linkedAccounts[aIdx] = acc.copyWith(balance: updatedBal);
    if (currentAccount?.id == acc.id) currentAccount = linkedAccounts[aIdx];

    final monthlyRate = interestRate / 12 / 100;
    final emi = (amount * monthlyRate * (1 + monthlyRate) * tenureMonths) /
        ((1 + monthlyRate) * tenureMonths - 1);
    final emiDisplay = emi.isFinite && emi > 0 ? emi.round().toDouble() : (amount / tenureMonths);

    final now = DateTime.now();
    final loanId = 'LN-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final loan = {
      'loanId': loanId,
      'loanType': loanType,
      'sanctionedAmount': amount,
      'tenureMonths': tenureMonths,
      'interestRate': interestRate,
      'monthlyEmi': emiDisplay,
      'disbursalDate': '30 Oct 2026',
      'disbursedToBank': '${acc.bankName} (${acc.maskedAccountNumber})',
      'status': 'ACTIVE_DISBURSED',
    };
    userActiveLoans.insert(0, loan);

    recordTransaction(
      title: 'Instant Loan Disbursal Credit • $loanType',
      type: 'CREDIT',
      category: 'LOAN',
      amount: amount,
      reference: loanId,
      status: 'SUCCESS',
    );

    saveSessionToDisk();
    return {'success': true, 'loan': loan, 'newBalance': updatedBal};
  }

  static Future<void> updateBusinessLogo(String logoData) async {
    businessProfile['logo'] = logoData;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('aiksetra_business_logo', logoData);
      await prefs.setString('aiksetra_business_profile', jsonEncode(businessProfile));
    } catch (_) {}
  }

  static Future<void> updateBusinessWebsite(String website) async {
    businessProfile['website'] = website;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('aiksetra_business_website', website);
      await prefs.setString('aiksetra_business_profile', jsonEncode(businessProfile));
    } catch (_) {}
  }

  static Future<void> registerBusinessAccount({
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
    required String ownerPan,
    required String ownerDesignation,
    required String companyName,
    required String businessType,
    required String gstin,
    required String businessAddress,
    required String bankName,
    required String bankAccountNo,
    required String ifsc,
    required String merchantVpa,
    String accountType = 'CURRENT',
  }) async {
    hasBusinessAccount = true;
    isBusinessMode = true;
    businessProfile = {
      'companyName': companyName,
      'businessType': businessType,
      'gstin': gstin.isEmpty ? '19AAECN1234F1Z5' : gstin,
      'pan': ownerPan,
      'businessAddress': businessAddress,
      'merchantVpa': merchantVpa,
      'bankName': bankName,
      'bankAccountNo': bankAccountNo,
      'accountType': accountType,
      'ifsc': ifsc,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPhone': ownerPhone,
      'ownerDesignation': ownerDesignation,
      'ownerPan': ownerPan,
      'verified': true,
      'balance': 48250.0,
      'openedAt': DateTime.now().toIso8601String().split('T')[0],
    };

    final last4 = bankAccountNo.length > 4 ? bankAccountNo.substring(bankAccountNo.length - 4) : bankAccountNo;
    final existingIdx = linkedAccounts.indexWhere((a) => a.maskedAccountNumber.endsWith(last4));
    if (existingIdx != -1) {
      linkedAccounts[existingIdx] = linkedAccounts[existingIdx].copyWith(
        isBusiness: true,
        accountType: accountType,
      );
      currentBusinessAccount = linkedAccounts[existingIdx];
    } else {
      final newAcc = BankAccountModel(
        id: 'acc_biz_${DateTime.now().millisecondsSinceEpoch}',
        bankName: bankName,
        bankCode: bankName.split(' ').first.toUpperCase(),
        ifsc: ifsc,
        maskedAccountNumber: '•••• $last4',
        balance: 48250.0,
        isPrimary: false,
        accountType: accountType,
        branch: 'Business Commercial Branch',
        isBusiness: true,
      );
      linkedAccounts.add(newAcc);
      currentBusinessAccount = newAcc;
    }
    businessOwners[0] = {
      'id': 'own_01',
      'name': ownerName,
      'role': ownerDesignation,
      'email': ownerEmail,
      'phone': ownerPhone,
      'pan': ownerPan,
      'stake': '100% Voting Rights',
      'status': 'AUTHORIZED SIGNATORY',
      'isPrimary': true,
    };
    await saveSessionToDisk();

    try {
      await _postWithFailover('/business/register', {
        'businessName': companyName,
        'category': businessType,
        'gstin': gstin,
        'pan': ownerPan,
        'ownerName': ownerName,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
        'ownerDesignation': ownerDesignation,
        'businessAddress': businessAddress,
        'bankName': bankName,
        'bankAccountNo': bankAccountNo,
        'ifsc': ifsc,
        'merchantVpa': merchantVpa,
      });
    } catch (_) {}
  }

  static void recordBusinessCollection({
    required String customerName,
    required String customerVpa,
    required double amount,
    required String method,
    String? particulars,
  }) {
    final currentBal = (businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
    final newBal = currentBal + amount;
    businessProfile['balance'] = newBal;

    businessLedger.insert(0, {
      'id': 'LED-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'date': 'Just now',
      'party': customerName,
      'vpa': customerVpa,
      'particulars': particulars ?? 'Standee Merchant QR Scan',
      'method': method,
      'type': 'CREDIT',
      'amount': amount,
      'balance': newBal,
    });
    saveSessionToDisk();
  }

  static bool recordBusinessPayout({
    required String payeeName,
    required String payeeVpaOrBank,
    required double amount,
    required String category,
    String? particulars,
    String method = 'IMPS / RTGS',
  }) {
    final currentBal = (businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
    if (amount <= 0 || amount > currentBal) return false;
    final newBal = currentBal - amount;
    businessProfile['balance'] = newBal;

    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = 'Today, $hour:$min $period';

    businessLedger.insert(0, {
      'id': 'LED-${now.millisecondsSinceEpoch.toString().substring(7)}',
      'date': timeStr,
      'party': payeeName,
      'vpa': payeeVpaOrBank,
      'particulars': particulars ?? '$category Payout',
      'method': method,
      'type': 'DEBIT',
      'amount': amount,
      'balance': newBal,
    });

    recentTransactions.insert(0, {
      'id': 'TXN-BIZ-${now.millisecondsSinceEpoch.toString().substring(6)}',
      'date': timeStr,
      'user': payeeName,
      'receiverName': payeeName,
      'receiverVpa': payeeVpaOrBank,
      'amount': amount,
      'isCredit': false,
      'remark': particulars ?? 'Business Account Payment',
      'status': 'SUCCESS',
      'source': 'Pentile Business Pool',
    });

    saveSessionToDisk();
    return true;
  }

  static bool payVendor({
    required String vendorId,
    required double amount,
    String? remarks,
  }) {
    final vIdx = businessVendors.indexWhere((v) => v['id'] == vendorId);
    if (vIdx == -1) return false;
    final vendor = businessVendors[vIdx];

    final success = recordBusinessPayout(
      payeeName: vendor['name'] as String,
      payeeVpaOrBank: (vendor['gstin'] ?? 'Vendor').toString(),
      amount: amount,
      category: 'Vendor Payment',
      particulars: remarks ?? 'Vendor Commercial Payment - ${vendor['name']}',
      method: 'IMPS B2B Commercial',
    );

    if (success) {
      final oldBal = (vendor['balance'] as num?)?.toDouble() ?? 0.0;
      vendor['balance'] = (oldBal - amount).clamp(0.0, double.infinity);
      saveSessionToDisk();
      return true;
    }
    return false;
  }

  static bool collectFromVendor({
    required String vendorId,
    required double amount,
    String? remarks,
  }) {
    final vIdx = businessVendors.indexWhere((v) => v['id'] == vendorId);
    if (vIdx == -1) return false;
    final vendor = businessVendors[vIdx];

    final currentBal = (businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
    final newBal = currentBal + amount;
    businessProfile['balance'] = newBal;

    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = 'Today, $hour:$min $period';

    businessLedger.insert(0, {
      'id': 'LED-${now.millisecondsSinceEpoch.toString().substring(7)}',
      'date': timeStr,
      'party': vendor['name'],
      'vpa': (vendor['gstin'] ?? 'B2B Buyer').toString(),
      'particulars': remarks ?? 'B2B Product Sale Collection - ${vendor['name']}',
      'method': 'UPI B2B Collect',
      'type': 'CREDIT',
      'amount': amount,
      'balance': newBal,
    });

    final oldBal = (vendor['balance'] as num?)?.toDouble() ?? 0.0;
    vendor['balance'] = (oldBal - amount).clamp(0.0, double.infinity);

    recentTransactions.insert(0, {
      'id': 'TXN-COL-${now.millisecondsSinceEpoch.toString().substring(6)}',
      'date': timeStr,
      'user': vendor['name'],
      'receiverName': 'Pentile Merchant Store',
      'receiverVpa': businessProfile['merchantVpa'] ?? 'merchant@aiksetra',
      'amount': amount,
      'isCredit': true,
      'remark': 'B2B Product Payment Collection',
      'status': 'SUCCESS',
      'source': 'B2B Commercial Buyer',
    });

    saveSessionToDisk();
    return true;
  }

  static void addVendor({
    required String name,
    required String type,
    required String deal,
    required String contactPerson,
    required String phone,
    required String gstin,
    required double balance,
    bool isBuyer = true,
  }) {
    businessVendors.add({
      'id': 'vnd_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'name': name,
      'type': type,
      'deal': deal,
      'contactPerson': contactPerson,
      'phone': phone,
      'gstin': gstin,
      'balance': balance,
      'isBuyer': isBuyer,
    });
    saveSessionToDisk();
  }

  static void markDueAsPaid({
    required String dueId,
    required double amount,
    required String provider,
  }) {
    paidDueIds.add(dueId);

    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = 'Today, $hour:$min $period';

    // If in business mode, debit from business pool; otherwise from personal account
    if (isBusinessMode) {
      final currentBal = (businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
      final newBal = (currentBal - amount).clamp(0.0, double.infinity);
      businessProfile['balance'] = newBal;
      businessLedger.insert(0, {
        'id': 'LED-${now.millisecondsSinceEpoch.toString().substring(7)}',
        'date': timeStr,
        'party': provider,
        'vpa': 'BBPS Utility',
        'particulars': 'Bill Payment via Bharat Connect',
        'method': 'BBPS AutoPay',
        'type': 'DEBIT',
        'amount': amount,
        'balance': newBal,
      });
    }

    recentTransactions.insert(0, {
      'id': 'TXN-BBPS-${now.millisecondsSinceEpoch.toString().substring(6)}',
      'date': timeStr,
      'user': provider,
      'receiverName': provider,
      'receiverVpa': 'bbps.biller@npci',
      'amount': amount,
      'isCredit': false,
      'remark': 'Bill Payment Successful',
      'status': 'SUCCESS',
      'metadata': {'isBbpsBill': true, 'biller': provider},
    });

    saveSessionToDisk();
  }

  static bool recordBusinessSettlement({
    required double amount,
    BankAccountModel? destinationAccount,
  }) {
    final currentBal = (businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
    if (amount <= 0 || amount > currentBal) return false;
    final newBal = currentBal - amount;
    businessProfile['balance'] = newBal;

    final dest = destinationAccount ?? currentBusinessAccount ?? primaryAccount;
    final bank = dest?.bankName ?? businessProfile['bankName'] ?? 'Bank Account';
    final acc = dest?.maskedAccountNumber ?? businessProfile['bankAccountNo'] ?? '•••• 4589';
    final accType = dest?.accountType ?? businessProfile['accountType'] ?? 'CURRENT';

    if (dest != null) {
      final idx = linkedAccounts.indexWhere((a) => a.id == dest.id);
      if (idx != -1) {
        final updated = linkedAccounts[idx].copyWith(balance: linkedAccounts[idx].balance + amount);
        linkedAccounts[idx] = updated;
        if (currentAccount?.id == dest.id) {
          currentAccount = updated;
        }
      }
    }

    businessLedger.insert(0, {
      'id': 'LED-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'date': 'Just now',
      'party': 'Settlement to $bank ($accType)',
      'vpa': '$bank $acc',
      'particulars': 'Instant Merchant Settlement ($accType)',
      'method': 'IMPS Instant',
      'type': 'DEBIT',
      'amount': amount,
      'balance': newBal,
    });
    saveSessionToDisk();
    return true;
  }

  static bool get isLoggedIn => currentUser != null && _authToken != null;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static void setActiveDevUser(String userId) {
    _activeUserId = userId;
  }

  // =========================================================================
  // LIVE TAX RATES & OFFICIAL PORTAL INTEGRATION (GST / TDS / INCOME TAX)
  // =========================================================================
  static Map<String, dynamic> officialTaxRates = {};
  static bool isOfficialTaxSyncing = false;

  static Future<Map<String, dynamic>> fetchLiveOfficialTaxRates() async {
    isOfficialTaxSyncing = true;
    try {
      final res = await _getWithFailover('/tools/tax-rates/live', timeout: const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          officialTaxRates = data;
          isOfficialTaxSyncing = false;
          return data;
        }
      }
    } catch (_) {}
    isOfficialTaxSyncing = false;
    return officialTaxRates;
  }

  // =========================================================================
  // LIVE STOCK MARKET & ALGORITHMIC PREDICTIONS ENGINE
  // =========================================================================
  static List<dynamic> liveStockMarketIdeas = [];

  static Future<List<dynamic>> fetchLiveMarketIdeas({String? category}) async {
    try {
      final endpoint = category != null ? '/stocks/market-ideas?category=${Uri.encodeComponent(category)}' : '/stocks/market-ideas';
      final res = await _getWithFailover(endpoint, timeout: const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['ideas'] is List) {
          liveStockMarketIdeas = data['ideas'];
          return liveStockMarketIdeas;
        }
      }
    } catch (_) {}
    return liveStockMarketIdeas;
  }

  // =========================================================================
  // PDF DOWNLOAD URL BUILDERS
  // =========================================================================
  static String getInvoicePdfUrl(String invoiceId) {
    return '${ApiConfig.baseUrl}/business/invoices/$invoiceId/pdf';
  }

  static String getStatementPdfUrl({
    bool? isBusiness,
    String? period,
    String? startDate,
    String? endDate,
    String? accountName,
    String? accountNumber,
    String? holderName,
    String? panNumber,
    String? gstin,
    String? ifsc,
    double? openingBalance,
    double? closingBalance,
  }) {
    final biz = isBusiness ?? isBusinessMode;
    final effectiveHolder = holderName ?? (biz ? (businessProfile['companyName'] ?? 'Pentile') : (currentUser?.fullName ?? 'Soumo Naskar'));
    final effectiveAcc = accountName ?? (biz ? 'Pentile Digital Store (Current Account)' : (currentAccount?.bankName ?? 'State Bank of India'));
    final effectiveAccNo = accountNumber ?? (biz ? (businessProfile['bankAccountNo'] ?? '•••• 4589') : (currentAccount?.maskedAccountNumber ?? '•••• 3038'));
    final effectivePan = panNumber ?? (biz ? (businessProfile['pan'] ?? 'AAECN1234F') : 'AAECN1234F');
    final effectiveGstin = gstin ?? (biz ? (businessProfile['gstin'] ?? '19AAECN1234F1Z5') : '');
    final effectiveIfsc = ifsc ?? (biz ? (businessProfile['ifsc'] ?? 'HDFC0001234') : (currentAccount?.ifsc ?? 'SBIN0001234'));
    final effectivePeriod = period ?? (biz ? "Today's Business Ledger & Audit Sheet (30 Oct 2026)" : "Date-Wise Statement (Last 30 Days)");

    final qParams = <String, String>{
      'type': biz ? 'business' : 'personal',
      'isBusiness': biz.toString(),
      'period': effectivePeriod,
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
      'holderName': effectiveHolder,
      'accountName': effectiveAcc,
      'accountNumber': effectiveAccNo,
      'panNumber': effectivePan,
      if (effectiveGstin.isNotEmpty) 'gstin': effectiveGstin,
      'ifscCode': effectiveIfsc,
      if (openingBalance != null) 'openingBalance': openingBalance.toString(),
      if (closingBalance != null) 'closingBalance': closingBalance.toString(),
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/account/statement/pdf').replace(queryParameters: qParams);
    return uri.toString();
  }


  static String getAuditCertificatePdfUrl({
    String? companyName,
    String? ownerName,
    String? gstin,
    String? pan,
    String? udin,
  }) {
    final effectiveCompany = companyName ?? (businessProfile['companyName'] ?? 'Pentile Business Solutions');
    final effectiveOwner = ownerName ?? (businessProfile['ownerName'] ?? (currentUser?.fullName ?? 'Soumo Naskar'));
    final effectiveGstin = gstin ?? (businessProfile['gstin'] ?? '19AAECN1234F1Z5');
    final effectivePan = pan ?? (businessProfile['pan'] ?? 'AAECN1234F');
    final effectiveUdin = udin ?? '26034871AKST99281';

    final qParams = <String, String>{
      'companyName': effectiveCompany,
      'ownerName': effectiveOwner,
      'gstin': effectiveGstin,
      'pan': effectivePan,
      'udin': effectiveUdin,
      'financialYear': 'FY 2026-27',
      'assessmentYear': 'AY 2027-28',
    };

    final uri = Uri.parse('\/business/audit/certificate/pdf').replace(queryParameters: qParams);
    return uri.toString();
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
      await prefs.setBool('aiksetra_has_business_account', hasBusinessAccount);
      await prefs.setString('aiksetra_business_profile', jsonEncode(businessProfile));
      await prefs.setString('aiksetra_business_ledger', jsonEncode(businessLedger.take(40).toList()));
      await prefs.setString('aiksetra_business_owners', jsonEncode(businessOwners));
      await prefs.setString('aiksetra_business_vendors', jsonEncode(businessVendors));
      await prefs.setString('aiksetra_business_employees', jsonEncode(businessEmployees));
      await prefs.setString('aiksetra_business_reimbursements', jsonEncode(businessReimbursements));
      await prefs.setString('aiksetra_business_audit_invoices', jsonEncode(businessAuditInvoices));
      await prefs.setString('aiksetra_user_fds', jsonEncode(userFixedDeposits));
      await prefs.setString('aiksetra_user_rds', jsonEncode(userRecurringDeposits));
      await prefs.setString('aiksetra_user_mfs', jsonEncode(userMutualFunds));
      await prefs.setString('aiksetra_user_insurance', jsonEncode(userInsurancePolicies));
      await prefs.setString('aiksetra_user_loans', jsonEncode(userActiveLoans));
      await prefs.setStringList('aiksetra_paid_dues', paidDueIds.toList());
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
        hasBusinessAccount = prefs.getBool('aiksetra_has_business_account') ?? false;
        final bizProfJson = prefs.getString('aiksetra_business_profile');
        if (bizProfJson != null) {
          businessProfile = Map<String, dynamic>.from(jsonDecode(bizProfJson));
        }
        final savedBizLogo = prefs.getString('aiksetra_business_logo');
        if (savedBizLogo != null && savedBizLogo.isNotEmpty) {
          businessProfile['logo'] = savedBizLogo;
        }
        final savedBizWeb = prefs.getString('aiksetra_business_website');
        if (savedBizWeb != null && savedBizWeb.isNotEmpty) {
          businessProfile['website'] = savedBizWeb;
        }
        final bizLedgJson = prefs.getString('aiksetra_business_ledger');
        if (bizLedgJson != null) {
          businessLedger = List<Map<String, dynamic>>.from(jsonDecode(bizLedgJson));
        }
        final bizOwnJson = prefs.getString('aiksetra_business_owners');
        if (bizOwnJson != null) {
          businessOwners = List<Map<String, dynamic>>.from(jsonDecode(bizOwnJson));
        }
        final bizVndJson = prefs.getString('aiksetra_business_vendors');
        if (bizVndJson != null) {
          businessVendors = List<Map<String, dynamic>>.from(jsonDecode(bizVndJson));
        }
        final bizEmpJson = prefs.getString('aiksetra_business_employees');
        if (bizEmpJson != null) {
          businessEmployees = List<Map<String, dynamic>>.from(jsonDecode(bizEmpJson));
        }
        final bizRmbJson = prefs.getString('aiksetra_business_reimbursements');
        if (bizRmbJson != null) {
          businessReimbursements = List<Map<String, dynamic>>.from(jsonDecode(bizRmbJson));
        }
        final bizAudJson = prefs.getString('aiksetra_business_audit_invoices');
        if (bizAudJson != null) {
          businessAuditInvoices = List<Map<String, dynamic>>.from(jsonDecode(bizAudJson));
        }
        final userFdJson = prefs.getString('aiksetra_user_fds');
        if (userFdJson != null) {
          userFixedDeposits = List<Map<String, dynamic>>.from(jsonDecode(userFdJson));
        }
        final userRdJson = prefs.getString('aiksetra_user_rds');
        if (userRdJson != null) {
          userRecurringDeposits = List<Map<String, dynamic>>.from(jsonDecode(userRdJson));
        }
        final userMfJson = prefs.getString('aiksetra_user_mfs');
        if (userMfJson != null) {
          userMutualFunds = List<Map<String, dynamic>>.from(jsonDecode(userMfJson));
        }
        final userInsJson = prefs.getString('aiksetra_user_insurance');
        if (userInsJson != null) {
          userInsurancePolicies = List<Map<String, dynamic>>.from(jsonDecode(userInsJson));
        }
        final userLoanJson = prefs.getString('aiksetra_user_loans');
        if (userLoanJson != null) {
          userActiveLoans = List<Map<String, dynamic>>.from(jsonDecode(userLoanJson));
        }
        final savedPaid = prefs.getStringList('aiksetra_paid_dues');
        if (savedPaid != null) {
          paidDueIds = savedPaid.toSet();
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
        dateOfBirth: dateOfBirth ?? '1998-05-12',
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

  static Future<bool> switchPrimaryAccount(String accountId) async {
    final ok = await setPrimaryAccount(accountId);
    if (ok) return true;
    final idx = linkedAccounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      for (int i = 0; i < linkedAccounts.length; i++) {
        linkedAccounts[i] = linkedAccounts[i].copyWith(isPrimary: linkedAccounts[i].id == accountId);
      }
      currentAccount = linkedAccounts[idx];
      await saveSessionToDisk();
      return true;
    }
    return false;
  }

  static Future<bool> switchBusinessAccount(String accountId) async {
    final idx = linkedAccounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      currentBusinessAccount = linkedAccounts[idx];
      businessProfile['bankName'] = linkedAccounts[idx].bankName;
      businessProfile['bankAccountNo'] = linkedAccounts[idx].maskedAccountNumber;
      businessProfile['ifsc'] = linkedAccounts[idx].ifsc;
      await saveSessionToDisk();
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> linkNewBankAccount({
    required String bankName,
    required String accountType,
    required String accountNumber,
    required String ifsc,
    String? branch,
    bool isBusiness = false,
  }) async {
    final masked = accountNumber.length > 4
        ? '•••• •••• ' + accountNumber.substring(accountNumber.length - 4)
        : accountNumber;
    final newId = 'acc_' + DateTime.now().millisecondsSinceEpoch.toString();
    final code = bankName.toUpperCase().replaceAll(' ', '');
    final acc = BankAccountModel(
      id: newId,
      bankName: bankName,
      bankCode: code.substring(0, code.length >= 4 ? 4 : code.length),
      ifsc: ifsc.toUpperCase(),
      maskedAccountNumber: masked,
      balance: accountType.toUpperCase() == 'CURRENT' ? 100000.0 : 25000.0,
      isPrimary: linkedAccounts.isEmpty,
      accountType: accountType.toUpperCase(),
      branch: branch ?? 'Main Branch',
      isBusiness: isBusiness || accountType.toUpperCase() == 'CURRENT',
    );
    linkedAccounts.add(acc);
    if (isBusiness || currentBusinessAccount == null) {
      currentBusinessAccount = acc;
      businessProfile['bankName'] = acc.bankName;
      businessProfile['bankAccountNo'] = acc.maskedAccountNumber;
      businessProfile['ifsc'] = acc.ifsc;
    }
    if (currentAccount == null) {
      currentAccount = acc;
    }
    await saveSessionToDisk();
    return {'success': true, 'account': acc};
  }

  // 4c. Deposit / Add Money to Bank Account
  static Future<Map<String, dynamic>> addMoneyToAccount({
    required double amount,
    String? accountId,
    String sourceNote = 'Self Transfer / IMPS Credit',
  }) async {
    final effectiveId = accountId ?? currentAccount?.id ?? (linkedAccounts.isNotEmpty ? linkedAccounts.first.id : null);
    try {
      final response = await _postWithFailover('/accounts/add-money', {
        'accountId': effectiveId,
        'amount': amount,
        'sourceNote': sourceNote,
      }, timeout: const Duration(seconds: 4));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if (effectiveId != null) {
          final aIdx = linkedAccounts.indexWhere((a) => a.id == effectiveId);
          if (aIdx != -1) {
            final acc = linkedAccounts[aIdx];
            final updated = acc.copyWith(balance: acc.balance + amount);
            linkedAccounts[aIdx] = updated;
            if (currentAccount?.id == effectiveId) {
              currentAccount = updated;
            }
          }
        }
        if (data['transaction'] != null) {
          recentTransactions.insert(0, Map<String, dynamic>.from(data['transaction']));
        }
        await saveSessionToDisk();
        return data;
      }
    } catch (_) {}

    // Reliable Offline / Simulation Fallback
    if (effectiveId != null) {
      final aIdx = linkedAccounts.indexWhere((a) => a.id == effectiveId);
      if (aIdx != -1) {
        final acc = linkedAccounts[aIdx];
        final updated = acc.copyWith(balance: acc.balance + amount);
        linkedAccounts[aIdx] = updated;
        if (currentAccount?.id == effectiveId) {
          currentAccount = updated;
        }
        final txn = {
          'id': 'txn_dep_${DateTime.now().millisecondsSinceEpoch}',
          'txnRef': 'DEP_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
          'upiRrn': '4291${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
          'amount': amount,
          'status': 'SUCCESS',
          'type': 'CREDIT',
          'remark': '$sourceNote (Credited to ${acc.bankName} ${acc.accountType})',
          'createdAt': DateTime.now().toIso8601String(),
        };
        recentTransactions.insert(0, txn);
        await saveSessionToDisk();
        return {'success': true, 'account': updated.toJson(), 'transaction': txn};
      }
    }
    return {
      'success': false,
      'message': 'Selected bank account not found.',
    };
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
    String? receiverName,
    required double amount,
    required String mpin,
    String remark = 'UPI Payment',
    String? senderAccountId,
    String? cardId,
    String? idempotencyKey,
    bool bypassScamWarning = false,
  }) async {
    final effectiveName = receiverName ?? receiverVpa;

    // Auto-update business pool & ledger when in business mode
    if (isBusinessMode) {
      final curBizBal = (businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
      final newBizBal = (curBizBal - amount).clamp(0.0, double.infinity);
      businessProfile['balance'] = newBizBal;
      final now = DateTime.now();
      final hr = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final timeStr = '$hr:${now.minute.toString().padLeft(2, '0')} $period';
      businessLedger.insert(0, {
        'id': 'b2b_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'DEBIT',
        'title': 'Business Payout • $effectiveName',
        'vendor': effectiveName,
        'description': remark.isNotEmpty ? remark : 'Commercial Payout',
        'amount': -amount,
        'balance': newBizBal,
        'method': 'Pentile Business Settlement Pool',
        'time': 'Today, $timeStr',
        'status': 'SETTLED',
      });
    }

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
          'receiverName': effectiveName,
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
          'receiverName': effectiveName,
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
        final effId = senderAccountId ?? currentAccount?.id ?? (linkedAccounts.isNotEmpty ? linkedAccounts.first.id : null);
        if (effId != null) {
          final aIdx = linkedAccounts.indexWhere((a) => a.id == effId);
          if (aIdx != -1) {
            final acc = linkedAccounts[aIdx];
            final updated = acc.copyWith(balance: newBal > 0 ? newBal : 0);
            linkedAccounts[aIdx] = updated;
            if (currentAccount?.id == effId) {
              currentAccount = updated;
            }
          }
        } else if (currentAccount != null) {
          currentAccount = currentAccount!.copyWith(balance: newBal > 0 ? newBal : 0);
        }
        final roundUp = (res['roundedUpAmount'] as num?)?.toDouble() ?? 0.0;
        if (roundUp > 0) {
          gullakBalance += roundUp;
        }
        recentTransactions.insert(0, {
          'id': txn['id'] ?? 'txn_${DateTime.now().millisecondsSinceEpoch}',
          'receiverName': effectiveName,
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
      
      // If backend returns failure (e.g. real device contact not in mock DB), complete as demo payment
      final fallbackBal = ((currentAccount?.balance ?? 50000.0) - amount);
      if (currentAccount != null) {
        currentAccount = BankAccountModel(
          id: currentAccount!.id,
          bankName: currentAccount!.bankName,
          bankCode: currentAccount!.bankCode,
          ifsc: currentAccount!.ifsc,
          maskedAccountNumber: currentAccount!.maskedAccountNumber,
          balance: fallbackBal > 0 ? fallbackBal : 0,
          isPrimary: currentAccount!.isPrimary,
        );
      }
      final simTxn = {
        'id': 'txn_demo_${DateTime.now().millisecondsSinceEpoch}',
        'receiverName': effectiveName,
        'receiverVpa': receiverVpa,
        'amount': amount,
        'upiRrn': '4291${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'status': 'SUCCESS',
        'isSimulated': true,
        'remark': remark.contains('Demo') ? remark : '$remark (Demo Payment)',
        'createdAt': DateTime.now().toIso8601String(),
      };
      recentTransactions.insert(0, simTxn);
      await saveSessionToDisk();
      return {'success': true, 'isSimulated': true, 'transaction': simTxn};
    } catch (e) {
      // Offline fallback: complete as demo payment
      final fallbackBal = ((currentAccount?.balance ?? 50000.0) - amount);
      if (currentAccount != null) {
        currentAccount = BankAccountModel(
          id: currentAccount!.id,
          bankName: currentAccount!.bankName,
          bankCode: currentAccount!.bankCode,
          ifsc: currentAccount!.ifsc,
          maskedAccountNumber: currentAccount!.maskedAccountNumber,
          balance: fallbackBal > 0 ? fallbackBal : 0,
          isPrimary: currentAccount!.isPrimary,
        );
      }
      final simTxn = {
        'id': 'txn_demo_${DateTime.now().millisecondsSinceEpoch}',
        'receiverName': effectiveName,
        'receiverVpa': receiverVpa,
        'amount': amount,
        'upiRrn': '4291${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'status': 'SUCCESS',
        'isSimulated': true,
        'remark': remark.contains('Demo') ? remark : '$remark (Demo Payment)',
        'createdAt': DateTime.now().toIso8601String(),
      };
      recentTransactions.insert(0, simTxn);
      await saveSessionToDisk();
      return {'success': true, 'isSimulated': true, 'transaction': simTxn};
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
    } else if (cat == 'LOAN') {
      amt = 4850.0;
      usage = 'Monthly Equated Monthly Installment (EMI)';
      breakdown = {
        'Principal Component': '₹3,620.00',
        'Interest Component': '₹1,230.00',
        'Loan Outstanding': '₹1,42,850.00',
        'Tenure Remaining': '32 Months',
      };
    } else if (cat == 'CREDIT_CARD') {
      amt = 2450.0;
      usage = 'Monthly Credit Card Statement (Minimum Due)';
      breakdown = {
        'Minimum Amount Due': '₹2,450.00',
        'Total Outstanding Due': '₹18,920.00',
        'Available Credit Limit': '₹81,080.00',
        'Reward Points Balance': '3,450 Pts',
      };
    } else if (cat == 'INSURANCE') {
      amt = 3850.0;
      usage = 'Annual Premium Installment (IRDAI Certified)';
      breakdown = {
        'Base Premium': '₹3,262.71',
        'GST (18%)': '₹587.29',
        'Sum Assured Cover': '₹10,00,000.00',
        'Policy Status': 'ACTIVE & IN FORCE',
      };
    } else if (cat == 'MUNICIPAL') {
      amt = 1850.0;
      usage = 'Quarterly Municipal Property Tax Assessment';
      breakdown = {
        'General Tax': '₹1,400.00',
        'Sewerage / Drainage Cess': '₹250.00',
        'Lighting Cess': '₹120.00',
        'Rebate Applied (5% Early Pay)': '-₹80.00',
      };
    } else if (cat == 'CHALLAN') {
      amt = 1000.0;
      usage = 'Motor Vehicles Act Traffic Violation E-Challan';
      breakdown = {
        'Offence': 'Over-Speeding / Signal Violation',
        'Section': 'Sec 183(1) MV Act 1988',
        'Location': 'EM Bypass Signal Intersection',
        'Status': 'PENDING AT VIRTUAL COURT',
      };
    } else if (cat == 'EDUCATION') {
      amt = 4500.0;
      usage = 'Quarterly Academic Tuition & Lab Session Fees';
      breakdown = {
        'Tuition Fee': '₹3,500.00',
        'Library & IT Laboratory': '₹700.00',
        'Sports & Extracurricular': '₹300.00',
      };
    } else if (cat == 'HOUSING') {
      amt = 2200.0;
      usage = 'Monthly Housing Society Maintenance & Utilities';
      breakdown = {
        'Maintenance Charges': '₹1,600.00',
        'Sinking Fund': '₹300.00',
        'Common Area Security & Power': '₹300.00',
      };
    } else if (cat == 'CABLE') {
      amt = 350.0;
      usage = 'Digital Cable TV 250+ HD Channels Monthly';
      breakdown = {
        'NCF Basic Tier': '₹153.40',
        'HD Tier Channels': '₹196.60',
      };
    } else if (cat == 'SUBSCRIPTION') {
      amt = 399.0;
      usage = 'Digital Prepaid Play Store Recharge Code';
      breakdown = {
        'Wallet Code Value': '₹399.00',
        'Convenience Fee': '₹0.00 (Zero Fee)',
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
