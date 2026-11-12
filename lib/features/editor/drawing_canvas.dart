import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'canvas_viewport.dart';
import 'drawing_renderer.dart';
import 'editor_controller.dart';

/// Lienzo interactivo. Un dedo pinta o rellena; dos dedos amplían y
/// desplazan. El mismo [CanvasViewport] transforma el render y los toques.
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.controller,
    required this.semanticLabel,
    required this.resetZoomLabel,
  });

  final EditorController controller;
  final String semanticLabel;
  final String resetZoomLabel;

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  static const double _tapSlop = 10;

  CanvasViewport? _viewport;
  final Map<int, Offset> _pointers = {};
  bool _transforming = false;
  Offset? _downLocal;
  bool _moved = false;
  double _startDistance = 1;
  double _startZoom = 1;
  Offset _lastFocal = Offset.zero;

  /// Transformación vigente (para pruebas e inspección).
  CanvasViewport? get viewport => _viewport;

  EditorController get _c => widget.controller;

  (Offset, Offset) _firstTwo() {
    final it = _pointers.values.iterator..moveNext();
    final a = it.current;
    it.moveNext();
    return (a, it.current);
  }

  void _beginTransform() {
    final (a, b) = _firstTwo();
    _startDistance = (a - b).distance.clamp(1.0, double.infinity);
    _startZoom = _viewport!.zoom;
    _lastFocal = (a + b) / 2;
  }

  void _onDown(PointerDownEvent e) {
    final vp = _viewport;
    if (vp == null) return;
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 1) {
      _transforming = false;
      _downLocal = e.localPosition;
      _moved = false;
      if (_c.tool != EditorTool.fill &&
          vp.paperRect.contains(e.localPosition)) {
        _c.startStroke(vp.toScene(e.localPosition));
      }
    } else if (_pointers.length == 2) {
      // Segundo dedo: se descarta el trazo provisional y empieza el zoom.
      _c.cancelStroke();
      _transforming = true;
      _beginTransform();
    }
  }

  void _onMove(PointerMoveEvent e) {
    final vp = _viewport;
    if (vp == null || !_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    if (_transforming) {
      if (_pointers.length < 2) return;
      final (a, b) = _firstTwo();
      final focal = (a + b) / 2;
      final distance = (a - b).distance.clamp(1.0, double.infinity);
      setState(() {
        _viewport = vp.transformed(
          focalLocal: focal,
          previousFocalLocal: _lastFocal,
          newZoom: _startZoom * distance / _startDistance,
        );
      });
      _lastFocal = focal;
      return;
    }
    if (_downLocal != null &&
        (e.localPosition - _downLocal!).distance > _tapSlop) {
      _moved = true;
    }
    _c.extendStroke(vp.toScene(e.localPosition));
  }

  void _onUp(PointerUpEvent e) {
    final vp = _viewport;
    if (_pointers.remove(e.pointer) == null || vp == null) return;
    if (_transforming) {
      if (_pointers.isEmpty) {
        _transforming = false;
      } else if (_pointers.length >= 2) {
        _beginTransform();
      }
      return;
    }
    if (_c.tool == EditorTool.fill) {
      if (!_moved && vp.paperRect.contains(e.localPosition)) {
        _c.fillAt(vp.toScene(e.localPosition));
      }
    } else {
      _c.endStroke();
    }
  }

  void _onCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    _c.cancelStroke();
    if (_pointers.isEmpty) _transforming = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final viewBox = _c.template.viewBox;
        final previous = _viewport;
        // Al rotar o cambiar el espacio se conserva la proporción y el zoom.
        final vp = previous == null || previous.viewBox != viewBox
            ? CanvasViewport(size: size, viewBox: viewBox)
            : previous.withSize(size);
        _viewport = vp;

        return Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                label: widget.semanticLabel,
                image: true,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onDown,
                  onPointerMove: _onMove,
                  onPointerUp: _onUp,
                  onPointerCancel: _onCancel,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey('drawing-canvas'),
                      painter: _CanvasPainter(_c, vp),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            if (vp.isZoomed)
              Positioned(
                top: 4,
                right: 4,
                child: Semantics(
                  button: true,
                  label: widget.resetZoomLabel,
                  excludeSemantics: true,
                  child: Material(
                    color: TukiColors.turquoise,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const ValueKey('reset-zoom'),
                      onTap: () => setState(() => _viewport = vp.reset()),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.zoom_out_map_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  _CanvasPainter(this.controller, this.viewport) : super(repaint: controller);

  final EditorController controller;
  final CanvasViewport viewport;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    viewport.applyTo(canvas);
    DrawingRenderer.paint(
      canvas,
      controller.template,
      controller.document,
      provisional: controller.provisional,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.controller != controller ||
      old.viewport.zoom != viewport.zoom ||
      old.viewport.pan != viewport.pan ||
      old.viewport.size != viewport.size;
}
