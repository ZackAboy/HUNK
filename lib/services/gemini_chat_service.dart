import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_chat_message.dart';
import 'ai_chat_service.dart';

class GeminiChatService {
  GeminiChatService({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 30);

  final http.Client _client;
  final Duration _timeout;

  Future<String> sendMessage({
    required String apiKey,
    required String modelId,
    required List<AiChatMessage> messages,
  }) async {
    try {
      final response = await _client
          .post(
            _generateContentUri(apiKey: apiKey, modelId: modelId),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {
                    'text':
                        'You are a concise AI fitness coach. Give practical, safe, text-only guidance. No health data integrations are connected yet.',
                  },
                ],
              },
              'contents': [for (final message in messages) _toContent(message)],
              'generationConfig': {'maxOutputTokens': 700},
            }),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiChatException(_statusMessage(response.statusCode));
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, Object?>) {
        throw const AiChatException('Gemini returned an unexpected response.');
      }

      final text = _extractCandidateText(body);
      if (text == null || text.trim().isEmpty) {
        throw AiChatException(_emptyTextMessage(body));
      }

      return text.trim();
    } on AiChatException {
      rethrow;
    } on TimeoutException {
      throw const AiChatException('Gemini request timed out. Try again.');
    } on FormatException {
      throw const AiChatException('Gemini returned malformed JSON.');
    } catch (_) {
      throw const AiChatException(
        'Gemini request failed. Check the saved API key and model.',
      );
    }
  }

  Uri _generateContentUri({required String apiKey, required String modelId}) {
    final modelName = modelId.startsWith('models/')
        ? modelId
        : 'models/$modelId';

    return Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/$modelName:generateContent',
      {'key': apiKey},
    );
  }

  Map<String, Object> _toContent(AiChatMessage message) {
    return {
      'role': switch (message.role) {
        AiChatRole.user => 'user',
        AiChatRole.assistant => 'model',
      },
      'parts': [
        {'text': message.text},
      ],
    };
  }

  String? _extractCandidateText(Map<String, Object?> body) {
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }

    final parts = <String>[];
    for (final candidate in candidates) {
      if (candidate is! Map<String, Object?>) {
        continue;
      }

      final content = candidate['content'];
      if (content is! Map<String, Object?>) {
        continue;
      }

      final contentParts = content['parts'];
      if (contentParts is! List) {
        continue;
      }

      for (final part in contentParts) {
        if (part is! Map<String, Object?>) {
          continue;
        }

        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) {
          parts.add(text.trim());
        }
      }
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join('\n\n');
  }

  String _emptyTextMessage(Map<String, Object?> body) {
    final promptFeedback = body['promptFeedback'];
    if (promptFeedback is Map<String, Object?>) {
      final blockReason = promptFeedback['blockReason'];
      if (blockReason is String && blockReason.isNotEmpty) {
        return 'Gemini returned no text response. Prompt feedback: $blockReason.';
      }
    }

    final candidates = body['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final firstCandidate = candidates.first;
      if (firstCandidate is Map<String, Object?>) {
        final finishReason = firstCandidate['finishReason'];
        if (finishReason is String && finishReason.isNotEmpty) {
          return 'Gemini returned no text response. Finish reason: $finishReason.';
        }
      }
    }

    return 'Gemini returned no text response.';
  }

  String _statusMessage(int statusCode) {
    return 'Gemini request failed with status $statusCode. Check the saved API key and selected model.';
  }
}
