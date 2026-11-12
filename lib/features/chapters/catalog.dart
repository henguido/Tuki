import 'dart:convert';

import '../editor/page_template.dart';

/// Idiomas de contenido obligatorios.
const List<String> kLanguages = ['es', 'en'];

class CatalogFormatException implements Exception {
  CatalogFormatException(this.message);
  final String message;
  @override
  String toString() => 'CatalogFormatException: $message';
}

/// La revisión de plantilla con la que se guardó una obra ya no está
/// disponible en el catálogo.
class TemplateRevisionMissing implements Exception {
  TemplateRevisionMissing(this.pageId, this.revision);
  final String pageId;
  final int revision;
  @override
  String toString() => 'TemplateRevisionMissing($pageId, r$revision)';
}

class LocalizedText {
  const LocalizedText(this.values);
  final Map<String, String> values;

  String of(String languageCode) => values[languageCode] ?? values['es']!;
}

enum Difficulty { easy, medium, detailed }

class CatalogPage {
  const CatalogPage({
    required this.id,
    required this.difficulty,
    required this.title,
    required this.templateAsset,
    required this.previousTemplateAssets,
  });

  final String id;
  final Difficulty difficulty;
  final LocalizedText title;

  /// Ruta de asset de la revisión vigente.
  final String templateAsset;

  /// Revisiones publicadas anteriores (`previousTemplates` en el manifiesto),
  /// por número de revisión.
  final Map<int, String> previousTemplateAssets;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.coverAsset,
    required this.title,
    required this.intro,
    required this.narrationAssets,
    required this.ambienceAsset,
    required this.pages,
  });

  final String id;
  final String coverAsset;
  final LocalizedText title;
  final LocalizedText intro;
  final Map<String, String> narrationAssets;
  final String ambienceAsset;
  final List<CatalogPage> pages;

  CatalogPage? pageById(String pageId) {
    for (final p in pages) {
      if (p.id == pageId) return p;
    }
    return null;
  }

  /// Lámina siguiente en el orden del capítulo, o `null` en la última.
  CatalogPage? nextPage(String pageId) {
    final i = pages.indexWhere((p) => p.id == pageId);
    if (i < 0 || i + 1 >= pages.length) return null;
    return pages[i + 1];
  }

  String narrationFor(String languageCode) =>
      narrationAssets[languageCode] ?? narrationAssets['es']!;
}

class Catalog {
  const Catalog(this.chapters);
  final List<Chapter> chapters;

  Chapter? chapterById(String id) {
    for (final c in chapters) {
      if (c.id == id) return c;
    }
    return null;
  }
}

typedef AssetStringLoader = Future<String> Function(String assetPath);

/// Carga índice, capítulos y plantillas desde assets y valida el contrato.
class CatalogRepository {
  CatalogRepository(this._loadString, {this.catalogAsset = defaultCatalog});

  static const String defaultCatalog = 'assets/chapters/catalog.json';
  static const int supportedSchemaVersion = 1;

  final AssetStringLoader _loadString;
  final String catalogAsset;

  Catalog? _catalog;
  final Map<String, Future<PageTemplate>> _templates = {};

  /// Resuelve [relative] respecto al directorio de [baseFile]. Solo se
  /// aceptan rutas relativas descendentes.
  static String resolve(String baseFile, String relative) {
    if (relative.isEmpty ||
        relative.startsWith('/') ||
        relative.contains('\\') ||
        relative.split('/').any((s) => s == '..' || s == '.' || s.isEmpty)) {
      throw CatalogFormatException('Ruta relativa inválida: "$relative"');
    }
    final slash = baseFile.lastIndexOf('/');
    return slash < 0 ? relative : '${baseFile.substring(0, slash)}/$relative';
  }

  Future<Map<String, dynamic>> _json(String asset) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(await _loadString(asset));
    } on FormatException catch (e) {
      throw CatalogFormatException('$asset: JSON inválido (${e.message})');
    }
    if (decoded is! Map<String, dynamic>) {
      throw CatalogFormatException('$asset: se esperaba un objeto JSON');
    }
    return decoded;
  }

  static T _req<T>(Map<String, dynamic> m, String key, String where) {
    final v = m[key];
    if (v is! T) {
      throw CatalogFormatException('$where: falta "$key" o tipo inválido');
    }
    return v;
  }

  static void _checkSchema(Map<String, dynamic> m, String where) {
    final v = _req<int>(m, 'schemaVersion', where);
    if (v != supportedSchemaVersion) {
      throw CatalogFormatException('$where: schemaVersion no soportado ($v)');
    }
  }

  static Map<String, String> _bilingual(
    Map<String, dynamic> m,
    String key,
    String where,
  ) {
    final raw = _req<Map<String, dynamic>>(m, key, where);
    final out = <String, String>{};
    for (final lang in kLanguages) {
      final v = raw[lang];
      if (v is! String || v.trim().isEmpty) {
        throw CatalogFormatException('$where: falta "$key.$lang"');
      }
      out[lang] = v;
    }
    return out;
  }

  Future<Catalog> load() async {
    final cached = _catalog;
    if (cached != null) return cached;

    final index = await _json(catalogAsset);
    _checkSchema(index, catalogAsset);
    final chapterIds = <String>{};
    final chapters = <Chapter>[];
    for (final rel in _req<List<dynamic>>(index, 'chapters', catalogAsset)) {
      if (rel is! String) {
        throw CatalogFormatException(
          '$catalogAsset: ruta de capítulo inválida',
        );
      }
      final manifestAsset = resolve(catalogAsset, rel);
      final chapter = _parseChapter(await _json(manifestAsset), manifestAsset);
      if (!chapterIds.add(chapter.id)) {
        throw CatalogFormatException('Capítulo repetido: ${chapter.id}');
      }
      chapters.add(chapter);
    }
    if (chapters.isEmpty) {
      throw CatalogFormatException('El catálogo no tiene capítulos');
    }
    return _catalog = Catalog(List.unmodifiable(chapters));
  }

  Chapter _parseChapter(Map<String, dynamic> m, String asset) {
    _checkSchema(m, asset);
    final id = _req<String>(m, 'id', asset);
    if (id.isEmpty) throw CatalogFormatException('$asset: id vacío');

    final narration = _bilingual(m, 'narration', asset);
    final pageIds = <String>{};
    final pages = <CatalogPage>[];
    for (final raw in _req<List<dynamic>>(m, 'pages', asset)) {
      if (raw is! Map<String, dynamic>) {
        throw CatalogFormatException('$asset: lámina inválida');
      }
      final pageId = _req<String>(raw, 'id', asset);
      final where = '$asset#$pageId';
      if (pageId.isEmpty || !pageIds.add(pageId)) {
        throw CatalogFormatException(
          '$asset: lámina vacía o repetida "$pageId"',
        );
      }
      final difficultyName = _req<String>(raw, 'difficulty', where);
      final difficulty = Difficulty.values.asNameMap()[difficultyName];
      if (difficulty == null) {
        throw CatalogFormatException('$where: dificultad "$difficultyName"');
      }
      final previous = <int, String>{};
      final rawPrevious = raw['previousTemplates'];
      if (rawPrevious != null) {
        if (rawPrevious is! Map<String, dynamic>) {
          throw CatalogFormatException('$where: previousTemplates inválido');
        }
        for (final e in rawPrevious.entries) {
          final rev = int.tryParse(e.key);
          if (rev == null || rev < 1 || e.value is! String) {
            throw CatalogFormatException('$where: previousTemplates inválido');
          }
          previous[rev] = resolve(asset, e.value as String);
        }
      }
      pages.add(
        CatalogPage(
          id: pageId,
          difficulty: difficulty,
          title: LocalizedText(_bilingual(raw, 'title', where)),
          templateAsset: resolve(asset, _req<String>(raw, 'template', where)),
          previousTemplateAssets: Map.unmodifiable(previous),
        ),
      );
    }
    if (pages.isEmpty) {
      throw CatalogFormatException('$asset: el capítulo no tiene láminas');
    }

    return Chapter(
      id: id,
      coverAsset: resolve(asset, _req<String>(m, 'cover', asset)),
      title: LocalizedText(_bilingual(m, 'title', asset)),
      intro: LocalizedText(_bilingual(m, 'intro', asset)),
      narrationAssets: {
        for (final e in narration.entries) e.key: resolve(asset, e.value),
      },
      ambienceAsset: resolve(asset, _req<String>(m, 'ambience', asset)),
      pages: List.unmodifiable(pages),
    );
  }

  Future<PageTemplate> _template(String asset) {
    return _templates[asset] ??= () async {
      final Map<String, dynamic> json;
      try {
        json = await _json(asset);
        return PageTemplate.fromJson(json);
      } catch (_) {
        _templates.remove(asset); // permite reintentar
        rethrow;
      }
    }();
  }

  /// Plantilla vigente de [page], o la [revision] publicada que se pida.
  /// Lanza [TemplateRevisionMissing] si esa revisión no está en el catálogo.
  Future<PageTemplate> loadTemplate(CatalogPage page, {int? revision}) async {
    final current = await _template(page.templateAsset);
    if (revision == null || current.revision == revision) return current;
    final asset = page.previousTemplateAssets[revision];
    if (asset == null) throw TemplateRevisionMissing(page.id, revision);
    final previous = await _template(asset);
    if (previous.revision != revision) {
      throw TemplateRevisionMissing(page.id, revision);
    }
    return previous;
  }
}
