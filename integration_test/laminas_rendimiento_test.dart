// Rendimiento de las láminas en un dispositivo real.
//
//   flutter test integration_test/laminas_rendimiento_test.dart -d <id>
//
// Abre una lámina de cada nivel (y las dos más pesadas), mide la carga y los
// fotogramas mientras se pinta con el pincel y se rellena, e imprime una
// línea `RENDIMIENTO {...}` por lámina. Usa una base de datos propia.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tuki_little_adventures/app/app.dart';
import 'package:tuki_little_adventures/app/dependencies.dart';
import 'package:tuki_little_adventures/features/editor/drawing_canvas.dart';
import 'package:tuki_little_adventures/features/editor/editor_screen.dart';

const chapter = 'bosque-nuboso';
const dbName = 'tuki_rendimiento.sqlite';
const pages = [
  'rana-en-la-hoja', // E01, 11 regiones
  'quetzal', // M06
  'd14-cascada', // horizontal
  'a10-helechos',
  'a13-arbol-gigante', // la plantilla más pesada
];

double _ms(Duration d) => d.inMicroseconds / 1000;

double _p90(List<double> v) {
  if (v.isEmpty) return 0;
  final s = [...v]..sort();
  return s[((s.length - 1) * 0.9).round()];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('carga y fotogramas al pintar', (tester) async {
    final dir = await getApplicationSupportDirectory();
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final f = File(p.join(dir.path, '$dbName$suffix'));
      if (f.existsSync()) f.deleteSync();
    }
    final deps = await AppDependencies.create(databaseName: dbName);
    await deps.preferences.setAgeRange(null);
    await tester.pumpWidget(TukiApp(deps: deps));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    final forest = deps.catalog.chapterById(chapter)!;

    for (final pageId in pages) {
      final page = forest.pageById(pageId)!;
      final reloj = Stopwatch()..start();
      nav.push(
        EditorScreen.route(
          chapterId: chapter,
          pageId: pageId,
          origin: EditorOrigin.pages,
        ),
      );
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.byType(DrawingCanvas).evaluate().isNotEmpty) break;
      }
      expect(find.byType(DrawingCanvas), findsOneWidget, reason: pageId);
      await tester.pump(const Duration(milliseconds: 300));
      final abrirMs = reloj.elapsedMilliseconds;
      final template = await deps.catalogRepository.loadTemplate(page);

      final frames = <FrameTiming>[];
      void recoge(List<FrameTiming> t) => frames.addAll(t);
      SchedulerBinding.instance.addTimingsCallback(recoge);

      // Pincel: un trazo largo, un fotograma por movimiento.
      await tester.tap(find.byKey(const ValueKey('tool-brush')));
      await tester.pump(const Duration(milliseconds: 100));
      final box = tester.getRect(find.byKey(const ValueKey('drawing-canvas')));
      final g = await tester.startGesture(
        box.topLeft + Offset(box.width * 0.2, box.height * 0.3),
      );
      for (var i = 0; i < 60; i++) {
        await g.moveBy(Offset(box.width * 0.008, box.height * 0.006));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pump(const Duration(milliseconds: 400));
      final trazo = [...frames];
      frames.clear();

      // Relleno: diez toques repartidos por la lámina.
      await tester.tap(find.byKey(const ValueKey('tool-fill')));
      await tester.pump(const Duration(milliseconds: 100));
      final relojRelleno = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        await tester.tapAt(
          box.topLeft +
              Offset(
                box.width * (0.15 + 0.07 * i),
                box.height * (0.2 + 0.06 * i),
              ),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      final rellenoMs = relojRelleno.elapsedMilliseconds / 10;
      await tester.pump(const Duration(milliseconds: 600));
      SchedulerBinding.instance.removeTimingsCallback(recoge);

      final raster = [for (final f in trazo) _ms(f.rasterDuration)];
      final build = [for (final f in trazo) _ms(f.buildDuration)];
      // ignore: avoid_print
      print(
        'RENDIMIENTO ${jsonEncode({'pagina': pageId, 'artId': page.artId, 'regiones': template.regions.length, 'abrir_ms': abrirMs, 'fotogramas_trazo': trazo.length, 'build_ms_media': build.isEmpty ? 0 : double.parse((build.reduce((a, b) => a + b) / build.length).toStringAsFixed(1)), 'raster_ms_media': raster.isEmpty ? 0 : double.parse((raster.reduce((a, b) => a + b) / raster.length).toStringAsFixed(1)), 'raster_ms_p90': double.parse(_p90(raster).toStringAsFixed(1)), 'toque_relleno_ms': double.parse(rellenoMs.toStringAsFixed(1))})}',
      );

      final guardada = await deps.drawings.find(chapter, pageId);
      expect(guardada, isNotNull, reason: '$pageId se guardó');
      expect(guardada!.document.ops, isNotEmpty);

      await tester.tap(find.byKey(const ValueKey('editor-back')));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(EditorScreen).evaluate().isEmpty) break;
      }
    }

    await tester.pumpWidget(const SizedBox());
    await deps.close();
  });
}
