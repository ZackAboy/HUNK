import 'package:flutter/material.dart';

import 'context_matrix_theme.dart';

class PlaceholderPanel extends StatelessWidget {
  const PlaceholderPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContextMatrixStyle.panel.withValues(alpha: 0.76),
        border: Border.all(
          color: ContextMatrixStyle.border.withValues(alpha: 0.74),
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ContextMatrixStyle.electricBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: ContextMatrixStyle.electricBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ContextMatrixStyle.electricBlue.withValues(
                    alpha: 0.34,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Icon(icon, color: ContextMatrixStyle.electricBlue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: ContextMatrixStyle.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: textTheme.bodyMedium?.copyWith(
                      color: ContextMatrixStyle.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
