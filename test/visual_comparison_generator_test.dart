import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> _decode(File file) async {
  final codec = await ui.instantiateImageCodec(await file.readAsBytes());
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

void _fit(Canvas canvas, ui.Image image, Rect destination) {
  final source = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );
  final fitted = applyBoxFit(BoxFit.contain, source.size, destination.size);
  final target = Alignment.center.inscribe(fitted.destination, destination);
  canvas.drawImageRect(image, source, target, Paint());
}

Future<ui.Image> _comparison(File original, File regions) async {
  final source = await _decode(original);
  final map = await _decode(regions);
  try {
    const width = 480, height = 310;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawColor(const Color(0xFFFFFFFF), BlendMode.src)
      ..drawRect(
        Rect.fromLTWH(0, 0, 240, height.toDouble()),
        Paint()..color = const Color(0xFFF5F5F5),
      );
    _fit(canvas, source, const Rect.fromLTWH(6, 6, 228, 298));
    _fit(canvas, map, const Rect.fromLTWH(246, 6, 228, 298));
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(width, height);
    } finally {
      picture.dispose();
    }
  } finally {
    source.dispose();
    map.dispose();
  }
}

Future<void> _writePng(ui.Image image, File output) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
}

void main() {
  test('las 60 comparaciones visuales tienen original y mapa de regiones', () async {
    final lines = const LineSplitter().convert(
      File('ilustraciones/_auditoria/matriz_60.csv').readAsStringSync(),
    );
    final rows = lines.skip(1).map((line) => line.split(',')).toList();
    expect(rows, hasLength(60));

    final generate =
        Platform.environment['TUKI_WRITE_VISUAL_COMPARISONS'] == '1';
    final output = Directory('docs/laminas/comparaciones');
    if (generate) output.createSync(recursive: true);

    final comparisons = <ui.Image>[];
    for (final row in rows) {
      final id = row[0];
      final original = File('ilustraciones/${row[4]}');
      final regions = File('docs/laminas/previas/$id.jpg');
      expect(original.existsSync(), true, reason: '$id original');
      expect(regions.existsSync(), true, reason: '$id mapa');
      if (!generate) continue;
      final image = await _comparison(original, regions);
      comparisons.add(image);
    }

    if (!generate) return;
    try {
      for (var group = 0; group < 12; group++) {
        const width = 480, rowHeight = 310, rowsPerSheet = 5;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)
          ..drawColor(const Color(0xFFFFFFFF), BlendMode.src);
        for (var row = 0; row < rowsPerSheet; row++) {
          final image = comparisons[group * rowsPerSheet + row];
          canvas.drawImage(
            image,
            Offset(0, (row * rowHeight).toDouble()),
            Paint(),
          );
        }
        final picture = recorder.endRecording();
        final sheet = await picture.toImage(width, rowHeight * rowsPerSheet);
        picture.dispose();
        try {
          await _writePng(
            sheet,
            File(
              '${output.path}/contacto-${(group + 1).toString().padLeft(2, '0')}.png',
            ),
          );
        } finally {
          sheet.dispose();
        }
      }
      expect(
        output
            .listSync()
            .whereType<File>()
            .map((file) => file.path)
            .where((path) => path.endsWith('.png')),
        hasLength(12),
      );
    } finally {
      for (final image in comparisons) {
        image.dispose();
      }
    }
  });
}
