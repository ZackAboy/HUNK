import 'package:flutter/material.dart';

import '../models/context_entry.dart';
import '../providers/context_controller.dart';
import '../services/context_repository.dart';
import '../widgets/context_matrix_detail_panel.dart';
import '../widgets/context_matrix_theme.dart';
import '../widgets/context_web_graph.dart';

class ContextWebScreen extends StatefulWidget {
  const ContextWebScreen({super.key, this.repository});

  final ContextRepository? repository;

  @override
  State<ContextWebScreen> createState() => _ContextWebScreenState();
}

class _ContextWebScreenState extends State<ContextWebScreen> {
  late final ContextController _controller;
  final Set<ContextSection> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    _controller = ContextController(
      repository: widget.repository ?? SecureContextRepository(),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matrixTheme = Theme.of(context).copyWith(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF38BDF8),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF050915),
    );

    return Theme(
      data: matrixTheme,
      child: Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFF050915),
        floatingActionButton: FloatingActionButton.small(
          key: const ValueKey('context-web-add-button'),
          onPressed: () => _showEntryDialog(),
          backgroundColor: const Color(0xFF38BDF8),
          foregroundColor: const Color(0xFF03101F),
          child: const Icon(Icons.add),
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF050915),
                        Color(0xFF071A2B),
                        Color(0xFF101025),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ContextWebGraph(
                    nodes: _nodeData,
                    expandedSections: _expandedSections,
                    onToggleSection: _toggleSection,
                    onCollapseSections: _collapseSections,
                    onManageSection: _showSectionSheet,
                    onAdd: (section, title) {
                      _showEntryDialog(
                        initialSection: section,
                        initialTitle: title,
                      );
                    },
                    onEdit: (entry) => _showEntryDialog(entry: entry),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _MatrixIconButton(
                        icon: Icons.close,
                        tooltip: 'Close Matrix',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
                if (_controller.errorMessage != null)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 84),
                        child: _ErrorPanel(message: _controller.errorMessage!),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<ContextEntry> _entriesFor(ContextSection section) {
    final entries = _controller.activeEntries
        .where((entry) => entry.section == section)
        .toList();
    entries.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }

      return b.updatedAt.compareTo(a.updatedAt);
    });

    return entries;
  }

  List<ContextSectionNodeData> get _nodeData {
    return [
      for (final section in ContextSection.values)
        ContextSectionNodeData(
          section: section,
          entries: _entriesFor(section),
          missingTitles: _controller.missingRecommendedTitles(section),
        ),
    ];
  }

  void _toggleSection(ContextSection section) {
    setState(() {
      if (_expandedSections.contains(section)) {
        _expandedSections.clear();
      } else {
        _expandedSections
          ..clear()
          ..add(section);
      }
    });
  }

  void _collapseSections() {
    if (_expandedSections.isEmpty) {
      return;
    }

    setState(_expandedSections.clear);
  }

  Future<void> _showEntryDialog({
    ContextEntry? entry,
    ContextSection? initialSection,
    String? initialTitle,
    ContextEntry? parentEntry,
  }) async {
    final result = await showDialog<_ContextEntryFormResult>(
      context: context,
      builder: (context) {
        return _ContextEntryDialog(
          entry: entry,
          initialSection: initialSection,
          initialTitle: initialTitle,
          parentEntry: parentEntry,
        );
      },
    );

    if (result == null) {
      return;
    }

    await _controller.saveManualEntry(
      id: entry?.id,
      section: result.section,
      title: result.title,
      value: result.value,
      isPinned: result.isPinned,
      node: result.node,
      parentId: result.parentId,
      lifespan: result.lifespan,
    );
    _showMessage(
      _controller.errorMessage == null
          ? 'Context saved'
          : _controller.errorMessage!,
    );
  }

  Future<void> _showSectionSheet(ContextSection section) async {
    final node = _nodeData.firstWhere(
      (candidate) => candidate.section == section,
      orElse: () => ContextSectionNodeData(
        section: section,
        entries: const [],
        missingTitles: const [],
      ),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.28,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ContextMatrixDetailPanel(
                key: ValueKey('context-detail-${node.section.storageValue}'),
                node: node,
                onClose: () => Navigator.of(sheetContext).pop(),
                onAdd: (title) {
                  Navigator.of(sheetContext).pop();
                  _showEntryDialog(
                    initialSection: section,
                    initialTitle: title,
                  );
                },
                onEdit: (entry) {
                  Navigator.of(sheetContext).pop();
                  _showEntryDialog(entry: entry);
                },
                onArchive: (entry) {
                  Navigator.of(sheetContext).pop();
                  _archiveEntry(entry);
                },
                onRemove: (entry) {
                  Navigator.of(sheetContext).pop();
                  _removeEntry(entry);
                },
                onConfirm: (entry) {
                  Navigator.of(sheetContext).pop();
                  _confirmEntry(entry);
                },
                onReject: (entry) {
                  Navigator.of(sheetContext).pop();
                  _rejectEntry(entry);
                },
                onAddSubNode: (entry) {
                  Navigator.of(sheetContext).pop();
                  _showEntryDialog(
                    initialSection: entry.section,
                    parentEntry: entry,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _archiveEntry(ContextEntry entry) async {
    await _controller.archiveEntry(entry.id);
    _showMessage(
      _controller.errorMessage == null
          ? 'Context archived'
          : _controller.errorMessage!,
    );
  }

  Future<void> _confirmEntry(ContextEntry entry) async {
    await _controller.confirmEntry(entry.id);
    _showMessage(
      _controller.errorMessage == null
          ? 'Context confirmed'
          : _controller.errorMessage!,
    );
  }

  Future<void> _rejectEntry(ContextEntry entry) async {
    await _controller.rejectEntry(entry.id);
    _showMessage(
      _controller.errorMessage == null
          ? 'Context rejected'
          : _controller.errorMessage!,
    );
  }

  Future<void> _removeEntry(ContextEntry entry) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove context'),
          content: Text('Remove "${entry.title}" from active context?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('context-confirm-remove-button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) {
      return;
    }

    await _controller.removeEntry(entry.id);
    _showMessage(
      _controller.errorMessage == null
          ? 'Context removed'
          : _controller.errorMessage!,
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ContextEntryDialog extends StatefulWidget {
  const _ContextEntryDialog({
    this.entry,
    this.initialSection,
    this.initialTitle,
    this.parentEntry,
  });

  final ContextEntry? entry;
  final ContextSection? initialSection;
  final String? initialTitle;
  final ContextEntry? parentEntry;

  @override
  State<_ContextEntryDialog> createState() => _ContextEntryDialogState();
}

class _ContextEntryDialogState extends State<_ContextEntryDialog> {
  late ContextSection _section;
  late ContextLifespan _lifespan;
  late final TextEditingController _titleController;
  late final TextEditingController _valueController;
  late final TextEditingController _nodeController;
  late bool _isPinned;
  String? _error;

  @override
  void initState() {
    super.initState();
    _section =
        widget.entry?.section ??
        widget.parentEntry?.section ??
        widget.initialSection ??
        ContextSection.profile;
    _lifespan = widget.entry?.lifespan ?? ContextLifespan.longTerm;
    _titleController = TextEditingController(
      text: widget.entry?.title ?? widget.initialTitle ?? '',
    );
    _valueController = TextEditingController(text: widget.entry?.value ?? '');
    _nodeController = TextEditingController(
      text:
          widget.entry?.nodeLabel ??
          widget.parentEntry?.nodeLabel ??
          _section.matrixLabel,
    );
    _isPinned = widget.entry?.isPinned ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _nodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(
        widget.entry != null
            ? 'Edit context'
            : widget.parentEntry != null
            ? 'Add sub-node'
            : 'Add node',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<ContextSection>(
              key: const ValueKey('context-section-dropdown'),
              isExpanded: true,
              initialValue: _section,
              items: [
                for (final section in ContextSection.values)
                  DropdownMenuItem(
                    value: section,
                    child: Text(
                      section.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Section',
              ),
              onChanged: (value) {
                if (value != null) {
                  final oldDefaultNode = _section.matrixLabel;
                  setState(() {
                    _section = value;
                    if (_nodeController.text.trim().isEmpty ||
                        _nodeController.text.trim() == oldDefaultNode) {
                      _nodeController.text = value.matrixLabel;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('context-entry-node-field'),
              controller: _nodeController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Node',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('context-entry-title-field'),
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('context-entry-value-field'),
              controller: _valueController,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Value',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ContextLifespan>(
              key: const ValueKey('context-lifespan-dropdown'),
              isExpanded: true,
              initialValue: _lifespan,
              items: [
                for (final lifespan in ContextLifespan.values)
                  DropdownMenuItem(
                    value: lifespan,
                    child: Text(lifespan.label),
                  ),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Lifespan',
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _lifespan = value;
                  });
                }
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isPinned,
              title: const Text('Confirmed'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  _isPinned = value ?? false;
                });
              },
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('context-save-button'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    final value = _valueController.text.trim();
    final node = _nodeController.text.trim();
    if (title.isEmpty || value.isEmpty) {
      setState(() {
        _error = 'Add both a title and a value.';
      });
      return;
    }

    Navigator.of(context).pop(
      _ContextEntryFormResult(
        section: _section,
        node: node.isEmpty ? _section.matrixLabel : node,
        parentId: widget.entry?.parentId ?? widget.parentEntry?.id,
        title: title,
        value: value,
        isPinned: _isPinned,
        lifespan: _lifespan,
      ),
    );
  }
}

class _MatrixIconButton extends StatelessWidget {
  const _MatrixIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContextMatrixStyle.panel.withValues(alpha: 0.74),
        shape: BoxShape.circle,
        border: Border.all(color: ContextMatrixStyle.border),
      ),
      child: IconButton(
        key: const ValueKey('context-web-close-button'),
        onPressed: onPressed,
        icon: Icon(icon),
        color: ContextMatrixStyle.text,
        tooltip: tooltip,
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
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
    );
  }
}

class _ContextEntryFormResult {
  const _ContextEntryFormResult({
    required this.section,
    required this.node,
    required this.parentId,
    required this.title,
    required this.value,
    required this.isPinned,
    required this.lifespan,
  });

  final ContextSection section;
  final String node;
  final String? parentId;
  final String title;
  final String value;
  final bool isPinned;
  final ContextLifespan lifespan;
}
