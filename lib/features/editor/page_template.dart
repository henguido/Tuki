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

/// Plantilla de una lámina: regiones coloreables (de fondo a frente) y
/// contornos que se dibujan siempre encima.
class PageTemplate {
  PageTemplate({
    required this.revision,
    required this.viewBox,
    required this.regions,
    required this.outlines,
  });

  static const int supportedSchemaVersion = 1;

  final int revision;
  final ui.Rect viewBox;
  final List<TemplateRegion> regions;
  final List<TemplateOutline> outlines;

  /// Región visible superior que contiene [scenePoint], o `null`.
  String? regionAt(ui.Offset scenePoint) {
    if (!viewBox.contains(scenePoint)) return null;
    for (var i = regions.length - 1; i >= 0; i--) {
      if (regions[i].path.contains(scenePoint)) return regions[i].id;
    }
    return null;
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

    return PageTemplate(
      revision: revision,
      viewBox: ui.Rect.fromLTWH(x, y, w, h),
      regions: regions,
      outlines: outlines,
    );
  }
}
