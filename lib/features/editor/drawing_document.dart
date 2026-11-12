import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

/// Versión del formato de `fillsJson` / `strokesJson`.
const int kDocumentVersion = 1;

const int kWhite = 0xFFFFFF;

String colorToHex(int rgb) =>
    '#${(rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

int colorFromHex(String hex) {
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) {
    throw FormatException('Color inválido: $hex');
  }
  return int.parse(hex.substring(1), radix: 16);
}

enum StrokeKind { brush, eraser }

/// Operación ordenada de la capa de trazos. Los puntos están en coordenadas
/// de la lámina. El borrador describe el área borrada con su propio trazo.
@immutable
class StrokeOp {
  const StrokeOp({
    required this.kind,
    required this.width,
    required this.points,
    this.color,
  }) : assert(kind == StrokeKind.eraser || color != null);

  final StrokeKind kind;

  /// Color RGB del pincel. `null` para el borrador.
  final int? color;
  final double width;
  final List<Offset> points;

  StrokeOp withPoint(Offset p) => StrokeOp(
    kind: kind,
    color: color,
    width: width,
    points: List.unmodifiable([...points, p]),
  );

  Map<String, dynamic> toJson() => {
    'type': kind.name,
    if (kind == StrokeKind.brush) 'color': colorToHex(color!),
    'width': _round(width),
    'points': [
      for (final p in points) [_round(p.dx), _round(p.dy)],
    ],
  };

  static double _round(double v) => (v * 10).roundToDouble() / 10;

  factory StrokeOp.fromJson(Map<String, dynamic> json) {
    final kind = switch (json['type']) {
      'brush' => StrokeKind.brush,
      'eraser' => StrokeKind.eraser,
      final other => throw FormatException('Operación desconocida: $other'),
    };
    final width = (json['width'] as num).toDouble();
    final points = <Offset>[
      for (final p in json['points'] as List)
        Offset(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];
    if (!width.isFinite || width <= 0 || points.isEmpty) {
      throw const FormatException('Trazo inválido');
    }
    if (points.any((p) => !p.dx.isFinite || !p.dy.isFinite)) {
      throw const FormatException('Punto no finito');
    }
    return StrokeOp(
      kind: kind,
      color: kind == StrokeKind.brush
          ? colorFromHex(json['color'] as String)
          : null,
      width: width,
      points: List.unmodifiable(points),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StrokeOp &&
      other.kind == kind &&
      other.color == color &&
      other.width == width &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(kind, color, width, Object.hashAll(points));
}

/// Estado editable e inmutable de una obra: rellenos por región y la lista
/// ordenada de operaciones de pincel y borrador.
@immutable
class DrawingDocument {
  const DrawingDocument({this.fills = const {}, this.ops = const []});

  static const DrawingDocument empty = DrawingDocument();

  /// ID de región → color RGB. Una región ausente es blanca.
  final Map<String, int> fills;
  final List<StrokeOp> ops;

  bool get isEmpty => fills.isEmpty && ops.isEmpty;

  int fillOf(String regionId) => fills[regionId] ?? kWhite;

  DrawingDocument withFill(String regionId, int rgb) {
    final next = Map<String, int>.of(fills);
    if (rgb == kWhite) {
      next.remove(regionId);
    } else {
      next[regionId] = rgb;
    }
    return DrawingDocument(fills: Map.unmodifiable(next), ops: ops);
  }

  DrawingDocument withOp(StrokeOp op) =>
      DrawingDocument(fills: fills, ops: List.unmodifiable([...ops, op]));

  String encodeFills() =>
      jsonEncode({for (final e in fills.entries) e.key: colorToHex(e.value)});

  String encodeStrokes() => jsonEncode([for (final op in ops) op.toJson()]);

  /// Lanza [FormatException] si los datos no se pueden interpretar.
  factory DrawingDocument.decode({
    required String fillsJson,
    required String strokesJson,
  }) {
    try {
      final fills = (jsonDecode(fillsJson) as Map).map<String, int>(
        (k, v) => MapEntry(k as String, colorFromHex(v as String)),
      );
      final ops = [
        for (final o in jsonDecode(strokesJson) as List)
          StrokeOp.fromJson((o as Map).cast<String, dynamic>()),
      ];
      return DrawingDocument(
        fills: Map.unmodifiable(fills),
        ops: List.unmodifiable(ops),
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Documento ilegible: $e');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DrawingDocument &&
      mapEquals(other.fills, fills) &&
      listEquals(other.ops, ops);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      fills.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAll(ops),
  );
}
