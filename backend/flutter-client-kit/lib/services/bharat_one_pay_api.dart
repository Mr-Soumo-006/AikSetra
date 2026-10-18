import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/user_model.dart';
import '../models/scam_shield_model.dart';
import '../models/cross_border_model.dart';
import '../models/protected_pay_model.dart';

class BharatOnePayApi {
  static String? _authToken;
  static String _activeUserId = ApiConfig.defaultDevUserId;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static void setActiveDevUser(String userId) {
    _activeUserId = userId;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-user-id': _activeUserId,
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // 1. Device Registration / Login
  static Future<Map<String, dynamic>> registerDevice({
    required String phone,
    required String deviceId,
    required String simId,
    String? fullName,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register-device'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'deviceId': deviceId,
        'simId': simId,
        'fullName': fullName,
      }),
    );
    final data = jsonDecode(response.body);
    if (data['token'] != null) {
      setAuthToken(data['token']);
    }
    return data;
  }

  // 2. Resolve VPA
  static Future<Map<String, dynamic>> resolveVpa(String vpa) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/vpa/resolve?vpa=$vpa'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // 3. Scam Shield Risk Analysis
  static Future<ScamShieldResult> analyzeScamRisk({
    required String receiverVpa,
    required double amount,
    String remark = '',
    String? expectedPayeeName,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/scam-shield/analyze'),
      headers: _headers,
      body: jsonEncode({
        'receiverVpa': receiverVpa,
        'amount': amount,
        'remark': remark,
        'expectedPayeeName': expectedPayeeName,
      }),
    );
    final data = jsonDecode(response.body);
    return ScamShieldResult.fromJson(data['analysis']);
  }

  // 4. Pay via Core UPI
  static Future<Map<String, dynamic>> payUpi({
    required String receiverVpa,
    required double amount,
    required String mpin,
    String remark = 'UPI Payment',
    String? senderAccountId,
    String? idempotencyKey,
    bool bypassScamWarning = false,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/pay'),
      headers: _headers,
      body: jsonEncode({
        'receiverVpa': receiverVpa,
        'amount': amount,
        'mpin': mpin,
        'remark': remark,
        'senderAccountId': senderAccountId,
        'idempotencyKey': idempotencyKey,
        'bypassScamShieldWarning': bypassScamWarning,
      }),
    );
    return jsonDecode(response.body);
  }

  // 5. UPI Lite PIN-less Payment (< ₹500)
  static Future<Map<String, dynamic>> payLite({
    required String receiverVpa,
    required double amount,
    String remark = 'UPI Lite',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/lite-pay'),
      headers: _headers,
      body: jsonEncode({
        'receiverVpa': receiverVpa,
        'amount': amount,
        'remark': remark,
      }),
    );
    return jsonDecode(response.body);
  }

  // 6. Cross-Border FX Quote
  static Future<CrossBorderQuoteModel> getCrossBorderQuote({
    required String targetCurrency,
    double? targetAmount,
    double? sourceAmountInr,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/cross-border/quote'),
      headers: _headers,
      body: jsonEncode({
        'targetCurrency': targetCurrency,
        'targetAmount': targetAmount,
        'sourceAmountInr': sourceAmountInr,
      }),
    );
    final data = jsonDecode(response.body);
    return CrossBorderQuoteModel.fromJson(data['quote']);
  }

  // 7. Protected Pay (Escrow)
  static Future<ProtectedPayEscrowModel> initiateProtectedPay({
    required String sellerVpa,
    required String sellerName,
    required double amount,
    required String itemDescription,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/protected-pay/initiate'),
      headers: _headers,
      body: jsonEncode({
        'sellerVpa': sellerVpa,
        'sellerName': sellerName,
        'amount': amount,
        'itemDescription': itemDescription,
      }),
    );
    final data = jsonDecode(response.body);
    return ProtectedPayEscrowModel.fromJson(data['escrow']);
  }

  static Future<void> confirmDelivery(String escrowId) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/protected-pay/$escrowId/confirm-delivery'),
      headers: _headers,
    );
  }

  static Future<void> disputeEscrow(String escrowId, String reason) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/protected-pay/$escrowId/dispute'),
      headers: _headers,
      body: jsonEncode({'disputeReason': reason}),
    );
  }
}
