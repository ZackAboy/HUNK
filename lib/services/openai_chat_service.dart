import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_chat_message.dart';
import 'ai_chat_service.dart';

class OpenAiChatService {
  OpenAiChatService({http.Client? client, Duration? timeout})
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
            Uri.https('api.openai.com', '/v1/responses'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': modelId,
              'input': [_forAppSystemMessage(), ...messages.map(_toInputItem)],
              'store': false,
              'max_output_tokens': 700,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiChatException(_statusMessage(response.statusCode));
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, Object?>) {
        throw const AiChatException('OpenAI returned an unexpected response.');
      }

      final text = _extractOutputText(body);
      if (text == null || text.trim().isEmpty) {
        final status = body['status'];
        if (status == 'incomplete') {
          throw const AiChatException(
            'OpenAI returned an incomplete response. Try a shorter prompt.',
          );
        }
        throw const AiChatException('OpenAI returned no text response.');
      }

      return text.trim();
    } on AiChatException {
      rethrow;
    } on TimeoutException {
      throw const AiChatException('OpenAI request timed out. Try again.');
    } on FormatException {
      throw const AiChatException('OpenAI returned malformed JSON.');
    } catch (_) {
      throw const AiChatException(
        'OpenAI request failed. Check the saved API key and model.',
      );
    }
  }

  Map<String, String> _forAppSystemMessage() {
    return const {
      'role': 'developer',
      'content':
          'You are a concise AI fitness coach. Give practical, safe, text-only guidance. No health data integrations are connected yet.',
    };
  }

  Map<String, String> _toInputItem(AiChatMessage message) {
    return {
      'role': switch (message.role) {
        AiChatRole.user => 'user',
        AiChatRole.assistant => 'assistant',
      },
      'content': message.text,
    };
  }

  String? _extractOutputText(Map<String, Object?> body) {
    final outputText = body['output_text'];
    if (outputText is String && outputText.trim().isNotEmpty) {
      return outputText;
    }

    final parts = <String>[];
    final output = body['output'];
    if (output is List) {
      for (final item in output) {
        if (item is! Map<String, Object?>) {
          continue;
        }

        final content = item['content'];
        if (content is! List) {
          continue;
        }

        for (final contentItem in content) {
          if (contentItem is! Map<String, Object?>) {
            continue;
          }

          final text = contentItem['text'];
          if (text is String && text.trim().isNotEmpty) {
            parts.add(text.trim());
          }
        }
      }
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join('\n\n');
  }

  String _statusMessage(int statusCode) {
    return 'OpenAI request failed with status $statusCode. Check the saved API key and selected model.';
  }
}
