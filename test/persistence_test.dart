import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuki_little_adventures/data/local/database.dart';
import 'package:tuki_little_adventures/data/local/drawings_repository.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';
import 'package:tuki_little_adventures/features/editor/save_coordinator.dart';

import 'support/fakes.dart';

const chapter = 'bosque-nuboso';

DrawingDocument doc(int n) => DrawingDocument(
  fills: {'hoja': 0x100000 + n},
  ops: [
    StrokeOp(
      kind: StrokeKind.brush,
      color: 0x1E88E5,
      width: 22,
      points: [Offset(n.toDouble(), 1), const Offset(50, 60)],
    ),
    const StrokeOp(kind: StrokeKind.eraser, width: 48, points: [Offset(5, 5)]),
  ],
);

DrawingSnapshot snap(
  int revision, {
  String page = 'rana-en-la-hoja',
  String id = 'id-rana',
  DateTime? at,
  DrawingDocument? document,
}) => DrawingSnapshot(
  drawingId: id,
  chapterId: chapter,
  pageId: page,
  templateRevision: 1,
  saveRevision: revision,
  document: document ?? doc(revision),
  updatedAt: at ?? DateTime.utc(2026, 11, 11, 12, 0, revision),
);

void main() {
  group('repositorio Drift', () {
    late TukiDatabase db;
    late DriftDrawingsRepository repo;

    setUp(() {
      db = TukiDatabase(NativeDatabase.memory());
      repo = DriftDrawingsRepository(db);
    });
    tearDown(() => db.close());

    test(
      'la galería empieza vacía y la fila nace con el primer guardado',
      () async {
        expect(await repo.all(), isEmpty);
        expect(await repo.latest(), isNull);
        expect(await repo.find(chapter, 'rana-en-la-hoja'), isNull);

        var notified = 0;
        repo.changes.addListener(() => notified++);
        expect(await repo.save(snap(1)), SaveOutcome.written);
        expect(notified, 1);

        final stored = (await repo.find(chapter, 'rana-en-la-hoja'))!;
        expect(stored.drawingId, 'id-rana');
        expect(stored.templateRevision, 1);
        expect(stored.documentVersion, kDocumentVersion);
        expect(stored.saveRevision, 1);
        expect(stored.document, doc(1));
        expect(stored.updatedAt, DateTime.utc(2026, 11, 11, 12, 0, 1));
        expect(stored.updatedAt.isUtc, true);
      },
    );

    test('guarda todos los campos de una vez y una fila por lámina', () async {
      await repo.save(snap(1));
      await repo.save(snap(2));
      final rows = await db.select(db.drawings).get();
      expect(rows.length, 1);
      expect(rows.single.saveRevision, 2);
      expect(rows.single.fillsJson, doc(2).encodeFills());
      expect(rows.single.strokesJson, doc(2).encodeStrokes());
    });

    test('A06: una escritura tardía no pisa la revisión nueva', () async {
      await repo.save(snap(1));
      expect(await repo.save(snap(3)), SaveOutcome.written);
      // Llega tarde la revisión 2 (y un duplicado de la 3).
      expect(await repo.save(snap(2)), SaveOutcome.stale);
      expect(await repo.save(snap(3, document: doc(99))), SaveOutcome.stale);
      final stored = (await repo.find(chapter, 'rana-en-la-hoja'))!;
      expect(stored.saveRevision, 3);
      expect(stored.document, doc(3));
    });

    test('ordena por última edición con desempate estable', () async {
      final same = DateTime.utc(2026, 11, 11, 10);
      await repo.save(snap(1, page: 'sendero', id: 'b', at: same));
      await repo.save(snap(1, page: 'quetzal', id: 'a', at: same));
      await repo.save(snap(4, page: 'rana-en-la-hoja', id: 'c', at: same));
      // Misma fecha: gana la revisión mayor y luego el ID.
      expect((await repo.all()).map((d) => d.pageId), [
        'rana-en-la-hoja',
        'quetzal',
        'sendero',
      ]);
      await repo.save(
        snap(
          2,
          page: 'sendero',
          id: 'b',
          at: same.add(const Duration(seconds: 1)),
        ),
      );
      expect((await repo.latest())!.pageId, 'sendero');
      for (var i = 0; i < 3; i++) {
        expect((await repo.all()).first.pageId, 'sendero');
      }
    });

    test(
      'el esquema tiene clave única por lámina e índice por fecha',
      () async {
        final rows = await db
            .customSelect(
              "SELECT name, sql FROM sqlite_master WHERE tbl_name = 'drawings'",
            )
            .get();
        final sql = rows
            .map((r) => '${r.data['name']} ${r.data['sql']}')
            .join('\n');
        expect(sql, contains('PRIMARY KEY'));
        expect(sql, contains('UNIQUE'));
        expect(sql, contains('drawings_updated_at'));
        // La clave única impide una segunda fila para la misma lámina.
        await repo.save(snap(1));
        await expectLater(
          db
              .into(db.drawings)
              .insert(
                DrawingsCompanion.insert(
                  drawingId: 'otro',
                  chapterId: chapter,
                  pageId: 'rana-en-la-hoja',
                  templateRevision: 1,
                  documentVersion: 1,
                  saveRevision: 1,
                  fillsJson: '{}',
                  strokesJson: '[]',
                  updatedAt: 0,
                ),
              ),
          throwsA(anything),
        );
      },
    );

    test(
      'una fila ilegible lanza error de lectura y no se sobrescribe',
      () async {
        await repo.save(snap(5));
        await (db.update(db.drawings))
            .write(const DrawingsCompanion(strokesJson: Value('{dañado')));
        await expectLater(
          repo.find(chapter, 'rana-en-la-hoja'),
          throwsA(isA<DrawingReadException>()),
        );
        // Una sesión nueva «en blanco» empezaría en la revisión 1: se rechaza.
        expect(
          await repo.save(snap(1, document: DrawingDocument.empty)),
          SaveOutcome.stale,
        );
        final row = await db.select(db.drawings).getSingle();
        expect(row.saveRevision, 5);
        expect(row.fillsJson, doc(5).encodeFills());
        // La galería omite la fila dañada sin fallar.
        expect(await repo.all(), isEmpty);
      },
    );

    test('un documentVersion desconocido no se interpreta', () async {
      await repo.save(snap(1));
      await (db.update(db.drawings))
          .write(const DrawingsCompanion(documentVersion: Value(99)));
      await expectLater(
        repo.find(chapter, 'rana-en-la-hoja'),
        throwsA(isA<DrawingReadException>()),
      );
    });
  });

  test(
    'A05: tras cerrar y reabrir la base se recupera la obra editable',
    () async {
      final dir = Directory.systemTemp.createTempSync('tuki_test_');
      final file = File('${dir.path}/tuki.sqlite');
      addTearDown(() => dir.deleteSync(recursive: true));

      var db = TukiDatabase(NativeDatabase(file));
      var repo = DriftDrawingsRepository(db);
      final session = SaveCoordinator(
        repository: repo,
        chapterId: chapter,
        pageId: 'rana-en-la-hoja',
        templateRevision: 1,
      );
      for (var i = 1; i <= 25; i++) {
        session.submit(doc(i)); // pintar rápido
      }
      expect(await session.flush(), true);
      expect(session.status, SaveStatus.saved);
      await db.close(); // «cierre del proceso»

      db = TukiDatabase(NativeDatabase(file));
      repo = DriftDrawingsRepository(db);
      final latest = (await repo.latest())!;
      expect(latest.pageId, 'rana-en-la-hoja');
      expect(latest.saveRevision, 25);
      expect(latest.document, doc(25));
      expect(latest.document.ops.first.kind, StrokeKind.brush);

      // La sesión reabierta continúa la numeración y sigue editando.
      final resumed = SaveCoordinator(
        repository: repo,
        chapterId: chapter,
        pageId: 'rana-en-la-hoja',
        templateRevision: 1,
        existing: latest,
      );
      expect(resumed.status, SaveStatus.clean);
      expect(resumed.exists, true);
      resumed.submit(doc(26));
      expect(await resumed.flush(), true);
      expect((await repo.latest())!.saveRevision, 26);
      await db.close();
    },
  );

  group('coordinador de guardado', () {
    late MemoryDrawingsRepository repo;
    late SaveCoordinator saver;

    setUp(() {
      repo = MemoryDrawingsRepository();
      saver = SaveCoordinator(
        repository: repo,
        chapterId: chapter,
        pageId: 'quetzal',
        templateRevision: 1,
        newId: () => 'fijo',
        clock: () => DateTime.utc(2026, 11, 11),
      );
    });

    test('no crea fila sin cambios', () async {
      expect(saver.status, SaveStatus.clean);
      expect(saver.exists, false);
      expect(await saver.flush(), true);
      expect(repo.rows, isEmpty);
      expect(repo.writeAttempts, 0);
    });

    test(
      'serializa: una escritura a la vez y siempre el snapshot más reciente',
      () async {
        repo.gates = [];
        saver.submit(doc(1));
        await pumpEventQueue();
        expect(saver.status, SaveStatus.saving);
        expect(repo.gates!.length, 1, reason: 'solo una escritura en curso');
        saver
          ..submit(doc(2))
          ..submit(doc(3))
          ..submit(doc(4));
        await pumpEventQueue();
        expect(repo.gates!.length, 1);

        repo.gates![0].complete();
        await pumpEventQueue();
        expect(
          saver.status,
          SaveStatus.saving,
          reason: 'falta la última revisión',
        );
        expect(repo.gates!.length, 2);
        repo.gates![1].complete();
        expect(await saver.flush(), true);

        expect(repo.writtenRevisions, [
          1,
          4,
        ], reason: 'las intermedias se fusionan');
        expect(saver.status, SaveStatus.saved);
        expect(repo.rows.values.single.document, doc(4));
        expect(repo.rows.values.single.drawingId, 'fijo');
      },
    );

    test('flush espera el guardado de la última acción', () async {
      repo.gates = [];
      saver.submit(doc(1));
      var done = false;
      final flushing = saver.flush().then((ok) => done = ok);
      await pumpEventQueue();
      expect(done, false);
      repo.gates![0].complete();
      await flushing;
      expect(done, true);
    });

    test(
      'A06: con fallo muestra error y Reintentar guarda lo más reciente',
      () async {
        saver.submit(doc(1));
        expect(await saver.flush(), true);

        repo.failWrites = true;
        saver.submit(doc(2));
        expect(await saver.flush(), false);
        expect(saver.status, SaveStatus.error);
        saver.submit(doc(3)); // se sigue pintando con el error visible
        expect(await saver.flush(), false);
        expect(saver.status, SaveStatus.error);
        // La obra guardada sigue siendo la última confirmada.
        expect(repo.rows.values.single.document, doc(1));

        repo.failWrites = false;
        await saver.retry();
        expect(saver.status, SaveStatus.saved);
        expect(await saver.flush(), true);
        expect(repo.rows.values.single.saveRevision, 3);
        expect(repo.rows.values.single.document, doc(3));
        expect(repo.writtenRevisions, [1, 3]);
      },
    );

    test('un fallo intermedio no bloquea el snapshot más nuevo', () async {
      repo
        ..gates = []
        ..failWrites = true;
      saver.submit(doc(1));
      await pumpEventQueue();
      saver.submit(doc(2));
      repo.failWrites = false;
      // La revisión 1 falla tarde; ya hay una más nueva en cola.
      repo.gates![0].completeError(const FileSystemException('fallo'));
      await pumpEventQueue();
      repo.gates![1].complete();
      expect(await saver.flush(), true);
      expect(saver.status, SaveStatus.saved);
      expect(repo.rows.values.single.document, doc(2));
    });

    test('las fechas se guardan en UTC', () async {
      final local = SaveCoordinator(
        repository: repo,
        chapterId: chapter,
        pageId: 'sendero',
        templateRevision: 1,
        clock: () => DateTime(2026, 11, 11, 8),
      );
      local.submit(doc(1));
      await local.flush();
      expect(repo.rows['$chapter/sendero']!.updatedAt.isUtc, true);
    });
  });
}
