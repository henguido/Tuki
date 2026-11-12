import 'dart:math' as math;
import 'dart:ui';

/// Transformación común para render y toque: ajusta el viewBox al espacio
/// disponible conservando la proporción y aplica zoom y desplazamiento.
class CanvasViewport {
  const CanvasViewport({
    required this.size,
    required this.viewBox,
    this.zoom = 1,
    this.pan = Offset.zero,
  });

  static const double minZoom = 1;
  static const double maxZoom = 6;

  /// Espacio disponible en píxeles lógicos.
  final Size size;
  final Rect viewBox;
  final double zoom;

  /// Desplazamiento en píxeles lógicos (siempre <= 0 en cada eje).
  final Offset pan;

  double get baseScale =>
      math.min(size.width / viewBox.width, size.height / viewBox.height);

  double get scale => baseScale * zoom;

  /// Rectángulo del papel en pantalla (el dibujo se recorta a él).
  Rect get paperRect {
    final w = viewBox.width * baseScale, h = viewBox.height * baseScale;
    return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  bool get isZoomed => zoom > 1.001;

  Offset toScene(Offset local) =>
      (local - paperRect.topLeft - pan) / scale + viewBox.topLeft;

  Offset toLocal(Offset scene) =>
      (scene - viewBox.topLeft) * scale + paperRect.topLeft + pan;

  /// Aplica la transformación lámina → pantalla sobre [canvas].
  void applyTo(Canvas canvas) {
    final paper = paperRect;
    canvas.clipRect(paper);
    canvas.translate(paper.left + pan.dx, paper.top + pan.dy);
    canvas.scale(scale);
    canvas.translate(-viewBox.left, -viewBox.top);
  }

  Offset _clampPan(Offset p, double z) {
    final paper = paperRect;
    return Offset(
      p.dx.clamp(paper.width * (1 - z), 0.0),
      p.dy.clamp(paper.height * (1 - z), 0.0),
    );
  }

  /// Cambia el zoom manteniendo fijo el punto de la lámina bajo [focalLocal]
  /// y desplazando el contenido según el movimiento del foco.
  CanvasViewport transformed({
    required Offset focalLocal,
    required Offset previousFocalLocal,
    required double newZoom,
  }) {
    final z = newZoom.clamp(minZoom, maxZoom);
    final anchor = toScene(previousFocalLocal);
    final rawPan =
        focalLocal -
        paperRect.topLeft -
        (anchor - viewBox.topLeft) * (baseScale * z);
    return CanvasViewport(
      size: size,
      viewBox: viewBox,
      zoom: z,
      pan: _clampPan(rawPan, z),
    );
  }

  /// Conserva zoom y encuadre relativo al cambiar el espacio (rotación).
  CanvasViewport withSize(Size newSize) {
    if (newSize == size) return this;
    final next = CanvasViewport(size: newSize, viewBox: viewBox, zoom: zoom);
    final factor = next.baseScale / baseScale;
    return CanvasViewport(
      size: newSize,
      viewBox: viewBox,
      zoom: zoom,
      pan: next._clampPan(pan * factor, zoom),
    );
  }

  CanvasViewport reset() => CanvasViewport(size: size, viewBox: viewBox);
}
