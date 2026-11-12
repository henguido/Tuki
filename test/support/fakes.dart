import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuki_little_adventures/app/dependencies.dart';
import 'package:tuki_little_adventures/data/local/drawings_repository.dart';
import 'package:tuki_little_adventures/data/local/preferences.dart';
import 'package:tuki_little_adventures/features/adults/export_service.dart';
import 'package:tuki_little_adventures/features/chapters/audio/audio_engine.dart';
import 'package:tuki_little_adventures/features/chapters/catalog.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';

/// Repositorio en memoria con la misma semántica que el de Drift.
/// Permite retrasar o hacer fallar escrituras.
class MemoryDrawingsRepository implements DrawingsRepository {
  final Map<String, StoredDrawing> rows = {};
  final ValueNotifier<int> _changes = ValueNotifier(0);

  /// Si no es `null`, cada `save` espera a que la prueba lo complete.
  List<Completer<void>>? gates;
  bool failWrites = false;
  bool failReads = false;
  int writeAttempts = 0;
  final List<int> writtenRevisions = [];

  @override
  Listenable get changes => _changes;

  static String _key(String c, String p) => '$c/$p';

  @override
  Future<StoredDrawing?> find(String chapterId, String pageId) async {
    if (failReads) throw DrawingReadException('lectura simulada');
    return rows[_key(chapterId, pageId)];
  }

  @override
  Future<List<StoredDrawing>> all() async {
    final list = rows.values.toList()
      ..sort((a, b) {
        final byDate = b.updatedAt.compareTo(a.updatedAt);
        if (byDate != 0) return byDate;
        final byRev = b.saveRevision.compareTo(a.saveRevision);
        return byRev != 0 ? byRev : a.drawingId.compareTo(b.drawingId);
      });
    return list;
  }

  @override
  Future<StoredDrawing?> latest() async {
    final list = await all();
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<SaveOutcome> save(DrawingSnapshot s) async {
    writeAttempts++;
    final gate = gates == null ? null : (Completer<void>()..let(gates!.add));
    if (gate != null) await gate.future;
    if (failWrites) throw const FileSystemException('disco simulado lleno');
    final key = _key(s.chapterId, s.pageId);
    final existing = rows[key];
    if (existing != null && existing.saveRevision >= s.saveRevision) {
      return SaveOutcome.stale;
    }
    rows[key] = StoredDrawing(
      drawingId: existing?.drawingId ?? s.drawingId,
      chapterId: s.chapterId,
      pageId: s.pageId,
      templateRevision: s.templateRevision,
      documentVersion: kDocumentVersion,
      saveRevision: s.saveRevision,
      document: s.document,
      updatedAt: s.updatedAt,
    );
    writtenRevisions.add(s.saveRevision);
    _changes.value++;
    return SaveOutcome.written;
  }
}

extension<T> on T {
  void let(void Function(T) f) => f(this);
}

class FakeTrack implements AudioTrack {
  FakeTrack(this.engine);
  final FakeAudioEngine engine;
  String? asset;
  bool playing = false;
  bool looping = false;
  double volume = 1;
  int seeks = 0;
  bool disposed = false;
  final StreamController<void> completed = StreamController.broadcast();

  @override
  Future<void> load(String a) async {
    if (engine.missingAssets.contains(a)) throw Exception('no existe $a');
    asset = a;
  }

  @override
  Future<void> setLooping(bool v) async => looping = v;
  @override
  Future<void> setVolume(double v) async => volume = v;
  @override
  Future<void> play() async => playing = true;
  @override
  Future<void> pause() async => playing = false;
  @override
  Future<void> seekToStart() async => seeks++;
  @override
  Stream<void> get onCompleted => completed.stream;
  @override
  Future<void> dispose() async {
    disposed = true;
    playing = false;
  }

  /// Simula el final natural de la pista.
  void finish() {
    playing = false;
    completed.add(null);
  }
}

class FakeAudioEngine implements AudioEngine {
  final List<FakeTrack> tracks = [];
  final Set<String> missingAssets = {};
  final StreamController<void> interruptionsController =
      StreamController.broadcast();
  int activations = 0;

  /// Las pistas se crean en orden: narración y luego ambiente.
  FakeTrack get narration => tracks[tracks.length - 2];
  FakeTrack get ambience => tracks.last;

  @override
  AudioTrack createTrack() {
    final t = FakeTrack(this);
    tracks.add(t);
    return t;
  }

  @override
  Future<bool> activate() async {
    activations++;
    return true;
  }

  @override
  Stream<void> get interruptions => interruptionsController.stream;
}

class FakeExportGateway implements ExportGateway {
  ExportResult next = ExportResult.done;
  final List<(String name, Uint8List png)> saved = [];
  final List<(String name, Uint8List png)> shared = [];
  int calls = 0;

  @override
  Future<ExportResult> save(Uint8List png, String fileName) async {
    calls++;
    if (next == ExportResult.done) saved.add((fileName, png));
    return next;
  }

  @override
  Future<ExportResult> share(Uint8List png, String fileName) async {
    calls++;
    if (next == ExportResult.done) shared.add((fileName, png));
    return next;
  }
}

/// Lector de assets que resuelve en microtareas (apto para testWidgets).
AssetStringLoader preloadedAssets() {
  final cache = <String, String>{};
  return (path) {
    try {
      return Future.value(cache[path] ??= File(path).readAsStringSync());
    } catch (e) {
      return Future.error(e);
    }
  };
}

class TestHarness {
  TestHarness._(this.deps, this.drawings, this.audio, this.gateway);

  final AppDependencies deps;
  final MemoryDrawingsRepository drawings;
  final FakeAudioEngine audio;
  final FakeExportGateway gateway;

  static Future<TestHarness> create({
    String deviceLanguage = 'es',
    Map<String, Object> prefs = const {},
    MemoryDrawingsRepository? drawings,
    bool instantExportRender = false,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final repo = CatalogRepository(preloadedAssets());
    final catalog = await repo.load();
    final memory = drawings ?? MemoryDrawingsRepository();
    final audio = FakeAudioEngine();
    final gateway = FakeExportGateway();
    final deps = AppDependencies(
      catalogRepository: repo,
      catalog: catalog,
      drawings: memory,
      preferences: await AppPreferences.load(
        deviceLocale: Locale(deviceLanguage),
      ),
      audio: audio,
      exportGateway: gateway,
      // El render real necesita reloj real; se prueba aparte.
      exportRenderer: instantExportRender
          ? (_, _) async => Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])
          : null,
    );
    return TestHarness._(deps, memory, audio, gateway);
  }
}
