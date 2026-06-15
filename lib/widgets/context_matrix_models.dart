import '../models/context_entry.dart';

class ContextSectionNodeData {
  const ContextSectionNodeData({
    required this.section,
    required this.entries,
    required this.missingTitles,
  });

  final ContextSection section;
  final List<ContextEntry> entries;
  final List<String> missingTitles;
}

class ContextMatrixCounts {
  const ContextMatrixCounts({
    required this.active,
    required this.confirmed,
    required this.extracted,
    required this.missing,
  });

  final int active;
  final int confirmed;
  final int extracted;
  final int missing;
}
