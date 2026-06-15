enum ContextSection {
  profile,
  goals,
  preferences,
  equipmentAccess,
  healthConstraints,
  currentState,
  trainingHistory,
  nutritionContext,
  environment,
  personalityMatrix,
  otherNotes,
}

extension ContextSectionInfo on ContextSection {
  String get storageValue {
    return switch (this) {
      ContextSection.profile => 'profile',
      ContextSection.goals => 'goals',
      ContextSection.preferences => 'preferences',
      ContextSection.equipmentAccess => 'equipment_access',
      ContextSection.healthConstraints => 'health_constraints',
      ContextSection.currentState => 'current_state',
      ContextSection.trainingHistory => 'training_history',
      ContextSection.nutritionContext => 'nutrition_context',
      ContextSection.environment => 'environment',
      ContextSection.personalityMatrix => 'personality_matrix',
      ContextSection.otherNotes => 'other_notes',
    };
  }

  String get label {
    return switch (this) {
      ContextSection.profile => 'Profile',
      ContextSection.goals => 'Goals',
      ContextSection.preferences => 'Preferences',
      ContextSection.equipmentAccess => 'Equipment and access',
      ContextSection.healthConstraints => 'Health and constraints',
      ContextSection.currentState => 'Current state',
      ContextSection.trainingHistory => 'Training history',
      ContextSection.nutritionContext => 'Nutrition context',
      ContextSection.environment => 'Environment',
      ContextSection.personalityMatrix => 'Personality matrix',
      ContextSection.otherNotes => 'Other notes',
    };
  }

  List<String> get recommendedTitles {
    return switch (this) {
      ContextSection.profile => [
        'Age',
        'Gender',
        'Height',
        'Weight',
        'Location/timezone',
      ],
      ContextSection.goals => [
        'Primary fitness goal',
        'Secondary goals',
        'Long-term goal',
        'Target weight/body composition',
        'Running goals',
        'Strength goals',
      ],
      ContextSection.preferences => [
        'Food preferences',
        'Workout preferences',
        'Coaching style',
        'Schedule preferences',
        'Exercise likes/dislikes',
      ],
      ContextSection.equipmentAccess => [
        'Gym access',
        'Home equipment',
        'Wearables',
        'Running gear',
        'Available machines/exercises',
      ],
      ContextSection.healthConstraints => [
        'Injuries',
        'Pain history',
        'Medical conditions',
        'Recovery limitations',
        'Sleep issues',
        'Mobility restrictions',
        'Things to avoid',
      ],
      ContextSection.currentState => [
        'Today',
        'Energy level',
        'Soreness/fatigue',
        'Hunger/stress/mood',
      ],
      ContextSection.trainingHistory => [
        'Past workouts',
        'Recent runs',
        'Recent lifts',
        'PRs / baselines',
      ],
      ContextSection.nutritionContext => [
        'Calorie target',
        'Protein target',
        'Dietary constraints',
        'Common foods',
        'Supplements',
      ],
      ContextSection.environment => [
        'Weather placeholder',
        'Outdoor running conditions',
        'Local gym/environment notes',
      ],
      ContextSection.personalityMatrix => [
        'Preferred coaching tone',
        'Motivation style',
        'Accountability level',
        'Detail level',
        'Risk tolerance',
        'Habit patterns',
      ],
      ContextSection.otherNotes => ['Other relevant facts'],
    };
  }

  static ContextSection fromStorageValue(String? value) {
    return ContextSection.values.firstWhere(
      (section) => section.storageValue == value,
      orElse: () => ContextSection.otherNotes,
    );
  }
}

enum ContextSource { manual, chatExtracted, futureHealthImport, systemDefault }

extension ContextSourceInfo on ContextSource {
  String get storageValue {
    return switch (this) {
      ContextSource.manual => 'manual',
      ContextSource.chatExtracted => 'chat_extracted',
      ContextSource.futureHealthImport => 'future_health_import',
      ContextSource.systemDefault => 'system/default',
    };
  }

  String get label {
    return switch (this) {
      ContextSource.manual => 'manual',
      ContextSource.chatExtracted => 'chat extracted',
      ContextSource.futureHealthImport => 'future health import',
      ContextSource.systemDefault => 'system/default',
    };
  }

  static ContextSource fromStorageValue(String? value) {
    return ContextSource.values.firstWhere(
      (source) => source.storageValue == value,
      orElse: () => ContextSource.manual,
    );
  }
}

class ContextEntry {
  const ContextEntry({
    required this.id,
    required this.section,
    required this.title,
    required this.value,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.confidence,
    this.isPinned = false,
    this.isArchived = false,
  });

  factory ContextEntry.fromJson(Map<String, Object?> json) {
    return ContextEntry(
      id: json['id'] as String? ?? '',
      section: ContextSectionInfo.fromStorageValue(json['section'] as String?),
      title: json['title'] as String? ?? '',
      value: json['value'] as String? ?? '',
      source: ContextSourceInfo.fromStorageValue(json['source'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  final String id;
  final ContextSection section;
  final String title;
  final String value;
  final ContextSource source;
  final double? confidence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isArchived;

  bool get isActive => !isArchived;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'section': section.storageValue,
      'title': title,
      'value': value,
      'source': source.storageValue,
      'confidence': confidence,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'isArchived': isArchived,
    };
  }

  ContextEntry copyWith({
    String? id,
    ContextSection? section,
    String? title,
    String? value,
    ContextSource? source,
    Object? confidence = _unchanged,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
  }) {
    return ContextEntry(
      id: id ?? this.id,
      section: section ?? this.section,
      title: title ?? this.title,
      value: value ?? this.value,
      source: source ?? this.source,
      confidence: confidence == _unchanged
          ? this.confidence
          : confidence as double?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}

const Object _unchanged = Object();
