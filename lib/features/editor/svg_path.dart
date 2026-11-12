import 'dart:ui' as ui;

/// Error de formato en los datos de trazado de una plantilla.
class SvgPathFormatException implements Exception {
  SvgPathFormatException(this.message);
  final String message;
  @override
  String toString() => 'SvgPathFormatException: $message';
}

enum SvgVerb { moveTo, lineTo, cubicTo, quadTo, close }

/// Comando ya normalizado a coordenadas absolutas.
class SvgCommand {
  const SvgCommand(this.verb, [this.args = const []]);
  final SvgVerb verb;
  final List<double> args;
}

/// Parser del subconjunto de datos de trazado SVG que aceptan las plantillas.
///
/// Comandos soportados, en mayúscula (absolutos) y minúscula (relativos):
/// `M`, `L`, `H`, `V`, `C`, `S`, `Q`, `T` y `Z`. Los arcos (`A`) no se
/// aceptan: las plantillas deben aproximarlos con curvas de Bézier.
/// Tras `Z` el siguiente subtrazado debe empezar con `M`.
class SvgPathData {
  SvgPathData._(this.commands);

  final List<SvgCommand> commands;

  /// Regla de relleno única para pintar y para detectar toques.
  static const ui.PathFillType fillType = ui.PathFillType.nonZero;

  static const Map<String, int> _arity = {
    'M': 2,
    'L': 2,
    'H': 1,
    'V': 1,
    'C': 6,
    'S': 4,
    'Q': 4,
    'T': 2,
    'Z': 0,
  };

  static final RegExp _number = RegExp(
    r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
  );

  static SvgPathData parse(String d) {
    final commands = <SvgCommand>[];
    var i = 0;
    var cx = 0.0, cy = 0.0; // punto actual
    var sx = 0.0, sy = 0.0; // inicio del subtrazado
    double? lastCubicX, lastCubicY, lastQuadX, lastQuadY;
    var open = false; // hay un subtrazado iniciado con M y sin cerrar
    var afterClose = false;

    void skipSeparators() {
      while (i < d.length) {
        final c = d.codeUnitAt(i);
        if (c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D || c == 0x2C) {
          i++;
        } else {
          break;
        }
      }
    }

    double readNumber(String cmd) {
      skipSeparators();
      final m = _number.matchAsPrefix(d, i);
      if (m == null) {
        throw SvgPathFormatException(
          'Se esperaba un número para "$cmd" en la posición $i',
        );
      }
      i = m.end;
      final v = double.parse(m.group(0)!);
      if (!v.isFinite) {
        throw SvgPathFormatException('Valor no finito en la posición $i');
      }
      return v;
    }

    bool numberAhead() {
      skipSeparators();
      return i < d.length && _number.matchAsPrefix(d, i) != null;
    }

    skipSeparators();
    if (i >= d.length) {
      throw SvgPathFormatException('Trazado vacío');
    }

    while (true) {
      skipSeparators();
      if (i >= d.length) break;
      final letter = d[i];
      final upper = letter.toUpperCase();
      final arity = _arity[upper];
      if (arity == null) {
        throw SvgPathFormatException(
          'Comando no soportado "$letter" en la posición $i',
        );
      }
      i++;
      final relative = letter != upper;

      if (upper == 'Z') {
        if (!open) {
          throw SvgPathFormatException('"Z" sin subtrazado abierto');
        }
        commands.add(const SvgCommand(SvgVerb.close));
        cx = sx;
        cy = sy;
        open = false;
        afterClose = true;
        lastCubicX = lastCubicY = lastQuadX = lastQuadY = null;
        continue;
      }
      if (upper != 'M' && (!open || afterClose)) {
        throw SvgPathFormatException(
          'El subtrazado debe empezar con "M" (posición ${i - 1})',
        );
      }

      var first = true;
      do {
        final a = [for (var k = 0; k < arity; k++) readNumber(letter)];
        final ox = relative ? cx : 0.0;
        final oy = relative ? cy : 0.0;
        switch (upper) {
          case 'M':
            if (first) {
              cx = a[0] + ox;
              cy = a[1] + oy;
              sx = cx;
              sy = cy;
              commands.add(SvgCommand(SvgVerb.moveTo, [cx, cy]));
              open = true;
              afterClose = false;
            } else {
              // Pares adicionales tras M equivalen a L.
              cx = a[0] + ox;
              cy = a[1] + oy;
              commands.add(SvgCommand(SvgVerb.lineTo, [cx, cy]));
            }
            lastCubicX = lastCubicY = lastQuadX = lastQuadY = null;
          case 'L':
            cx = a[0] + ox;
            cy = a[1] + oy;
            commands.add(SvgCommand(SvgVerb.lineTo, [cx, cy]));
            lastCubicX = lastCubicY = lastQuadX = lastQuadY = null;
          case 'H':
            cx = a[0] + ox;
            commands.add(SvgCommand(SvgVerb.lineTo, [cx, cy]));
            lastCubicX = lastCubicY = lastQuadX = lastQuadY = null;
          case 'V':
            cy = a[0] + oy;
            commands.add(SvgCommand(SvgVerb.lineTo, [cx, cy]));
            lastCubicX = lastCubicY = lastQuadX = lastQuadY = null;
          case 'C':
            final x1 = a[0] + ox, y1 = a[1] + oy;
            final x2 = a[2] + ox, y2 = a[3] + oy;
            cx = a[4] + ox;
            cy = a[5] + oy;
            commands.add(SvgCommand(SvgVerb.cubicTo, [x1, y1, x2, y2, cx, cy]));
            lastCubicX = x2;
            lastCubicY = y2;
            lastQuadX = lastQuadY = null;
          case 'S':
            final x1 = lastCubicX == null ? cx : 2 * cx - lastCubicX;
            final y1 = lastCubicY == null ? cy : 2 * cy - lastCubicY;
            final x2 = a[0] + ox, y2 = a[1] + oy;
            cx = a[2] + ox;
            cy = a[3] + oy;
            commands.add(SvgCommand(SvgVerb.cubicTo, [x1, y1, x2, y2, cx, cy]));
            lastCubicX = x2;
            lastCubicY = y2;
            lastQuadX = lastQuadY = null;
          case 'Q':
            final x1 = a[0] + ox, y1 = a[1] + oy;
            cx = a[2] + ox;
            cy = a[3] + oy;
            commands.add(SvgCommand(SvgVerb.quadTo, [x1, y1, cx, cy]));
            lastQuadX = x1;
            lastQuadY = y1;
            lastCubicX = lastCubicY = null;
          case 'T':
            final x1 = lastQuadX == null ? cx : 2 * cx - lastQuadX;
            final y1 = lastQuadY == null ? cy : 2 * cy - lastQuadY;
            cx = a[0] + ox;
            cy = a[1] + oy;
            commands.add(SvgCommand(SvgVerb.quadTo, [x1, y1, cx, cy]));
            lastQuadX = x1;
            lastQuadY = y1;
            lastCubicX = lastCubicY = null;
        }
        first = false;
      } while (numberAhead());
    }

    if (commands.isEmpty) {
      throw SvgPathFormatException('Trazado sin comandos');
    }
    return SvgPathData._(commands);
  }

  /// Verdadero si cada subtrazado dibuja algo y termina con `Z` explícito.
  bool get everySubpathClosed {
    var inSubpath = false;
    var drew = false;
    for (final c in commands) {
      switch (c.verb) {
        case SvgVerb.moveTo:
          if (inSubpath) return false; // el anterior quedó abierto
          inSubpath = true;
          drew = false;
        case SvgVerb.close:
          if (!inSubpath || !drew) return false;
          inSubpath = false;
        default:
          drew = true;
      }
    }
    return !inSubpath;
  }

  ui.Path toPath() {
    final path = ui.Path()..fillType = fillType;
    for (final c in commands) {
      final a = c.args;
      switch (c.verb) {
        case SvgVerb.moveTo:
          path.moveTo(a[0], a[1]);
        case SvgVerb.lineTo:
          path.lineTo(a[0], a[1]);
        case SvgVerb.cubicTo:
          path.cubicTo(a[0], a[1], a[2], a[3], a[4], a[5]);
        case SvgVerb.quadTo:
          path.quadraticBezierTo(a[0], a[1], a[2], a[3]);
        case SvgVerb.close:
          path.close();
      }
    }
    return path;
  }
}
