import '../models/ai_model.dart';
import '../models/ai_provider.dart';
import 'gemini_model_listing_service.dart';
import 'openai_model_listing_service.dart';

abstract class ModelListingService {
  Future<List<AiModel>> listModels({
    required AiProvider provider,
    required String apiKey,
  });
}

class ProviderModelListingService implements ModelListingService {
  ProviderModelListingService({
    OpenAiModelListingService? openAi,
    GeminiModelListingService? gemini,
  }) : _openAi = openAi ?? OpenAiModelListingService(),
       _gemini = gemini ?? GeminiModelListingService();

  final OpenAiModelListingService _openAi;
  final GeminiModelListingService _gemini;

  @override
  Future<List<AiModel>> listModels({
    required AiProvider provider,
    required String apiKey,
  }) {
    return switch (provider) {
      AiProvider.openAi => _openAi.listModels(apiKey: apiKey),
      AiProvider.gemini => _gemini.listModels(apiKey: apiKey),
    };
  }
}

class ModelListingException implements Exception {
  const ModelListingException(this.message);

  final String message;
}
