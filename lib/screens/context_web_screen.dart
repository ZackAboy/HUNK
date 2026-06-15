import 'package:flutter/material.dart';

import '../models/context_entry.dart';
import '../providers/context_controller.dart';
import '../services/context_repository.dart';
import '../widgets/context_web_graph.dart';

class ContextWebScreen extends StatefulWidget {
  const ContextWebScreen({super.key, this.repository});

  final ContextRepository? repository;

  @override
  State<ContextWebScreen> createState() => _ContextWebScreenState();
}

class _ContextWebScreenState extends State<ContextWebScreen> {
  late final ContextController _controller;
  final Set<ContextSection> _expandedSections = {
    ContextSection.profile,
    ContextSection.goals,
  };

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
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F4F7),
    );

    return Theme(
      data: matrixTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        appBar: AppBar(
          title: const Text('Context Web'),
          backgroundColor: const Color(0xFFF2F4F7),
          foregroundColor: const Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              key: const ValueKey('context-web-appbar-add-button'),
              onPressed: () => _showEntryDialog(),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add context',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('context-web-add-button'),
          onPressed: () => _showEntryDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                if (_controller.errorMessage != null) ...[
                  _ErrorPanel(message: _controller.errorMessage!),
                  const SizedBox(height: 12),
                ],
                ContextWebGraph(
                  activeCount: _controller.activeEntries.length,
                  nodes: [
                    for (final section in ContextSection.values)
                      ContextSectionNodeData(
                        section: section,
                        entries: _entriesFor(section),
                        missingTitles: _controller.missingRecommendedTitles(
                          section,
                        ),
                      ),
                  ],
                  expandedSections: _expandedSections,
                  onToggleSection: _toggleSection,
                  onAdd: (section, title) {
                    _showEntryDialog(
                      initialSection: section,
                      initialTitle: title,
                    );
                  },
                  onEdit: (entry) => _showEntryDialog(entry: entry),
                  onArchive: _archiveEntry,
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

  void _toggleSection(ContextSection section) {
    setState(() {
      if (_expandedSections.contains(section)) {
        _expandedSections.remove(section);
      } else {
        _expandedSections.add(section);
      }
    });
  }

  Future<void> _showEntryDialog({
    ContextEntry? entry,
    ContextSection? initialSection,
    String? initialTitle,
  }) async {
    final result = await showDialog<_ContextEntryFormResult>(
      context: context,
      builder: (context) {
        return _ContextEntryDialog(
          entry: entry,
          initialSection: initialSection,
          initialTitle: initialTitle,
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
    );
    _showMessage(
      _controller.errorMessage == null
          ? 'Context saved'
          : _controller.errorMessage!,
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
  });

  final ContextEntry? entry;
  final ContextSection? initialSection;
  final String? initialTitle;

  @override
  State<_ContextEntryDialog> createState() => _ContextEntryDialogState();
}

class _ContextEntryDialogState extends State<_ContextEntryDialog> {
  late ContextSection _section;
  late final TextEditingController _titleController;
  late final TextEditingController _valueController;
  late bool _isPinned;
  String? _error;

  @override
  void initState() {
    super.initState();
    _section =
        widget.entry?.section ??
        widget.initialSection ??
        ContextSection.profile;
    _titleController = TextEditingController(
      text: widget.entry?.title ?? widget.initialTitle ?? '',
    );
    _valueController = TextEditingController(text: widget.entry?.value ?? '');
    _isPinned = widget.entry?.isPinned ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.entry == null ? 'Add context' : 'Edit context'),
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
                  setState(() {
                    _section = value;
                  });
                }
              },
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
    if (title.isEmpty || value.isEmpty) {
      setState(() {
        _error = 'Add both a title and a value.';
      });
      return;
    }

    Navigator.of(context).pop(
      _ContextEntryFormResult(
        section: _section,
        title: title,
        value: value,
        isPinned: _isPinned,
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
    required this.title,
    required this.value,
    required this.isPinned,
  });

  final ContextSection section;
  final String title;
  final String value;
  final bool isPinned;
}
