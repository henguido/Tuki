// Las 60 láminas dentro de la app: lista, filtros, miniaturas, orientación,
// pintado desde la interfaz y compatibilidad con obras anteriores.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuki_little_adventures/data/local/drawings_repository.dart';
import 'package:tuki_little_adventures/features/editor/drawing_canvas.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';

import 'app_flow_test.dart' show chapter, loadFonts, pumpApp, tapScene;
import 'support/fakes.dart';

Future<TestHarness> realHarness({
  Map<String, Object> prefs = const {},
  MemoryDrawingsRepository? drawings,
}) => TestHarness.create(
  prefs: prefs,
  drawings: drawings,
  assets: preloadedAssets(realCatalog: true),
);

/// Lista vertical de tarjetas (la barra de filtros es otro desplazable).
final Finder pagesList = find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> openPages(WidgetTester tester) async {
  for (final key in ['explore-$chapter', 'cover-color']) {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }
}

Future<void> openPage(WidgetTester tester, String level, String page) async {
  await openPages(tester);
  await tester.ensureVisible(find.byKey(ValueKey('filter-$level')));
  await tester.tap(find.byKey(ValueKey('filter-$level')));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(ValueKey('page-$page')),
    300,
    scrollable: pagesList,
  );
  await tester.ensureVisible(find.byKey(ValueKey('page-$page')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('page-$page')));
  await tester.pumpAndSettle();
}

/// Centro de la región más grande de la lámina [artId], en coordenadas de
/// la plantilla.
(String, Offset) firstProbe(String artId) {
  final m = jsonDecode(
    File('tool/laminas/validacion/$artId.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final s = (m['sondas'] as List).first as Map<String, dynamic>;
  final p = (s['puntos'] as List).first as List<dynamic>;
  return (
    s['id'] as String,
    Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
  );
}

void main() {
  setUpAll(loadFonts);

  testWidgets('cada nivel ofrece sus 15 láminas, con miniatura', (
    tester,
  ) async {
    final h = await realHarness();
    await pumpApp(tester, h);
    final forest = h.deps.catalog.chapterById(chapter)!;
    expect(forest.pages.length, 60);
    expect(forest.plannedPages, isEmpty);

    await openPages(tester);
    for (final level in ['easy', 'medium', 'detailed', 'advanced']) {
      // Los filtros se desplazan con la lista: se vuelve arriba para verlos.
      await tester.drag(pagesList, const Offset(0, 9000));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ValueKey('filter-$level')));
      await tester.tap(find.byKey(ValueKey('filter-$level')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('filter-empty')), findsNothing);
      final pages = forest.pages.where((p) => p.level.id == level).toList();
      expect(pages.length, 15, reason: level);
      // La lista es perezosa: se recorre hasta la última tarjeta del nivel.
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('page-${pages.last.id}')),
        400,
        scrollable: pagesList,
      );
      expect(find.byKey(ValueKey('page-${pages.last.id}')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('page-${pages.last.id}')),
          matching: find.byType(Image),
        ),
        findsOneWidget,
        reason: 'miniatura PNG, sin cargar la plantilla',
      );
      expect(tester.takeException(), isNull, reason: level);
    }
    expect(h.drawings.rows, isEmpty);
  });

  for (final (size, name) in [
    (const Size(390, 844), 'teléfono vertical'),
    (const Size(320, 568), 'teléfono pequeño'),
    (const Size(844, 390), 'teléfono horizontal'),
    (const Size(1280, 800), 'tableta horizontal'),
  ]) {
    testWidgets('lámina horizontal D08 en $name: sin deformar ni desbordar', (
      tester,
    ) async {
      final h = await realHarness();
      await pumpApp(tester, h, size: size);
      await openPage(tester, 'detailed', 'd08-mono');
      expect(tester.takeException(), isNull);

      final vp = tester
          .state<DrawingCanvasState>(find.byType(DrawingCanvas))
          .viewport!;
      final paper = vp.paperRect;
      expect(vp.viewBox.width > vp.viewBox.height, true);
      expect(
        paper.width / paper.height,
        closeTo(vp.viewBox.width / vp.viewBox.height, 1e-6),
      );
      expect(paper.left >= 0 && paper.right <= vp.size.width + 0.01, true);
      expect(paper.top >= 0 && paper.bottom <= vp.size.height + 0.01, true);
      expect(paper.width, greaterThan(150), reason: 'lienzo útil');

      // Un toque en el centro de una región la rellena y se guarda.
      final (region, point) = firstProbe('D08');
      await tapScene(tester, point);
      expect(h.drawings.rows['$chapter/d08-mono']!.document.fills.keys, [
        region,
      ]);
      expect(find.text('Guardado'), findsOneWidget);
    });
  }

  testWidgets('pintar, deshacer, salir y retomar una lámina avanzada', (
    tester,
  ) async {
    final h = await realHarness();
    await pumpApp(tester, h);
    await openPage(tester, 'advanced', 'a10-helechos');
    expect(find.text('Los helechos'), findsOneWidget);
    // Avanzado abre con la paleta completa.
    expect(find.byKey(const ValueKey('palette-more')), findsNothing);

    final (region, point) = firstProbe('A10');
    await tapScene(tester, point);
    StoredDrawing row() => h.drawings.rows['$chapter/a10-helechos']!;
    expect(row().document.fills.keys, [region]);
    expect(row().templateRevision, 1);

    await tester.tap(find.byKey(const ValueKey('editor-undo')));
    await tester.pumpAndSettle();
    expect(row().document.fills, isEmpty);
    await tapScene(tester, point);
    expect(row().document.fills.keys, [region]);

    await tester.tap(find.byKey(const ValueKey('editor-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-a10-helechos')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('page-a10-helechos')));
    await tester.pumpAndSettle();
    expect(find.byType(DrawingCanvas), findsOneWidget);
    expect(find.text('Guardado'), findsOneWidget);
    expect(row().document.fills.keys, [region]);
  });

  testWidgets(
    'una obra guardada con la rana anterior se abre con su plantilla',
    (tester) async {
      // Fila escrita por la versión que tenía la rana dibujada a mano (v1).
      final repo = MemoryDrawingsRepository();
      await repo.save(
        DrawingSnapshot(
          drawingId: 'd1',
          chapterId: chapter,
          pageId: 'rana-en-la-hoja',
          templateRevision: 1,
          saveRevision: 4,
          document: const DrawingDocument(fills: {'cuerpo': 0x7CB342}),
          updatedAt: DateTime.utc(2026, 11, 12),
        ),
      );
      final h = await realHarness(drawings: repo);
      await pumpApp(tester, h);
      await tester.tap(find.byKey(const ValueKey('continue-drawing')));
      await tester.pumpAndSettle();
      expect(find.byType(DrawingCanvas), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Sigue editándose sobre la plantilla 1: la obra no se pierde ni se mezcla
      // con las regiones de la ilustración nueva.
      await tapScene(tester, const Offset(5, 5)); // fondo de la v1
      final row = repo.rows['$chapter/rana-en-la-hoja']!;
      expect(row.templateRevision, 1);
      expect(row.document.fills.keys.toSet(), {'cuerpo', 'fondo'});
    },
  );

  testWidgets('la rana nueva (E01) es fácil: paleta corta y toque tolerante', (
    tester,
  ) async {
    final h = await realHarness();
    await pumpApp(tester, h);
    await openPage(tester, 'easy', 'rana-en-la-hoja');
    expect(find.byKey(const ValueKey('palette-more')), findsOneWidget);
    final (region, point) = firstProbe('E01');
    await tapScene(tester, point);
    final row = h.drawings.rows['$chapter/rana-en-la-hoja']!;
    expect(row.templateRevision, 2);
    expect(row.document.fills.keys, [region]);
  });
}
