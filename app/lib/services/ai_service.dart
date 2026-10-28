import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import 'bharat_one_pay_api.dart';

class AICitationModel {
  final String documentId;
  final String title;
  final String category;
  final String snippet;
  final double relevanceScore;

  AICitationModel({
    required this.documentId,
    required this.title,
    required this.category,
    required this.snippet,
    required this.relevanceScore,
  });

  factory AICitationModel.fromJson(Map<String, dynamic> json) {
    return AICitationModel(
      documentId: json['documentId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Official AikSetra Doc',
      category: json['category']?.toString() ?? 'General',
      snippet: json['snippet']?.toString() ?? '',
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AIMessageModel {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final List<AICitationModel> citations;
  final List<String> suggestedQuestions;
  final String? actionType;
  final Map<String, dynamic>? actionPayload;
  final DateTime createdAt;

  AIMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.citations = const [],
    this.suggestedQuestions = const [],
    this.actionType,
    this.actionPayload,
    required this.createdAt,
  });

  factory AIMessageModel.fromJson(Map<String, dynamic> json) {
    var rawCitations = json['citations'];
    List<AICitationModel> parsedCitations = [];
    if (rawCitations is List) {
      parsedCitations = rawCitations
          .whereType<Map<String, dynamic>>()
          .map((c) => AICitationModel.fromJson(c))
          .toList();
    } else if (rawCitations is String) {
      try {
        final decoded = jsonDecode(rawCitations);
        if (decoded is List) {
          parsedCitations = decoded
              .whereType<Map<String, dynamic>>()
              .map((c) => AICitationModel.fromJson(c))
              .toList();
        }
      } catch (_) {}
    }

    var rawSuggestions = json['suggested_questions'] ?? json['suggestedQuestions'];
    List<String> parsedSuggestions = [];
    if (rawSuggestions is List) {
      parsedSuggestions = rawSuggestions.map((s) => s.toString()).toList();
    } else if (rawSuggestions is String) {
      try {
        final decoded = jsonDecode(rawSuggestions);
        if (decoded is List) {
          parsedSuggestions = decoded.map((s) => s.toString()).toList();
        }
      } catch (_) {}
    }

    Map<String, dynamic>? parsedPayload;
    final rawPayload = json['action_payload'] ?? json['actionPayload'];
    if (rawPayload is Map<String, dynamic>) {
      parsedPayload = rawPayload;
    } else if (rawPayload is String) {
      try {
        final dec = jsonDecode(rawPayload);
        if (dec is Map<String, dynamic>) parsedPayload = dec;
      } catch (_) {}
    }

    return AIMessageModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? json['reply']?.toString() ?? '',
      citations: parsedCitations,
      suggestedQuestions: parsedSuggestions,
      actionType: json['action_type']?.toString() ?? json['actionType']?.toString(),
      actionPayload: parsedPayload,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AIService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'bypass-tunnel-reminder': 'true',
        if (BharatOnePayApi.authToken != null)
          'Authorization': 'Bearer ${BharatOnePayApi.authToken}',
      };

  static Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final encoded = jsonEncode(body);
    if (!Platform.isAndroid) {
      return await http
          .post(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers, body: encoded)
          .timeout(const Duration(seconds: 45));
    }
    Object? lastErr;
    for (final host in ApiConfig.candidateHosts) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrlForHost(host)}$path');
        final res = await http.post(uri, headers: _headers, body: encoded).timeout(const Duration(seconds: 45));
        if (res.statusCode < 502) {
          ApiConfig.activeHost = host;
          return res;
        }
      } catch (e) {
        lastErr = e;
      }
    }
    throw lastErr ?? const SocketException('Backend unreachable');
  }

  static Future<http.Response> _get(String path) async {
    if (!Platform.isAndroid) {
      return await http
          .get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers)
          .timeout(const Duration(seconds: 15));
    }
    Object? lastErr;
    for (final host in ApiConfig.candidateHosts) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrlForHost(host)}$path');
        final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
        if (res.statusCode < 502) {
          ApiConfig.activeHost = host;
          return res;
        }
      } catch (e) {
        lastErr = e;
      }
    }
    throw lastErr ?? const SocketException('Backend unreachable');
  }

  static Future<Map<String, dynamic>> sendMessage(String query, {String? conversationId}) async {
    try {
      final res = await _post('/ai/chat', {
        'query': query,
        if (conversationId != null) 'conversationId': conversationId,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        final err = jsonDecode(res.body);
        return {
          'success': false,
          'message': err['message'] ?? 'Failed to get response (${res.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to AI Assistant: ${e.toString()}',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final res = await _get('/ai/conversations');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> getConversation(String id) async {
    try {
      final res = await _get('/ai/conversations/$id');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> submitFeedback(String messageId, String rating, {String? comment}) async {
    try {
      final res = await _post('/ai/feedback', {
        'messageId': messageId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      });
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
