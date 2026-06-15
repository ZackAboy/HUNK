import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/context_entry.dart';
import '../models/context_matrix.dart';

abstract class ContextRepository {
  Future<ContextMatrix> loadMatrix();

  Future<void> saveMatrix(ContextMatrix matrix);

  Future<ContextEntry> saveEntry(ContextEntry entry);

  Future<void> archiveEntry(String entryId);

  Future<void> removeEntry(String entryId);
}

class SecureContextRepository implements ContextRepository {
  SecureContextRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? FlutterSecureStorage();

  static const _contextMatrixKey = 'context.matrix.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<ContextMatrix> loadMatrix() async {
    final raw = await _storage.read(key: _contextMatrixKey);
    if (raw == null || raw.isEmpty) {
      return ContextMatrix.empty();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return ContextMatrix.empty();
      }

      return ContextMatrix.fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      return ContextMatrix.empty();
    }
  }

  @override
  Future<void> saveMatrix(ContextMatrix matrix) {
    return _storage.write(
      key: _contextMatrixKey,
      value: jsonEncode(matrix.toJson()),
    );
  }

  @override
  Future<ContextEntry> saveEntry(ContextEntry entry) async {
    final matrix = await loadMatrix();
    final entries = [...matrix.entries];
    final existingIndex = entries.indexWhere((item) => item.id == entry.id);

    if (existingIndex == -1) {
      entries.add(entry);
    } else {
      entries[existingIndex] = entry;
    }

    await saveMatrix(ContextMatrix(entries: entries));
    return entry;
  }

  @override
  Future<void> archiveEntry(String entryId) async {
    final matrix = await loadMatrix();
    final now = DateTime.now();
    final entries = [
      for (final entry in matrix.entries)
        if (entry.id == entryId)
          entry.copyWith(status: ContextStatus.archived, updatedAt: now)
        else
          entry,
    ];

    await saveMatrix(ContextMatrix(entries: entries));
  }

  @override
  Future<void> removeEntry(String entryId) async {
    final matrix = await loadMatrix();
    final now = DateTime.now();
    await saveMatrix(
      ContextMatrix(
        entries: [
          for (final entry in matrix.entries)
            if (entry.id == entryId)
              entry.copyWith(status: ContextStatus.deleted, updatedAt: now)
            else
              entry,
        ],
      ),
    );
  }
}
