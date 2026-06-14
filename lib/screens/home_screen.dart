import 'package:flutter/material.dart';

import '../widgets/placeholder_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('AI fitness coach', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'A simple starting point for health summaries, coaching prompts, and recovery guidance.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        const PlaceholderPanel(
          icon: Icons.insights,
          title: 'Daily snapshot',
          body:
              'This area will eventually show a short health and recovery summary after data is connected.',
        ),
        const SizedBox(height: 12),
        const PlaceholderPanel(
          icon: Icons.flag_outlined,
          title: 'Next best action',
          body:
              'Future versions will surface a practical coaching suggestion based on recent activity, sleep, and goals.',
        ),
      ],
    );
  }
}
