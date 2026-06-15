import 'package:flutter/material.dart';

import '../models/context_entry.dart';
import 'context_matrix_models.dart';
import 'context_matrix_universe.dart';

export 'context_matrix_models.dart' show ContextSectionNodeData;

class ContextWebGraph extends StatefulWidget {
  const ContextWebGraph({
    super.key,
    required this.nodes,
    required this.expandedSections,
    required this.onToggleSection,
    required this.onCollapseSections,
    required this.onManageSection,
    required this.onAdd,
    required this.onEdit,
  });

  final List<ContextSectionNodeData> nodes;
  final Set<ContextSection> expandedSections;
  final ValueChanged<ContextSection> onToggleSection;
  final VoidCallback onCollapseSections;
  final ValueChanged<ContextSection> onManageSection;
  final void Function(ContextSection section, String? title) onAdd;
  final ValueChanged<ContextEntry> onEdit;

  @override
  State<ContextWebGraph> createState() => _ContextWebGraphState();
}

class _ContextWebGraphState extends State<ContextWebGraph> {
  ContextSection? _focusedSection;

  @override
  Widget build(BuildContext context) {
    return ContextMatrixUniverse(
      nodes: widget.nodes,
      expandedSections: widget.expandedSections,
      focusedSection: _focusedSection,
      onSectionFocused: _focusSection,
      onSectionManaged: _manageSection,
      onAdd: widget.onAdd,
      onEdit: widget.onEdit,
      onResetFocus: _clearFocus,
    );
  }

  void _focusSection(ContextSection section) {
    setState(() {
      _focusedSection = section;
    });
    if (!widget.expandedSections.contains(section)) {
      widget.onToggleSection(section);
    }
  }

  void _manageSection(ContextSection section) {
    _focusSection(section);
    widget.onManageSection(section);
  }

  void _clearFocus() {
    setState(() {
      _focusedSection = null;
    });
    widget.onCollapseSections();
  }
}
