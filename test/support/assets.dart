import 'dart:convert';
import 'dart:io';

import 'package:tuki_little_adventures/features/chapters/catalog.dart';
import 'package:tuki_little_adventures/features/editor/page_template.dart';

/// Lee los assets reales del repositorio (las pruebas corren en la raíz).
Future<String> readAssetFromDisk(String assetPath) =>
    File(assetPath).readAsString();

CatalogRepository diskCatalog() => CatalogRepository(readAssetFromDisk);

/// Catálogo con el capítulo de tres láminas v1 (ver `kChapterFixture`).
CatalogRepository legacyCatalog() => CatalogRepository(
  (path) => readAssetFromDisk(
    path == 'assets/chapters/bosque-nuboso/chapter.json'
        ? 'test/fixtures/chapter_tres_laminas.json'
        : path,
  ),
);

PageTemplate loadTemplateFile(String name) => PageTemplate.fromJson(
  jsonDecode(
    File('assets/chapters/bosque-nuboso/pages/$name').readAsStringSync(),
  ) as Map<String, dynamic>,
);
