import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'drawing_document.dart';
import 'page_template.dart';

/// Composición única de una obra. La usan el editor, las miniaturas y la
/// exportación: fondo y rellenos → capa de trazos → contornos.
abstract final class DrawingRenderer {
  static const Color outlineColor = Color(0xFF17383A);
  static final Expando<ui.Picture> _inkPictures = Expando<ui.Picture>();

  /// Pinta en coordenadas de la lámina. Quien llama aplica la transformación.
  static void paint(
    Canvas canvas,
    PageTemplate template,
    DrawingDocument document, {
    StrokeOp? provisional,
  }) {
    final box = template.viewBox;
    canvas.save();
    canvas.clipRect(box);

    // 1. Fondo y rellenos.
    canvas.drawRect(box, Paint()..color = const Color(0xFFFFFFFF));
    final fill = Paint()..style = PaintingStyle.fill;
    // Las regiones se apilan de fondo a frente y son opacas: una región sin
    // relleno se pinta en blanco para tapar lo que queda detrás.
    for (final region in template.regions) {
      fill.color = Color(0xFF000000 | document.fillOf(region.id));
      canvas.drawPath(region.path, fill);
    }

    // 2. Trazos en su propia capa: el borrador solo afecta a esta capa.
    if (document.ops.isNotEmpty || provisional != null) {
      canvas.saveLayer(box, Paint());
      for (final op in document.ops) {
        _paintOp(canvas, op);
      }
      if (provisional != null) _paintOp(canvas, provisional);
      canvas.restore();
    }

    // 3. Contornos siempre visibles. La geometría de esta capa no cambia
    // durante la edición. Grabarla una vez evita reconstruir cientos de
    // operaciones de trazado en cada movimiento del pincel (sobre todo en
    // las láminas avanzadas).
    canvas.drawPicture(_inkPicture(template));
    canvas.restore();
  }

  static ui.Picture _inkPicture(PageTemplate template) {
    final cached = _inkPictures[template];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..clipRect(template.viewBox);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = outlineColor;
    for (final outline in template.outlines) {
      stroke.strokeWidth = outline.width;
      canvas.drawPath(outline.path, stroke);
    }
    if (template.inks.isNotEmpty) {
      final ink = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = outlineColor;
      for (final shape in template.inks) {
        canvas.drawPath(shape.path, ink);
      }
    }
    final picture = recorder.endRecording();
    _inkPictures[template] = picture;
    return picture;
  }

  static void _paintOp(Canvas canvas, StrokeOp op) {
    final erase = op.kind == StrokeKind.eraser;
    final paint = Paint()
      ..isAntiAlias = true
      ..blendMode = erase ? BlendMode.clear : BlendMode.srcOver
      ..color = erase ? const Color(0xFF000000) : Color(0xFF000000 | op.color!);
    if (op.points.length == 1) {
      canvas.drawCircle(
        op.points.first,
        op.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = op.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(strokePath(op.points), paint);
  }

  /// Trazo suavizado que pasa por los puntos medios de cada segmento.
  static Path strokePath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
      return path;
    }
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  /// Tamaño en píxeles con la proporción original y lado mayor [maxSide].
  static ({int width, int height}) pixelSize(PageTemplate t, int maxSide) {
    final box = t.viewBox;
    final scale = maxSide / math.max(box.width, box.height);
    return (
      width: math.max(1, (box.width * scale).round()),
      height: math.max(1, (box.height * scale).round()),
    );
  }

  static Future<ui.Image> toImage(
    PageTemplate template,
    DrawingDocument document, {
    required int maxSide,
  }) {
    final size = pixelSize(template, maxSide);
    final box = template.viewBox;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width.toDouble(), size.height.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.scale(size.width / box.width, size.height / box.height);
    canvas.translate(-box.left, -box.top);
    paint(canvas, template, document);
    final picture = recorder.endRecording();
    return picture
        .toImage(size.width, size.height)
        .whenComplete(picture.dispose);
  }

  /// PNG con fondo blanco y la misma composición que el editor.
  static Future<Uint8List> toPng(
    PageTemplate template,
    DrawingDocument document, {
    int maxSide = 2048,
  }) async {
    final image = await toImage(template, document, maxSide: maxSide);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}
