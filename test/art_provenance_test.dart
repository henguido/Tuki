import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _quotedCsvRow(String line) {
  if (!line.startsWith('"') || !line.endsWith('"')) {
    throw FormatException('Fila CSV sin comillas', line);
  }
  return line
      .substring(1, line.length - 1)
      .split('","')
      .map((value) => value.replaceAll('""', '"'))
      .toList(growable: false);
}

String _sha256(File file) => sha256.convert(file.readAsBytesSync()).toString();

void main() {
  final lines = const LineSplitter()
      .convert(File('docs/play/inventario-licencias-60.csv').readAsStringSync())
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);
  final headers = _quotedCsvRow(lines.first);
  final rows = lines
      .skip(1)
      .map((line) {
        final values = _quotedCsvRow(line);
        if (values.length != headers.length) {
          throw FormatException(
            'Fila con ${values.length} campos; se esperaban ${headers.length}',
            line,
          );
        }
        return Map<String, String>.fromIterables(headers, values);
      })
      .toList(growable: false);

  test(
    'el inventario conserva 60 IDs únicos y todos sus campos de evidencia',
    () {
      expect(rows, hasLength(60));
      expect(rows.map((row) => row['id']).toSet(), hasLength(60));
      for (final row in rows) {
        for (final field in [
          'id',
          'nivel',
          'archivo_fuente',
          'sha256',
          'fecha_generacion_c2pa',
          'evidencia_documental',
          'transformaciones',
          'derechos',
          'pendiente',
          'estado',
        ]) {
          expect(row[field], isNotEmpty, reason: '${row['id']}: $field');
        }
      }
    },
  );

  test('los originales y las copias organizadas coinciden con sus SHA-256', () {
    for (final row in rows) {
      final source = File('ilustraciones/${row['archivo_fuente']}');
      final organized = File('ilustraciones/${row['archivo_organizado']}');
      expect(source.existsSync(), isTrue, reason: source.path);
      expect(organized.existsSync(), isTrue, reason: organized.path);
      expect(_sha256(source), row['sha256'], reason: row['id']);
      expect(_sha256(organized), row['sha256'], reason: row['id']);
    }
  });

  test('los 60 originales conservan credenciales de procedencia OpenAI', () {
    for (final row in rows) {
      final raw = latin1.decode(
        File('ilustraciones/${row['archivo_fuente']}').readAsBytesSync(),
      );
      expect(raw, contains('c2pa.actions.v2'), reason: row['id']);
      expect(raw, contains('ChatGPT'), reason: row['id']);
      expect(raw, contains('OpenAI Media Service API'), reason: row['id']);
      expect(raw, contains('trainedAlgorithmicMedia'), reason: row['id']);
      expect(raw, contains(row['fecha_generacion_c2pa']!), reason: row['id']);
    }
  });

  test(
    'cada fuente enlaza al registro de conversión y a una plantilla real',
    () {
      for (final row in rows) {
        final validationFile = File(
          'tool/laminas/validacion/${row['id']}.json',
        );
        expect(validationFile.existsSync(), isTrue, reason: row['id']);
        final validation = jsonDecode(
          validationFile.readAsStringSync(),
        ) as Map<String, dynamic>;
        final expectedHash = row['id'] == 'E06'
            ? _sha256(File('tool/laminas/fuentes_corregidas/E06.png'))
            : row['sha256'];
        expect(validation['sha256_fuente'], expectedHash, reason: row['id']);
        expect(File(validation['plantilla'] as String).existsSync(), isTrue);
        expect(row['plantilla'], validation['plantilla'], reason: row['id']);
      }
    },
  );
}
