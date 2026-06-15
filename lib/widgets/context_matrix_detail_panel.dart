import 'package:flutter/material.dart';

import '../models/context_entry.dart';
import 'context_matrix_models.dart';
import 'context_matrix_theme.dart';

class ContextMatrixDetailPanel extends StatelessWidget {
  const ContextMatrixDetailPanel({
    super.key,
    required this.node,
    required this.onAdd,
    required this.onEdit,
    required this.onArchive,
    required this.onRemove,
    required this.onConfirm,
    required this.onReject,
    required this.onAddSubNode,
    this.onClose,
  });

  final ContextSectionNodeData node;
  final ValueChanged<String?> onAdd;
  final ValueChanged<ContextEntry> onEdit;
  final ValueChanged<ContextEntry> onArchive;
  final ValueChanged<ContextEntry> onRemove;
  final ValueChanged<ContextEntry> onConfirm;
  final ValueChanged<ContextEntry> onReject;
  final ValueChanged<ContextEntry> onAddSubNode;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final accent = ContextMatrixStyle.sectionColor(node.section);

    return Semantics(
      label: '${node.section.label} details',
      child: DecoratedBox(
        decoration: ContextMatrixStyle.panelDecoration(accent: accent),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailHeader(section: node.section, onClose: onClose),
              if (node.missingTitles.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final title in node.missingTitles.take(8))
                      ActionChip(
                        key: ValueKey(
                          'context-missing-chip-${node.section.storageValue}-$title',
                        ),
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.add, size: 16),
                        label: _EllipsizedLabel(title, maxWidth: 210),
                        onPressed: () => onAdd(title),
                        backgroundColor: ContextMatrixStyle.warning.withValues(
                          alpha: 0.14,
                        ),
                        side: BorderSide(
                          color: ContextMatrixStyle.warning.withValues(
                            alpha: 0.62,
                          ),
                        ),
                        labelStyle: const TextStyle(
                          color: Color(0xFFFFD38A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              if (node.entries.isEmpty)
                Text(
                  'No active entries yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ContextMatrixStyle.mutedText,
                  ),
                )
              else
                for (final entry in node.entries) ...[
                  _EntryDetailTile(
                    entry: entry,
                    accent: accent,
                    onEdit: () => onEdit(entry),
                    onArchive: () => onArchive(entry),
                    onRemove: () => onRemove(entry),
                    onConfirm: () => onConfirm(entry),
                    onReject: () => onReject(entry),
                    onAddSubNode: () => onAddSubNode(entry),
                  ),
                  if (entry != node.entries.last) const SizedBox(height: 10),
                ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  key: ValueKey(
                    'context-detail-add-${node.section.storageValue}',
                  ),
                  onPressed: () => onAdd(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContextMatrixLegend extends StatelessWidget {
  const ContextMatrixLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ContextMatrixStyle.panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _LegendPill(
              label: 'manual',
              color: ContextMatrixStyle.cyan,
              icon: Icons.edit_outlined,
            ),
            _LegendPill(
              label: 'chat_extracted',
              color: ContextMatrixStyle.purple,
              icon: Icons.auto_awesome_outlined,
            ),
            _LegendPill(
              label: 'user_confirmed',
              color: ContextMatrixStyle.success,
              icon: Icons.verified_outlined,
            ),
            _LegendPill(
              label: 'future_health_import',
              color: ContextMatrixStyle.success,
              icon: Icons.favorite_border,
            ),
            _LegendPill(
              label: 'future_weather_import',
              color: ContextMatrixStyle.teal,
              icon: Icons.cloud_outlined,
            ),
            _LegendPill(
              label: 'system_default',
              color: ContextMatrixStyle.slate,
              icon: Icons.settings_suggest_outlined,
            ),
            _LegendPill(
              label: 'missing',
              color: ContextMatrixStyle.warning,
              icon: Icons.add_circle_outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.section, this.onClose});

  final ContextSection section;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final accent = ContextMatrixStyle.sectionColor(section);

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.58)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              ContextMatrixStyle.sectionIcon(section),
              color: accent,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ContextMatrixStyle.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Manage context',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ContextMatrixStyle.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (onClose != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: const Icon(Icons.close),
            color: ContextMatrixStyle.mutedText,
            tooltip: 'Close details',
          ),
      ],
    );
  }
}

class _EntryDetailTile extends StatelessWidget {
  const _EntryDetailTile({
    required this.entry,
    required this.accent,
    required this.onEdit,
    required this.onArchive,
    required this.onRemove,
    required this.onConfirm,
    required this.onReject,
    required this.onAddSubNode,
  });

  final ContextEntry entry;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRemove;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onAddSubNode;

  @override
  Widget build(BuildContext context) {
    final sourceColor = ContextMatrixStyle.sourceColor(entry.source);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContextMatrixStyle.panel2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: entry.isPinned
              ? accent.withValues(alpha: 0.58)
              : ContextMatrixStyle.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ContextMatrixStyle.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('context-entry-edit-${entry.id}'),
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  color: ContextMatrixStyle.cyan,
                ),
                IconButton(
                  key: ValueKey('context-entry-subnode-${entry.id}'),
                  visualDensity: VisualDensity.compact,
                  onPressed: onAddSubNode,
                  icon: const Icon(Icons.account_tree_outlined),
                  tooltip: 'Add sub-node',
                  color: ContextMatrixStyle.magenta,
                ),
                IconButton(
                  key: ValueKey('context-entry-archive-${entry.id}'),
                  visualDensity: VisualDensity.compact,
                  onPressed: onArchive,
                  icon: const Icon(Icons.archive_outlined),
                  tooltip: 'Archive',
                  color: ContextMatrixStyle.warning,
                ),
                IconButton(
                  key: ValueKey('context-entry-remove-${entry.id}'),
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove',
                  color: ContextMatrixStyle.danger,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.value,
              softWrap: true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFD7E2F2),
                height: 1.32,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MetaPill(
                  label: entry.source.storageValue,
                  color: sourceColor,
                  icon: _sourceIcon(entry.source),
                ),
                if (entry.confidence != null)
                  _MetaPill(
                    label: 'confidence ${entry.confidence!.toStringAsFixed(2)}',
                    color: ContextMatrixStyle.electricBlue,
                    icon: Icons.speed_outlined,
                  ),
                _MetaPill(
                  label: entry.confirmationState.storageValue,
                  color: entry.isConfirmed
                      ? ContextMatrixStyle.success
                      : entry.isRejected
                      ? ContextMatrixStyle.danger
                      : ContextMatrixStyle.warning,
                  icon: entry.isConfirmed
                      ? Icons.verified_outlined
                      : Icons.help_outline,
                ),
                _MetaPill(
                  label: entry.lifespan.storageValue,
                  color: ContextMatrixStyle.indigo,
                  icon: Icons.timelapse_outlined,
                ),
                _MetaPill(
                  label: entry.sensitivity.storageValue,
                  color: entry.sensitivity == ContextSensitivity.health
                      ? ContextMatrixStyle.danger
                      : ContextMatrixStyle.slate,
                  icon: Icons.privacy_tip_outlined,
                ),
              ],
            ),
            if (entry.source == ContextSource.chatExtracted &&
                entry.confirmationState ==
                    ContextConfirmationState.unconfirmed) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    key: ValueKey('context-entry-confirm-${entry.id}'),
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                  ),
                  OutlinedButton.icon(
                    key: ValueKey('context-entry-reject-${entry.id}'),
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _MetaPill(label: label, color: color, icon: icon);
  }
}

class _EllipsizedLabel extends StatelessWidget {
  const _EllipsizedLabel(this.label, {required this.maxWidth});

  final String label;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

IconData _sourceIcon(ContextSource source) {
  return switch (source) {
    ContextSource.manual => Icons.edit_outlined,
    ContextSource.chatExtracted => Icons.auto_awesome_outlined,
    ContextSource.userConfirmed => Icons.verified_outlined,
    ContextSource.futureHealthImport => Icons.favorite_border,
    ContextSource.futureWeatherImport => Icons.cloud_outlined,
    ContextSource.systemDefault => Icons.settings_suggest_outlined,
  };
}
