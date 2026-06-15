import 'ai_provider.dart';

class AiSettings {
  const AiSettings({
    required this.activeProvider,
    required this.openAiKeySaved,
    required this.geminiKeySaved,
    required this.openAiSelectedModel,
    required this.geminiSelectedModel,
  });

  factory AiSettings.initial() {
    return const AiSettings(
      activeProvider: AiProvider.openAi,
      openAiKeySaved: false,
      geminiKeySaved: false,
      openAiSelectedModel: null,
      geminiSelectedModel: null,
    );
  }

  final AiProvider activeProvider;
  final bool openAiKeySaved;
  final bool geminiKeySaved;
  final String? openAiSelectedModel;
  final String? geminiSelectedModel;

  bool isKeySaved(AiProvider provider) {
    return switch (provider) {
      AiProvider.openAi => openAiKeySaved,
      AiProvider.gemini => geminiKeySaved,
    };
  }

  String? selectedModel(AiProvider provider) {
    return switch (provider) {
      AiProvider.openAi => openAiSelectedModel,
      AiProvider.gemini => geminiSelectedModel,
    };
  }

  AiSettings copyWith({
    AiProvider? activeProvider,
    bool? openAiKeySaved,
    bool? geminiKeySaved,
    Object? openAiSelectedModel = _unchanged,
    Object? geminiSelectedModel = _unchanged,
  }) {
    return AiSettings(
      activeProvider: activeProvider ?? this.activeProvider,
      openAiKeySaved: openAiKeySaved ?? this.openAiKeySaved,
      geminiKeySaved: geminiKeySaved ?? this.geminiKeySaved,
      openAiSelectedModel: openAiSelectedModel == _unchanged
          ? this.openAiSelectedModel
          : openAiSelectedModel as String?,
      geminiSelectedModel: geminiSelectedModel == _unchanged
          ? this.geminiSelectedModel
          : geminiSelectedModel as String?,
    );
  }
}

const Object _unchanged = Object();
