import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_model.dart';
import '../models/ai_provider.dart';
import 'model_listing_service.dart';

class OpenAiModelListingService {
  OpenAiModelListingService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<AiModel>> listModels({required String apiKey}) async {
    final response = await _client.get(
      Uri.https('api.openai.com', '/v1/models'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode != 200) {
      throw const ModelListingException(
        'OpenAI models could not be loaded. Check the saved API key and try again.',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, Object?> || body['data'] is! List) {
      throw const ModelListingException(
        'OpenAI returned an unexpected model list.',
      );
    }

    final models = <AiModel>[];
    for (final item in body['data'] as List) {
      if (item is! Map<String, Object?>) {
        continue;
      }

      final id = item['id'];
      if (id is String && _isLikelyTextToolModel(id)) {
        models.add(
          AiModel(provider: AiProvider.openAi, id: id, displayName: id),
        );
      }
    }

    models.sort((a, b) => a.displayName.compareTo(b.displayName));
    return models;
  }

  bool _isLikelyTextToolModel(String id) {
    final normalized = id.toLowerCase();
    // The OpenAI list-models endpoint exposes IDs and ownership metadata, not
    // a per-model MCP/tool flag, so filter by known text/reasoning families and
    // exclude specialized non-text model families.
    final excludedTerms = [
      'embedding',
      'embed',
      'image',
      'dall-e',
      'audio',
      'tts',
      'speech',
      'transcribe',
      'transcription',
      'whisper',
      'moderation',
      'realtime',
      'search',
      'sora',
      'video',
      'vision',
      'computer-use',
    ];

    if (excludedTerms.any(normalized.contains)) {
      return false;
    }

    return _isLikelyCurrentGptFamily(normalized) ||
        normalized.startsWith('chatgpt-') ||
        RegExp(r'^o\d').hasMatch(normalized);
  }

  bool _isLikelyCurrentGptFamily(String normalizedId) {
    final match = RegExp(r'^gpt-(\d+)').firstMatch(normalizedId);
    final majorVersion = int.tryParse(match?.group(1) ?? '');

    return majorVersion != null && majorVersion >= 4;
  }
}
