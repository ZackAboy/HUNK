enum AiProvider { openAi, gemini }

extension AiProviderLabel on AiProvider {
  String get label {
    return switch (this) {
      AiProvider.openAi => 'OpenAI',
      AiProvider.gemini => 'Google Gemini',
    };
  }

  String get storageValue {
    return switch (this) {
      AiProvider.openAi => 'openai',
      AiProvider.gemini => 'gemini',
    };
  }

  static AiProvider fromStorageValue(String? value) {
    return switch (value) {
      'gemini' => AiProvider.gemini,
      _ => AiProvider.openAi,
    };
  }
}
