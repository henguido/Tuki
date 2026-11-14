// Validación de las 60 láminas con el motor real del editor.
//
// Lee cada plantilla generada por tool/laminas/convertir.py y sus sondas
// (tool/laminas/validacion/<ID>.json) y ejecuta las comprobaciones. Solo
// reescribe la evidencia con TUKI_WRITE_APPROVAL_EVIDENCE=1, para que una
// prueba normal o CI nunca ensucie el checkout. Una lámina solo se aprueba si
// pasa todas; tool/laminas/manifiesto.py publica únicamente las aprobadas.
//
// Lo que este archivo NO puede comprobar (necesita un dispositivo) queda
// anotado como tal en la matriz: rendimiento en Android y tacto real.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuki_little_adventures/data/local/database.dart';
import 'package:tuki_little_adventures/data/local/drawings_repository.dart';
import 'package:tuki_little_adventures/features/chapters/catalog.dart';
import 'package:tuki_little_adventures/features/editor/canvas_viewport.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';
import 'package:tuki_little_adventures/features/editor/drawing_renderer.dart';
import 'package:tuki_little_adventures/features/editor/editor_controller.dart';
import 'package:tuki_little_adventures/features/editor/page_template.dart';

import 'support/assets.dart';

const _niveles = {'E': 'easy', 'M': 'medium', 'D': 'detailed', 'A': 'advanced'};

/// Color único por región, lejos del blanco del papel y del negro de la tinta.
int _color(int i) =>
    ((40 + (i * 53) % 180) << 16) |
    ((40 + (i * 97) % 180) << 8) |
    (40 + (i * 29) % 180);

int _rgbAt(ByteData bytes, int width, int x, int y) {
  final o = (y * width + x) * 4;
  return (bytes.getUint8(o) << 16) |
      (bytes.getUint8(o + 1) << 8) |
      bytes.getUint8(o + 2);
}

/// Mismo color salvo el suavizado de un borde de tinta vecino (el centro de
/// una zona diminuta queda a un par de píxeles de la línea).
bool _parecido(int a, int b) {
  for (final shift in [16, 8, 0]) {
    if ((((a >> shift) & 0xFF) - ((b >> shift) & 0xFF)).abs() > 10) {
      return false;
    }
  }
  return true;
}

/// Lienzos de referencia: teléfono vertical, teléfono pequeño, teléfono
/// horizontal y tableta horizontal (área del lienzo, no de la pantalla).
const _lienzos = {
  'telefono_vertical': Size(366, 470),
  'telefono_pequeno': Size(296, 240),
  'telefono_horizontal': Size(540, 300),
  'tableta_horizontal': Size(820, 690),
};

void main() {
  final ids = [
    for (final letra in ['E', 'M', 'D', 'A'])
      for (var i = 1; i <= 15; i++) '$letra${i.toString().padLeft(2, '0')}',
  ];
  final matriz = <String, Map<String, Object?>>{};

  tearDownAll(() {
    if (Platform.environment['TUKI_WRITE_APPROVAL_EVIDENCE'] == '1') {
      File('tool/laminas/aprobacion.json').writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert(matriz)}\n',
      );
    }
  });

  for (final id in ids) {
    test('lámina $id', () async {
      final medidas = jsonDecode(
        File('tool/laminas/validacion/$id.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final sondas = (medidas['sondas'] as List).cast<Map<String, dynamic>>();
      final pruebas = <String, Object?>{};
      final fallos = <String>[];
      void anota(String nombre, bool ok, [String detalle = '']) {
        pruebas[nombre] = ok
            ? 'ok'
            : 'FALLO${detalle.isEmpty ? '' : ': $detalle'}';
        if (!ok) fallos.add('$nombre $detalle');
      }

      // 1. Carga con el parser del editor.
      final reloj = Stopwatch()..start();
      final archivo = File(medidas['plantilla'] as String);
      final template = PageTemplate.fromJson(
        jsonDecode(archivo.readAsStringSync()) as Map<String, dynamic>,
      );
      final cargaMs = reloj.elapsedMilliseconds;
      anota(
        'carga',
        template.regions.isNotEmpty &&
            template.inks.isNotEmpty &&
            template.revision == medidas['revision'],
      );

      // 2. Cantidad de regiones: la que midió el conversor.
      anota(
        'regiones',
        template.regions.length == sondas.length &&
            template.regions.length == medidas['regiones'],
        '${template.regions.length}',
      );

      // 3. Relleno individual: el centro de cada parte de cada región
      // pertenece a esa región y a ninguna otra.
      final ajenos = <String>[];
      for (final s in sondas) {
        for (final p in (s['puntos'] as List).cast<List<dynamic>>()) {
          final punto = Offset((p[0] as num) + 0.5, (p[1] as num) + 0.5);
          final hit = template.regionAt(punto);
          if (hit != s['id']) ajenos.add('${s['id']}→$hit');
        }
      }
      final controller = EditorController(template: template);
      var rellenos = 0;
      for (var i = 0; i < sondas.length; i++) {
        final p = (sondas[i]['puntos'] as List).first as List<dynamic>;
        controller.color = _color(i);
        final antes = controller.document.fills.length;
        if (controller.fillAt(
              Offset((p[0] as num) + 0.5, (p[1] as num) + 0.5),
            ) &&
            controller.document.fills.length == antes + 1 &&
            controller.document.fills[sondas[i]['id']] == _color(i)) {
          rellenos++;
        }
      }
      anota(
        'relleno_individual',
        ajenos.isEmpty && rellenos == sondas.length,
        ajenos.take(3).join(' '),
      );
      final pintado = controller.document;

      // 4. Fugas: se pinta la lámina con un color por región y se lee el
      // píxel de cada sonda. Sin pintar, todas deben seguir en blanco.
      final box = template.viewBox;
      final lado = box.longestSide.round();
      Future<ByteData> pixeles(DrawingDocument doc) async {
        final image = await DrawingRenderer.toImage(
          template,
          doc,
          maxSide: lado,
        );
        final data = await image.toByteData();
        image.dispose();
        return data!;
      }

      reloj.reset();
      final lleno = await pixeles(pintado);
      final pintaMs = reloj.elapsedMilliseconds;
      final vacio = await pixeles(DrawingDocument.empty);
      final ancho = DrawingRenderer.pixelSize(template, lado).width;
      final fugas = <String>[];
      for (var i = 0; i < sondas.length; i++) {
        for (final p in (sondas[i]['puntos'] as List).cast<List<dynamic>>()) {
          final x = p[0] as int, y = p[1] as int;
          if (!_parecido(_rgbAt(lleno, ancho, x, y), _color(i))) {
            fugas.add('${sondas[i]['id']}@$x,$y');
          }
          if (!_parecido(_rgbAt(vacio, ancho, x, y), 0xFFFFFF)) {
            fugas.add('${sondas[i]['id']} no blanca');
          }
        }
      }
      anota(
        'sin_fugas',
        fugas.isEmpty &&
            (medidas['fuga'] as num) < 0.001 &&
            (medidas['solape_visible'] as num) < 0.001 &&
            (medidas['papel_sin_region'] as num) < 0.001,
        fugas.take(3).join(' '),
      );

      // 5. Deshacer: cada relleno se revierte, hasta la lámina en blanco.
      var pasos = 0;
      while (controller.undo()) {
        pasos++;
      }
      anota(
        'deshacer',
        pasos == sondas.length && controller.document.isEmpty,
        '$pasos pasos',
      );

      // 6. Guardado y recuperación en SQLite (en memoria).
      final db = TukiDatabase(NativeDatabase.memory());
      final repo = DriftDrawingsRepository(db);
      final pagina = medidas['pagina'] as String;
      final conTrazo = pintado.withOp(
        StrokeOp(
          kind: StrokeKind.brush,
          color: 0x1E88E5,
          width: 20,
          points: [box.center, box.center + const Offset(40, 25)],
        ),
      );
      await repo.save(
        DrawingSnapshot(
          drawingId: 'd-$id',
          chapterId: 'bosque-nuboso',
          pageId: pagina,
          templateRevision: template.revision,
          saveRevision: 1,
          document: conTrazo,
          updatedAt: DateTime.utc(2026, 11, 13),
        ),
      );
      final leido = await repo.find('bosque-nuboso', pagina);
      await repo.close();
      anota(
        'guardado',
        leido != null &&
            leido.templateRevision == template.revision &&
            mapEquals(leido.document.fills, pintado.fills) &&
            leido.document.ops.length == 1 &&
            leido.document.fills.keys.every(template.hasRegion),
      );

      // 7 y 9. Encaje sin deformar, zoom y desplazamiento en cada lienzo.
      final encaje = <String>[];
      for (final e in _lienzos.entries) {
        final vp = CanvasViewport(size: e.value, viewBox: box);
        final papel = vp.paperRect;
        final dentro =
            papel.left >= -0.01 &&
            papel.top >= -0.01 &&
            papel.right <= e.value.width + 0.01 &&
            papel.bottom <= e.value.height + 0.01;
        final proporcion =
            (papel.width / papel.height - box.width / box.height).abs() < 1e-6;
        // Zoom máximo sobre la región más pequeña: el toque cae donde debe.
        final p = (sondas.last['puntos'] as List).first as List<dynamic>;
        final punto = Offset((p[0] as num) + 0.5, (p[1] as num) + 0.5);
        final local = vp.toLocal(punto);
        final cerca = vp.transformed(
          focalLocal: local,
          previousFocalLocal: local,
          newZoom: CanvasViewport.maxZoom,
        );
        final ida = cerca.toScene(cerca.toLocal(punto));
        final movido = cerca.transformed(
          focalLocal: local + const Offset(30, -20),
          previousFocalLocal: local,
          newZoom: CanvasViewport.maxZoom,
        );
        final ok =
            dentro &&
            proporcion &&
            (ida - punto).distance < 0.01 &&
            template.regionAt(cerca.toScene(cerca.toLocal(punto))) ==
                sondas.last['id'] &&
            movido.pan.dx <= 0 &&
            movido.pan.dy <= 0 &&
            (cerca.withSize(e.value.flipped).zoom - cerca.zoom).abs() < 1e-9;
        if (!ok) encaje.add(e.key);
      }
      anota('zoom_y_orientacion', encaje.isEmpty, encaje.join(' '));

      // 10. Tacto: diámetro mínimo exigido por el nivel (sin contar brillos).
      final minimo = (medidas['diametro_min'] as num).toDouble();
      final exigido = (medidas['diametro_min_exigido'] as num).toDouble();
      final brillos = sondas.where((s) => s['brillo'] == true).length;
      anota(
        'tacto_del_nivel',
        minimo >= exigido &&
            template.regions.length - brillos <=
                (medidas['tope_regiones'] as int) &&
            medidas['nivel'] == _niveles[id[0]],
        'mínimo ${(minimo * 100).toStringAsFixed(1)} %',
      );

      matriz[id] = {
        'pagina': pagina,
        'nivel': medidas['nivel'],
        'aprobada': fallos.isEmpty,
        'pruebas': pruebas,
        'regiones': template.regions.length,
        'brillos_exentos': brillos,
        'diametro_min_dp_en_360dp': double.parse(
          (minimo *
                  (box.shortestSide /
                      box.longestSide *
                      (box.width >= box.height
                          ? 1
                          : box.longestSide / box.shortestSide)) *
                  360)
              .toStringAsFixed(1),
        ),
        'orientacion': medidas['orientacion'],
        'kb': archivo.lengthSync() ~/ 1024,
        'host_carga_ms': cargaMs,
        'host_pintado_ms': pintaMs,
        'rehacer': 'no aplica: el editor no tiene rehacer',
        'rendimiento_android': 'pendiente de dispositivo',
        'tacto_real': 'pendiente de dispositivo',
      };
      expect(fallos, isEmpty, reason: id);
    });
  }

  test('el catálogo publica solo láminas aprobadas, con miniatura', () async {
    final aprobacion = File('tool/laminas/aprobacion.json');
    final catalog = await diskCatalog().load();
    final capitulo = catalog.chapterById('bosque-nuboso')!;
    final todas = capitulo.pages.length + capitulo.plannedPages.length;
    expect(todas, 60);
    expect(
      {
        ...capitulo.pages.map((p) => p.id),
        ...capitulo.plannedPages.map((p) => p.id),
      }.length,
      60,
      reason: 'identificadores únicos',
    );
    // Las tres páginas que ya existían conservan su identificador y siguen
    // pudiendo abrir las obras guardadas con la plantilla anterior.
    for (final id in ['rana-en-la-hoja', 'quetzal', 'sendero']) {
      final page = capitulo.pageById(id);
      if (page == null) continue;
      expect(page.previousTemplateAssets.keys, [1], reason: id);
      final repo = diskCatalog();
      await repo.load();
      expect((await repo.loadTemplate(page, revision: 1)).revision, 1);
    }
    if (!aprobacion.existsSync()) return;
    final matrizGuardada =
        jsonDecode(aprobacion.readAsStringSync()) as Map<String, dynamic>;
    for (final page in capitulo.pages) {
      expect(matrizGuardada[page.artId]?['aprobada'], true, reason: page.id);
      expect(File(page.thumbnailAsset!).existsSync(), true, reason: page.id);
      expect(File(page.templateAsset).existsSync(), true, reason: page.id);
      for (final lang in kLanguages) {
        expect(page.funFact!.values[lang], isNotEmpty);
        expect(page.description!.values[lang], isNotEmpty);
      }
    }
    // Quince temas por nivel, en el mismo orden.
    for (final nivel in _niveles.values) {
      expect(
        [...capitulo.pages, ...capitulo.plannedPages.map((p) => p)]
            .where(
              (p) => p is CatalogPage
                  ? p.level.id == nivel
                  : (p as PlannedPage).level.id == nivel,
            )
            .length,
        15,
        reason: nivel,
      );
    }
  });
}

bool mapEquals(Map<String, int> a, Map<String, int> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
