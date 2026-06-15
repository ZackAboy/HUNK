import 'package:flutter/foundation.dart';

import '../models/ai_chat_message.dart';
import '../models/ai_provider.dart';
import '../models/ai_settings.dart';
import '../services/ai_chat_service.dart';
import '../services/settings_storage.dart';

class ChatController extends ChangeNotifier {
  ChatController({required this.storage, required this.chatService});

  final SettingsStorage storage;
  final AiChatService chatService;

  final List<AiChatMessage> _messages = [];
  bool _isSending = false;
  String? _errorMessage;

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  Future<void> sendPrompt(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || _isSending) {
      return;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final settings = await _loadChatSettings();
      final userMessage = AiChatMessage.user(trimmed);
      _messages.add(userMessage);
      notifyListeners();

      final response = await chatService.sendMessage(
        provider: settings.provider,
        apiKey: settings.apiKey,
        modelId: settings.modelId,
        messages: _messages,
      );
      _messages.add(AiChatMessage.assistant(response));
    } on _ChatConfigurationException catch (error) {
      _errorMessage = error.message;
    } on AiChatException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'The chat request failed. Try again.';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<_ResolvedChatSettings> _loadChatSettings() async {
    final settings = await _loadSettings();
    final provider = settings.activeProvider;
    if (!settings.isKeySaved(provider)) {
      throw _ChatConfigurationException(
        'No ${provider.label} API key is saved. Add one in Settings.',
      );
    }

    final modelId = settings.selectedModel(provider)?.trim();
    if (modelId == null || modelId.isEmpty) {
      throw _ChatConfigurationException(
        'No ${provider.label} model is selected. Open Settings, refresh models, and choose a model.',
      );
    }

    final apiKey = await _readApiKey(provider);
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw _ChatConfigurationException(
        'No ${provider.label} API key is saved. Add one in Settings.',
      );
    }

    return _ResolvedChatSettings(
      provider: provider,
      apiKey: apiKey,
      modelId: modelId,
    );
  }

  Future<AiSettings> _loadSettings() async {
    try {
      return await storage.loadSettings();
    } catch (_) {
      throw const _ChatConfigurationException(
        'No provider is selected. Open Settings and choose OpenAI or Google Gemini.',
      );
    }
  }

  Future<String?> _readApiKey(AiProvider provider) async {
    try {
      return await storage.readApiKey(provider);
    } catch (_) {
      throw _ChatConfigurationException(
        '${provider.label} API key could not be read. Save it again in Settings.',
      );
    }
  }
}

class _ResolvedChatSettings {
  const _ResolvedChatSettings({
    required this.provider,
    required this.apiKey,
    required this.modelId,
  });

  final AiProvider provider;
  final String apiKey;
  final String modelId;
}

class _ChatConfigurationException implements Exception {
  const _ChatConfigurationException(this.message);

  final String message;
}
