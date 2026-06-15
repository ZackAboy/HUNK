import 'dart:convert';

import '../models/context_entry.dart';

enum ContextSuggestionAction { create, update, archive, ignore }

class ContextUpdateSuggestion {
  const ContextUpdateSuggestion({
    required this.action,
    required this.section,
    required this.node,
    required this.title,
    required this.value,
    required this.lifespan,
    required this.sensitivity,
    required this.confidence,
    required this.reason,
    this.parentTitle,
  });

  final ContextSuggestionAction action;
  final ContextSection section;
  final String node;
  final String? parentTitle;
  final String title;
  final String value;
  final ContextLifespan lifespan;
  final ContextSensitivity sensitivity;
  final double confidence;
  final String reason;
}

class ContextExtractionService {
  const ContextExtractionService();

  List<ContextEntry> extractFromUserMessage({
    required String message,
    required List<ContextEntry> existingEntries,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final trimmed = message.trim();
    if (trimmed.length < 8) {
      return const [];
    }

    final lower = trimmed.toLowerCase();
    final candidates = <_ContextCandidate>[];

    _addProfileCandidates(trimmed, candidates);
    _addGoalCandidates(trimmed, lower, candidates);
    _addEquipmentCandidates(trimmed, lower, candidates);
    _addPreferenceCandidates(trimmed, lower, candidates);
    _addHealthCandidates(trimmed, lower, timestamp, candidates);
    _addCurrentStateCandidates(trimmed, lower, timestamp, candidates);
    _addTrainingCandidates(trimmed, lower, candidates);
    _addNutritionCandidates(trimmed, lower, candidates);

    final entries = <ContextEntry>[];
    for (var i = 0; i < candidates.length; i += 1) {
      final entry = _toEntry(candidates[i], existingEntries, timestamp, i);
      if (entry != null) {
        entries.add(entry);
      }
    }

    return entries;
  }

  List<ContextUpdateSuggestion> parseSuggestionsJson(String rawJson) {
    Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException {
      return const [];
    }

    final rawItems = switch (decoded) {
      List() => decoded,
      Map<String, Object?>() =>
        decoded['updates'] is List
            ? decoded['updates'] as List
            : decoded['suggestions'] is List
            ? decoded['suggestions'] as List
            : const [],
      _ => const [],
    };

    final suggestions = <ContextUpdateSuggestion>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map) {
        continue;
      }
      final parsed = _parseSuggestion(Map<String, Object?>.from(rawItem));
      if (parsed != null) {
        suggestions.add(parsed);
      }
    }

    return suggestions;
  }

  void _addProfileCandidates(
    String trimmed,
    List<_ContextCandidate> candidates,
  ) {
    final ageMatch = RegExp(
      r"\b(?:i am|i'm|im)\s+(\d{1,3})\s*(?:years old|yo)?\b",
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (ageMatch != null) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.profile,
          node: 'Body',
          title: 'Age',
          value: ageMatch.group(1)!,
          confidence: 0.72,
          lifespan: ContextLifespan.permanent,
          sensitivity: ContextSensitivity.personal,
          priority: 0.92,
        ),
      );
    }

    final genderMatch = RegExp(
      r"\b(?:i am|i'm|im)\s+(male|female|nonbinary|non-binary|a man|a woman)\b",
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (genderMatch != null) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.profile,
          node: 'Body',
          title: 'Gender',
          value: genderMatch.group(1)!,
          confidence: 0.68,
          lifespan: ContextLifespan.permanent,
          sensitivity: ContextSensitivity.personal,
          priority: 0.8,
        ),
      );
    }

    final feetHeightMatch = RegExp(
      r'''\b(?:i am|i'm|im|height is|my height is)\s+([4-7])\s*(?:'|ft|feet)\s*(\d{1,2})?\s*(?:"|in|inches)?''',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (feetHeightMatch != null) {
      final feet = feetHeightMatch.group(1)!;
      final inches = feetHeightMatch.group(2);
      candidates.add(
        _ContextCandidate(
          section: ContextSection.profile,
          node: 'Body',
          title: 'Height',
          value: inches == null || inches.isEmpty
              ? '$feet ft'
              : "$feet'$inches",
          confidence: 0.68,
          lifespan: ContextLifespan.permanent,
          sensitivity: ContextSensitivity.personal,
          priority: 0.9,
        ),
      );
    }

    final metricHeightMatch = RegExp(
      r"\b(?:i am|i'm|im|height is|my height is)\s+(\d{2,3})\s*cm\b",
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (metricHeightMatch != null) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.profile,
          node: 'Body',
          title: 'Height',
          value: '${metricHeightMatch.group(1)!} cm',
          confidence: 0.68,
          lifespan: ContextLifespan.permanent,
          sensitivity: ContextSensitivity.personal,
          priority: 0.9,
        ),
      );
    }

    final weightMatch = RegExp(
      r'\b(?:i weigh|my weight is|weight is)\s+(\d{2,3})\s*(lbs?|pounds|kg)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (weightMatch != null) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.profile,
          node: 'Body',
          title: 'Weight',
          value: '${weightMatch.group(1)!} ${weightMatch.group(2)!}',
          confidence: 0.68,
          lifespan: ContextLifespan.longTerm,
          sensitivity: ContextSensitivity.personal,
          priority: 0.9,
        ),
      );
    }
  }

  void _addGoalCandidates(
    String trimmed,
    String lower,
    List<_ContextCandidate> candidates,
  ) {
    if (!_mentionsGoal(lower)) {
      return;
    }

    final runningGoal = _containsAny(lower, ['5k', '10k', 'marathon', 'run']);
    final strengthGoal = _containsAny(lower, ['strength', 'stronger', 'lift']);
    candidates.add(
      _ContextCandidate(
        section: ContextSection.goals,
        node: runningGoal
            ? 'Running'
            : strengthGoal
            ? 'Strength'
            : 'Goals',
        title: runningGoal
            ? 'Running goal'
            : strengthGoal
            ? 'Strength goal'
            : 'Primary goal',
        value: trimmed,
        confidence: 0.62,
        lifespan: ContextLifespan.longTerm,
        sensitivity: ContextSensitivity.normal,
        priority: 0.86,
      ),
    );
  }

  void _addEquipmentCandidates(
    String trimmed,
    String lower,
    List<_ContextCandidate> candidates,
  ) {
    if (!_mentionsEquipment(lower)) {
      return;
    }

    candidates.add(
      _ContextCandidate(
        section: ContextSection.equipmentAccess,
        node: 'Equipment',
        title: 'Equipment/access',
        value: trimmed,
        confidence: 0.64,
        lifespan: ContextLifespan.longTerm,
        sensitivity: ContextSensitivity.normal,
        priority: 0.78,
      ),
    );
  }

  void _addPreferenceCandidates(
    String trimmed,
    String lower,
    List<_ContextCandidate> candidates,
  ) {
    if (!_mentionsPreference(lower)) {
      return;
    }

    final coaching = lower.contains('coaching') || lower.contains('concise');
    candidates.add(
      _ContextCandidate(
        section: coaching
            ? ContextSection.personalityMatrix
            : ContextSection.preferences,
        node: coaching ? 'Personality' : 'Preferences',
        title: coaching ? 'Preferred coaching style' : 'Preference',
        value: trimmed,
        confidence: 0.58,
        lifespan: ContextLifespan.longTerm,
        sensitivity: ContextSensitivity.normal,
        priority: coaching ? 0.78 : 0.62,
      ),
    );
  }

  void _addHealthCandidates(
    String trimmed,
    String lower,
    DateTime now,
    List<_ContextCandidate> candidates,
  ) {
    if (!_mentionsHealthConstraint(lower)) {
      return;
    }

    final temporary = _containsAny(lower, [
      'today',
      'this week',
      'for a week',
      'right now',
      'temporary',
    ]);
    candidates.add(
      _ContextCandidate(
        section: ContextSection.healthConstraints,
        node: lower.contains('injur') ? 'Injuries' : 'Health',
        title: temporary ? 'Temporary constraint' : 'Injuries or constraints',
        value: trimmed,
        confidence: 0.66,
        lifespan: temporary
            ? ContextLifespan.temporary
            : ContextLifespan.longTerm,
        sensitivity: ContextSensitivity.health,
        priority: temporary ? 0.92 : 0.84,
        expiresAt: temporary ? now.add(const Duration(days: 7)) : null,
      ),
    );
  }

  void _addCurrentStateCandidates(
    String trimmed,
    String lower,
    DateTime now,
    List<_ContextCandidate> candidates,
  ) {
    if (!_mentionsCurrentState(lower)) {
      return;
    }

    candidates.add(
      _ContextCandidate(
        section: ContextSection.currentState,
        node: lower.contains('sore') ? 'Recovery' : 'Today',
        title: lower.contains('sore') ? 'Today soreness' : 'Today',
        value: trimmed,
        confidence: 0.58,
        lifespan: ContextLifespan.temporary,
        sensitivity: ContextSensitivity.personal,
        priority: 0.88,
        expiresAt: now.add(const Duration(days: 1)),
      ),
    );
  }

  void _addTrainingCandidates(
    String trimmed,
    String lower,
    List<_ContextCandidate> candidates,
  ) {
    if (_containsAny(lower, ['beginner', 'intermediate', 'advanced'])) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.trainingHistory,
          node: 'Training',
          title: 'Training experience level',
          value: trimmed,
          confidence: 0.62,
          lifespan: ContextLifespan.longTerm,
          sensitivity: ContextSensitivity.normal,
          priority: 0.8,
        ),
      );
      return;
    }

    if (!_mentionsTrainingHistory(lower)) {
      return;
    }

    candidates.add(
      _ContextCandidate(
        section: ContextSection.trainingHistory,
        node: lower.contains('run') ? 'Running' : 'Training',
        title: lower.contains('baseline')
            ? 'Current activity baseline'
            : 'Training note',
        value: trimmed,
        confidence: 0.56,
        lifespan: ContextLifespan.longTerm,
        sensitivity: ContextSensitivity.normal,
        priority: 0.58,
      ),
    );
  }

  void _addNutritionCandidates(
    String trimmed,
    String lower,
    List<_ContextCandidate> candidates,
  ) {
    if (!_mentionsNutrition(lower)) {
      return;
    }

    candidates.add(
      _ContextCandidate(
        section: ContextSection.nutritionContext,
        node: 'Nutrition',
        title: lower.contains('cutting') ? 'Cutting weight' : 'Nutrition note',
        value: trimmed,
        confidence: 0.58,
        lifespan: ContextLifespan.longTerm,
        sensitivity: ContextSensitivity.personal,
        priority: 0.66,
      ),
    );
  }

  bool _mentionsGoal(String lower) {
    return _containsAny(lower, [
          'my goal is',
          'primary goal',
          'main goal',
          'trying to',
          'i want to',
          'training for',
          'target weight',
          'improve my',
          'run a',
          '5k',
          '10k',
          'marathon',
          'half marathon',
          'build muscle',
          'lose weight',
          'cutting weight',
          'get stronger',
        ]) &&
        _containsAny(lower, [
          'goal',
          'training',
          'run',
          '5k',
          '10k',
          'marathon',
          'muscle',
          'weight',
          'strong',
          'fitness',
        ]);
  }

  bool _mentionsEquipment(String lower) {
    return _containsAny(lower, [
      'gym access',
      'gym membership',
      'home gym',
      'i have dumbbells',
      'i own dumbbells',
      'adjustable dumbbells',
      'i have a barbell',
      'i have a treadmill',
      'i have kettlebells',
      'wear a',
      'wearable',
      'apple watch',
      'garmin',
      'whoop',
    ]);
  }

  bool _mentionsPreference(String lower) {
    return _containsAny(lower, [
      'i prefer',
      'i like',
      'i dislike',
      "i don't like",
      'i hate',
      'coaching style',
      'concise coaching',
      'workout preference',
      'food preference',
      'burpees',
    ]);
  }

  bool _mentionsHealthConstraint(String lower) {
    return _containsAny(lower, [
      'injury',
      'injured',
      'pain',
      'hurts',
      'hurt my',
      'medical condition',
      'doctor told me',
      'avoid',
      'mobility',
      'restriction',
      'sleep issue',
      'wrist',
      'knee',
      'shoulder',
      'back',
    ]);
  }

  bool _mentionsCurrentState(String lower) {
    return _containsAny(lower, [
          'today',
          'right now',
          'this morning',
          'tonight',
          'this week',
        ]) &&
        _containsAny(lower, [
          'energy',
          'sore',
          'soreness',
          'fatigue',
          'tired',
          'stress',
          'mood',
          'hungry',
          'recovered',
          'legs',
        ]);
  }

  bool _mentionsTrainingHistory(String lower) {
    return _containsAny(lower, [
      'yesterday i ran',
      'i ran',
      'i lifted',
      'workout',
      'bench',
      'squat',
      'deadlift',
      'pr',
      'personal record',
      'recent run',
      'recent lift',
      'baseline',
    ]);
  }

  bool _mentionsNutrition(String lower) {
    return _containsAny(lower, [
      'calorie',
      'protein',
      'vegan',
      'vegetarian',
      'gluten',
      'diet',
      'supplement',
      'creatine',
      'common foods',
      'cutting weight',
      'cut weight',
    ]);
  }

  bool _containsAny(String value, List<String> needles) {
    return needles.any(value.contains);
  }

  ContextEntry? _toEntry(
    _ContextCandidate candidate,
    List<ContextEntry> existingEntries,
    DateTime now,
    int index,
  ) {
    final existing = existingEntries.where((entry) {
      return entry.status == ContextStatus.active &&
          entry.section == candidate.section &&
          _normalize(entry.nodeLabel) == _normalize(candidate.node) &&
          _normalize(entry.title) == _normalize(candidate.title);
    }).toList();

    if (existing.any(_isProtectedFromExtraction)) {
      return null;
    }

    final updatable = existing.isEmpty ? null : existing.first;
    if (updatable != null && updatable.value.trim() == candidate.value.trim()) {
      return null;
    }

    final id =
        updatable?.id ??
        'ctx_${now.microsecondsSinceEpoch}_${index}_${candidate.title.hashCode.abs()}';

    return ContextEntry(
      id: id,
      section: candidate.section,
      node: candidate.node,
      title: candidate.title,
      value: candidate.value,
      source: ContextSource.chatExtracted,
      lifespan: candidate.lifespan,
      confirmationState: ContextConfirmationState.unconfirmed,
      sensitivity: candidate.sensitivity,
      priority: candidate.priority,
      confidence: candidate.confidence,
      createdAt: updatable?.createdAt ?? now,
      updatedAt: now,
      expiresAt: candidate.expiresAt,
    );
  }

  ContextUpdateSuggestion? _parseSuggestion(Map<String, Object?> json) {
    final action = _parseAction(json['action']);
    if (action == null) {
      return null;
    }

    final title = _cleanText(json['key'] ?? json['title']);
    final value = _cleanText(json['value'] ?? json['content']);
    if (action != ContextSuggestionAction.ignore &&
        action != ContextSuggestionAction.archive &&
        (title == null || value == null)) {
      return null;
    }

    final node = _cleanText(json['node']) ?? 'Memory';
    return ContextUpdateSuggestion(
      action: action,
      section: _sectionForNode(node),
      node: node,
      parentTitle: _cleanText(json['parentNode'] ?? json['parentTitle']),
      title: title ?? '',
      value: value ?? '',
      lifespan: ContextLifespanInfo.fromStorageValue(
        _cleanText(json['lifespan']),
      ),
      sensitivity: ContextSensitivityInfo.fromStorageValue(
        _cleanText(json['sensitivity']),
      ),
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.0).clamp(
        0.0,
        1.0,
      ),
      reason: _cleanText(json['reason']) ?? '',
    );
  }

  ContextSuggestionAction? _parseAction(Object? value) {
    final normalized = _cleanText(value)?.toLowerCase();
    return switch (normalized) {
      'create' => ContextSuggestionAction.create,
      'update' => ContextSuggestionAction.update,
      'archive' => ContextSuggestionAction.archive,
      'ignore' => ContextSuggestionAction.ignore,
      _ => null,
    };
  }

  ContextSection _sectionForNode(String node) {
    final lower = node.toLowerCase();
    if (_containsAny(lower, ['goal', 'running', 'strength'])) {
      return ContextSection.goals;
    }
    if (_containsAny(lower, ['body', 'profile'])) {
      return ContextSection.profile;
    }
    if (_containsAny(lower, ['equipment', 'gear', 'gym'])) {
      return ContextSection.equipmentAccess;
    }
    if (_containsAny(lower, ['injury', 'health', 'recovery'])) {
      return ContextSection.healthConstraints;
    }
    if (_containsAny(lower, ['today', 'current'])) {
      return ContextSection.currentState;
    }
    if (_containsAny(lower, ['training'])) {
      return ContextSection.trainingHistory;
    }
    if (_containsAny(lower, ['nutrition', 'diet'])) {
      return ContextSection.nutritionContext;
    }
    if (_containsAny(lower, ['environment', 'weather'])) {
      return ContextSection.environment;
    }
    if (_containsAny(lower, ['preference'])) {
      return ContextSection.preferences;
    }
    if (_containsAny(lower, ['personality', 'style'])) {
      return ContextSection.personalityMatrix;
    }
    return ContextSection.otherNotes;
  }

  bool _isProtectedFromExtraction(ContextEntry entry) {
    return entry.source == ContextSource.manual ||
        entry.source == ContextSource.userConfirmed ||
        entry.isConfirmed ||
        entry.lifespan == ContextLifespan.permanent;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  }

  String? _cleanText(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 600) {
      return null;
    }
    return trimmed;
  }
}

class _ContextCandidate {
  const _ContextCandidate({
    required this.section,
    required this.node,
    required this.title,
    required this.value,
    required this.confidence,
    required this.lifespan,
    required this.sensitivity,
    required this.priority,
    this.expiresAt,
  });

  final ContextSection section;
  final String node;
  final String title;
  final String value;
  final double confidence;
  final ContextLifespan lifespan;
  final ContextSensitivity sensitivity;
  final double priority;
  final DateTime? expiresAt;
}
