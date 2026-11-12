import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuki_little_adventures/features/editor/canvas_viewport.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';
import 'package:tuki_little_adventures/features/editor/editor_controller.dart';
import 'package:tuki_little_adventures/features/editor/page_template.dart';

import 'support/assets.dart';

const red = 0xE53935, blue = 0x1E88E5;

final Expando<List<(Offset, double)>> _outlineSamples = Expando();

/// Algún punto cuya región visible superior es [id], lejos de bordes y
/// contornos (para poder comprobar el color del píxel exportado).
Offset pointIn(PageTemplate t, String id) {
  final samples = _outlineSamples[t] ??= [
    for (final o in t.outlines)
      for (final m in o.path.computeMetrics())
        for (var d = 0.0; d <= m.length; d += 3)
          (m.getTangentForOffset(d)!.position, o.width),
  ];
  const margin = 8.0;
  final b = t.regions.firstWhere((r) => r.id == id).path.getBounds();
  for (var i = 1; i < 60; i++) {
    for (var j = 1; j < 60; j++) {
      final p = Offset(b.left + b.width * i / 60, b.top + b.height * j / 60);
      if (t.regionAt(p) != id) continue;
      final clear =
          [
            const Offset(margin, 0),
            const Offset(-margin, 0),
            const Offset(0, margin),
            const Offset(0, -margin),
          ].every((d) => t.regionAt(p + d) == id) &&
          samples.every((s) => (s.$1 - p).distance > s.$2 / 2 + margin);
      if (clear) return p;
    }
  }
  throw StateError('sin punto visible para $id');
}

void main() {
  late PageTemplate frog;
  late List<DrawingDocument> commits;
  late EditorController c;

  setUp(() {
    frog = loadTemplateFile('rana-en-la-hoja-v1.json');
    commits = [];
    c = EditorController(template: frog, onCommit: commits.add)..color = red;
  });

  group('detección de toque', () {
    test('elige la región visible superior', () {
      // El ojo está sobre el cuerpo, y el cuerpo sobre la hoja y el fondo.
      final eye = frog.regions.firstWhere((r) => r.id == 'ojo');
      final center = eye.path.getBounds().center;
      expect(frog.regionAt(center), 'ojo');
      final body = frog.regions.firstWhere((r) => r.id == 'cuerpo');
      expect(body.path.contains(center), true, reason: 'el cuerpo está debajo');
      expect(frog.regionAt(pointIn(frog, 'cuerpo')), 'cuerpo');
      expect(frog.regionAt(pointIn(frog, 'hoja')), 'hoja');
      expect(frog.regionAt(const Offset(5, 5)), 'fondo');
    });

    test('fuera del lienzo no hay región', () {
      expect(frog.regionAt(const Offset(-1, 500)), isNull);
      expect(frog.regionAt(const Offset(500, 1000.5)), isNull);
    });
  });

  group('relleno (A02)', () {
    test('solo cambia la región tocada entre vecinas', () {
      expect(c.fillAt(pointIn(frog, 'cuerpo')), true);
      expect(c.document.fills, {'cuerpo': red});
      c.color = blue;
      expect(c.fillAt(pointIn(frog, 'pata')), true);
      expect(c.document.fills, {'cuerpo': red, 'pata': blue});
      expect(commits.length, 2);
    });

    test('tocar fuera o repetir el color no crea acción', () {
      expect(c.fillAt(const Offset(-20, 10)), false);
      expect(c.fillAt(pointIn(frog, 'hoja')), true);
      expect(c.fillAt(pointIn(frog, 'hoja')), false);
      expect(commits.length, 1);
      expect(c.canUndo, true);
      c.undo();
      expect(c.canUndo, false);
    });

    test('el blanco limpia el relleno y no actúa sobre una región vacía', () {
      c.color = kWhite;
      expect(c.fillAt(pointIn(frog, 'hoja')), false);
      c.color = red;
      c.fillAt(pointIn(frog, 'hoja'));
      c.color = kWhite;
      expect(c.fillAt(pointIn(frog, 'hoja')), true);
      expect(c.document.fills, isEmpty);
    });

    test('el trazo permanece al cambiar el relleno', () {
      final p = pointIn(frog, 'cuerpo');
      c.fillAt(p);
      c.tool = EditorTool.brush;
      c.startStroke(p);
      c.extendStroke(p + const Offset(40, 10));
      c.endStroke();
      final strokes = c.document.ops;
      c
        ..tool = EditorTool.fill
        ..color = blue;
      expect(c.fillAt(p), true);
      expect(c.document.fills['cuerpo'], blue);
      expect(c.document.ops, strokes);
      c.color = kWhite;
      c.fillAt(p);
      expect(c.document.ops, strokes);
    });
  });

  group('pincel y borrador', () {
    test('un gesto es una sola acción con puntos en coordenadas de lámina', () {
      c.tool = EditorTool.brush;
      c.startStroke(const Offset(100, 100));
      for (var i = 1; i <= 20; i++) {
        c.extendStroke(Offset(100 + i * 10, 100 + i * 5));
      }
      expect(commits, isEmpty, reason: 'nada se confirma durante el gesto');
      expect(c.provisional, isNotNull);
      expect(c.endStroke(), true);
      expect(commits.length, 1);
      final op = c.document.ops.single;
      expect(op.kind, StrokeKind.brush);
      expect(op.color, red);
      expect(op.width, c.strokeWidth);
      expect(op.points.first, const Offset(100, 100));
      expect(op.points.last, const Offset(300, 200));
    });

    test('un toque deja un punto', () {
      c.tool = EditorTool.brush;
      c.startStroke(const Offset(400, 400));
      c.endStroke();
      expect(c.document.ops.single.points, [const Offset(400, 400)]);
    });

    test('el gesto de zoom cancela el trazo provisional', () {
      c.tool = EditorTool.brush;
      c.startStroke(const Offset(100, 100));
      c.extendStroke(const Offset(150, 150));
      c.cancelStroke();
      expect(c.provisional, isNull);
      expect(c.endStroke(), false);
      expect(c.document.isEmpty, true);
      expect(commits, isEmpty);
    });

    test('no empieza trazos fuera del lienzo ni con Rellenar', () {
      c.startStroke(const Offset(100, 100)); // herramienta: rellenar
      expect(c.provisional, isNull);
      c.tool = EditorTool.brush;
      c.startStroke(const Offset(-5, 100));
      expect(c.provisional, isNull);
    });

    test('el borrador es una operación ordenada y no toca rellenos', () {
      final p = pointIn(frog, 'cuerpo');
      c.fillAt(p);
      c.tool = EditorTool.eraser;
      c.startStroke(p);
      expect(c.provisional, isNull, reason: 'sin trazos no hay qué borrar');

      c.tool = EditorTool.brush;
      c.startStroke(const Offset(100, 500));
      c.extendStroke(const Offset(600, 500));
      c.endStroke();
      c.tool = EditorTool.eraser;
      c.startStroke(const Offset(300, 480));
      c.extendStroke(const Offset(300, 520));
      c.endStroke();
      c.tool = EditorTool.brush;
      c.startStroke(const Offset(280, 500));
      c.extendStroke(const Offset(320, 500));
      c.endStroke();

      expect(c.document.ops.map((o) => o.kind), [
        StrokeKind.brush,
        StrokeKind.eraser,
        StrokeKind.brush,
      ]);
      expect(c.document.ops[1].color, isNull);
      expect(c.document.fills, {'cuerpo': red});
    });
  });

  group('deshacer (A03)', () {
    test('revierte cada acción y persiste el resultado como cambio nuevo', () {
      final p = pointIn(frog, 'hoja');
      expect(c.canUndo, false);
      expect(c.undo(), false);

      c.fillAt(p); // 1
      final afterFill = c.document;
      c.tool = EditorTool.brush;
      c.startStroke(const Offset(100, 500));
      c.extendStroke(const Offset(600, 500));
      c.endStroke(); // 2
      final afterBrush = c.document;
      c.tool = EditorTool.eraser;
      c.startStroke(const Offset(300, 500));
      c.endStroke(); // 3
      expect(commits.length, 3);

      expect(c.undo(), true);
      expect(c.document, afterBrush);
      expect(c.undo(), true);
      expect(c.document, afterFill);
      expect(c.undo(), true);
      expect(c.document, DrawingDocument.empty);
      expect(c.canUndo, false);

      // Cada deshacer se envía a guardar.
      expect(commits.length, 6);
      expect(commits.last, DrawingDocument.empty);
    });

    test('el historial es de la sesión', () {
      c.fillAt(pointIn(frog, 'hoja'));
      final reopened = EditorController(template: frog, initial: c.document);
      expect(reopened.document.fills, {'hoja': red});
      expect(reopened.canUndo, false);
    });
  });

  group('serialización', () {
    test('rellenos y trazos sobreviven al ida y vuelta', () {
      c.fillAt(pointIn(frog, 'hoja'));
      c.tool = EditorTool.brush;
      c.color = blue;
      c.startStroke(const Offset(100.25, 500.5));
      c.extendStroke(const Offset(600, 512.3));
      c.endStroke();
      c.tool = EditorTool.eraser;
      c.startStroke(const Offset(300, 500));
      c.endStroke();

      final fillsJson = c.document.encodeFills();
      final strokesJson = c.document.encodeStrokes();
      expect(fillsJson, '{"hoja":"#E53935"}');
      expect(strokesJson, contains('"type":"brush","color":"#1E88E5"'));
      expect(strokesJson, contains('"type":"eraser","width"'));
      expect(strokesJson, isNot(contains('"type":"eraser","color"')));

      final decoded = DrawingDocument.decode(
        fillsJson: fillsJson,
        strokesJson: strokesJson,
      );
      expect(decoded.fills, c.document.fills);
      expect(decoded.ops.length, 2);
      expect(decoded.ops[0].points.first, const Offset(100.3, 500.5));
      // Una vez redondeado, el formato es estable.
      expect(decoded.encodeStrokes(), strokesJson);
      expect(
        DrawingDocument.decode(
          fillsJson: decoded.encodeFills(),
          strokesJson: decoded.encodeStrokes(),
        ),
        decoded,
      );
    });

    test('los datos ilegibles lanzan FormatException', () {
      for (final (f, s) in [
        ('no json', '[]'),
        ('{"a":"rojo"}', '[]'),
        ('{}', '[{"type":"laser","width":3,"points":[[1,2]]}]'),
        ('{}', '[{"type":"brush","color":"#112233","width":3,"points":[]}]'),
        ('{}', '{"no":"lista"}'),
        ('[]', '[]'),
      ]) {
        expect(
          () => DrawingDocument.decode(fillsJson: f, strokesJson: s),
          throwsFormatException,
          reason: '$f / $s',
        );
      }
    });
  });

  group('transformación de toque (A04)', () {
    const box = Rect.fromLTWH(0, 0, 1000, 1200);

    test('ajusta el viewBox conservando la proporción', () {
      for (final size in const [
        Size(360, 500),
        Size(900, 400),
        Size(300, 300),
      ]) {
        final vp = CanvasViewport(size: size, viewBox: box);
        final paper = vp.paperRect;
        expect(paper.width / paper.height, closeTo(1000 / 1200, 1e-9));
        expect(paper.left >= -1e-9 && paper.top >= -1e-9, true);
        expect(paper.right <= size.width + 1e-9, true);
        expect(paper.bottom <= size.height + 1e-9, true);
        expect(paper.center.dx, closeTo(size.width / 2, 1e-9));
      }
    });

    test(
      'el toque coincide con el punto del lienzo con zoom y desplazamiento',
      () {
        var vp = CanvasViewport(size: const Size(360, 500), viewBox: box);
        const scene = Offset(250, 900);
        expect(vp.toScene(vp.toLocal(scene)).dx, closeTo(250, 1e-9));

        // Pellizco centrado en un punto: ese punto de la lámina no se mueve.
        final focal = vp.toLocal(scene);
        vp = vp.transformed(
          focalLocal: focal,
          previousFocalLocal: focal,
          newZoom: 3,
        );
        expect(vp.zoom, 3);
        expect((vp.toLocal(scene) - focal).distance, lessThan(1e-6));
        // Arrastre con dos dedos: el contenido sigue al foco.
        final moved = focal + const Offset(-30, -40);
        vp = vp.transformed(
          focalLocal: moved,
          previousFocalLocal: focal,
          newZoom: 3,
        );
        expect((vp.toLocal(scene) - moved).distance, lessThan(1e-6));
        for (final local in const [
          Offset(10, 10),
          Offset(200, 333),
          Offset(359, 499),
        ]) {
          expect(
            (vp.toLocal(vp.toScene(local)) - local).distance,
            lessThan(1e-6),
          );
        }
      },
    );

    test('limita el zoom y mantiene el papel cubierto', () {
      var vp = CanvasViewport(size: const Size(360, 500), viewBox: box);
      vp = vp.transformed(
        focalLocal: const Offset(0, 0),
        previousFocalLocal: const Offset(0, 0),
        newZoom: 50,
      );
      expect(vp.zoom, CanvasViewport.maxZoom);
      vp = vp.transformed(
        focalLocal: const Offset(5000, 5000),
        previousFocalLocal: const Offset(0, 0),
        newZoom: 2,
      );
      final paper = vp.paperRect;
      // Las esquinas del papel siguen mostrando lámina.
      for (final corner in [
        paper.topLeft,
        paper.bottomRight - const Offset(0.01, 0.01),
      ]) {
        expect(box.contains(vp.toScene(corner)), true);
      }
      expect(vp.reset().zoom, 1);
      expect(vp.reset().pan, Offset.zero);
    });

    test('al rotar conserva zoom, proporción y correspondencia', () {
      var vp = CanvasViewport(size: const Size(360, 600), viewBox: box);
      final focal = vp.toLocal(const Offset(500, 600));
      vp = vp.transformed(
        focalLocal: focal,
        previousFocalLocal: focal,
        newZoom: 2,
      );
      final rotated = vp.withSize(const Size(600, 360));
      expect(rotated.zoom, 2);
      expect(
        rotated.paperRect.width / rotated.paperRect.height,
        closeTo(1000 / 1200, 1e-9),
      );
      const local = Offset(300, 180);
      expect(
        (rotated.toLocal(rotated.toScene(local)) - local).distance,
        lessThan(1e-6),
      );
      // El centro del papel sigue mostrando el mismo punto de la lámina.
      expect(
        (rotated.toScene(rotated.paperRect.center) -
                vp.toScene(vp.paperRect.center))
            .distance,
        lessThan(1e-6),
      );
    });
  });
}
