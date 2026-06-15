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

  String get matrixLabel {
    return switch (this) {
      ContextSection.profile => 'Body',
      ContextSection.goals => 'Goals',
      ContextSection.preferences => 'Preferences',
      ContextSection.equipmentAccess => 'Equipment',
      ContextSection.healthConstraints => 'Health',
      ContextSection.currentState => 'Today',
      ContextSection.trainingHistory => 'Training',
      ContextSection.nutritionContext => 'Nutrition',
      ContextSection.environment => 'Environment',
      ContextSection.personalityMatrix => 'Personality',
      ContextSection.otherNotes => 'Memory',
    };
  }

  List<String> get recommendedTitles {
    return switch (this) {
      ContextSection.profile => ['Age', 'Gender', 'Height', 'Weight'],
      ContextSection.goals => [
        'Primary goal',
        'Secondary goals',
        'Long-term goal',
        'Target weight/body composition',
        'Running goals',
        'Strength goals',
      ],
      ContextSection.preferences => [
        'Preferred coaching style',
        'Food preferences',
        'Workout preferences',
        'Schedule availability',
        'Exercise likes/dislikes',
      ],
      ContextSection.equipmentAccess => [
        'Equipment/access',
        'Gym access',
        'Home equipment',
        'Wearables',
        'Running gear',
        'Available machines/exercises',
      ],
      ContextSection.healthConstraints => [
        'Injuries or constraints',
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
        'Training experience level',
        'Current activity baseline',
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

enum ContextSource {
  manual,
  chatExtracted,
  userConfirmed,
  futureHealthImport,
  futureWeatherImport,
  systemDefault,
}

extension ContextSourceInfo on ContextSource {
  String get storageValue {
    return switch (this) {
      ContextSource.manual => 'manual',
      ContextSource.chatExtracted => 'chat_extracted',
      ContextSource.userConfirmed => 'user_confirmed',
      ContextSource.futureHealthImport => 'future_health_import',
      ContextSource.futureWeatherImport => 'future_weather_import',
      ContextSource.systemDefault => 'system_default',
    };
  }

  String get label {
    return switch (this) {
      ContextSource.manual => 'manual',
      ContextSource.chatExtracted => 'chat extracted',
      ContextSource.userConfirmed => 'user confirmed',
      ContextSource.futureHealthImport => 'future health import',
      ContextSource.futureWeatherImport => 'future weather import',
      ContextSource.systemDefault => 'system default',
    };
  }

  static ContextSource fromStorageValue(String? value) {
    if (value == 'system/default') {
      return ContextSource.systemDefault;
    }

    return ContextSource.values.firstWhere(
      (source) => source.storageValue == value,
      orElse: () => ContextSource.manual,
    );
  }
}

enum ContextLifespan { temporary, session, longTerm, permanent }

extension ContextLifespanInfo on ContextLifespan {
  String get storageValue {
    return switch (this) {
      ContextLifespan.temporary => 'temporary',
      ContextLifespan.session => 'session',
      ContextLifespan.longTerm => 'long_term',
      ContextLifespan.permanent => 'permanent',
    };
  }

  String get label {
    return switch (this) {
      ContextLifespan.temporary => 'temporary',
      ContextLifespan.session => 'session',
      ContextLifespan.longTerm => 'long term',
      ContextLifespan.permanent => 'permanent',
    };
  }

  static ContextLifespan fromStorageValue(String? value) {
    return ContextLifespan.values.firstWhere(
      (lifespan) => lifespan.storageValue == value,
      orElse: () => ContextLifespan.longTerm,
    );
  }
}

enum ContextStatus { active, archived, deleted }

extension ContextStatusInfo on ContextStatus {
  String get storageValue {
    return switch (this) {
      ContextStatus.active => 'active',
      ContextStatus.archived => 'archived',
      ContextStatus.deleted => 'deleted',
    };
  }

  static ContextStatus fromStorageValue(
    String? value, {
    bool archived = false,
  }) {
    if (archived) {
      return ContextStatus.archived;
    }

    return ContextStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => ContextStatus.active,
    );
  }
}

enum ContextConfirmationState { unconfirmed, confirmed, rejected }

extension ContextConfirmationStateInfo on ContextConfirmationState {
  String get storageValue {
    return switch (this) {
      ContextConfirmationState.unconfirmed => 'unconfirmed',
      ContextConfirmationState.confirmed => 'confirmed',
      ContextConfirmationState.rejected => 'rejected',
    };
  }

  String get label {
    return switch (this) {
      ContextConfirmationState.unconfirmed => 'unconfirmed',
      ContextConfirmationState.confirmed => 'confirmed',
      ContextConfirmationState.rejected => 'rejected',
    };
  }

  static ContextConfirmationState fromStorageValue(
    String? value, {
    bool pinned = false,
  }) {
    if (pinned) {
      return ContextConfirmationState.confirmed;
    }

    return ContextConfirmationState.values.firstWhere(
      (state) => state.storageValue == value,
      orElse: () => ContextConfirmationState.unconfirmed,
    );
  }
}

enum ContextSensitivity { normal, personal, health, sensitive }

extension ContextSensitivityInfo on ContextSensitivity {
  String get storageValue {
    return switch (this) {
      ContextSensitivity.normal => 'normal',
      ContextSensitivity.personal => 'personal',
      ContextSensitivity.health => 'health',
      ContextSensitivity.sensitive => 'sensitive',
    };
  }

  String get label {
    return switch (this) {
      ContextSensitivity.normal => 'normal',
      ContextSensitivity.personal => 'personal',
      ContextSensitivity.health => 'health',
      ContextSensitivity.sensitive => 'sensitive',
    };
  }

  static ContextSensitivity fromStorageValue(String? value) {
    return ContextSensitivity.values.firstWhere(
      (sensitivity) => sensitivity.storageValue == value,
      orElse: () => ContextSensitivity.normal,
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
    this.node,
    this.parentId,
    this.lifespan = ContextLifespan.longTerm,
    ContextStatus status = ContextStatus.active,
    ContextConfirmationState confirmationState =
        ContextConfirmationState.unconfirmed,
    this.sensitivity = ContextSensitivity.normal,
    this.priority = 0.5,
    this.confidence,
    this.lastUsedAt,
    this.expiresAt,
    this.isPinned = false,
    bool isArchived = false,
  }) : status = isArchived ? ContextStatus.archived : status,
       confirmationState = isPinned
           ? ContextConfirmationState.confirmed
           : confirmationState;

  factory ContextEntry.fromJson(Map<String, Object?> json) {
    final pinned = json['isPinned'] as bool? ?? false;
    final archived = json['isArchived'] as bool? ?? false;
    final source = ContextSourceInfo.fromStorageValue(
      json['source'] as String?,
    );
    final section = ContextSectionInfo.fromStorageValue(
      json['section'] as String?,
    );
    final confirmationState = ContextConfirmationStateInfo.fromStorageValue(
      json['confirmationState'] as String?,
      pinned: pinned,
    );

    return ContextEntry(
      id: json['id'] as String? ?? '',
      section: section,
      node: _trimmedOrNull(json['node']) ?? section.matrixLabel,
      parentId: _trimmedOrNull(json['parentId']),
      title: json['title'] as String? ?? '',
      value: json['value'] as String? ?? '',
      source: source,
      lifespan: ContextLifespanInfo.fromStorageValue(
        json['lifespan'] as String?,
      ),
      status: ContextStatusInfo.fromStorageValue(
        json['status'] as String?,
        archived: archived,
      ),
      confirmationState: confirmationState,
      sensitivity: ContextSensitivityInfo.fromStorageValue(
        json['sensitivity'] as String?,
      ),
      priority: (json['priority'] as num?)?.toDouble() ?? 0.5,
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      lastUsedAt: _parseDate(json['lastUsedAt']),
      expiresAt: _parseDate(json['expiresAt']),
      isPinned:
          pinned || confirmationState == ContextConfirmationState.confirmed,
    );
  }

  final String id;
  final ContextSection section;
  final String? node;
  final String? parentId;
  final String title;
  final String value;
  final ContextSource source;
  final ContextLifespan lifespan;
  final ContextStatus status;
  final ContextConfirmationState confirmationState;
  final ContextSensitivity sensitivity;
  final double priority;
  final double? confidence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;
  final bool isPinned;

  String get nodeLabel {
    final trimmed = node?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return section.matrixLabel;
  }

  bool get isArchived => status == ContextStatus.archived;
  bool get isDeleted => status == ContextStatus.deleted;
  bool get isRejected => confirmationState == ContextConfirmationState.rejected;
  bool get isConfirmed =>
      confirmationState == ContextConfirmationState.confirmed;

  bool get isActive => isActiveAt(DateTime.now());

  bool isActiveAt(DateTime now) {
    return status == ContextStatus.active &&
        confirmationState != ContextConfirmationState.rejected &&
        !_isExpiredAt(now);
  }

  bool _isExpiredAt(DateTime now) {
    final expiry = expiresAt;
    return expiry != null && !expiry.isAfter(now);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'section': section.storageValue,
      'node': nodeLabel,
      'parentId': parentId,
      'title': title,
      'value': value,
      'source': source.storageValue,
      'lifespan': lifespan.storageValue,
      'status': status.storageValue,
      'confirmationState': confirmationState.storageValue,
      'sensitivity': sensitivity.storageValue,
      'priority': priority,
      'confidence': confidence,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isPinned': isPinned || isConfirmed,
      'isArchived': isArchived,
    };
  }

  ContextEntry copyWith({
    String? id,
    ContextSection? section,
    Object? node = _unchanged,
    Object? parentId = _unchanged,
    String? title,
    String? value,
    ContextSource? source,
    ContextLifespan? lifespan,
    ContextStatus? status,
    ContextConfirmationState? confirmationState,
    ContextSensitivity? sensitivity,
    double? priority,
    Object? confidence = _unchanged,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastUsedAt = _unchanged,
    Object? expiresAt = _unchanged,
    bool? isPinned,
    bool? isArchived,
  }) {
    final nextStatus = isArchived == true
        ? ContextStatus.archived
        : status ?? this.status;
    final nextConfirmation = isPinned == true
        ? ContextConfirmationState.confirmed
        : confirmationState ?? this.confirmationState;

    return ContextEntry(
      id: id ?? this.id,
      section: section ?? this.section,
      node: node == _unchanged ? this.node : node as String?,
      parentId: parentId == _unchanged ? this.parentId : parentId as String?,
      title: title ?? this.title,
      value: value ?? this.value,
      source: source ?? this.source,
      lifespan: lifespan ?? this.lifespan,
      status: nextStatus,
      confirmationState: nextConfirmation,
      sensitivity: sensitivity ?? this.sensitivity,
      priority: priority ?? this.priority,
      confidence: confidence == _unchanged
          ? this.confidence
          : confidence as double?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt == _unchanged
          ? this.lastUsedAt
          : lastUsedAt as DateTime?,
      expiresAt: expiresAt == _unchanged
          ? this.expiresAt
          : expiresAt as DateTime?,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static String? _trimmedOrNull(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

const Object _unchanged = Object();
