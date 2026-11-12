// Recorrido de aceptación sobre la app real (catálogo, SQLite, audio y PNG).
//
//   flutter test integration_test -d <dispositivo>
//
// Usa una base de datos propia (tuki_itest.sqlite) para no tocar las obras
// de la app instalada.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tuki_little_adventures/app/app.dart';
import 'package:tuki_little_adventures/app/dependencies.dart';
import 'package:tuki_little_adventures/features/chapters/pages_screen.dart';
import 'package:tuki_little_adventures/features/editor/drawing_canvas.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';
import 'package:tuki_little_adventures/features/editor/editor_screen.dart';

const chapter = 'bosque-nuboso';
const dbName = 'tuki_itest.sqlite';

Future<void> settle(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(milliseconds: 100));

/// Espera (con reloj real) a que aparezca [finder].
Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> tapScene(WidgetTester tester, Offset scene) async {
  final state = tester.state<DrawingCanvasState>(find.byType(DrawingCanvas));
  final origin = tester.getTopLeft(
    find.byKey(const ValueKey('drawing-canvas')),
  );
  await tester.tapAt(origin + state.viewport!.toLocal(scene));
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recorrido completo: escuchar, colorear, guardar y avanzar', (
    tester,
  ) async {
    final dir = await getApplicationSupportDirectory();
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final f = File(p.join(dir.path, '$dbName$suffix'));
      if (f.existsSync()) f.deleteSync();
    }
    final deps = await AppDependencies.create(databaseName: dbName);
    await deps.preferences.setLanguage('es');
    await deps.preferences.setNarrationEnabled(true);
    await deps.preferences.setAmbienceEnabled(true);
    await tester.pumpWidget(TukiApp(deps: deps));
    await settle(tester);

    // A01: Inicio, galería vacía.
    expect(find.text('TUKI'), findsOneWidget);
    expect(find.text('Continuar mi dibujo'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await settle(tester);
    expect(find.byKey(const ValueKey('gallery-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gallery-explore')));
    await settle(tester);

    // Portada con audio real empaquetado.
    await tester.tap(find.byKey(const ValueKey('explore-$chapter')));
    await settle(tester);
    expect(find.byKey(const ValueKey('cover-intro')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('audio-narration')));
    await waitFor(tester, find.text('Pausar'));
    await tester.tap(find.byKey(const ValueKey('audio-ambience')));
    await waitFor(tester, find.text('Pausar sonidos'));
    expect(find.text('Audio no disponible'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byKey(const ValueKey('cover-color')));
    await settle(tester);

    // Láminas → rana.
    expect(find.byType(PagesScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('page-rana-en-la-hoja')));
    await waitFor(tester, find.byType(DrawingCanvas));
    await tapScene(tester, const Offset(450, 400)); // cuerpo
    await waitFor(tester, find.text('Guardado'));
    await tester.tap(find.byKey(const ValueKey('tool-brush')));
    await settle(tester);
    final origin = tester.getTopLeft(
      find.byKey(const ValueKey('drawing-canvas')),
    );
    final vp = tester
        .state<DrawingCanvasState>(find.byType(DrawingCanvas))
        .viewport!;
    final g = await tester.startGesture(
      origin + vp.toLocal(const Offset(200, 150)),
    );
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(12, 3));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await waitFor(tester, find.text('Guardado'));

    final frog = (await deps.drawings.find(chapter, 'rana-en-la-hoja'))!;
    expect(frog.document.fills, {'cuerpo': 0x7CB342});
    expect(frog.document.ops.single.kind, StrokeKind.brush);
    expect(frog.saveRevision, 2);

    // A07: avanzar hasta la última lámina.
    await tester.tap(find.byKey(const ValueKey('editor-next')));
    await waitFor(tester, find.text('El quetzal'));
    await waitFor(tester, find.byType(DrawingCanvas));
    await tapScene(tester, const Offset(495, 560)); // vientre
    await waitFor(tester, find.text('Guardado'));
    await tester.tap(find.byKey(const ValueKey('editor-next')));
    await waitFor(tester, find.text('El sendero'));
    await waitFor(tester, find.text('Volver a las láminas'));
    await tester.tap(find.byKey(const ValueKey('editor-next')));
    await settle(tester);
    expect(find.byType(PagesScreen), findsOneWidget);
    expect(find.byType(EditorScreen), findsNothing);
    expect((await deps.drawings.all()).map((d) => d.pageId), [
      'quetzal',
      'rana-en-la-hoja',
    ]);

    await tester.pumpWidget(const SizedBox());
    await deps.close();
  });

  testWidgets('tras reabrir la base: continuar, editar y exportar PNG', (
    tester,
  ) async {
    final deps = await AppDependencies.create(databaseName: dbName);
    await tester.pumpWidget(TukiApp(deps: deps));
    await waitFor(tester, find.text('Continuar mi dibujo'));

    // Abre directamente la última obra editada.
    await tester.tap(find.byKey(const ValueKey('continue-drawing')));
    await waitFor(tester, find.byType(DrawingCanvas));
    expect(find.text('El quetzal'), findsOneWidget);
    expect(find.text('Guardado'), findsOneWidget);
    final before = (await deps.drawings.find(chapter, 'quetzal'))!;
    expect(before.document.fills, {'vientre': 0x7CB342});
    await tapScene(tester, const Offset(40, 40)); // fondo
    await tester.pump(const Duration(milliseconds: 500));
    await waitFor(tester, find.text('Guardado'));
    final after = (await deps.drawings.find(chapter, 'quetzal'))!;
    expect(after.saveRevision, before.saveRevision + 1);
    expect(after.document.fills.keys.toSet(), {'vientre', 'fondo'});

    // La rana conserva rellenos y trazos editables.
    final frog = (await deps.drawings.find(chapter, 'rana-en-la-hoja'))!;
    expect(frog.document.ops.single.points.length, greaterThan(3));

    // A09: PNG de la obra guardada.
    final png = await deps.exporter.renderPng(chapter, 'quetzal');
    final codec = await ui.instantiateImageCodec(png);
    final image = (await codec.getNextFrame()).image;
    expect(image.height, 2048);
    expect(image.width, 1707);

    await tester.tap(find.byKey(const ValueKey('editor-back')));
    await settle(tester);
    expect(find.text('Continuar mi dibujo'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await deps.close();
  });
}
