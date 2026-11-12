import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../features/editor/drawing_document.dart';
import 'database.dart';

/// Obra persistida y ya decodificada.
@immutable
class StoredDrawing {
  const StoredDrawing({
    required this.drawingId,
    required this.chapterId,
    required this.pageId,
    required this.templateRevision,
    required this.documentVersion,
    required this.saveRevision,
    required this.document,
    required this.updatedAt,
  });

  final String drawingId;
  final String chapterId;
  final String pageId;
  final int templateRevision;
  final int documentVersion;
  final int saveRevision;
  final DrawingDocument document;

  /// Siempre en UTC.
  final DateTime updatedAt;
}

/// Snapshot inmutable de una escritura.
@immutable
class DrawingSnapshot {
  const DrawingSnapshot({
    required this.drawingId,
    required this.chapterId,
    required this.pageId,
    required this.templateRevision,
    required this.saveRevision,
    required this.document,
    required this.updatedAt,
  });

  final String drawingId;
  final String chapterId;
  final String pageId;
  final int templateRevision;
  final int saveRevision;
  final DrawingDocument document;
  final DateTime updatedAt;
}

enum SaveOutcome {
  /// La fila se creó o actualizó.
  written,

  /// Ya había una revisión igual o posterior: no se escribió nada.
  stale,
}

/// La fila existe pero no se pudo leer o interpretar.
class DrawingReadException implements Exception {
  DrawingReadException(this.message);
  final String message;
  @override
  String toString() => 'DrawingReadException: $message';
}

abstract class DrawingsRepository {
  /// Se notifica tras cada escritura confirmada.
  Listenable get changes;

  /// Obra de una lámina, o `null` si todavía no existe.
  /// Lanza [DrawingReadException] si existe pero no se puede leer.
  Future<StoredDrawing?> find(String chapterId, String pageId);

  /// Obras ordenadas por última edición (más reciente primero).
  Future<List<StoredDrawing>> all();

  /// Última obra editada, o `null`.
  Future<StoredDrawing?> latest();

  /// Guarda todos los campos en una operación atómica. Una revisión anterior
  /// nunca reemplaza a una posterior.
  Future<SaveOutcome> save(DrawingSnapshot snapshot);
}

class DriftDrawingsRepository implements DrawingsRepository {
  DriftDrawingsRepository(this._db);

  final TukiDatabase _db;
  final ValueNotifier<int> _changes = ValueNotifier(0);

  @override
  Listenable get changes => _changes;

  Future<void> close() => _db.close();

  StoredDrawing _decode(DrawingRow row) {
    if (row.documentVersion != kDocumentVersion) {
      throw DrawingReadException(
        'documentVersion no soportado: ${row.documentVersion}',
      );
    }
    try {
      return StoredDrawing(
        drawingId: row.drawingId,
        chapterId: row.chapterId,
        pageId: row.pageId,
        templateRevision: row.templateRevision,
        documentVersion: row.documentVersion,
        saveRevision: row.saveRevision,
        document: DrawingDocument.decode(
          fillsJson: row.fillsJson,
          strokesJson: row.strokesJson,
        ),
        updatedAt: DateTime.fromMicrosecondsSinceEpoch(
          row.updatedAt,
          isUtc: true,
        ),
      );
    } on FormatException catch (e) {
      throw DrawingReadException(e.message);
    }
  }

  @override
  Future<StoredDrawing?> find(String chapterId, String pageId) async {
    final DrawingRow? row;
    try {
      row =
          await (_db.select(_db.drawings)..where(
                (t) => t.chapterId.equals(chapterId) & t.pageId.equals(pageId),
              ))
              .getSingleOrNull();
    } catch (e) {
      throw DrawingReadException('$e');
    }
    return row == null ? null : _decode(row);
  }

  /// Orden estable: fecha, luego revisión, luego ID.
  SimpleSelectStatement<$DrawingsTable, DrawingRow> _ordered() =>
      _db.select(_db.drawings)..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
        (t) => OrderingTerm.desc(t.saveRevision),
        (t) => OrderingTerm.asc(t.drawingId),
      ]);

  @override
  Future<List<StoredDrawing>> all() async {
    final rows = await _ordered().get();
    final result = <StoredDrawing>[];
    for (final row in rows) {
      try {
        result.add(_decode(row));
      } on DrawingReadException {
        // Una fila ilegible no oculta las demás ni se modifica.
      }
    }
    return result;
  }

  @override
  Future<StoredDrawing?> latest() async {
    final list = await all();
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<SaveOutcome> save(DrawingSnapshot s) async {
    final outcome = await _db.transaction(() async {
      final existing =
          await (_db.select(_db.drawings)..where(
                (t) =>
                    t.chapterId.equals(s.chapterId) & t.pageId.equals(s.pageId),
              ))
              .getSingleOrNull();
      final companion = DrawingsCompanion(
        chapterId: Value(s.chapterId),
        pageId: Value(s.pageId),
        templateRevision: Value(s.templateRevision),
        documentVersion: const Value(kDocumentVersion),
        saveRevision: Value(s.saveRevision),
        fillsJson: Value(s.document.encodeFills()),
        strokesJson: Value(s.document.encodeStrokes()),
        updatedAt: Value(s.updatedAt.toUtc().microsecondsSinceEpoch),
      );
      if (existing == null) {
        await _db
            .into(_db.drawings)
            .insert(companion.copyWith(drawingId: Value(s.drawingId)));
        return SaveOutcome.written;
      }
      if (existing.saveRevision >= s.saveRevision) {
        return SaveOutcome.stale;
      }
      await (_db.update(
        _db.drawings,
      )..where((t) => t.drawingId.equals(existing.drawingId))).write(companion);
      return SaveOutcome.written;
    });
    if (outcome == SaveOutcome.written) _changes.value++;
    return outcome;
  }
}
