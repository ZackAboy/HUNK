import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../models/ai_chat_message.dart';
import '../providers/chat_controller.dart';
import '../services/ai_chat_service.dart';
import '../services/context_repository.dart';
import '../services/provider_ai_chat_service.dart';
import '../services/settings_storage.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Coach chat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (isCompact)
            IconButton.filledTonal(
              key: const ValueKey('coach-chat-context-button'),
              onPressed: onOpenContext,
              icon: const Icon(Icons.hub_outlined),
              tooltip: 'Open Context Web',
            )
          else
            FilledButton.tonalIcon(
              key: const ValueKey('coach-chat-context-button'),
              onPressed: onOpenContext,
              icon: const Icon(Icons.hub_outlined),
              label: const Text('Matrix'),
            ),
        ],
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Ask the coach a question to test your selected provider and model.',
            textAlign: TextAlign.center,
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
    final colorScheme = Theme.of(context).colorScheme;

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
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isUser
                  ? Text(
                      message.text,
                      softWrap: true,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
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
    final colorScheme = theme.colorScheme;
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
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
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: baseStyle?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: colorScheme.surface,
        ),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorScheme.outlineVariant),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colorScheme.onErrorContainer),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Ask the coach',
              ),
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
    );
  }
}
