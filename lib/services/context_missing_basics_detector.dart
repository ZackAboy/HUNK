import '../models/context_entry.dart';
import '../models/context_matrix.dart';

class MissingBasicInfo {
  const MissingBasicInfo({
    required this.title,
    required this.section,
    required this.node,
    this.aliases = const [],
  });

  final String title;
  final ContextSection section;
  final String node;
  final List<String> aliases;
}

class ContextMissingBasicsDetector {
  const ContextMissingBasicsDetector();

  static const requiredBasics = [
    MissingBasicInfo(
      title: 'Age',
      section: ContextSection.profile,
      node: 'Body',
    ),
    MissingBasicInfo(
      title: 'Gender',
      section: ContextSection.profile,
      node: 'Body',
    ),
    MissingBasicInfo(
      title: 'Height',
      section: ContextSection.profile,
      node: 'Body',
    ),
    MissingBasicInfo(
      title: 'Weight',
      section: ContextSection.profile,
      node: 'Body',
      aliases: ['Current weight'],
    ),
    MissingBasicInfo(
      title: 'Primary goal',
      section: ContextSection.goals,
      node: 'Goals',
      aliases: ['Primary fitness goal', 'Main goal'],
    ),
    MissingBasicInfo(
      title: 'Training experience level',
      section: ContextSection.trainingHistory,
      node: 'Training',
      aliases: ['Experience level'],
    ),
    MissingBasicInfo(
      title: 'Equipment/access',
      section: ContextSection.equipmentAccess,
      node: 'Equipment',
      aliases: ['Gym access', 'Home equipment'],
    ),
    MissingBasicInfo(
      title: 'Injuries or constraints',
      section: ContextSection.healthConstraints,
      node: 'Health',
      aliases: ['Injuries', 'Constraints', 'Things to avoid'],
    ),
    MissingBasicInfo(
      title: 'Schedule availability',
      section: ContextSection.preferences,
      node: 'Preferences',
      aliases: ['Schedule preferences'],
    ),
    MissingBasicInfo(
      title: 'Current activity baseline',
      section: ContextSection.trainingHistory,
      node: 'Training',
      aliases: ['Activity baseline'],
    ),
    MissingBasicInfo(
      title: 'Preferred coaching style',
      section: ContextSection.preferences,
      node: 'Personality',
      aliases: ['Coaching style', 'Preferred coaching tone'],
    ),
  ];

  List<MissingBasicInfo> missingBasics(ContextMatrix matrix, {DateTime? now}) {
    final activeEntries = matrix.activeEntriesAt(now ?? DateTime.now());
    final activeTitles = <String>{};

    for (final entry in activeEntries) {
      activeTitles.add(_normalize(entry.title));
      activeTitles.add(_normalize(entry.nodeLabel));
    }

    return [
      for (final basic in requiredBasics)
        if (!_hasBasic(activeTitles, basic)) basic,
    ];
  }

  List<String> missingTitlesForSection(
    ContextMatrix matrix,
    ContextSection section, {
    DateTime? now,
  }) {
    return [
      for (final basic in missingBasics(matrix, now: now))
        if (basic.section == section) basic.title,
    ];
  }

  bool _hasBasic(Set<String> activeTitles, MissingBasicInfo basic) {
    final candidates = {
      _normalize(basic.title),
      for (final alias in basic.aliases) _normalize(alias),
    };
    return candidates.any(activeTitles.contains);
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  }
}
