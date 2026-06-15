enum AiChatRole { user, assistant }

class AiChatMessage {
  const AiChatMessage({required this.role, required this.text});

  const AiChatMessage.user(String text)
    : this(role: AiChatRole.user, text: text);

  const AiChatMessage.assistant(String text)
    : this(role: AiChatRole.assistant, text: text);

  final AiChatRole role;
  final String text;
}
