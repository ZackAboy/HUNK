import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/ai_provider.dart';
import '../models/ai_settings.dart';

abstract class SettingsStorage {
  Future<AiSettings> loadSettings();

  Future<void> saveActiveProvider(AiProvider provider);

  Future<void> saveApiKey({
    required AiProvider provider,
    required String apiKey,
  });

  Future<String?> readApiKey(AiProvider provider);

  Future<void> removeApiKey(AiProvider provider);

  Future<void> saveSelectedModel({
    required AiProvider provider,
    required String modelId,
  });
}

class SecureSettingsStorage implements SettingsStorage {
  SecureSettingsStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? FlutterSecureStorage();

  static const _activeProviderKey = 'ai.active_provider';
  static const _openAiApiKeyKey = 'ai.openai.api_key';
  static const _geminiApiKeyKey = 'ai.gemini.api_key';
  static const _openAiSelectedModelKey = 'ai.openai.selected_model';
  static const _geminiSelectedModelKey = 'ai.gemini.selected_model';

  final FlutterSecureStorage _storage;

  @override
  Future<AiSettings> loadSettings() async {
    final activeProviderValue = await _storage.read(key: _activeProviderKey);
    final hasOpenAiKey = await _storage.containsKey(key: _openAiApiKeyKey);
    final hasGeminiKey = await _storage.containsKey(key: _geminiApiKeyKey);
    final openAiSelectedModel = await _storage.read(
      key: _openAiSelectedModelKey,
    );
    final geminiSelectedModel = await _storage.read(
      key: _geminiSelectedModelKey,
    );

    return AiSettings(
      activeProvider: AiProviderLabel.fromStorageValue(activeProviderValue),
      openAiKeySaved: hasOpenAiKey,
      geminiKeySaved: hasGeminiKey,
      openAiSelectedModel: openAiSelectedModel,
      geminiSelectedModel: geminiSelectedModel,
    );
  }

  @override
  Future<void> saveActiveProvider(AiProvider provider) async {
    await _storage.write(key: _activeProviderKey, value: provider.storageValue);
  }

  @override
  Future<void> saveApiKey({
    required AiProvider provider,
    required String apiKey,
  }) async {
    await _storage.write(key: _apiKeyStorageKey(provider), value: apiKey);
    await _storage.delete(key: _selectedModelStorageKey(provider));
  }

  @override
  Future<String?> readApiKey(AiProvider provider) {
    return _storage.read(key: _apiKeyStorageKey(provider));
  }

  @override
  Future<void> removeApiKey(AiProvider provider) async {
    await _storage.delete(key: _apiKeyStorageKey(provider));
    await _storage.delete(key: _selectedModelStorageKey(provider));
  }

  @override
  Future<void> saveSelectedModel({
    required AiProvider provider,
    required String modelId,
  }) {
    return _storage.write(
      key: _selectedModelStorageKey(provider),
      value: modelId,
    );
  }

  String _apiKeyStorageKey(AiProvider provider) {
    return switch (provider) {
      AiProvider.openAi => _openAiApiKeyKey,
      AiProvider.gemini => _geminiApiKeyKey,
    };
  }

  String _selectedModelStorageKey(AiProvider provider) {
    return switch (provider) {
      AiProvider.openAi => _openAiSelectedModelKey,
      AiProvider.gemini => _geminiSelectedModelKey,
    };
  }
}
