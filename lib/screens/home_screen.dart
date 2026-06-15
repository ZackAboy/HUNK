import 'package:flutter/material.dart';

import '../widgets/context_matrix_theme.dart';
import '../widgets/placeholder_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _PulseIcon(icon: Icons.auto_awesome),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI fitness coach',
                style: textTheme.headlineSmall?.copyWith(
                  color: ContextMatrixStyle.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'A simple starting point for health summaries, coaching prompts, and recovery guidance.',
          style: textTheme.bodyLarge?.copyWith(
            color: ContextMatrixStyle.mutedText,
          ),
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

class _PulseIcon extends StatelessWidget {
  const _PulseIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContextMatrixStyle.electricBlue.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ContextMatrixStyle.electricBlue.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: ContextMatrixStyle.electricBlue.withValues(alpha: 0.18),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: ContextMatrixStyle.electricBlue),
      ),
    );
  }
}
