import 'dart:math' as math;
import 'dart:ui' as ui;

import 'svg_path.dart';

class TemplateFormatException implements Exception {
  TemplateFormatException(this.message);
  final String message;
  @override
  String toString() => 'TemplateFormatException: $message';
}

class TemplateRegion {
  TemplateRegion(this.id, this.path);
  final String id;
  final ui.Path path;
}

class TemplateOutline {
  TemplateOutline(this.path, this.width);
  final ui.Path path;

  /// Grosor en unidades del lienzo.
  final double width;
}

/// Tinta de una lámina vectorizada desde un dibujo: formas negras cerradas
/// (líneas con su grosor real) que se pintan encima de todo.
class TemplateInk {
  TemplateInk(this.path);
  final ui.Path path;
}

/// Plantilla de una lámina: regiones coloreables (de fondo a frente) y
/// contornos o tinta que se dibujan siempre encima.
class PageTemplate {
  PageTemplate({
    required this.revision,
    required this.viewBox,
    required this.regions,
    required this.outlines,
    this.inks = const [],
  });

  static const int supportedSchemaVersion = 1;

  final int revision;
  final ui.Rect viewBox;
  final List<TemplateRegion> regions;
  final List<TemplateOutline> outlines;
  final List<TemplateInk> inks;

  /// Región visible superior que contiene [scenePoint], o `null`.
  String? regionAt(ui.Offset scenePoint) {
    final i = _indexAt(scenePoint);
    return i < 0 ? null : regions[i].id;
  }

  int _indexAt(ui.Offset scenePoint) {
    if (!viewBox.contains(scenePoint)) return -1;
    for (var i = regions.length - 1; i >= 0; i--) {
      if (regions[i].path.contains(scenePoint)) return i;
    }
    return -1;
  }

  /// Como [regionAt], con tolerancia para dedos pequeños: si el toque cae en
  /// el fondo (la primera región) pero a menos de [radius] de una figura, se
  /// elige la figura más presente alrededor del toque.
  String? regionNear(ui.Offset scenePoint, double radius) {
    final exact = _indexAt(scenePoint);
    if (exact != 0 || radius <= 0 || regions.length < 2) {
      return exact < 0 ? null : regions[exact].id;
    }
    final votes = <int, int>{};
    for (final r in [radius * 0.5, radius]) {
      for (var k = 0; k < 8; k++) {
        final a = k * math.pi / 4;
        final i = _indexAt(
          scenePoint + ui.Offset(math.cos(a), math.sin(a)) * r,
        );
        if (i > 0) votes[i] = (votes[i] ?? 0) + 1;
      }
    }
    if (votes.isEmpty) return regions[0].id;
    var best = votes.keys.first;
    for (final e in votes.entries) {
      if (e.value > votes[best]! || (e.value == votes[best] && e.key > best)) {
        best = e.key;
      }
    }
    return regions[best].id;
  }

  bool hasRegion(String id) => regions.any((r) => r.id == id);

  factory PageTemplate.fromJson(Map<String, dynamic> json) {
    T req<T>(Map<String, dynamic> m, String key, String where) {
      final v = m[key];
      if (v is! T) {
        throw TemplateFormatException('Falta "$key" o tipo inválido en $where');
      }
      return v;
    }

    final schema = req<int>(json, 'schemaVersion', 'plantilla');
    if (schema != supportedSchemaVersion) {
      throw TemplateFormatException('schemaVersion no soportado: $schema');
    }
    final revision = req<int>(json, 'revision', 'plantilla');
    if (revision < 1) {
      throw TemplateFormatException('revision debe ser >= 1');
    }
    final vb = req<List<dynamic>>(json, 'viewBox', 'plantilla');
    if (vb.length != 4 || vb.any((v) => v is! num || !v.isFinite)) {
      throw TemplateFormatException('viewBox debe ser [x, y, ancho, alto]');
    }
    final x = (vb[0] as num).toDouble(), y = (vb[1] as num).toDouble();
    final w = (vb[2] as num).toDouble(), h = (vb[3] as num).toDouble();
    if (w <= 0 || h <= 0) {
      throw TemplateFormatException('viewBox con dimensiones no positivas');
    }

    final ids = <String>{};
    final regions = <TemplateRegion>[];
    for (final raw in req<List<dynamic>>(json, 'regions', 'plantilla')) {
      final m = (raw as Map).cast<String, dynamic>();
      final id = req<String>(m, 'id', 'región');
      if (id.isEmpty || !ids.add(id)) {
        throw TemplateFormatException('ID de región vacío o repetido: "$id"');
      }
      final SvgPathData data;
      try {
        data = SvgPathData.parse(req<String>(m, 'path', 'región $id'));
      } on SvgPathFormatException catch (e) {
        throw TemplateFormatException('Región $id: ${e.message}');
      }
      if (!data.everySubpathClosed) {
        throw TemplateFormatException(
          'Región $id: cada subtrazado debe cerrarse con Z',
        );
      }
      regions.add(TemplateRegion(id, data.toPath()));
    }
    if (regions.isEmpty) {
      throw TemplateFormatException('La plantilla no tiene regiones');
    }

    final outlines = <TemplateOutline>[];
    for (final raw in req<List<dynamic>>(json, 'outlines', 'plantilla')) {
      final m = (raw as Map).cast<String, dynamic>();
      final width = req<num>(m, 'width', 'contorno').toDouble();
      if (!width.isFinite || width <= 0) {
        throw TemplateFormatException('Contorno con width inválido');
      }
      try {
        outlines.add(
          TemplateOutline(
            SvgPathData.parse(req<String>(m, 'path', 'contorno')).toPath(),
            width,
          ),
        );
      } on SvgPathFormatException catch (e) {
        throw TemplateFormatException('Contorno: ${e.message}');
      }
    }

    // `inks` es opcional: las plantillas dibujadas a mano no lo usan.
    final inks = <TemplateInk>[];
    final rawInks = json['inks'];
    if (rawInks != null && rawInks is! List) {
      throw TemplateFormatException('inks debe ser una lista');
    }
    for (final raw in (rawInks as List<dynamic>? ?? const [])) {
      final m = (raw as Map).cast<String, dynamic>();
      final SvgPathData data;
      try {
        data = SvgPathData.parse(req<String>(m, 'path', 'tinta'));
      } on SvgPathFormatException catch (e) {
        throw TemplateFormatException('Tinta: ${e.message}');
      }
      if (!data.everySubpathClosed) {
        throw TemplateFormatException(
          'Tinta: cada subtrazado debe cerrarse con Z',
        );
      }
      inks.add(TemplateInk(data.toPath()));
    }

    return PageTemplate(
      revision: revision,
      viewBox: ui.Rect.fromLTWH(x, y, w, h),
      regions: regions,
      outlines: outlines,
      inks: inks,
    );
  }
}
