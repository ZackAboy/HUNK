import '../models/context_entry.dart';
import '../models/context_matrix.dart';

class ContextSummaryBuilder {
  const ContextSummaryBuilder({
    this.maxEntries = 28,
    this.maxCharacters = 3200,
  });

  final int maxEntries;
  final int maxCharacters;

  String build(ContextMatrix matrix) {
    const endMarker = 'END APP-STORED USER CONTEXT MATRIX';
    final entries =
        matrix.activeEntries
            .where((entry) => entry.title.trim().isNotEmpty)
            .where((entry) => entry.value.trim().isNotEmpty)
            .toList()
          ..sort(_compareEntries);

    if (entries.isEmpty) {
      return '';
    }

    final buffer = StringBuffer()
      ..writeln('APP-STORED USER CONTEXT MATRIX')
      ..writeln(
        'Use this as user-provided/app-stored context. It may be incomplete. Do not treat it as medical diagnosis.',
      )
      ..writeln(
        'Only use this context when relevant to the current coaching question.',
      );

    var included = 0;
    for (final section in ContextSection.values) {
      final sectionEntries = entries
          .where((entry) => entry.section == section)
          .take(5)
          .toList(growable: false);

      if (sectionEntries.isEmpty) {
        continue;
      }

      final sectionBuffer = StringBuffer()..writeln('${section.label}:');
      for (final entry in sectionEntries) {
        if (included >= maxEntries) {
          break;
        }

        final confidence = entry.confidence == null
            ? ''
            : ', confidence ${entry.confidence!.toStringAsFixed(2)}';
        final confirmed = entry.isPinned ? ', confirmed' : '';
        sectionBuffer.writeln(
          '- ${entry.title.trim()}: ${entry.value.trim()} (${entry.source.label}$confidence$confirmed)',
        );
        included += 1;
      }

      final nextLength =
          buffer.length + sectionBuffer.length + endMarker.length;
      if (nextLength > maxCharacters) {
        break;
      }
      buffer.write(sectionBuffer);
    }

    buffer.writeln(endMarker);

    final summary = buffer.toString().trim();
    if (summary.length <= maxCharacters) {
      return summary;
    }

    return summary.substring(0, maxCharacters).trimRight();
  }

  int _compareEntries(ContextEntry a, ContextEntry b) {
    final sectionCompare = a.section.index.compareTo(b.section.index);
    if (sectionCompare != 0) {
      return sectionCompare;
    }

    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }

    if (a.source != b.source) {
      if (a.source == ContextSource.manual) {
        return -1;
      }
      if (b.source == ContextSource.manual) {
        return 1;
      }
    }

    return b.updatedAt.compareTo(a.updatedAt);
  }
}
