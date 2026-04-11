import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_chat_message.dart';
import 'config.dart';

class GeminiAssistantReply {
  final String reply;
  final String model;
  final bool safetySensitive;
  final bool escalationRecommended;
  final List<String> suggestedReplies;

  const GeminiAssistantReply({
    required this.reply,
    required this.model,
    required this.safetySensitive,
    required this.escalationRecommended,
    required this.suggestedReplies,
  });
}

class GeminiAiService {
  static Future<GeminiAssistantReply> sendMessage({
    required String message,
    required List<AiChatMessage> history,
    String? context,
    String? locationLabel,
    bool sosActive = false,
    double? latitude,
    double? longitude,
  }) async {
    final backendUrl = Config.backendUrl.trim();
    final backendApiKey = Config.backendApiKey.trim();

    if (backendUrl.isEmpty) {
      return const GeminiAssistantReply(
        reply: 'Gemini is not configured yet. Set BACKEND_URL in the app and GEMINI_API_KEY on the backend to enable the assistant.',
        model: 'unconfigured',
        safetySensitive: true,
        escalationRecommended: false,
        suggestedReplies: [
          'How do I trigger SOS?',
          'What should I do if I feel unsafe?',
          'Help me make a safety plan',
        ],
      );
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (backendApiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $backendApiKey';
    }

    final response = await http
        .post(
          Uri.parse('$backendUrl/api/v1/ai/chat'),
          headers: headers,
          body: jsonEncode({
            'message': message,
            'context': context,
            'locationLabel': locationLabel,
            'sosActive': sosActive,
            'latitude': latitude,
            'longitude': longitude,
            'history': history.take(12).map((item) => item.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 401) {
      throw Exception('Backend API key rejected. Check BACKEND_API_KEY on the app and server.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini request failed with HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (decoded['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final suggestedReplies = <String>[];
    final rawSuggestions = data['suggestedReplies'];
    if (rawSuggestions is List) {
      for (final item in rawSuggestions) {
        if (item is String && item.trim().isNotEmpty) {
          suggestedReplies.add(item.trim());
        }
      }
    }

    return GeminiAssistantReply(
      reply: (data['reply'] as String?)?.trim().isNotEmpty == true
          ? (data['reply'] as String).trim()
          : 'I could not generate a response right now.',
      model: (data['model'] as String?) ?? 'gemini',
      safetySensitive: data['safetySensitive'] == true,
      escalationRecommended: data['escalationRecommended'] == true,
      suggestedReplies: suggestedReplies.isNotEmpty
          ? suggestedReplies
          : const [
              'What should I do next?',
              'Make this safer',
              'Create a quick safety plan',
            ],
    );
  }
}