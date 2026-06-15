import 'context_entry.dart';

class ContextMatrix {
  const ContextMatrix({required this.entries});

  factory ContextMatrix.empty() {
    return const ContextMatrix(entries: []);
  }

  factory ContextMatrix.fromJson(Map<String, Object?> json) {
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      return ContextMatrix.empty();
    }

    return ContextMatrix(
      entries: [
        for (final rawEntry in rawEntries)
          if (rawEntry is Map)
            ContextEntry.fromJson(Map<String, Object?>.from(rawEntry)),
      ],
    );
  }

  final List<ContextEntry> entries;

  List<ContextEntry> get activeEntries {
    return activeEntriesAt(DateTime.now());
  }

  List<ContextEntry> activeEntriesAt(DateTime now) {
    return entries
        .where((entry) => entry.isActiveAt(now))
        .toList(growable: false);
  }

  Map<String, Object?> toJson() {
    return {
      'entries': [for (final entry in entries) entry.toJson()],
    };
  }

  ContextMatrix copyWith({List<ContextEntry>? entries}) {
    return ContextMatrix(entries: entries ?? this.entries);
  }
}
