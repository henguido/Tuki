import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'drawing_document.dart';
import 'page_template.dart';

enum EditorTool { fill, brush, eraser }

enum StrokeSize { small, medium, large }

/// Estado de sesión del editor y pila de acciones, independiente del widget.
///
/// Cada acción confirmada (relleno, trazo, borrado o deshacer) produce un
/// documento nuevo y se notifica a [onCommit] para persistirlo.
class EditorController extends ChangeNotifier {
  EditorController({
    required this.template,
    DrawingDocument initial = DrawingDocument.empty,
    this.onCommit,
    int initialColor = 0x7CB342,
    this.touchTolerance = 0,
  }) : _document = initial,
       _color = initialColor;

  static const int maxUndo = 200;

  final PageTemplate template;
  final void Function(DrawingDocument document)? onCommit;

  /// Tolerancia táctil del relleno, como fracción del lado mayor de la
  /// lámina. La fija el nivel de la lámina al abrirla y no cambia después.
  final double touchTolerance;

  DrawingDocument _document;
  final List<DrawingDocument> _undo = [];
  EditorTool _tool = EditorTool.fill;
  int _color;
  StrokeSize _size = StrokeSize.medium;
  StrokeOp? _provisional;

  DrawingDocument get document => _document;
  EditorTool get tool => _tool;
  int get color => _color;
  StrokeSize get strokeSize => _size;
  bool get canUndo => _undo.isNotEmpty;

  /// Trazo en curso, todavía sin confirmar.
  StrokeOp? get provisional => _provisional;

  set tool(EditorTool value) {
    if (_tool == value) return;
    cancelStroke();
    _tool = value;
    notifyListeners();
  }

  set color(int rgb) {
    if (_color == rgb) return;
    _color = rgb & 0xFFFFFF;
    notifyListeners();
  }

  set strokeSize(StrokeSize value) {
    if (_size == value) return;
    _size = value;
    notifyListeners();
  }

  /// Grosor en unidades de la lámina para la herramienta y tamaño activos.
  double get strokeWidth {
    final unit = template.viewBox.longestSide / 1000;
    final brush = _tool != EditorTool.eraser;
    return unit *
        switch (_size) {
          StrokeSize.small => brush ? 10 : 26,
          StrokeSize.medium => brush ? 22 : 48,
          StrokeSize.large => brush ? 42 : 80,
        };
  }

  void _commit(DrawingDocument next) {
    _undo.add(_document);
    if (_undo.length > maxUndo) _undo.removeAt(0);
    _document = next;
    notifyListeners();
    onCommit?.call(next);
  }

  /// Rellena la región visible superior bajo [scenePoint]. Devuelve `false`
  /// sin crear acción si se toca fuera o el color ya es el mismo.
  bool fillAt(Offset scenePoint) {
    final id = template.regionNear(
      scenePoint,
      template.viewBox.longestSide * touchTolerance,
    );
    if (id == null) return false;
    if (_document.fillOf(id) == _color) return false;
    _commit(_document.withFill(id, _color));
    return true;
  }

  void startStroke(Offset scenePoint) {
    if (_tool == EditorTool.fill) return;
    if (!template.viewBox.contains(scenePoint)) return;
    final eraser = _tool == EditorTool.eraser;
    if (eraser && _document.ops.isEmpty) return; // nada que borrar
    _provisional = StrokeOp(
      kind: eraser ? StrokeKind.eraser : StrokeKind.brush,
      color: eraser ? null : _color,
      width: strokeWidth,
      points: List.unmodifiable([scenePoint]),
    );
    notifyListeners();
  }

  void extendStroke(Offset scenePoint) {
    final current = _provisional;
    if (current == null) return;
    // Evita puntos redundantes: mínimo ~0,15 % del lado mayor.
    final minStep = template.viewBox.longestSide * 0.0015;
    if ((scenePoint - current.points.last).distance < minStep) return;
    _provisional = current.withPoint(scenePoint);
    notifyListeners();
  }

  /// Confirma el gesto como una sola acción.
  bool endStroke() {
    final current = _provisional;
    if (current == null) return false;
    _provisional = null;
    _commit(_document.withOp(current));
    return true;
  }

  /// Descarta el trazo provisional (p. ej. al entrar un segundo dedo).
  void cancelStroke() {
    if (_provisional == null) return;
    _provisional = null;
    notifyListeners();
  }

  /// Revierte la última acción y persiste el resultado como cambio nuevo.
  bool undo() {
    if (_undo.isEmpty) return false;
    _provisional = null;
    _document = _undo.removeLast();
    notifyListeners();
    onCommit?.call(_document);
    return true;
  }
}
