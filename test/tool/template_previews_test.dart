// Herramienta de revisión visual: genera PNG de cada lámina (en blanco y con
// todas las regiones coloreadas) en build/template_previews/.
//
//   flutter test test/tool/template_previews_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';
import 'package:tuki_little_adventures/features/editor/drawing_renderer.dart';

import '../support/assets.dart';

void main() {
  const palette = [
    0xE53935,
    0xFB8C00,
    0xFDD835,
    0x7CB342,
    0x2E7D52,
    0x26A69A,
    0x1E88E5,
    0x8E44AD,
    0xF06292,
    0x8D6E63,
  ];

  for (final name in ['rana-en-la-hoja-v1', 'quetzal-v1', 'sendero-v1']) {
    testWidgets('vista previa de $name', (tester) async {
      final template = loadTemplateFile('$name.json');
      var colored = DrawingDocument.empty;
      for (var i = 0; i < template.regions.length; i++) {
        colored = colored.withFill(
          template.regions[i].id,
          palette[i % palette.length],
        );
      }
      await tester.runAsync(() async {
        final dir = Directory('build/template_previews')
          ..createSync(recursive: true);
        for (final (suffix, doc) in [
          ('blank', DrawingDocument.empty),
          ('colored', colored),
        ]) {
          final png = await DrawingRenderer.toPng(template, doc, maxSide: 900);
          File('${dir.path}/$name-$suffix.png').writeAsBytesSync(png);
        }
      });
    });
  }
}
