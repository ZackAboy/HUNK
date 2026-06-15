import 'package:flutter/material.dart';

import '../widgets/context_matrix_theme.dart';
import '../widgets/placeholder_panel.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        Row(
          children: [
            const _PulseIcon(icon: Icons.favorite_border),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Health',
                style: textTheme.headlineSmall?.copyWith(
                  color: ContextMatrixStyle.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Recovery, constraints, and future device signals stay organized around the same context universe.',
          style: textTheme.bodyLarge?.copyWith(
            color: ContextMatrixStyle.mutedText,
          ),
        ),
        const SizedBox(height: 24),
        const PlaceholderPanel(
          icon: Icons.favorite_border,
          title: 'Health data sources',
          body:
              'Apple HealthKit on iOS and Google Health Connect on Android will connect here. No real health integration is active yet.',
        ),
        const SizedBox(height: 12),
        const PlaceholderPanel(
          icon: Icons.summarize_outlined,
          title: 'Basic health summary',
          body:
              'This screen will eventually summarize metrics such as sleep, activity, workouts, and recovery signals.',
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
        color: ContextMatrixStyle.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ContextMatrixStyle.teal.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: ContextMatrixStyle.teal.withValues(alpha: 0.16),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: ContextMatrixStyle.teal),
      ),
    );
  }
}
