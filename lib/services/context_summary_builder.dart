import '../models/context_entry.dart';
import '../models/context_matrix.dart';
import 'context_missing_basics_detector.dart';

class ContextSummaryBuilder {
  const ContextSummaryBuilder({
    this.maxEntries = 30,
    this.maxCharacters = 3600,
    this.missingBasicsDetector = const ContextMissingBasicsDetector(),
  });

  final int maxEntries;
  final int maxCharacters;
  final ContextMissingBasicsDetector missingBasicsDetector;

  String build(
    ContextMatrix matrix, {
    DateTime? now,
    bool includeMissingBasics = true,
  }) {
    final timestamp = now ?? DateTime.now();
    const endMarker = 'END APP-STORED USER CONTEXT MATRIX';
    final entries =
        matrix
            .activeEntriesAt(timestamp)
            .where((entry) => entry.title.trim().isNotEmpty)
            .where((entry) => entry.value.trim().isNotEmpty)
            .toList()
          ..sort(_compareEntries);

    final missingBasics = includeMissingBasics
        ? missingBasicsDetector.missingBasics(matrix, now: timestamp).take(5)
        : const Iterable<MissingBasicInfo>.empty();

    if (entries.isEmpty && missingBasics.isEmpty) {
      return '';
    }

    final buffer = StringBuffer()
      ..writeln('APP-STORED USER CONTEXT MATRIX')
      ..writeln(
        'This is app-stored user context. It may be incomplete and is separate from the current user message.',
      )
      ..writeln(
        'Use only relevant active context. Do not treat health notes as diagnosis.',
      );

    if (missingBasics.isNotEmpty) {
      buffer
        ..writeln('Missing basics to ask naturally when useful:')
        ..writeln('- ${missingBasics.map((basic) => basic.title).join(', ')}')
        ..writeln(
          'Ask for at most a few missing basics at a time and avoid repeating the same request every turn.',
        );
    }

    var included = 0;
    for (final group in _groupedEntries(entries)) {
      if (included >= maxEntries) {
        break;
      }

      final groupBuffer = StringBuffer()..writeln('${group.label}:');
      for (final entry in group.entries.take(6)) {
        if (included >= maxEntries) {
          break;
        }

        groupBuffer.writeln('- ${entry.title.trim()}: ${entry.value.trim()}');
        included += 1;
      }

      final nextLength =
          buffer.length + groupBuffer.length + endMarker.length + 1;
      if (nextLength > maxCharacters) {
        break;
      }
      buffer.write(groupBuffer);
    }

    buffer.writeln(endMarker);

    final summary = buffer.toString().trim();
    if (summary.length <= maxCharacters) {
      return summary;
    }

    return summary.substring(0, maxCharacters).trimRight();
  }

  List<_ContextSummaryGroup> _groupedEntries(List<ContextEntry> entries) {
    final byNode = <String, List<ContextEntry>>{};
    for (final entry in entries) {
      byNode.putIfAbsent(entry.nodeLabel, () => []).add(entry);
    }

    final groups = [
      for (final MapEntry(:key, :value) in byNode.entries)
        _ContextSummaryGroup(label: key, entries: value),
    ];
    groups.sort((a, b) {
      final aPriority = a.entries.fold<double>(
        0,
        (max, entry) => entry.priority > max ? entry.priority : max,
      );
      final bPriority = b.entries.fold<double>(
        0,
        (max, entry) => entry.priority > max ? entry.priority : max,
      );
      final priorityCompare = bPriority.compareTo(aPriority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return a.label.compareTo(b.label);
    });

    return groups;
  }

  int _compareEntries(ContextEntry a, ContextEntry b) {
    final lifespanCompare = _lifespanRank(b).compareTo(_lifespanRank(a));
    if (lifespanCompare != 0) {
      return lifespanCompare;
    }

    final priorityCompare = b.priority.compareTo(a.priority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }

    if (a.isConfirmed != b.isConfirmed) {
      return a.isConfirmed ? -1 : 1;
    }

    if (a.source != b.source) {
      if (a.source == ContextSource.manual ||
          a.source == ContextSource.userConfirmed) {
        return -1;
      }
      if (b.source == ContextSource.manual ||
          b.source == ContextSource.userConfirmed) {
        return 1;
      }
    }

    return b.updatedAt.compareTo(a.updatedAt);
  }

  int _lifespanRank(ContextEntry entry) {
    return switch (entry.lifespan) {
      ContextLifespan.temporary => 4,
      ContextLifespan.session => 3,
      ContextLifespan.permanent => 2,
      ContextLifespan.longTerm => 1,
    };
  }
}

class _ContextSummaryGroup {
  const _ContextSummaryGroup({required this.label, required this.entries});

  final String label;
  final List<ContextEntry> entries;
}
