import '../models/ai_chat_message.dart';
import '../models/ai_provider.dart';
import 'ai_chat_service.dart';
import 'gemini_chat_service.dart';
import 'openai_chat_service.dart';

class ProviderAiChatService implements AiChatService {
  ProviderAiChatService({OpenAiChatService? openAi, GeminiChatService? gemini})
    : _openAi = openAi ?? OpenAiChatService(),
      _gemini = gemini ?? GeminiChatService();

  final OpenAiChatService _openAi;
  final GeminiChatService _gemini;

  @override
  Future<String> sendMessage({
    required AiProvider provider,
    required String apiKey,
    required String modelId,
    required List<AiChatMessage> messages,
  }) {
    return switch (provider) {
      AiProvider.openAi => _openAi.sendMessage(
        apiKey: apiKey,
        modelId: modelId,
        messages: messages,
      ),
      AiProvider.gemini => _gemini.sendMessage(
        apiKey: apiKey,
        modelId: modelId,
        messages: messages,
      ),
    };
  }
}
