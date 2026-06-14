import 'package:flutter/material.dart';

import '../widgets/placeholder_panel.dart';

class CoachChatScreen extends StatelessWidget {
  const CoachChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PlaceholderPanel(
          icon: Icons.chat_bubble_outline,
          title: 'AI coach chat',
          body:
              'This chat will eventually send user questions and a health summary to the selected AI provider.',
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Placeholder coach response: connect health data and add an API key to enable real coaching later.',
                style: textTheme.bodyMedium,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          enabled: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Ask the coach',
            helperText:
                'Chat input is disabled until AI provider support is added.',
          ),
        ),
      ],
    );
  }
}
