import 'ai_provider.dart';

class AiModel {
  const AiModel({
    required this.provider,
    required this.id,
    required this.displayName,
  });

  final AiProvider provider;
  final String id;
  final String displayName;
}
