import '../models/ai_chat_message.dart';
import '../models/ai_provider.dart';

abstract class AiChatService {
  Future<String> sendMessage({
    required AiProvider provider,
    required String apiKey,
    required String modelId,
    required List<AiChatMessage> messages,
  });
}

class AiChatException implements Exception {
  const AiChatException(this.message);

  final String message;
}
