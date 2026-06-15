import 'package:flutter/foundation.dart';

import '../models/context_entry.dart';
import '../models/context_matrix.dart';
import '../services/context_repository.dart';

class ContextController extends ChangeNotifier {
  ContextController({required this.repository});

  final ContextRepository repository;

  ContextMatrix _matrix = ContextMatrix.empty();
  bool _isLoading = true;
  String? _errorMessage;

  ContextMatrix get matrix => _matrix;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ContextEntry> get activeEntries => _matrix.activeEntries;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _matrix = await repository.loadMatrix();
    } catch (_) {
      _errorMessage = 'Context Web could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveManualEntry({
    String? id,
    required ContextSection section,
    required String title,
    required String value,
    required bool isPinned,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedValue = value.trim();
    if (trimmedTitle.isEmpty || trimmedValue.isEmpty) {
      _errorMessage = 'Add both a title and a value.';
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    ContextEntry? existing;
    for (final entry in _matrix.entries) {
      if (entry.id == id) {
        existing = entry;
        break;
      }
    }
    final entry = ContextEntry(
      id: id ?? _newEntryId(now),
      section: section,
      title: trimmedTitle,
      value: trimmedValue,
      source: ContextSource.manual,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      isPinned: isPinned,
    );

    try {
      await repository.saveEntry(entry);
      _matrix = await repository.loadMatrix();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Context item could not be saved.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> archiveEntry(String entryId) async {
    try {
      await repository.archiveEntry(entryId);
      _matrix = await repository.loadMatrix();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Context item could not be removed.';
    } finally {
      notifyListeners();
    }
  }

  List<String> missingRecommendedTitles(ContextSection section) {
    final existingTitles = activeEntries
        .where((entry) => entry.section == section)
        .map((entry) => entry.title.toLowerCase())
        .toSet();

    return [
      for (final title in section.recommendedTitles)
        if (!existingTitles.contains(title.toLowerCase())) title,
    ];
  }

  String _newEntryId(DateTime now) {
    return 'ctx_manual_${now.microsecondsSinceEpoch}';
  }
}
