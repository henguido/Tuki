import 'dart:convert';
import 'dart:io';

import 'package:tuki_little_adventures/features/chapters/catalog.dart';
import 'package:tuki_little_adventures/features/editor/page_template.dart';

/// Lee los assets reales del repositorio (las pruebas corren en la raíz).
Future<String> readAssetFromDisk(String assetPath) =>
    File(assetPath).readAsString();

CatalogRepository diskCatalog() => CatalogRepository(readAssetFromDisk);

PageTemplate loadTemplateFile(String name) => PageTemplate.fromJson(
  jsonDecode(
    File('assets/chapters/bosque-nuboso/pages/$name').readAsStringSync(),
  ) as Map<String, dynamic>,
);
