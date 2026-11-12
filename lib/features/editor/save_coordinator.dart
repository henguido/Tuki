import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/local/drawings_repository.dart';
import 'drawing_document.dart';

enum SaveStatus {
  /// Sin cambios en esta sesión.
  clean,
  saving,
  saved,
  error,
}

/// Serializa las escrituras de una obra: una a la vez, siempre con el
/// snapshot más reciente, y expone el estado de la última revisión.
class SaveCoordinator extends ChangeNotifier {
  SaveCoordinator({
    required DrawingsRepository repository,
    required this.chapterId,
    required this.pageId,
    required this.templateRevision,
    StoredDrawing? existing,
    DateTime Function()? clock,
    String Function()? newId,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now,
       _drawingId = existing?.drawingId ?? (newId ?? _randomId)(),
       _exists = existing != null,
       _revision = existing?.saveRevision ?? 0,
       _savedRevision = existing?.saveRevision ?? 0;

  final DrawingsRepository _repository;
  final DateTime Function() _clock;
  final String chapterId;
  final String pageId;
  final int templateRevision;
  final String _drawingId;

  bool _exists;
  int _revision;
  int _savedRevision;
  DrawingSnapshot? _latest;
  DrawingSnapshot? _pending;
  bool _writing = false;
  bool _failed = false;
  bool _disposed = false;
  Completer<void>? _idle;

  static String _randomId() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// Hay una fila confirmada para esta obra.
  bool get exists => _exists;
  int get revision => _revision;
  int get savedRevision => _savedRevision;

  SaveStatus get status {
    if (_failed) return SaveStatus.error;
    if (_writing || _pending != null || _savedRevision < _revision) {
      return SaveStatus.saving;
    }
    return _latest == null ? SaveStatus.clean : SaveStatus.saved;
  }

  /// Registra una edición confirmada. La fila se crea con el primer cambio.
  void submit(DrawingDocument document) {
    _revision++;
    final snapshot = DrawingSnapshot(
      drawingId: _drawingId,
      chapterId: chapterId,
      pageId: pageId,
      templateRevision: templateRevision,
      saveRevision: _revision,
      document: document,
      updatedAt: _clock().toUtc(),
    );
    _latest = snapshot;
    _pending = snapshot;
    _failed = false;
    _notify();
    unawaited(_pump());
  }

  /// Reintenta con el estado más reciente.
  Future<void> retry() {
    if (_latest != null && _savedRevision < _revision) {
      _pending = _latest;
    }
    _failed = false;
    _notify();
    return _pump();
  }

  /// Espera a que termine el guardado en curso. Devuelve `true` si la última
  /// revisión quedó confirmada (o no había cambios).
  Future<bool> flush() async {
    while (_writing) {
      await (_idle ??= Completer<void>()).future;
    }
    if (_pending != null && !_failed) {
      await _pump();
      return flush();
    }
    return !_failed && _savedRevision == _revision;
  }

  Future<void> _pump() async {
    if (_writing) {
      await (_idle ??= Completer<void>()).future;
      return;
    }
    _writing = true;
    try {
      while (_pending != null) {
        final snapshot = _pending!;
        _pending = null;
        try {
          await _repository.save(snapshot);
          // `stale` también cuenta: ya hay algo igual o más nuevo guardado.
          if (snapshot.saveRevision > _savedRevision) {
            _savedRevision = snapshot.saveRevision;
          }
          _exists = true;
          _failed = false;
        } catch (_) {
          if (_pending == null) {
            _failed = true;
            break;
          }
          // Hay un snapshot más nuevo: se intenta directamente con él.
        }
        _notify();
      }
    } finally {
      _writing = false;
      _notify();
      final idle = _idle;
      _idle = null;
      idle?.complete();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
