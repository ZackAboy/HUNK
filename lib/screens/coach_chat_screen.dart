import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../models/ai_chat_message.dart';
import '../providers/chat_controller.dart';
import '../services/ai_chat_service.dart';
import '../services/context_repository.dart';
import '../services/provider_ai_chat_service.dart';
import '../services/settings_storage.dart';
import '../widgets/context_matrix_theme.dart';
import 'context_web_screen.dart';

class CoachChatScreen extends StatefulWidget {
  const CoachChatScreen({
    super.key,
    this.settingsStorage,
    this.chatService,
    this.contextRepository,
  });

  final SettingsStorage? settingsStorage;
  final AiChatService? chatService;
  final ContextRepository? contextRepository;

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  late final ChatController _chatController;
  late final ContextRepository _contextRepository;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _contextRepository = widget.contextRepository ?? SecureContextRepository();
    _chatController = ChatController(
      storage: widget.settingsStorage ?? SecureSettingsStorage(),
      chatService: widget.chatService ?? ProviderAiChatService(),
      contextRepository: _contextRepository,
    )..addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _chatController
      ..removeListener(_scrollToBottom)
      ..dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _chatController,
      builder: (context, _) {
        return Column(
          children: [
            _ChatHeader(onOpenContext: _openContextWeb),
            Expanded(
              child: _MessageList(
                chatController: _chatController,
                scrollController: _scrollController,
              ),
            ),
            if (_chatController.errorMessage != null)
              _ErrorBanner(message: _chatController.errorMessage!),
            if (_chatController.isSending) const LinearProgressIndicator(),
            _ChatComposer(
              controller: _textController,
              enabled: !_chatController.isSending,
              onSend: _sendMessage,
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final beforeCount = _chatController.messages.length;
    await _chatController.sendPrompt(_textController.text);
    if (_chatController.messages.length > beforeCount) {
      _textController.clear();
    }
  }

  Future<void> _openContextWeb() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ContextWebScreen(repository: _contextRepository);
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onOpenContext});

  final VoidCallback onOpenContext;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ContextMatrixStyle.panel.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ContextMatrixStyle.border.withValues(alpha: 0.72),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ContextMatrixStyle.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ContextMatrixStyle.teal.withValues(alpha: 0.34),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.psychology_outlined,
                    color: ContextMatrixStyle.teal,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Coach chat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ContextMatrixStyle.text,
                  ),
                ),
              ),
              _MatrixNavButton(compact: isCompact, onPressed: onOpenContext),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatrixNavButton extends StatelessWidget {
  const _MatrixNavButton({required this.compact, required this.onPressed});

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);

    return Tooltip(
      message: 'Open Context Web',
      child: Semantics(
        button: true,
        label: 'Open Info Matrix',
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF22D3EE),
                  Color(0xFF6366F1),
                  Color(0xFFA855F7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              key: const ValueKey('coach-chat-context-button'),
              borderRadius: radius,
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: compact ? 42 : 108,
                  minHeight: 42,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 14,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.hub_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Matrix',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.chatController,
    required this.scrollController,
  });

  final ChatController chatController;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final messages = chatController.messages;

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ContextMatrixStyle.panel.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ContextMatrixStyle.border.withValues(alpha: 0.72),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Ask the coach a question to test your selected provider and model.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ContextMatrixStyle.mutedText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (chatController.isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const _LoadingBubble();
        }

        return _ChatBubble(message: messages[index]);
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiChatRole.user;
    final color = isUser
        ? ContextMatrixStyle.electricBlue
        : ContextMatrixStyle.violet;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF0B304D).withValues(alpha: 0.92)
                  : ContextMatrixStyle.panel2.withValues(alpha: 0.9),
              border: Border.all(color: color.withValues(alpha: 0.32)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isUser
                  ? Text(
                      message.text,
                      softWrap: true,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ContextMatrixStyle.text,
                      ),
                    )
                  : _AssistantMarkdown(text: message.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantMarkdown extends StatelessWidget {
  const _AssistantMarkdown({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: ContextMatrixStyle.text,
    );

    return MarkdownBody(
      data: text,
      selectable: true,
      softLineBreak: true,
      onTapLink: (_, _, _) {},
      imageBuilder: (_, _, alt) {
        return Text(
          alt == null || alt.isEmpty ? '[image omitted]' : '[image: $alt]',
          style: baseStyle,
        );
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: baseStyle,
        listBullet: baseStyle,
        a: baseStyle?.copyWith(
          color: ContextMatrixStyle.electricBlue,
          decoration: TextDecoration.underline,
        ),
        code: baseStyle?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: ContextMatrixStyle.background2,
        ),
        codeblockDecoration: BoxDecoration(
          color: ContextMatrixStyle.background2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ContextMatrixStyle.border),
        ),
        codeblockPadding: const EdgeInsets.all(8),
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ContextMatrixStyle.panel2.withValues(alpha: 0.9),
          border: Border.all(
            color: ContextMatrixStyle.violet.withValues(alpha: 0.28),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF3B1420).withValues(alpha: 0.92),
          border: Border.all(
            color: ContextMatrixStyle.danger.withValues(alpha: 0.42),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: ContextMatrixStyle.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Color(0xFFFFDCE4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContextMatrixStyle.background.withValues(alpha: 0.72),
        border: Border(
          top: BorderSide(
            color: ContextMatrixStyle.border.withValues(alpha: 0.58),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('coach-chat-input'),
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(labelText: 'Ask the coach'),
                onSubmitted: enabled ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const ValueKey('coach-chat-send-button'),
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}
