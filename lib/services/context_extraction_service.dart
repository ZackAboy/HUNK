import '../models/context_entry.dart';

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

    final ageMatch = RegExp(
      r"\b(?:i am|i'm|im)\s+(\d{1,3})\s*(?:years old|yo)?\b",
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (ageMatch != null) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.profile,
          title: 'Age',
          value: ageMatch.group(1)!,
          confidence: 0.72,
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
          title: 'Height',
          value: inches == null || inches.isEmpty
              ? '$feet ft'
              : "$feet'$inches",
          confidence: 0.68,
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
          title: 'Height',
          value: '${metricHeightMatch.group(1)!} cm',
          confidence: 0.68,
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
          title: 'Weight',
          value: '${weightMatch.group(1)!} ${weightMatch.group(2)!}',
          confidence: 0.68,
        ),
      );
    }

    if (_mentionsGoal(lower)) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.goals,
          title: 'Primary fitness goal',
          value: trimmed,
          confidence: 0.58,
        ),
      );
    }

    if (_mentionsEquipment(lower)) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.equipmentAccess,
          title: 'Equipment/access',
          value: trimmed,
          confidence: 0.61,
        ),
      );
    }

    if (_mentionsPreference(lower)) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.preferences,
          title: 'Preference',
          value: trimmed,
          confidence: 0.54,
        ),
      );
    }

    if (_mentionsHealthConstraint(lower)) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.healthConstraints,
          title: 'User-stated constraint',
          value: trimmed,
          confidence: 0.62,
        ),
      );
    }

    if (_mentionsCurrentState(lower)) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.currentState,
          title: 'Today',
          value: trimmed,
          confidence: 0.56,
        ),
      );
    }

    if (_mentionsTrainingHistory(lower)) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.trainingHistory,
          title: 'Training note',
          value: trimmed,
          confidence: 0.55,
        ),
      );
    }

    if (_mentionsNutrition(lower)) {
      candidates.add(
        _ContextCandidate(
          section: ContextSection.nutritionContext,
          title: 'Nutrition note',
          value: trimmed,
          confidence: 0.55,
        ),
      );
    }

    final entries = <ContextEntry>[];
    for (var i = 0; i < candidates.length; i += 1) {
      final entry = _toEntry(candidates[i], existingEntries, timestamp, i);
      if (entry != null) {
        entries.add(entry);
      }
    }

    return entries;
  }

  bool _mentionsGoal(String lower) {
    return _containsAny(lower, [
          'my goal is',
          'primary goal',
          'trying to',
          'i want to',
          'training for',
          'target weight',
          'run a',
          'marathon',
          'half marathon',
          'build muscle',
          'lose weight',
          'get stronger',
        ]) &&
        _containsAny(lower, [
          'goal',
          'training',
          'run',
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
      'workout preference',
      'food preference',
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
    ]);
  }

  bool _mentionsCurrentState(String lower) {
    return _containsAny(lower, [
          'today',
          'right now',
          'this morning',
          'tonight',
        ]) &&
        _containsAny(lower, [
          'energy',
          'sore',
          'fatigue',
          'tired',
          'stress',
          'mood',
          'hungry',
          'recovered',
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
      return entry.isActive &&
          entry.section == candidate.section &&
          entry.title.toLowerCase() == candidate.title.toLowerCase();
    }).toList();

    if (existing.any(
      (entry) => entry.isPinned || entry.source == ContextSource.manual,
    )) {
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
      title: candidate.title,
      value: candidate.value,
      source: ContextSource.chatExtracted,
      confidence: candidate.confidence,
      createdAt: updatable?.createdAt ?? now,
      updatedAt: now,
    );
  }
}

class _ContextCandidate {
  const _ContextCandidate({
    required this.section,
    required this.title,
    required this.value,
    required this.confidence,
  });

  final ContextSection section;
  final String title;
  final String value;
  final double confidence;
}
