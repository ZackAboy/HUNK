import 'package:flutter/foundation.dart';

import '../models/context_entry.dart';
import '../models/context_matrix.dart';
import '../services/context_missing_basics_detector.dart';
import '../services/context_repository.dart';

class ContextController extends ChangeNotifier {
  ContextController({
    required this.repository,
    this.missingBasicsDetector = const ContextMissingBasicsDetector(),
  });

  final ContextRepository repository;
  final ContextMissingBasicsDetector missingBasicsDetector;

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
    String? node,
    String? parentId,
    ContextLifespan lifespan = ContextLifespan.longTerm,
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
      node: _cleanNode(node) ?? existing?.node ?? section.matrixLabel,
      parentId: parentId ?? existing?.parentId,
      title: trimmedTitle,
      value: trimmedValue,
      source: isPinned ? ContextSource.userConfirmed : ContextSource.manual,
      lifespan: existing?.lifespan ?? lifespan,
      confirmationState: isPinned
          ? ContextConfirmationState.confirmed
          : ContextConfirmationState.unconfirmed,
      sensitivity: existing?.sensitivity ?? _sensitivityFor(section),
      priority: existing?.priority ?? _priorityFor(section, lifespan),
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

  Future<void> removeEntry(String entryId) async {
    try {
      await repository.removeEntry(entryId);
      _matrix = await repository.loadMatrix();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Context item could not be removed.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> confirmEntry(String entryId) async {
    await _updateEntry(
      entryId,
      (entry, now) => entry.copyWith(
        source: ContextSource.userConfirmed,
        confirmationState: ContextConfirmationState.confirmed,
        isPinned: true,
        updatedAt: now,
      ),
      failureMessage: 'Context item could not be confirmed.',
    );
  }

  Future<void> rejectEntry(String entryId) async {
    await _updateEntry(
      entryId,
      (entry, now) => entry.copyWith(
        confirmationState: ContextConfirmationState.rejected,
        updatedAt: now,
      ),
      failureMessage: 'Context item could not be rejected.',
    );
  }

  List<String> missingRecommendedTitles(ContextSection section) {
    return missingBasicsDetector.missingTitlesForSection(_matrix, section);
  }

  Future<void> _updateEntry(
    String entryId,
    ContextEntry Function(ContextEntry entry, DateTime now) update, {
    required String failureMessage,
  }) async {
    try {
      final now = DateTime.now();
      ContextEntry? existing;
      for (final entry in _matrix.entries) {
        if (entry.id == entryId) {
          existing = entry;
          break;
        }
      }
      if (existing == null) {
        _errorMessage = failureMessage;
        notifyListeners();
        return;
      }

      await repository.saveEntry(update(existing, now));
      _matrix = await repository.loadMatrix();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = failureMessage;
    } finally {
      notifyListeners();
    }
  }

  String _newEntryId(DateTime now) {
    return 'ctx_manual_${now.microsecondsSinceEpoch}';
  }

  String? _cleanNode(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  ContextSensitivity _sensitivityFor(ContextSection section) {
    return switch (section) {
      ContextSection.profile => ContextSensitivity.personal,
      ContextSection.healthConstraints => ContextSensitivity.health,
      ContextSection.currentState => ContextSensitivity.personal,
      ContextSection.nutritionContext => ContextSensitivity.personal,
      _ => ContextSensitivity.normal,
    };
  }

  double _priorityFor(ContextSection section, ContextLifespan lifespan) {
    final lifespanPriority = switch (lifespan) {
      ContextLifespan.temporary => 0.86,
      ContextLifespan.session => 0.72,
      ContextLifespan.longTerm => 0.64,
      ContextLifespan.permanent => 0.82,
    };
    final sectionBoost = switch (section) {
      ContextSection.profile => 0.08,
      ContextSection.goals => 0.12,
      ContextSection.healthConstraints => 0.12,
      ContextSection.currentState => 0.12,
      _ => 0.0,
    };
    return (lifespanPriority + sectionBoost).clamp(0.0, 1.0);
  }
}
