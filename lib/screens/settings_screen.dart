import 'package:flutter/material.dart';

import '../widgets/placeholder_panel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        PlaceholderPanel(
          icon: Icons.key_outlined,
          title: 'API keys',
          body:
              'OpenAI and Google Gemini API keys will be entered and stored locally here in a future task.',
        ),
        SizedBox(height: 12),
        PlaceholderPanel(
          icon: Icons.tune,
          title: 'Provider settings',
          body:
              'This screen will eventually let users choose an AI provider and manage health data permissions.',
        ),
      ],
    );
  }
}
