import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/context_entry.dart';

class ContextSectionNodeData {
  const ContextSectionNodeData({
    required this.section,
    required this.entries,
    required this.missingTitles,
  });

  final ContextSection section;
  final List<ContextEntry> entries;
  final List<String> missingTitles;
}

class ContextWebGraph extends StatelessWidget {
  const ContextWebGraph({
    super.key,
    required this.activeCount,
    required this.nodes,
    required this.expandedSections,
    required this.onToggleSection,
    required this.onAdd,
    required this.onEdit,
    required this.onArchive,
  });

  final int activeCount;
  final List<ContextSectionNodeData> nodes;
  final Set<ContextSection> expandedSections;
  final ValueChanged<ContextSection> onToggleSection;
  final void Function(ContextSection section, String? title) onAdd;
  final ValueChanged<ContextEntry> onEdit;
  final ValueChanged<ContextEntry> onArchive;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartStats(
          activeCount: activeCount,
          confirmedCount: _confirmedCount,
          extractedCount: _extractedCount,
          missingCount: _missingCount,
        ),
        const SizedBox(height: 12),
        _StarterPromptPanel(nodes: nodes, onAdd: onAdd),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = width < 430 ? 560.0 : math.min(680.0, width * 0.7);
            final layout = _GraphLayout.build(
              width: width,
              height: height,
              nodes: nodes,
              expandedSections: expandedSections,
            );

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) {
                return _NetworkCanvas(
                  layout: layout,
                  progress: progress,
                  onToggleSection: onToggleSection,
                  onAdd: onAdd,
                  onEdit: onEdit,
                );
              },
            );
          },
        ),
        const SizedBox(height: 14),
        _ExpandedSectionDetails(
          nodes: nodes,
          expandedSections: expandedSections,
          onToggleSection: onToggleSection,
          onAdd: onAdd,
          onEdit: onEdit,
          onArchive: onArchive,
        ),
      ],
    );
  }

  int get _missingCount {
    return nodes.fold(0, (sum, node) => sum + node.missingTitles.length);
  }

  int get _confirmedCount {
    return nodes.fold(
      0,
      (sum, node) => sum + node.entries.where((entry) => entry.isPinned).length,
    );
  }

  int get _extractedCount {
    return nodes.fold(
      0,
      (sum, node) =>
          sum +
          node.entries
              .where((entry) => entry.source == ContextSource.chatExtracted)
              .length,
    );
  }
}

class _NetworkCanvas extends StatelessWidget {
  const _NetworkCanvas({
    required this.layout,
    required this.progress,
    required this.onToggleSection,
    required this.onAdd,
    required this.onEdit,
  });

  final _GraphLayout layout;
  final double progress;
  final ValueChanged<ContextSection> onToggleSection;
  final void Function(ContextSection section, String? title) onAdd;
  final ValueChanged<ContextEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: SizedBox(
          key: const ValueKey('context-network-chart'),
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ContextNetworkPainter(
                    edges: layout.edges,
                    progress: progress,
                  ),
                ),
              ),
              for (final node in layout.visualNodes)
                _PositionedGraphNode(
                  node: node,
                  progress: progress,
                  onTap: () {
                    switch (node.kind) {
                      case _GraphNodeKind.hub:
                        break;
                      case _GraphNodeKind.section:
                        onToggleSection(node.section!);
                      case _GraphNodeKind.entry:
                        onEdit(node.entry!);
                      case _GraphNodeKind.missing:
                        onAdd(node.section!, node.missingTitle);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextNetworkPainter extends CustomPainter {
  const _ContextNetworkPainter({required this.edges, required this.progress});

  final List<_GraphEdge> edges;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFD9DEE5).withValues(alpha: 0.26)
      ..strokeWidth = 0.8;
    for (var x = 36.0; x < size.width; x += 54) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 34.0; y < size.height; y += 54) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final edgePaint = Paint()
      ..color = const Color(0xFF717A86).withValues(alpha: 0.34 * progress)
      ..strokeCap = StrokeCap.round;
    for (final edge in edges) {
      edgePaint.strokeWidth = edge.width;
      final end = Offset.lerp(edge.from, edge.to, progress)!;
      canvas.drawLine(edge.from, end, edgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContextNetworkPainter oldDelegate) {
    return oldDelegate.edges != edges || oldDelegate.progress != progress;
  }
}

class _PositionedGraphNode extends StatelessWidget {
  const _PositionedGraphNode({
    required this.node,
    required this.progress,
    required this.onTap,
  });

  final _GraphVisualNode node;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scaledCenter = Offset.lerp(node.anchor, node.center, progress)!;

    return Positioned(
      left: scaledCenter.dx - node.size.width / 2,
      top: scaledCenter.dy - node.size.height / 2,
      width: node.size.width,
      height: node.size.height,
      child: Opacity(
        opacity: progress,
        child: Transform.scale(
          scale: 0.92 + progress * 0.08,
          child: _GraphNodeButton(node: node, onTap: onTap),
        ),
      ),
    );
  }
}

class _GraphNodeButton extends StatelessWidget {
  const _GraphNodeButton({required this.node, required this.onTap});

  final _GraphVisualNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRound =
        node.kind == _GraphNodeKind.hub || node.kind == _GraphNodeKind.section;
    final borderColor = node.isExpanded
        ? const Color(0xFF111827)
        : const Color(0xFF4B5563);
    final shadowColor = node.color.withValues(alpha: 0.22);

    return Tooltip(
      message: node.tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: node.key,
          customBorder: isRound ? const CircleBorder() : null,
          borderRadius: isRound ? null : BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: node.color,
              shape: isRound ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isRound ? null : BorderRadius.circular(999),
              border: Border.all(
                color: borderColor,
                width: node.isPinned || node.isExpanded ? 2.2 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: node.kind == _GraphNodeKind.hub ? 18 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      node.label,
                      textAlign: TextAlign.center,
                      maxLines: node.kind == _GraphNodeKind.entry ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: node.textColor,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  if (node.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      node.subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: node.textColor.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartStats extends StatelessWidget {
  const _ChartStats({
    required this.activeCount,
    required this.confirmedCount,
    required this.extractedCount,
    required this.missingCount,
  });

  final int activeCount;
  final int confirmedCount;
  final int extractedCount;
  final int missingCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_outlined, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Info Matrix',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(label: 'active', value: '$activeCount'),
                _StatPill(label: 'confirmed', value: '$confirmedCount'),
                _StatPill(label: 'extracted', value: '$extractedCount'),
                _StatPill(label: 'missing', value: '$missingCount'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF7C3AED),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF475467),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarterPromptPanel extends StatelessWidget {
  const _StarterPromptPanel({required this.nodes, required this.onAdd});

  final List<ContextSectionNodeData> nodes;
  final void Function(ContextSection section, String? title) onAdd;

  @override
  Widget build(BuildContext context) {
    final starters = <_StarterField>[
      ..._missing(ContextSection.profile, ['Age', 'Height', 'Weight']),
      ..._missing(ContextSection.goals, ['Primary fitness goal']),
      ..._missing(ContextSection.equipmentAccess, ['Gym access']),
      ..._missing(ContextSection.healthConstraints, [
        'Injuries',
        'Things to avoid',
      ]),
    ];

    if (starters.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_fix_high_outlined,
                  size: 18,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Text(
                  'Complete profile',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in starters)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: _EllipsizedLabel(item.title),
                    onPressed: () => onAdd(item.section, item.title),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    labelStyle: const TextStyle(color: Color(0xFF92400E)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_StarterField> _missing(ContextSection section, List<String> titles) {
    ContextSectionNodeData? node;
    for (final candidate in nodes) {
      if (candidate.section == section) {
        node = candidate;
        break;
      }
    }
    final missing = node?.missingTitles.toSet() ?? const <String>{};
    return [
      for (final title in titles)
        if (missing.contains(title)) _StarterField(section, title),
    ];
  }
}

class _ExpandedSectionDetails extends StatelessWidget {
  const _ExpandedSectionDetails({
    required this.nodes,
    required this.expandedSections,
    required this.onToggleSection,
    required this.onAdd,
    required this.onEdit,
    required this.onArchive,
  });

  final List<ContextSectionNodeData> nodes;
  final Set<ContextSection> expandedSections;
  final ValueChanged<ContextSection> onToggleSection;
  final void Function(ContextSection section, String? title) onAdd;
  final ValueChanged<ContextEntry> onEdit;
  final ValueChanged<ContextEntry> onArchive;

  @override
  Widget build(BuildContext context) {
    final visibleNodes = [
      for (final node in nodes)
        if (expandedSections.contains(node.section)) node,
    ];

    if (visibleNodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final node in visibleNodes) ...[
          _SectionDetailCard(
            node: node,
            onCollapse: () => onToggleSection(node.section),
            onAdd: (title) => onAdd(node.section, title),
            onEdit: onEdit,
            onArchive: onArchive,
          ),
          if (node != visibleNodes.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SectionDetailCard extends StatelessWidget {
  const _SectionDetailCard({
    required this.node,
    required this.onCollapse,
    required this.onAdd,
    required this.onEdit,
    required this.onArchive,
  });

  final ContextSectionNodeData node;
  final VoidCallback onCollapse;
  final ValueChanged<String> onAdd;
  final ValueChanged<ContextEntry> onEdit;
  final ValueChanged<ContextEntry> onArchive;

  @override
  Widget build(BuildContext context) {
    final color = _colorForSection(node.section);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForSection(node.section), color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.section.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onCollapse,
                  icon: const Icon(Icons.expand_less),
                  tooltip: 'Collapse',
                ),
              ],
            ),
            if (node.missingTitles.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final title in node.missingTitles.take(6))
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.add, size: 16),
                      label: _EllipsizedLabel(title),
                      onPressed: () => onAdd(title),
                      backgroundColor: const Color(0xFFFFFBEB),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      labelStyle: const TextStyle(color: Color(0xFF92400E)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (node.entries.isEmpty)
              Text(
                'No active entries yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
              )
            else
              for (final entry in node.entries) ...[
                _EntryDetailTile(
                  entry: entry,
                  accent: color,
                  onEdit: () => onEdit(entry),
                  onArchive: () => onArchive(entry),
                ),
                if (entry != node.entries.last) const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _EntryDetailTile extends StatelessWidget {
  const _EntryDetailTile({
    required this.entry,
    required this.accent,
    required this.onEdit,
    required this.onArchive,
  });

  final ContextEntry entry;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isPinned
              ? accent.withValues(alpha: 0.48)
              : const Color(0xFFE4E7EC),
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
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onArchive,
                  icon: const Icon(Icons.archive_outlined),
                  tooltip: 'Archive',
                  color: const Color(0xFFB42318),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.value,
              softWrap: true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF344054),
                height: 1.32,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _SourcePill(
                  label: entry.source.label,
                  color: _sourceColor(entry.source),
                ),
                if (entry.confidence != null)
                  _SourcePill(
                    label: 'confidence ${entry.confidence!.toStringAsFixed(2)}',
                    color: const Color(0xFF0284C7),
                  ),
                if (entry.isPinned)
                  const _SourcePill(
                    label: 'confirmed',
                    color: Color(0xFF059669),
                    icon: Icons.verified_outlined,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
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

class _EllipsizedLabel extends StatelessWidget {
  const _EllipsizedLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _GraphLayout {
  const _GraphLayout({
    required this.width,
    required this.height,
    required this.visualNodes,
    required this.edges,
  });

  final double width;
  final double height;
  final List<_GraphVisualNode> visualNodes;
  final List<_GraphEdge> edges;

  static _GraphLayout build({
    required double width,
    required double height,
    required List<ContextSectionNodeData> nodes,
    required Set<ContextSection> expandedSections,
  }) {
    final center = Offset(width / 2, height / 2);
    final radiusX = math.max(116.0, width * 0.36);
    final radiusY = height * 0.31;
    final visualNodes = <_GraphVisualNode>[];
    final edges = <_GraphEdge>[];

    visualNodes.add(
      _GraphVisualNode(
        key: const ValueKey('context-hub-node'),
        kind: _GraphNodeKind.hub,
        center: center,
        anchor: center,
        size: const Size(108, 108),
        label: 'User\nContext',
        subtitle: 'Matrix',
        color: const Color(0xFF7C3AED),
        textColor: Colors.white,
        tooltip: 'User Context Matrix',
      ),
    );

    for (var index = 0; index < nodes.length; index += 1) {
      final data = nodes[index];
      final angle = -math.pi / 2 + (index / nodes.length) * math.pi * 2;
      final sectionCenter = _clampCenter(
        Offset(
          center.dx + math.cos(angle) * radiusX,
          center.dy + math.sin(angle) * radiusY,
        ),
        const Size(88, 88),
        width,
        height,
      );
      final sectionColor = _colorForSection(data.section);
      final isExpanded = expandedSections.contains(data.section);

      edges.add(
        _GraphEdge(
          from: center,
          to: sectionCenter,
          width: isExpanded ? 1.8 : 1.1,
        ),
      );
      visualNodes.add(
        _GraphVisualNode(
          key: ValueKey('context-section-${data.section.storageValue}'),
          kind: _GraphNodeKind.section,
          section: data.section,
          center: sectionCenter,
          anchor: center,
          size: Size(isExpanded ? 92 : 78, isExpanded ? 92 : 78),
          label: _shortSectionLabel(data.section),
          subtitle: '${data.entries.length}/${data.missingTitles.length}',
          color: sectionColor,
          textColor: Colors.white,
          tooltip:
              '${data.section.label}: tap to ${isExpanded ? 'collapse' : 'expand'}',
          isExpanded: isExpanded,
        ),
      );

      if (isExpanded) {
        _addChildNodes(
          data: data,
          sectionCenter: sectionCenter,
          center: center,
          baseAngle: angle,
          width: width,
          height: height,
          visualNodes: visualNodes,
          edges: edges,
        );
      }
    }

    return _GraphLayout(
      width: width,
      height: height,
      visualNodes: visualNodes,
      edges: edges,
    );
  }

  static void _addChildNodes({
    required ContextSectionNodeData data,
    required Offset sectionCenter,
    required Offset center,
    required double baseAngle,
    required double width,
    required double height,
    required List<_GraphVisualNode> visualNodes,
    required List<_GraphEdge> edges,
  }) {
    final childItems = <_ChildNodeItem>[
      for (final entry in data.entries.take(3)) _ChildNodeItem.entry(entry),
      for (final title in data.missingTitles.take(3))
        _ChildNodeItem.missing(title),
    ];
    if (childItems.isEmpty) {
      return;
    }

    final outwardAngle = math.atan2(
      sectionCenter.dy - center.dy,
      sectionCenter.dx - center.dx,
    );
    final spread = childItems.length == 1 ? 0.0 : math.pi / 3;
    final childRadius = width < 430 ? 66.0 : 82.0;

    for (var index = 0; index < childItems.length; index += 1) {
      final offsetFactor = childItems.length == 1
          ? 0.0
          : index / (childItems.length - 1) - 0.5;
      final childAngle = outwardAngle + offsetFactor * spread;
      final size = childItems[index].isEntry
          ? const Size(86, 42)
          : const Size(78, 36);
      final childCenter = _clampCenter(
        Offset(
          sectionCenter.dx + math.cos(childAngle) * childRadius,
          sectionCenter.dy + math.sin(childAngle) * childRadius,
        ),
        size,
        width,
        height,
      );

      edges.add(_GraphEdge(from: sectionCenter, to: childCenter, width: 0.9));

      final item = childItems[index];
      if (item.isEntry) {
        final entry = item.entry!;
        visualNodes.add(
          _GraphVisualNode(
            key: ValueKey('context-entry-node-${entry.id}'),
            kind: _GraphNodeKind.entry,
            section: data.section,
            entry: entry,
            center: childCenter,
            anchor: sectionCenter,
            size: size,
            label: entry.title,
            color: _sourceColor(entry.source),
            textColor: Colors.white,
            tooltip: '${entry.title}: tap to edit',
            isPinned: entry.isPinned,
          ),
        );
      } else {
        visualNodes.add(
          _GraphVisualNode(
            key: ValueKey(
              'context-missing-node-${data.section.storageValue}-${item.missingTitle}',
            ),
            kind: _GraphNodeKind.missing,
            section: data.section,
            missingTitle: item.missingTitle,
            center: childCenter,
            anchor: sectionCenter,
            size: size,
            label: item.missingTitle!,
            color: const Color(0xFFF59E0B),
            textColor: Colors.white,
            tooltip: '${item.missingTitle}: tap to add',
          ),
        );
      }
    }
  }

  static Offset _clampCenter(
    Offset center,
    Size size,
    double width,
    double height,
  ) {
    final halfWidth = size.width / 2 + 8;
    final halfHeight = size.height / 2 + 8;
    return Offset(
      center.dx.clamp(halfWidth, width - halfWidth),
      center.dy.clamp(halfHeight, height - halfHeight),
    );
  }
}

class _GraphVisualNode {
  const _GraphVisualNode({
    required this.key,
    required this.kind,
    required this.center,
    required this.anchor,
    required this.size,
    required this.label,
    required this.color,
    required this.textColor,
    required this.tooltip,
    this.subtitle,
    this.section,
    this.entry,
    this.missingTitle,
    this.isExpanded = false,
    this.isPinned = false,
  });

  final Key key;
  final _GraphNodeKind kind;
  final Offset center;
  final Offset anchor;
  final Size size;
  final String label;
  final String? subtitle;
  final Color color;
  final Color textColor;
  final String tooltip;
  final ContextSection? section;
  final ContextEntry? entry;
  final String? missingTitle;
  final bool isExpanded;
  final bool isPinned;
}

class _GraphEdge {
  const _GraphEdge({required this.from, required this.to, required this.width});

  final Offset from;
  final Offset to;
  final double width;
}

class _ChildNodeItem {
  const _ChildNodeItem.entry(this.entry) : missingTitle = null;
  const _ChildNodeItem.missing(this.missingTitle) : entry = null;

  final ContextEntry? entry;
  final String? missingTitle;

  bool get isEntry => entry != null;
}

class _StarterField {
  const _StarterField(this.section, this.title);

  final ContextSection section;
  final String title;
}

enum _GraphNodeKind { hub, section, entry, missing }

String _shortSectionLabel(ContextSection section) {
  return switch (section) {
    ContextSection.profile => 'Profile',
    ContextSection.goals => 'Goals',
    ContextSection.preferences => 'Prefs',
    ContextSection.equipmentAccess => 'Gear',
    ContextSection.healthConstraints => 'Health',
    ContextSection.currentState => 'State',
    ContextSection.trainingHistory => 'History',
    ContextSection.nutritionContext => 'Nutrition',
    ContextSection.environment => 'Env',
    ContextSection.personalityMatrix => 'Personality',
    ContextSection.otherNotes => 'Notes',
  };
}

Color _colorForSection(ContextSection section) {
  return switch (section) {
    ContextSection.profile => const Color(0xFF0891B2),
    ContextSection.goals => const Color(0xFF7C3AED),
    ContextSection.preferences => const Color(0xFFDB2777),
    ContextSection.equipmentAccess => const Color(0xFFF97316),
    ContextSection.healthConstraints => const Color(0xFFE11D48),
    ContextSection.currentState => const Color(0xFF059669),
    ContextSection.trainingHistory => const Color(0xFF2563EB),
    ContextSection.nutritionContext => const Color(0xFFCA8A04),
    ContextSection.environment => const Color(0xFF0D9488),
    ContextSection.personalityMatrix => const Color(0xFF9333EA),
    ContextSection.otherNotes => const Color(0xFF64748B),
  };
}

Color _sourceColor(ContextSource source) {
  return switch (source) {
    ContextSource.manual => const Color(0xFF0891B2),
    ContextSource.chatExtracted => const Color(0xFF9333EA),
    ContextSource.futureHealthImport => const Color(0xFF059669),
    ContextSource.systemDefault => const Color(0xFF64748B),
  };
}

IconData _iconForSection(ContextSection section) {
  return switch (section) {
    ContextSection.profile => Icons.person_outline,
    ContextSection.goals => Icons.flag_outlined,
    ContextSection.preferences => Icons.tune_outlined,
    ContextSection.equipmentAccess => Icons.fitness_center_outlined,
    ContextSection.healthConstraints => Icons.health_and_safety_outlined,
    ContextSection.currentState => Icons.battery_5_bar_outlined,
    ContextSection.trainingHistory => Icons.history_outlined,
    ContextSection.nutritionContext => Icons.restaurant_outlined,
    ContextSection.environment => Icons.wb_sunny_outlined,
    ContextSection.personalityMatrix => Icons.psychology_outlined,
    ContextSection.otherNotes => Icons.notes_outlined,
  };
}
