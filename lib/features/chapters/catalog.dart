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

/// Nivel de dificultad. Se declara en el catálogo (`levels`), no en la
/// interfaz: añadir un nivel o cambiar sus edades no requiere tocar pantallas.
class DifficultyLevel {
  const DifficultyLevel({
    required this.id,
    required this.order,
    required this.name,
    required this.minAge,
    this.maxAge,
    this.starterPalette = false,
    this.touchTolerance = 0,
  });

  final String id;

  /// Posición creciente de dificultad (1 = la más sencilla).
  final int order;
  final LocalizedText name;

  /// Edad sugerida. Es orientativa: nunca bloquea una lámina.
  final int minAge;
  final int? maxAge;

  /// El editor empieza con una paleta corta, ampliable.
  final bool starterPalette;

  /// Radio de tolerancia táctil del relleno, como fracción del lado mayor de
  /// la lámina. 0 = toque exacto.
  final double touchTolerance;
}

/// Rango de edad que un adulto puede elegir. Solo se guarda su [id].
class AgeRange {
  const AgeRange({
    required this.id,
    required this.minAge,
    this.maxAge,
    required this.recommendedLevelId,
  });

  final String id;
  final int minAge;
  final int? maxAge;
  final String recommendedLevelId;
}

/// Niveles y rangos usados cuando el catálogo no los declara (manifiestos
/// anteriores a la clasificación por edades).
const List<DifficultyLevel> kDefaultLevels = [
  DifficultyLevel(
    id: 'easy',
    order: 1,
    name: LocalizedText({'es': 'Fácil', 'en': 'Easy'}),
    minAge: 2,
    maxAge: 4,
    starterPalette: true,
    touchTolerance: 0.025,
  ),
  DifficultyLevel(
    id: 'medium',
    order: 2,
    name: LocalizedText({'es': 'Medio', 'en': 'Medium'}),
    minAge: 4,
    maxAge: 6,
  ),
  DifficultyLevel(
    id: 'detailed',
    order: 3,
    name: LocalizedText({'es': 'Detallado', 'en': 'Detailed'}),
    minAge: 6,
    maxAge: 8,
  ),
  DifficultyLevel(
    id: 'advanced',
    order: 4,
    name: LocalizedText({'es': 'Avanzado', 'en': 'Advanced'}),
    minAge: 8,
  ),
];

const List<AgeRange> kDefaultAgeRanges = [
  AgeRange(id: '2-4', minAge: 2, maxAge: 4, recommendedLevelId: 'easy'),
  AgeRange(id: '4-6', minAge: 4, maxAge: 6, recommendedLevelId: 'medium'),
  AgeRange(id: '6-8', minAge: 6, maxAge: 8, recommendedLevelId: 'detailed'),
  AgeRange(id: '8+', minAge: 8, recommendedLevelId: 'advanced'),
];

/// Cómo se obtiene un capítulo.
class ChapterAccess {
  const ChapterAccess.free() : productId = null;
  const ChapterAccess.pack(String this.productId);

  /// `null` = gratuito. En otro caso, identificador de producto de la tienda.
  final String? productId;
  bool get isFree => productId == null;
}

/// Paquete que desbloquea varios capítulos con una sola compra. La lista de
/// capítulos es cerrada: no incluye capítulos futuros.
class ChapterBundle {
  const ChapterBundle({required this.productId, required this.chapterIds});
  final String productId;
  final List<String> chapterIds;
}

/// Lámina anunciada en el manifiesto cuyo arte aún no está integrado. No se
/// puede abrir ni aparece como contenido terminado.
class PlannedPage {
  const PlannedPage({
    required this.id,
    required this.level,
    required this.title,
  });

  final String id;
  final DifficultyLevel level;
  final LocalizedText title;
}

class CatalogPage {
  const CatalogPage({
    required this.id,
    required this.chapterId,
    required this.level,
    required this.title,
    required this.templateAsset,
    required this.previousTemplateAssets,
    this.description,
    this.funFact,
    this.funFactAudioAssets = const {},
    this.minAgeOverride,
    this.maxAgeOverride,
    this.contentVersion = 1,
  });

  /// Identificador estable: las obras guardadas lo referencian.
  final String id;
  final String chapterId;
  final DifficultyLevel level;
  final LocalizedText title;
  final LocalizedText? description;

  /// Curiosidad educativa breve.
  final LocalizedText? funFact;

  /// Narración de la curiosidad por idioma, si existe.
  final Map<String, String> funFactAudioAssets;

  final int? minAgeOverride;
  final int? maxAgeOverride;

  /// Versión del contenido de la lámina (textos, audio, metadatos).
  final int contentVersion;

  /// Edad sugerida: la de la lámina si la declara, o la de su nivel.
  int get minAge => minAgeOverride ?? level.minAge;
  int? get maxAge => minAgeOverride != null || maxAgeOverride != null
      ? maxAgeOverride
      : level.maxAge;

  String? funFactAudioFor(String languageCode) =>
      funFactAudioAssets[languageCode];

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
    this.plannedPages = const [],
    this.access = const ChapterAccess.free(),
    this.contentVersion = 1,
  });

  final String id;
  final String coverAsset;
  final LocalizedText title;
  final LocalizedText intro;
  final Map<String, String> narrationAssets;
  final String ambienceAsset;

  /// Láminas disponibles, en el orden del capítulo.
  final List<CatalogPage> pages;

  /// Láminas previstas sin arte integrado (`"status": "planned"`).
  final List<PlannedPage> plannedPages;
  final ChapterAccess access;
  final int contentVersion;

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
  const Catalog(
    this.chapters, {
    this.levels = kDefaultLevels,
    this.ageRanges = kDefaultAgeRanges,
    this.bundles = const [],
    this.contentVersion = 1,
  });
  final List<Chapter> chapters;

  /// Niveles en orden creciente de dificultad.
  final List<DifficultyLevel> levels;
  final List<AgeRange> ageRanges;
  final List<ChapterBundle> bundles;
  final int contentVersion;

  DifficultyLevel? levelById(String? id) {
    for (final l in levels) {
      if (l.id == id) return l;
    }
    return null;
  }

  AgeRange? ageRangeById(String? id) {
    for (final r in ageRanges) {
      if (r.id == id) return r;
    }
    return null;
  }

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
    final levels = _parseLevels(index);
    final ageRanges = _parseAgeRanges(index, levels);
    final chapterIds = <String>{};
    final chapters = <Chapter>[];
    for (final rel in _req<List<dynamic>>(index, 'chapters', catalogAsset)) {
      if (rel is! String) {
        throw CatalogFormatException(
          '$catalogAsset: ruta de capítulo inválida',
        );
      }
      final manifestAsset = resolve(catalogAsset, rel);
      final chapter = _parseChapter(
        await _json(manifestAsset),
        manifestAsset,
        levels,
      );
      if (!chapterIds.add(chapter.id)) {
        throw CatalogFormatException('Capítulo repetido: ${chapter.id}');
      }
      chapters.add(chapter);
    }
    if (chapters.isEmpty) {
      throw CatalogFormatException('El catálogo no tiene capítulos');
    }
    final bundles = <ChapterBundle>[];
    final rawBundles = index['bundles'];
    if (rawBundles != null) {
      if (rawBundles is! List) {
        throw CatalogFormatException('$catalogAsset: bundles inválido');
      }
      for (final raw in rawBundles) {
        if (raw is! Map<String, dynamic>) {
          throw CatalogFormatException('$catalogAsset: bundle inválido');
        }
        final ids = _req<List<dynamic>>(raw, 'chapters', catalogAsset);
        // Un paquete enumera capítulos concretos y existentes.
        if (ids.isEmpty || ids.any((id) => !chapterIds.contains(id))) {
          throw CatalogFormatException(
            '$catalogAsset: bundle con capítulos desconocidos',
          );
        }
        bundles.add(
          ChapterBundle(
            productId: _req<String>(raw, 'productId', catalogAsset),
            chapterIds: List.unmodifiable(ids.cast<String>()),
          ),
        );
      }
    }
    return _catalog = Catalog(
      List.unmodifiable(chapters),
      levels: levels,
      ageRanges: ageRanges,
      bundles: List.unmodifiable(bundles),
      contentVersion: _optVersion(index, catalogAsset),
    );
  }

  static int _optVersion(Map<String, dynamic> m, String where) {
    final v = m['contentVersion'];
    if (v == null) return 1;
    if (v is! int || v < 1) {
      throw CatalogFormatException('$where: contentVersion inválido');
    }
    return v;
  }

  static int? _optAge(Map<String, dynamic> m, String key, String where) {
    final v = m[key];
    if (v == null) return null;
    if (v is! int || v < 0 || v > 99) {
      throw CatalogFormatException('$where: "$key" inválido');
    }
    return v;
  }

  static Map<String, String>? _optBilingual(
    Map<String, dynamic> m,
    String key,
    String where,
  ) => m[key] == null ? null : _bilingual(m, key, where);

  List<DifficultyLevel> _parseLevels(Map<String, dynamic> index) {
    final raw = index['levels'];
    if (raw == null) return kDefaultLevels;
    if (raw is! List || raw.isEmpty) {
      throw CatalogFormatException('$catalogAsset: levels inválido');
    }
    final ids = <String>{};
    final out = <DifficultyLevel>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) {
        throw CatalogFormatException('$catalogAsset: nivel inválido');
      }
      final id = _req<String>(item, 'id', catalogAsset);
      final where = '$catalogAsset#level:$id';
      if (id.isEmpty || !ids.add(id)) {
        throw CatalogFormatException('$catalogAsset: nivel repetido "$id"');
      }
      final minAge = _optAge(item, 'minAge', where);
      final maxAge = _optAge(item, 'maxAge', where);
      if (minAge == null || (maxAge != null && maxAge < minAge)) {
        throw CatalogFormatException('$where: edades inválidas');
      }
      final tolerance = item['touchTolerance'] ?? 0;
      if (tolerance is! num || tolerance < 0 || tolerance > 0.1) {
        throw CatalogFormatException('$where: touchTolerance inválido');
      }
      out.add(
        DifficultyLevel(
          id: id,
          order: _req<int>(item, 'order', where),
          name: LocalizedText(_bilingual(item, 'name', where)),
          minAge: minAge,
          maxAge: maxAge,
          starterPalette: item['starterPalette'] == true,
          touchTolerance: tolerance.toDouble(),
        ),
      );
    }
    out.sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(out);
  }

  List<AgeRange> _parseAgeRanges(
    Map<String, dynamic> index,
    List<DifficultyLevel> levels,
  ) {
    final raw = index['ageRanges'];
    if (raw == null) {
      // Solo valen los rangos por defecto que apuntan a niveles existentes.
      return [
        for (final r in kDefaultAgeRanges)
          if (levels.any((l) => l.id == r.recommendedLevelId)) r,
      ];
    }
    if (raw is! List) {
      throw CatalogFormatException('$catalogAsset: ageRanges inválido');
    }
    final ids = <String>{};
    final out = <AgeRange>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) {
        throw CatalogFormatException('$catalogAsset: rango de edad inválido');
      }
      final id = _req<String>(item, 'id', catalogAsset);
      final where = '$catalogAsset#age:$id';
      final level = _req<String>(item, 'recommendedLevel', where);
      final minAge = _optAge(item, 'minAge', where);
      if (id.isEmpty ||
          !ids.add(id) ||
          minAge == null ||
          !levels.any((l) => l.id == level)) {
        throw CatalogFormatException('$where: rango de edad inválido');
      }
      out.add(
        AgeRange(
          id: id,
          minAge: minAge,
          maxAge: _optAge(item, 'maxAge', where),
          recommendedLevelId: level,
        ),
      );
    }
    return List.unmodifiable(out);
  }

  Chapter _parseChapter(
    Map<String, dynamic> m,
    String asset,
    List<DifficultyLevel> levels,
  ) {
    _checkSchema(m, asset);
    final id = _req<String>(m, 'id', asset);
    if (id.isEmpty) throw CatalogFormatException('$asset: id vacío');

    final narration = _bilingual(m, 'narration', asset);
    final pageIds = <String>{};
    final pages = <CatalogPage>[];
    final planned = <PlannedPage>[];
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
      DifficultyLevel? level;
      for (final l in levels) {
        if (l.id == difficultyName) level = l;
      }
      if (level == null) {
        throw CatalogFormatException('$where: dificultad "$difficultyName"');
      }
      final title = LocalizedText(_bilingual(raw, 'title', where));
      final status = raw['status'] ?? 'available';
      if (status == 'planned') {
        // Sin arte integrado: se registra, pero no se ofrece para colorear.
        planned.add(PlannedPage(id: pageId, level: level, title: title));
        continue;
      }
      if (status != 'available') {
        throw CatalogFormatException('$where: status "$status"');
      }
      final minAge = _optAge(raw, 'minAge', where);
      final maxAge = _optAge(raw, 'maxAge', where);
      if (minAge != null && maxAge != null && maxAge < minAge) {
        throw CatalogFormatException('$where: edades inválidas');
      }
      final description = _optBilingual(raw, 'description', where);
      final funFact = _optBilingual(raw, 'funFact', where);
      final funFactAudio = _optBilingual(raw, 'funFactAudio', where);
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
          chapterId: id,
          level: level,
          title: title,
          templateAsset: resolve(asset, _req<String>(raw, 'template', where)),
          previousTemplateAssets: Map.unmodifiable(previous),
          description: description == null ? null : LocalizedText(description),
          funFact: funFact == null ? null : LocalizedText(funFact),
          funFactAudioAssets: {
            for (final e in (funFactAudio ?? const {}).entries)
              e.key: resolve(asset, e.value),
          },
          minAgeOverride: minAge,
          maxAgeOverride: maxAge,
          contentVersion: _optVersion(raw, where),
        ),
      );
    }
    if (pages.isEmpty) {
      throw CatalogFormatException('$asset: el capítulo no tiene láminas');
    }
    final rawAccess = m['access'];
    var access = const ChapterAccess.free();
    if (rawAccess != null) {
      if (rawAccess is! Map<String, dynamic>) {
        throw CatalogFormatException('$asset: access inválido');
      }
      final type = rawAccess['type'];
      if (type == 'pack') {
        final product = _req<String>(rawAccess, 'productId', asset);
        if (product.isEmpty) {
          throw CatalogFormatException('$asset: productId vacío');
        }
        access = ChapterAccess.pack(product);
      } else if (type != 'free') {
        throw CatalogFormatException('$asset: access.type "$type"');
      }
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
      plannedPages: List.unmodifiable(planned),
      access: access,
      contentVersion: _optVersion(m, asset),
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
