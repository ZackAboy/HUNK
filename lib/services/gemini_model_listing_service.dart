import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_model.dart';
import '../models/ai_provider.dart';
import 'model_listing_service.dart';

class GeminiModelListingService {
  GeminiModelListingService({http.Client? client})
    : _client = client ?? http.Client();

  static const _maxPages = 5;

  final http.Client _client;

  Future<List<AiModel>> listModels({required String apiKey}) async {
    final models = <AiModel>[];
    String? pageToken;

    for (var page = 0; page < _maxPages; page += 1) {
      final query = {'key': apiKey, 'pageSize': '1000'};
      if (pageToken != null) {
        query['pageToken'] = pageToken;
      }
      final response = await _client.get(
        Uri.https('generativelanguage.googleapis.com', '/v1beta/models', query),
      );

      if (response.statusCode != 200) {
        throw const ModelListingException(
          'Gemini models could not be loaded. Check the saved API key and try again.',
        );
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, Object?> || body['models'] is! List) {
        throw const ModelListingException(
          'Gemini returned an unexpected model list.',
        );
      }

      for (final item in body['models'] as List) {
        if (item is! Map<String, Object?>) {
          continue;
        }

        final model = _parseModel(item);
        if (model != null) {
          models.add(model);
        }
      }

      final nextPageToken = body['nextPageToken'];
      if (nextPageToken is! String || nextPageToken.isEmpty) {
        break;
      }
      pageToken = nextPageToken;
    }

    models.sort((a, b) => a.displayName.compareTo(b.displayName));
    return models;
  }

  AiModel? _parseModel(Map<String, Object?> item) {
    final generationMethods = item['supportedGenerationMethods'];
    if (generationMethods is! List ||
        !generationMethods.contains('generateContent')) {
      return null;
    }

    final id = _modelId(item);
    if (id == null || !_isLikelyTextToolModel(item, id)) {
      return null;
    }

    final displayName = item['displayName'];
    return AiModel(
      provider: AiProvider.gemini,
      id: id,
      displayName: displayName is String && displayName.isNotEmpty
          ? displayName
          : id,
    );
  }

  String? _modelId(Map<String, Object?> item) {
    final baseModelId = item['baseModelId'];
    if (baseModelId is String && baseModelId.isNotEmpty) {
      return baseModelId;
    }

    final name = item['name'];
    if (name is String && name.startsWith('models/')) {
      return name.substring('models/'.length);
    }

    return null;
  }

  bool _isLikelyTextToolModel(Map<String, Object?> item, String id) {
    final normalizedId = id.toLowerCase();
    if (!normalizedId.startsWith('gemini-')) {
      return false;
    }

    final displayName = item['displayName'];
    final description = item['description'];
    final searchable = [
      normalizedId,
      if (displayName is String) displayName,
      if (description is String) description,
    ].join(' ').toLowerCase();
    // Gemini's model list exposes supported generation methods but no explicit
    // MCP/tool flag, so keep standard text generateContent models and exclude
    // specialized media, embedding, and live-only families.
    final excludedTerms = [
      'embedding',
      'embed',
      'imagen',
      'veo',
      'lyria',
      'tts',
      'text-to-speech',
      'speech generation',
      'live',
      'audio generation',
      'image generation',
      'native image',
      'video generation',
      'realtime',
    ];

    return !excludedTerms.any(searchable.contains);
  }
}
