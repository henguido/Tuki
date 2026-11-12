// Instalación de paquetes de contenido: integridad, reanudación y versiones.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuki_little_adventures/data/content/content_pack_installer.dart';

class MemoryFetcher implements PackFetcher {
  MemoryFetcher(this.files);

  final Map<String, List<int>> files;
  final List<(String, int)> requests = [];

  /// Corta la descarga de ese archivo tras estos bytes (una sola vez).
  String? breakFile;
  int breakAfter = 0;

  @override
  Stream<List<int>> fetch(
    PackDescriptor pack,
    PackFile file, {
    int offset = 0,
  }) async* {
    requests.add((file.path, offset));
    final bytes = files[file.path]!.sublist(offset);
    if (breakFile == file.path) {
      breakFile = null;
      yield bytes.sublist(0, breakAfter);
      throw const SocketException('conexión perdida');
    }
    yield bytes;
  }
}

PackDescriptor describe(String chapter, int version, Map<String, List<int>> f) {
  return PackDescriptor.fromJson({
    'chapterId': chapter,
    'version': version,
    'files': [
      for (final e in f.entries)
        {
          'path': e.key,
          'size': e.value.length,
          'sha256': sha256.convert(e.value).toString(),
        },
    ],
  });
}

void main() {
  late Directory root;
  late ContentPackInstaller installer;
  final v1 = {
    'chapter.json': utf8.encode('{"id":"costa","contentVersion":1}'),
    'pages/tortuga-v1.json': List<int>.generate(5000, (i) => i % 251),
  };

  setUp(() {
    root = Directory.systemTemp.createTempSync('tuki_packs');
    installer = ContentPackInstaller(root);
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('instala, verifica y deja el contenido legible sin conexión', () async {
    final pack = describe('costa', 1, v1);
    await installer.install(pack, MemoryFetcher(v1));

    expect(installer.isInstalled('costa', 1), true);
    expect(installer.installedVersions('costa'), [1]);
    expect(
      installer.installedFile('costa', 1, 'chapter.json').readAsStringSync(),
      '{"id":"costa","contentVersion":1}',
    );
    expect(
      installer.installedFile('costa', 1, 'pages/tortuga-v1.json').lengthSync(),
      5000,
    );
    expect(Directory('${root.path}/.staging/costa-v1').existsSync(), false);

    // Instalado: no vuelve a descargar.
    final again = MemoryFetcher(v1);
    await installer.install(pack, again);
    expect(again.requests, isEmpty);
  });

  test('una descarga interrumpida se reanuda desde donde quedó', () async {
    final pack = describe('costa', 1, v1);
    final fetcher = MemoryFetcher(v1)
      ..breakFile = 'pages/tortuga-v1.json'
      ..breakAfter = 1200;

    await expectLater(
      installer.install(pack, fetcher),
      throwsA(isA<SocketException>()),
    );
    expect(installer.isInstalled('costa', 1), false);
    expect(installer.installedVersions('costa'), isEmpty);

    await installer.install(pack, fetcher);
    expect(installer.isInstalled('costa', 1), true);
    // El archivo ya verificado no se pide otra vez; el cortado continúa.
    expect(fetcher.requests, [
      ('chapter.json', 0),
      ('pages/tortuga-v1.json', 0),
      ('pages/tortuga-v1.json', 1200),
    ]);
    expect(
      installer
          .installedFile('costa', 1, 'pages/tortuga-v1.json')
          .readAsBytesSync(),
      v1['pages/tortuga-v1.json'],
    );
  });

  test('contenido alterado: no se instala y se puede reintentar', () async {
    final pack = describe('costa', 1, v1);
    final tampered = {
      ...v1,
      'pages/tortuga-v1.json': List<int>.filled(5000, 7),
    };
    await expectLater(
      installer.install(pack, MemoryFetcher(tampered)),
      throwsA(
        isA<PackIntegrityException>().having(
          (e) => e.reason,
          'reason',
          contains('SHA-256'),
        ),
      ),
    );
    expect(installer.isInstalled('costa', 1), false);

    await installer.install(pack, MemoryFetcher(v1));
    expect(installer.isInstalled('costa', 1), true);
  });

  test('tamaño distinto del declarado: rechazado', () async {
    final pack = describe('costa', 1, v1);
    final longer = {...v1, 'chapter.json': utf8.encode('x' * 500)};
    await expectLater(
      installer.install(pack, MemoryFetcher(longer)),
      throwsA(isA<PackIntegrityException>()),
    );
    expect(installer.isInstalled('costa', 1), false);
  });

  test('rutas e identificadores que salen de la carpeta: rechazados', () async {
    for (final path in ['../fuera.json', '/abs.json', 'a/../../b', r'a\b']) {
      final files = {path: utf8.encode('x')};
      await expectLater(
        installer.install(describe('costa', 1, files), MemoryFetcher(files)),
        throwsA(isA<PackIntegrityException>()),
        reason: path,
      );
    }
    await expectLater(
      installer.install(describe('../otro', 1, v1), MemoryFetcher(v1)),
      throwsA(isA<PackIntegrityException>()),
    );
    expect(
      root.parent.listSync().any((e) => e.path.endsWith('fuera.json')),
      false,
    );
  });

  test('una versión nueva convive con la anterior', () async {
    final v2 = {
      'chapter.json': utf8.encode('{"id":"costa","contentVersion":2}'),
      'pages/tortuga-v2.json': List<int>.generate(300, (i) => i % 7),
    };
    await installer.install(describe('costa', 1, v1), MemoryFetcher(v1));
    await installer.install(describe('costa', 2, v2), MemoryFetcher(v2));

    expect(installer.installedVersions('costa'), [1, 2]);
    // La plantilla con la que se guardó una obra sigue disponible.
    expect(
      installer.installedFile('costa', 1, 'pages/tortuga-v1.json').existsSync(),
      true,
    );
    // La versión vigente nunca se retira; una anterior, solo a petición.
    expect(await installer.removeVersion('costa', 2), false);
    expect(await installer.removeVersion('costa', 1), true);
    expect(installer.installedVersions('costa'), [2]);
  });
}
