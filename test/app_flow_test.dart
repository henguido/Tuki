import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuki_little_adventures/app/app.dart';
import 'package:tuki_little_adventures/app/theme.dart';
import 'package:tuki_little_adventures/data/local/drawings_repository.dart';
import 'package:tuki_little_adventures/features/adults/export_service.dart';
import 'package:tuki_little_adventures/features/chapters/pages_screen.dart';
import 'package:tuki_little_adventures/features/editor/drawing_canvas.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';
import 'package:tuki_little_adventures/features/editor/editor_screen.dart';
import 'package:tuki_little_adventures/features/editor/page_template.dart';

import 'editor_engine_test.dart' show pointIn;
import 'support/assets.dart';
import 'support/fakes.dart';

const chapter = 'bosque-nuboso';
const leafGreen = 0x7CB342; // color activo inicial
const phone = Size(390, 844);

Future<void> loadFonts() async {
  final loader = FontLoader('Fredoka')
    ..addFont(
      File('assets/fonts/Fredoka-Variable.ttf')
          .readAsBytes()
          .then((b) => ByteData.view(b.buffer)),
    );
  await loader.load();
}

Future<void> pumpApp(
  WidgetTester tester,
  TestHarness h, {
  Size size = phone,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(TukiApp(deps: h.deps));
  await tester.pumpAndSettle();
}

/// Toca el lienzo en un punto de la lámina, con la transformación vigente.
Future<void> tapScene(WidgetTester tester, Offset scene) async {
  final state = tester.state<DrawingCanvasState>(find.byType(DrawingCanvas));
  final origin = tester.getTopLeft(
    find.byKey(const ValueKey('drawing-canvas')),
  );
  await tester.tapAt(origin + state.viewport!.toLocal(scene));
  await tester.pumpAndSettle();
}

/// Botón Volver de la pantalla visible.
Future<void> goBack(WidgetTester tester) =>
    tester.tap(find.byIcon(Icons.arrow_back_rounded).hitTestable().last);

StoredDrawing? row(TestHarness h, String page) =>
    h.drawings.rows['$chapter/$page'];

Future<void> openFrogFromHome(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('explore-$chapter')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('cover-color')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('page-rana-en-la-hoja')));
  await tester.pumpAndSettle();
}

void main() {
  late PageTemplate frog;

  setUpAll(() async {
    await loadFonts();
    frog = loadTemplateFile('rana-en-la-hoja-v1.json');
  });

  testWidgets('A01: primera apertura sin datos ni red', (tester) async {
    final h = await TestHarness.create();
    await pumpApp(tester, h);

    // Inicio de TUKI.
    expect(find.bySemanticsLabel(kBrandName), findsOneWidget);
    expect(find.text('TUKI'), findsOneWidget);
    expect(find.text('Little Adventures'), findsOneWidget);
    expect(find.text('El bosque nuboso'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Continuar mi dibujo'), findsNothing);

    // Galería vacía con acceso a los capítulos.
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gallery-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gallery-explore')));
    await tester.pumpAndSettle();
    expect(find.text('Explorar'), findsOneWidget);

    // Portada: texto y dos controles de audio independientes.
    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'En este bosque, las nubes pasan entre los árboles. '
        '¿Ves la rana entre las hojas?',
      ),
      findsOneWidget,
    );
    expect(h.audio.narration.playing, false);
    expect(h.audio.ambience.playing, false);
    await tester.tap(find.text('Escuchar'));
    await tester.pumpAndSettle();
    expect(h.audio.narration.playing, true);
    expect(h.audio.narration.asset, endsWith('audio/intro_es.mp3'));
    expect(find.text('Pausar'), findsOneWidget);
    await tester.tap(find.text('Sonidos'));
    await tester.pumpAndSettle();
    expect(h.audio.ambience.playing, true);
    expect(find.text('Pausar sonidos'), findsOneWidget);

    // Colorear detiene el audio y muestra las tres láminas.
    await tester.tap(find.text('Colorear'));
    await tester.pumpAndSettle();
    expect(h.audio.narration.playing, false);
    expect(h.audio.ambience.playing, false);
    expect(find.text('Elige una lámina'), findsOneWidget);
    for (final t in ['La rana en la hoja', 'El quetzal', 'El sendero']) {
      expect(find.text(t), findsOneWidget);
    }
    for (final d in ['Fácil', 'Media', 'Detallada']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(h.drawings.rows, isEmpty, reason: 'visitar no crea obras');
  });

  testWidgets('recorrido de la rana: pintar, guardar, volver y retomar', (
    tester,
  ) async {
    final h = await TestHarness.create();
    await pumpApp(tester, h);
    await openFrogFromHome(tester);

    expect(find.text('La rana en la hoja'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-status')), findsNothing);
    // Deshacer deshabilitado con la pila vacía.
    expect(
      tester.getSemantics(find.byKey(const ValueKey('editor-undo'))),
      isSemantics(isButton: true, isEnabled: false, hasEnabledState: true),
    );
    await tester.tap(find.byKey(const ValueKey('editor-undo')));
    await tester.pumpAndSettle();
    expect(h.drawings.rows, isEmpty);

    // Relleno por toque: solo cambia la región tocada.
    await tapScene(tester, pointIn(frog, 'cuerpo'));
    expect(find.text('Guardado'), findsOneWidget);
    expect(row(h, 'rana-en-la-hoja')!.document.fills, {'cuerpo': leafGreen});

    // Pincel: un arrastre es una sola acción.
    await tester.tap(find.byKey(const ValueKey('tool-brush')));
    await tester.pumpAndSettle();
    final origin = tester.getTopLeft(
      find.byKey(const ValueKey('drawing-canvas')),
    );
    final vp = tester
        .state<DrawingCanvasState>(find.byType(DrawingCanvas))
        .viewport!;
    final start = origin + vp.toLocal(const Offset(300, 300));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(40, 20));
    await gesture.moveBy(const Offset(40, 20));
    await gesture.up();
    await tester.pumpAndSettle();
    var doc = row(h, 'rana-en-la-hoja')!.document;
    expect(doc.ops.single.kind, StrokeKind.brush);
    expect(
      (doc.ops.single.points.first - const Offset(300, 300)).distance,
      lessThan(1),
    );
    expect(row(h, 'rana-en-la-hoja')!.saveRevision, 2);

    // Deshacer persiste el estado anterior.
    await tester.tap(find.byKey(const ValueKey('editor-undo')));
    await tester.pumpAndSettle();
    doc = row(h, 'rana-en-la-hoja')!.document;
    expect(doc.ops, isEmpty);
    expect(doc.fills, {'cuerpo': leafGreen});
    expect(row(h, 'rana-en-la-hoja')!.saveRevision, 3);

    // Volver → Láminas → Portada → Inicio, que ahora ofrece continuar.
    await tester.tap(find.byKey(const ValueKey('editor-back')));
    await tester.pumpAndSettle();
    expect(find.text('Elige una lámina'), findsOneWidget);
    await goBack(tester);
    await tester.pumpAndSettle();
    await goBack(tester);
    await tester.pumpAndSettle();
    expect(find.text('Continuar mi dibujo'), findsOneWidget);

    // Continuar abre directamente la última obra, editable.
    await tester.tap(find.byKey(const ValueKey('continue-drawing')));
    await tester.pumpAndSettle();
    expect(find.byType(EditorScreen), findsOneWidget);
    expect(find.text('Guardado'), findsOneWidget);
    await tapScene(tester, pointIn(frog, 'hoja'));
    expect(row(h, 'rana-en-la-hoja')!.document.fills, {
      'cuerpo': leafGreen,
      'hoja': leafGreen,
    });
    expect(row(h, 'rana-en-la-hoja')!.saveRevision, 4);

    // El botón de regreso del sistema respeta el guardado y el origen.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(EditorScreen), findsNothing);
    expect(find.text('Continuar mi dibujo'), findsOneWidget);

    // La galería muestra la obra y la reabre.
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('gallery-rana-en-la-hoja')),
      findsOneWidget,
    );
    await tester.tap(find.text('Seguir coloreando'));
    await tester.pumpAndSettle();
    expect(find.byType(EditorScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-back')));
    await tester.pumpAndSettle();
    expect(
      find.text('Seguir coloreando'),
      findsOneWidget,
      reason: 'vuelve a la galería',
    );
  });

  testWidgets('A07: rana → quetzal → sendero y regreso desde cada origen', (
    tester,
  ) async {
    final h = await TestHarness.create();
    await pumpApp(tester, h);

    Future<void> walkToLast() async {
      expect(find.text('La rana en la hoja'), findsOneWidget);
      await tapScene(tester, const Offset(10, 10)); // fondo
      await tester.tap(find.text('Siguiente lámina'));
      await tester.pumpAndSettle();
      expect(find.text('El quetzal'), findsOneWidget);
      await tester.tap(find.text('Siguiente lámina'));
      await tester.pumpAndSettle();
      expect(find.text('El sendero'), findsOneWidget);
      expect(find.text('Siguiente lámina'), findsNothing);
      expect(find.text('Volver a las láminas'), findsOneWidget);
    }

    // Origen: Láminas.
    await openFrogFromHome(tester);
    await walkToLast();
    expect(row(h, 'rana-en-la-hoja'), isNotNull, reason: 'avanzar guarda');
    expect(row(h, 'quetzal'), isNull, reason: 'pasar de largo no crea obra');
    // Volver desde una lámina intermedia regresa al origen (Láminas).
    await tester.tap(find.byKey(const ValueKey('editor-back')));
    await tester.pumpAndSettle();
    expect(find.byType(PagesScreen), findsOneWidget);
    expect(find.byType(EditorScreen), findsNothing);

    await tester.tap(find.byKey(const ValueKey('page-sendero')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver a las láminas'));
    await tester.pumpAndSettle();
    expect(find.byType(PagesScreen), findsOneWidget);
    await goBack(tester);
    await tester.pumpAndSettle();
    await goBack(tester);
    await tester.pumpAndSettle();

    // Origen: Inicio (Continuar mi dibujo).
    await tester.tap(find.byKey(const ValueKey('continue-drawing')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente lámina'));
    await tester.pumpAndSettle();
    expect(find.text('El quetzal'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-back')));
    await tester.pumpAndSettle();
    expect(
      find.text('Continuar mi dibujo'),
      findsOneWidget,
      reason: 'vuelve a Inicio',
    );

    await tester.tap(find.byKey(const ValueKey('continue-drawing')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente lámina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente lámina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver a las láminas'));
    await tester.pumpAndSettle();
    expect(find.byType(PagesScreen), findsOneWidget);
    await goBack(tester);
    await tester.pumpAndSettle();
    expect(find.text('Continuar mi dibujo'), findsOneWidget);

    // Origen: Mis dibujos.
    await tester.tap(find.byKey(const ValueKey('tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gallery-rana-en-la-hoja')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente lámina'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.text('Seguir coloreando'),
      findsOneWidget,
      reason: 'vuelve a la galería',
    );
  });

  testWidgets('A06: error de escritura ofrece Reintentar y conserva la obra', (
    tester,
  ) async {
    final h = await TestHarness.create();
    await pumpApp(tester, h);
    await openFrogFromHome(tester);

    h.drawings.failWrites = true;
    await tapScene(tester, pointIn(frog, 'cuerpo'));
    expect(find.text('Error al guardar'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-retry')), findsOneWidget);
    expect(h.drawings.rows, isEmpty);

    // Intentar salir no pierde la obra: se queda en el editor.
    await tester.tap(find.byKey(const ValueKey('editor-back')));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos guardar'), findsOneWidget);
    await tester.tap(find.text('Seguir pintando'));
    await tester.pumpAndSettle();
    expect(find.byType(EditorScreen), findsOneWidget);

    // Se sigue pintando; al reintentar se guarda la edición más reciente.
    await tapScene(tester, pointIn(frog, 'hoja'));
    h.drawings.failWrites = false;
    await tester.tap(find.byKey(const ValueKey('save-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Guardado'), findsOneWidget);
    expect(row(h, 'rana-en-la-hoja')!.document.fills, {
      'cuerpo': leafGreen,
      'hoja': leafGreen,
    });
    expect(row(h, 'rana-en-la-hoja')!.saveRevision, 2);

    // Reintentar desde el diálogo de salida también guarda y navega.
    h.drawings.failWrites = true;
    await tapScene(tester, pointIn(frog, 'ojo'));
    await tester.tap(find.text('Siguiente lámina'));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos guardar'), findsOneWidget);
    h.drawings.failWrites = false;
    await tester.tap(find.byKey(const ValueKey('dialog-retry')));
    await tester.pumpAndSettle();
    expect(find.text('El quetzal'), findsOneWidget);
    expect(row(h, 'rana-en-la-hoja')!.document.fills.keys, contains('ojo'));
  });

  testWidgets('un error de lectura no abre un lienzo en blanco', (
    tester,
  ) async {
    final h = await TestHarness.create();
    await h.drawings.save(
      DrawingSnapshot(
        drawingId: 'x',
        chapterId: chapter,
        pageId: 'rana-en-la-hoja',
        templateRevision: 1,
        saveRevision: 7,
        document: const DrawingDocument(fills: {'hoja': 0xE53935}),
        updatedAt: DateTime.utc(2026),
      ),
    );
    await pumpApp(tester, h);
    h.drawings.failReads = true;
    await openFrogFromHome(tester);
    expect(find.text('No pudimos abrir este dibujo'), findsOneWidget);
    expect(find.byType(DrawingCanvas), findsNothing);
    expect(row(h, 'rana-en-la-hoja')!.saveRevision, 7);

    h.drawings.failReads = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byType(DrawingCanvas), findsOneWidget);
    expect(find.text('Guardado'), findsOneWidget);
  });

  testWidgets(
    'si falta la revisión de plantilla ofrece volver y preserva la obra',
    (tester) async {
      final h = await TestHarness.create();
      await h.drawings.save(
        DrawingSnapshot(
          drawingId: 'x',
          chapterId: chapter,
          pageId: 'rana-en-la-hoja',
          templateRevision: 9,
          saveRevision: 2,
          document: const DrawingDocument(fills: {'region-antigua': 0xE53935}),
          updatedAt: DateTime.utc(2026),
        ),
      );
      await pumpApp(tester, h);
      await tester.tap(find.byKey(const ValueKey('continue-drawing')));
      await tester.pumpAndSettle();
      expect(find.textContaining('cambió de versión'), findsOneWidget);
      expect(find.byType(DrawingCanvas), findsNothing);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.byType(EditorScreen), findsNothing);
      final kept = row(h, 'rana-en-la-hoja')!;
      expect(kept.templateRevision, 9);
      expect(kept.document.fills, {'region-antigua': 0xE53935});
    },
  );

  testWidgets('A08: el idioma cambia interfaz, contenido y pista, y persiste', (
    tester,
  ) async {
    final h = await TestHarness.create(deviceLanguage: 'fr');
    await pumpApp(tester, h);
    expect(
      find.text('Explorar'),
      findsOneWidget,
      reason: 'otros idiomas → español',
    );

    await tester.tap(find.byKey(const ValueKey('settings')));
    await tester.pumpAndSettle();
    expect(find.text('Para adultos'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-en')));
    await tester.pumpAndSettle();
    // Misma pantalla, ya traducida: no se pierde la navegación.
    expect(find.text('For grown-ups'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('language'), 'en');

    await goBack(tester);
    await tester.pumpAndSettle();
    expect(find.text('TUKI'), findsOneWidget);
    expect(find.text('Little Adventures'), findsOneWidget);
    expect(find.text('The Cloud Forest'), findsOneWidget);
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Can you spot the frog'), findsOneWidget);
    await tester.tap(find.text('Listen'));
    await tester.pumpAndSettle();
    expect(h.audio.narration.asset, endsWith('audio/intro_en.mp3'));
    expect(h.audio.narration.playing, true);
    await tester.tap(find.text('Sounds'));
    await tester.pumpAndSettle();
    expect(h.audio.ambience.volume, lessThan(0.5), reason: 'baja con la voz');

    // Segundo plano: se detienen ambas pistas.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(h.audio.narration.playing, false);
    expect(h.audio.ambience.playing, false);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(h.audio.narration.playing, false, reason: 'solo reanuda el usuario');
    expect(find.text('Listen'), findsOneWidget);

    // Salir de la portada libera el audio.
    await goBack(tester);
    await tester.pumpAndSettle();
    expect(h.audio.narration.disposed, true);
  });

  testWidgets('cambiar de idioma con el editor abierto conserva la obra', (
    tester,
  ) async {
    final h = await TestHarness.create();
    await pumpApp(tester, h);
    await openFrogFromHome(tester);
    await tapScene(tester, pointIn(frog, 'cuerpo'));
    await h.deps.preferences.setLanguage('en');
    await tester.pumpAndSettle();
    expect(find.byType(EditorScreen), findsOneWidget);
    expect(find.text('The Frog on the Leaf'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Next page'), findsOneWidget);
    // Deshacer sigue disponible: la sesión no se reinició.
    await tester.tap(find.byKey(const ValueKey('editor-undo')));
    await tester.pumpAndSettle();
    expect(row(h, 'rana-en-la-hoja')!.document.fills, isEmpty);
  });

  testWidgets('con el sonido desactivado la portada sigue disponible', (
    tester,
  ) async {
    final h = await TestHarness.create(prefs: {'narrationEnabled': false});
    h.audio.missingAssets.add('assets/chapters/bosque-nuboso/audio/bosque.mp3');
    await pumpApp(tester, h);
    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('audio-narration')));
    await tester.pumpAndSettle();
    expect(h.audio.narration.playing, false);
    // Falta la pista de ambiente: se indica y el resto funciona.
    await tester.tap(find.byKey(const ValueKey('audio-ambience')));
    await tester.pumpAndSettle();
    expect(find.text('Audio no disponible'), findsOneWidget);
    expect(find.byKey(const ValueKey('cover-intro')), findsOneWidget);
    await tester.tap(find.text('Colorear'));
    await tester.pumpAndSettle();
    expect(find.text('Elige una lámina'), findsOneWidget);
  });

  testWidgets('A04: zoom con dos dedos, rotación y toque en el punto exacto', (
    tester,
  ) async {
    final h = await TestHarness.create();
    await pumpApp(tester, h);
    await openFrogFromHome(tester);
    await tester.tap(find.byKey(const ValueKey('tool-brush')));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const ValueKey('drawing-canvas'));
    DrawingCanvasState state() =>
        tester.state<DrawingCanvasState>(find.byType(DrawingCanvas));
    final center = tester.getCenter(canvas);

    // El primer dedo empieza un trazo; el segundo lo cancela y amplía.
    final a = await tester.startGesture(
      center - const Offset(20, 0),
      pointer: 1,
    );
    await a.moveBy(const Offset(-6, 0));
    final b = await tester.startGesture(
      center + const Offset(20, 0),
      pointer: 2,
    );
    await a.moveBy(const Offset(-40, 0));
    await b.moveBy(const Offset(40, 0));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(state().viewport!.zoom, greaterThan(2));
    expect(h.drawings.rows, isEmpty, reason: 'el zoom no dibuja');
    expect(find.byKey(const ValueKey('reset-zoom')), findsOneWidget);

    // Con zoom, el toque rellena la región que está bajo el dedo.
    await tester.tap(find.byKey(const ValueKey('tool-fill')));
    await tester.pumpAndSettle();
    final target = state().viewport!.toScene(
      state().viewport!.paperRect.center + const Offset(13, 17),
    );
    final expected = frog.regionAt(target)!;
    await tapScene(tester, target);
    expect(row(h, 'rana-en-la-hoja')!.document.fills.keys, [expected]);

    // Rotar: el dibujo conserva proporción y zoom, y el toque sigue acertando.
    final zoom = state().viewport!.zoom;
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final vp = state().viewport!;
    expect(vp.zoom, zoom);
    expect(vp.paperRect.width / vp.paperRect.height, closeTo(1, 1e-6));
    expect(find.text('Herramientas'), findsOneWidget, reason: 'panel lateral');

    await tester.tap(find.byKey(const ValueKey('reset-zoom')));
    await tester.pumpAndSettle();
    expect(state().viewport!.zoom, 1);
    await tapScene(tester, pointIn(frog, 'pata'));
    expect(row(h, 'rana-en-la-hoja')!.document.fills.keys, {expected, 'pata'});

    // Pintar tras rotar: el trazo queda en coordenadas de la lámina.
    await tester.tap(find.byKey(const ValueKey('tool-brush')));
    await tester.pumpAndSettle();
    final origin = tester.getTopLeft(canvas);
    final p = origin + state().viewport!.toLocal(const Offset(200, 200));
    final g = await tester.startGesture(p);
    await g.moveBy(const Offset(30, 0));
    await g.up();
    await tester.pumpAndSettle();
    final first = row(h, 'rana-en-la-hoja')!.document.ops.single.points.first;
    expect((first - const Offset(200, 200)).distance, lessThan(1));
  });

  group('A10: adaptación y accesibilidad', () {
    testWidgets('tableta horizontal: lienzo a la izquierda y panel lateral', (
      tester,
    ) async {
      final h = await TestHarness.create();
      await pumpApp(tester, h, size: const Size(1280, 800));
      await openFrogFromHome(tester);
      expect(tester.takeException(), isNull);

      final canvas = tester.getRect(
        find.byKey(const ValueKey('drawing-canvas')),
      );
      final tools = tester.getRect(find.byKey(const ValueKey('tool-fill')));
      expect(
        tools.left,
        greaterThan(canvas.right),
        reason: 'panel a la derecha',
      );
      expect(canvas.width, greaterThan(1280 * 0.55));
      expect(canvas.height, greaterThan(800 * 0.6));
      for (final t in [
        'Herramientas',
        'Rellenar',
        'Pincel',
        'Borrador',
        'Colores',
        'Verde hoja',
        'Siguiente lámina',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.byKey(const ValueKey('editor-back')), findsOneWidget);
      expect(find.byKey(const ValueKey('editor-undo')), findsOneWidget);
      await tapScene(tester, pointIn(frog, 'cuerpo'));
      expect(find.text('Guardado'), findsOneWidget);
    });

    testWidgets('teléfono: herramientas y paleta bajo el lienzo', (
      tester,
    ) async {
      final h = await TestHarness.create();
      await pumpApp(tester, h);
      await openFrogFromHome(tester);
      final canvas = tester.getRect(
        find.byKey(const ValueKey('drawing-canvas')),
      );
      final tools = tester.getRect(find.byKey(const ValueKey('tool-fill')));
      expect(tools.top, greaterThan(canvas.bottom));
      expect(canvas.height, greaterThan(844 * 0.4));
      for (final key in [
        'tool-fill',
        'tool-brush',
        'tool-eraser',
        'editor-next',
      ]) {
        expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
      }
    });

    for (final (name, size) in [
      ('teléfono', phone),
      ('teléfono pequeño', Size(320, 568)),
    ]) {
      testWidgets(
        'texto ampliado ×2 en $name: sin desbordes y con lienzo útil',
        (tester) async {
          final h = await TestHarness.create();
          await pumpApp(tester, h, size: size, textScale: 2);
          expect(tester.takeException(), isNull, reason: 'Inicio');
          await tester.tap(find.byKey(const ValueKey('tab-1')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Galería vacía');
          await tester.tap(find.byKey(const ValueKey('tab-0')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('settings')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Adultos');
          await goBack(tester);
          await tester.pumpAndSettle();

          await tester.ensureVisible(
            find.byKey(const ValueKey('explore-$chapter')),
          );
          await tester.tap(find.byKey(const ValueKey('explore-$chapter')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Portada');
          await tester.ensureVisible(find.byKey(const ValueKey('cover-color')));
          await tester.tap(find.byKey(const ValueKey('cover-color')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Láminas');
          await tester.tap(find.byKey(const ValueKey('page-rana-en-la-hoja')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Editor');

          final canvas = tester.getRect(
            find.byKey(const ValueKey('drawing-canvas')),
          );
          expect(canvas.height, greaterThan(size.height * 0.28));
          // Con texto muy ampliado la barra inferior se puede desplazar.
          await tester.ensureVisible(find.byKey(const ValueKey('editor-next')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('editor-next')).hitTestable(),
            findsOneWidget,
          );
          await tester.ensureVisible(find.byKey(const ValueKey('tool-fill')));
          await tester.pumpAndSettle();
          for (final key in [
            'tool-fill',
            'tool-brush',
            'tool-eraser',
            'editor-back',
            'editor-undo',
          ]) {
            expect(
              find.byKey(ValueKey(key)).hitTestable(),
              findsOneWidget,
              reason: key,
            );
          }
          await tester.tap(find.byKey(const ValueKey('tool-brush')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Editor con grosor');
        },
      );
    }

    testWidgets('áreas táctiles de 48 dp y etiquetas para lector de pantalla', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = await TestHarness.create();
      await pumpApp(tester, h);

      Future<void> check(String screen) async {
        await expectLater(
          tester,
          meetsGuideline(androidTapTargetGuideline),
          reason: screen,
        );
        await expectLater(
          tester,
          meetsGuideline(labeledTapTargetGuideline),
          reason: screen,
        );
      }

      await check('Inicio');
      expect(find.bySemanticsLabel('Ajustes para adultos'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tab-1')));
      await tester.pumpAndSettle();
      await check('Galería');
      await tester.tap(find.byKey(const ValueKey('tab-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings')));
      await tester.pumpAndSettle();
      await check('Adultos');
      await goBack(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('explore-$chapter')));
      await tester.pumpAndSettle();
      await check('Portada');
      expect(find.bySemanticsLabel('Narración: Escuchar'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Sonidos del bosque: Sonidos'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('cover-color')));
      await tester.pumpAndSettle();
      await check('Láminas');
      expect(
        find.bySemanticsLabel('La rana en la hoja. Dificultad: Fácil'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('page-rana-en-la-hoja')));
      await tester.pumpAndSettle();
      await check('Editor');

      // Herramienta y color activos se anuncian como seleccionados.
      expect(
        tester.getSemantics(find.byKey(const ValueKey('tool-fill'))),
        isSemantics(
          label: 'Rellenar',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('tool-brush'))),
        isSemantics(
          label: 'Pincel',
          isButton: true,
          isSelected: false,
          hasSelectedState: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('color-7cb342'))),
        isSemantics(
          label: 'Verde hoja',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
        ),
      );
      for (final label in [
        'Volver',
        'Deshacer',
        'Borrador',
        'Rojo',
        'Naranja',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      expect(
        find.bySemanticsLabel(RegExp('^Lienzo de La rana en la hoja')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('tool-brush')));
      await tester.pumpAndSettle();
      await check('Editor con grosor');
      handle.dispose();
    });
  });

  testWidgets('A09: exportar desde el área de adultos y cancelar después', (
    tester,
  ) async {
    final h = await TestHarness.create(instantExportRender: true);
    await h.drawings.save(
      DrawingSnapshot(
        drawingId: 'x',
        chapterId: chapter,
        pageId: 'quetzal',
        templateRevision: 1,
        saveRevision: 1,
        document: const DrawingDocument(fills: {'pico': 0xFDD835}),
        updatedAt: DateTime.utc(2026),
      ),
    );
    await pumpApp(tester, h);
    await tester.tap(find.byKey(const ValueKey('settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-open')));
    await tester.pumpAndSettle();

    // Sin elegir obra no hay acción de exportar.
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const ValueKey('export-save')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('export-quetzal')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('export-save')));
    await tester.pumpAndSettle();
    expect(find.text('Copia PNG exportada.'), findsOneWidget);
    expect(h.gateway.saved.single.$1, 'tuki-quetzal.png');

    h.gateway.next = ExportResult.canceled;
    await tester.tap(find.byKey(const ValueKey('export-share')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Exportación cancelada'), findsOneWidget);
    expect(h.gateway.shared, isEmpty);
    expect(find.byKey(const ValueKey('export-quetzal')), findsOneWidget);
    expect(row(h, 'quetzal')!.saveRevision, 1);
    expect(row(h, 'quetzal')!.document.fills, {'pico': 0xFDD835});
  });
}
