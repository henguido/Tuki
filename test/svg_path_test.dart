import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuki_little_adventures/features/editor/svg_path.dart';

void main() {
  group('SvgPathData', () {
    test('interpreta comandos absolutos y relativos', () {
      final abs = SvgPathData.parse('M10 10 L110 10 V110 H10 Z');
      final rel = SvgPathData.parse('m10,10 l100,0 v100 h-100 z');
      expect(abs.commands.length, 5);
      expect(abs.commands.map((c) => c.args), rel.commands.map((c) => c.args));
      expect(abs.toPath().getBounds(), const Rect.fromLTRB(10, 10, 110, 110));
    });

    test('acepta pares implícitos, signos pegados, decimales y exponentes', () {
      final p = SvgPathData.parse('M0 0 10-5 .5.5 1e1 2E0Z');
      expect(p.commands.map((c) => c.verb), [
        SvgVerb.moveTo,
        SvgVerb.lineTo,
        SvgVerb.lineTo,
        SvgVerb.lineTo,
        SvgVerb.close,
      ]);
      expect(p.commands[1].args, [10, -5]);
      expect(p.commands[2].args, [0.5, 0.5]);
      expect(p.commands[3].args, [10, 2]);
    });

    test('convierte C, S, Q y T a curvas absolutas', () {
      final p = SvgPathData.parse(
        'M0 0 C10 0 20 10 20 20 S30 40 40 40 Q50 50 60 40 T80 40 Z',
      );
      expect(p.commands[1].verb, SvgVerb.cubicTo);
      // S refleja el segundo punto de control anterior (20,10) → (20,30).
      expect(p.commands[2].args.sublist(0, 2), [20, 30]);
      // T refleja el control anterior (50,50) → (70,30).
      expect(p.commands[4].args, [70, 30, 80, 40]);
    });

    test('curvas relativas usan el punto actual', () {
      final p = SvgPathData.parse('M10 10 c10 0 10 10 0 10 q-5 5 -10 0 z');
      expect(p.commands[1].args, [20, 10, 20, 20, 10, 20]);
      expect(p.commands[2].args, [5, 25, 0, 20]);
    });

    test('rechaza comandos fuera del subconjunto', () {
      for (final d in ['M0 0 A5 5 0 0 1 10 10 Z', 'M0 0 X5', 'M0 0 L']) {
        expect(
          () => SvgPathData.parse(d),
          throwsA(isA<SvgPathFormatException>()),
          reason: d,
        );
      }
    });

    test('rechaza trazados vacíos, sin M inicial o con valores no finitos', () {
      for (final d in ['', '   ', 'L10 10', 'M0 0 L1e999 0 Z', 'M0 0 Z L5 5']) {
        expect(
          () => SvgPathData.parse(d),
          throwsA(isA<SvgPathFormatException>()),
          reason: '"$d"',
        );
      }
    });

    test('detecta el cierre explícito de cada subtrazado', () {
      expect(SvgPathData.parse('M0 0 L10 0 L10 10 Z').everySubpathClosed, true);
      expect(
        SvgPathData.parse('M0 0 L10 0 L10 10 Z M20 20 L30 20 L30 30 Z')
            .everySubpathClosed,
        true,
      );
      expect(SvgPathData.parse('M0 0 L10 0 L10 10').everySubpathClosed, false);
      expect(
        SvgPathData.parse('M0 0 L10 0 L10 10 M20 20 L30 20 L30 30 Z')
            .everySubpathClosed,
        false,
      );
    });

    test('la regla de relleno es la misma para pintar y detectar toques', () {
      // Cuadrado exterior e interior en el mismo sentido: con nonZero el
      // interior también se rellena (con evenOdd quedaría hueco).
      final path = SvgPathData.parse(
        'M0 0 L100 0 L100 100 L0 100 Z M25 25 L75 25 L75 75 L25 75 Z',
      ).toPath();
      expect(path.fillType, SvgPathData.fillType);
      expect(path.fillType, PathFillType.nonZero);
      expect(path.contains(const Offset(50, 50)), true);
      expect(path.contains(const Offset(150, 50)), false);
    });
  });
}
