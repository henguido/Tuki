// Recorrido exhaustivo de las 60 láminas en un dispositivo Android real.
//
//   flutter drive --debug -d <id> \
//     --target integration_test/laminas_60_device_test.dart \
//     --driver test_driver/integration_test.dart \
// El target integration_test activa automáticamente el paquete aislado
// dev.tukiapp.tuki_little_adventures.qa.integration. Nunca ejecutar estas
// pruebas contra dev.tukiapp.tuki_little_adventures.qa.
//
// Usa una base de datos exclusiva para QA; no toca las obras de la app normal.
// Por cada lámina comprueba carga/render, relleno, pincel, deshacer, zoom,
// guardado y reapertura, y emite una línea LAMINA_60 con evidencia medible.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tuki_little_adventures/app/app.dart';
import 'package:tuki_little_adventures/app/dependencies.dart';
import 'package:tuki_little_adventures/features/editor/drawing_canvas.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';
import 'package:tuki_little_adventures/features/editor/editor_screen.dart';
import 'package:tuki_little_adventures/features/editor/page_template.dart';

const _chapterId = 'bosque-nuboso';
const _databaseName = 'tuki_laminas_60_device.sqlite';

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 200; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> _waitForGone(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 200; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isEmpty) return;
  }
  expect(finder, findsNothing);
}

Offset _pointInside(PageTemplate template) {
  // Evita depender de archivos de validación del host. Busca un punto real
  // dentro de una figura; si no lo encuentra, usa el fondo de la plantilla.
  for (final region in template.regions.skip(1).toList().reversed) {
    final bounds = region.path.getBounds();
    for (var y = 1; y < 20; y++) {
      for (var x = 1; x < 20; x++) {
        final point = Offset(
          bounds.left + bounds.width * x / 20,
          bounds.top + bounds.height * y / 20,
        );
        if (region.path.contains(point) &&
            template.regionAt(point) == region.id) {
          return point;
        }
      }
    }
  }
  return template.viewBox.center;
}

Future<void> _tapScene(WidgetTester tester, Offset scene) async {
  final state = tester.state<DrawingCanvasState>(find.byType(DrawingCanvas));
  final origin = tester.getTopLeft(
    find.byKey(const ValueKey('drawing-canvas')),
  );
  await tester.tapAt(origin + state.viewport!.toLocal(scene));
  await tester.pump();
}

Future<void> _zoomAndReset(WidgetTester tester) async {
  final canvas = find.byKey(const ValueKey('drawing-canvas'));
  final center = tester.getCenter(canvas);
  final a = await tester.startGesture(center - const Offset(20, 0), pointer: 1);
  final b = await tester.startGesture(center + const Offset(20, 0), pointer: 2);
  await a.moveBy(const Offset(-35, 0));
  await b.moveBy(const Offset(35, 0));
  await tester.pump();
  await a.up();
  await b.up();
  await tester.pump();
  final state = tester.state<DrawingCanvasState>(find.byType(DrawingCanvas));
  expect(state.viewport!.zoom, greaterThan(1), reason: 'zoom físico');
  await tester.tap(find.byKey(const ValueKey('reset-zoom')));
  await tester.pump();
  expect(state.viewport!.zoom, 1);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('las 60 láminas: interacción, persistencia y rendimiento', (
    tester,
  ) async {
    final dir = await getApplicationSupportDirectory();
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File(p.join(dir.path, '$_databaseName$suffix'));
      if (file.existsSync()) file.deleteSync();
    }
    final deps = await AppDependencies.create(databaseName: _databaseName);
    await tester.pumpWidget(TukiApp(deps: deps));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    final chapter = deps.catalog.chapterById(_chapterId)!;
    expect(chapter.pages, hasLength(60));

    for (final page in chapter.pages) {
      final load = Stopwatch()..start();
      navigator.push(
        EditorScreen.route(
          chapterId: _chapterId,
          pageId: page.id,
          origin: EditorOrigin.pages,
        ),
      );
      await _waitFor(tester, find.byType(DrawingCanvas));
      await tester.pump(const Duration(milliseconds: 250));
      final loadMs = load.elapsedMilliseconds;
      expect(tester.takeException(), isNull, reason: '${page.artId}: carga');

      final template = await deps.catalogRepository.loadTemplate(page);
      final point = _pointInside(template);
      final expectedRegion = template.regionAt(point);
      expect(expectedRegion, isNotNull, reason: '${page.artId}: sonda');

      final fill = Stopwatch()..start();
      await tester.tap(find.byKey(const ValueKey('tool-fill')));
      await _tapScene(tester, point);
      await _waitFor(tester, find.text('Guardado'));
      final fillMs = fill.elapsedMilliseconds;

      var legacySeparated = false;
      final formerlyShared = switch (page.artId) {
        'A10' => const (Offset(359.5, 169.5), Offset(47.5, 80.5)),
        'D02' => const (Offset(676, 280), Offset(516, 101)),
        _ => null,
      };
      if (formerlyShared != null) {
        final first = template.regionAt(formerlyShared.$1);
        final second = template.regionAt(formerlyShared.$2);
        expect(first, isNotNull, reason: '${page.artId}: zona histórica A');
        expect(second, isNotNull, reason: '${page.artId}: zona histórica B');
        expect(first, isNot(second), reason: '${page.artId}: zonas separadas');
        await _tapScene(tester, formerlyShared.$1);
        await _tapScene(tester, formerlyShared.$2);
        final separated = await deps.drawings.find(_chapterId, page.id);
        expect(separated!.document.fills.keys, containsAll([first, second]));
        legacySeparated = true;
      }

      await tester.tap(find.byKey(const ValueKey('tool-brush')));
      final viewport = tester
          .state<DrawingCanvasState>(find.byType(DrawingCanvas))
          .viewport!;
      final origin = tester.getTopLeft(
        find.byKey(const ValueKey('drawing-canvas')),
      );
      final start = origin + viewport.paperRect.center - const Offset(18, 0);
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(36, 0));
      await gesture.up();
      await tester.pump();
      var stored = await deps.drawings.find(_chapterId, page.id);
      expect(stored, isNotNull, reason: '${page.artId}: pincel guardado');
      expect(stored!.document.ops.single.kind, StrokeKind.brush);

      await tester.tap(find.byKey(const ValueKey('tool-eraser')));
      final erase = await tester.startGesture(start + const Offset(18, -18));
      await erase.moveBy(const Offset(0, 36));
      await erase.up();
      await tester.pump(const Duration(milliseconds: 250));
      stored = await deps.drawings.find(_chapterId, page.id);
      expect(stored!.document.ops, hasLength(2));
      expect(stored.document.ops.last.kind, StrokeKind.eraser);

      // Deshace y rehace el borrador, luego deja deshechos borrador y pincel.
      await tester.tap(find.byKey(const ValueKey('editor-undo')));
      await tester.pump(const Duration(milliseconds: 100));
      stored = await deps.drawings.find(_chapterId, page.id);
      expect(stored!.document.ops.single.kind, StrokeKind.brush);
      await tester.tap(find.byKey(const ValueKey('editor-redo')));
      await tester.pump(const Duration(milliseconds: 100));
      stored = await deps.drawings.find(_chapterId, page.id);
      expect(stored!.document.ops, hasLength(2));
      expect(stored.document.ops.last.kind, StrokeKind.eraser);
      await tester.tap(find.byKey(const ValueKey('editor-undo')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('editor-undo')));
      await _waitFor(tester, find.text('Guardado'));
      await _zoomAndReset(tester);

      stored = await deps.drawings.find(_chapterId, page.id);
      expect(stored, isNotNull, reason: '${page.artId}: guardado');
      expect(stored!.document.fills.keys, contains(expectedRegion));
      expect(stored.document.ops, isEmpty, reason: '${page.artId}: deshacer');

      await tester.tap(find.byKey(const ValueKey('editor-back')));
      await _waitForGone(tester, find.byType(EditorScreen));
      navigator.push(
        EditorScreen.route(
          chapterId: _chapterId,
          pageId: page.id,
          origin: EditorOrigin.pages,
        ),
      );
      await _waitFor(tester, find.byType(DrawingCanvas));
      stored = await deps.drawings.find(_chapterId, page.id);
      expect(stored!.document.fills.keys, contains(expectedRegion));
      expect(
        find.text('Guardado'),
        findsOneWidget,
        reason: '${page.artId}: reapertura',
      );

      // ignore: avoid_print
      print(
        'LAMINA_60 ${jsonEncode({'artId': page.artId, 'pagina': page.id, 'nivel': page.level.id, 'orientacion': template.viewBox.width > template.viewBox.height ? 'horizontal' : 'vertical', 'regiones': template.regions.length, 'carga_ms': loadMs, 'relleno_guardado_ms': fillMs, 'relleno': 'ok', 'zonas_antes_compartidas': legacySeparated ? 'separadas' : 'no_aplica', 'pincel': 'ok', 'borrador': 'ok', 'deshacer': 'ok', 'rehacer': 'ok', 'zoom': 'ok', 'guardado': 'ok', 'reapertura': 'ok'})}',
      );

      await tester.tap(find.byKey(const ValueKey('editor-back')));
      await _waitForGone(tester, find.byType(EditorScreen));
    }

    expect(await deps.drawings.all(), hasLength(60));
    await tester.pumpWidget(const SizedBox());
    await deps.close();
  });
}
