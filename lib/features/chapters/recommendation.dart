import 'catalog.dart';

/// Recomendación de láminas según el rango de edad elegido por un adulto.
/// Lógica pura: no depende de pantallas ni de almacenamiento.
///
/// La recomendación ordena y preselecciona; nunca oculta ni bloquea láminas.
class PageRecommender {
  const PageRecommender(this.catalog, {this.ageRangeId});

  final Catalog catalog;

  /// `null` = el adulto no indicó edad.
  final String? ageRangeId;

  /// Nivel sugerido para el rango elegido, o `null` sin preferencia.
  DifficultyLevel? get recommendedLevel {
    final range = catalog.ageRangeById(ageRangeId);
    return range == null ? null : catalog.levelById(range.recommendedLevelId);
  }

  /// Filtro inicial de «Elige una lámina»: el nivel sugerido si el capítulo
  /// tiene láminas de ese nivel; en otro caso `null` (Todas).
  String? initialFilter(Chapter chapter) {
    final level = recommendedLevel;
    if (level == null) return null;
    return chapter.pages.any((p) => p.level.id == level.id) ? level.id : null;
  }

  bool isRecommended(CatalogPage page) => page.level.id == recommendedLevel?.id;

  /// Láminas de [chapter] para el filtro [levelId] (`null` = todas).
  ///
  /// Sin preferencia: dificultad creciente. Con preferencia: primero el nivel
  /// sugerido y después los más cercanos a él. Dentro de un nivel se conserva
  /// el orden del capítulo.
  List<CatalogPage> pagesFor(Chapter chapter, {String? levelId}) {
    final indexed = [
      for (var i = 0; i < chapter.pages.length; i++)
        if (levelId == null || chapter.pages[i].level.id == levelId)
          (i, chapter.pages[i]),
    ];
    final target = recommendedLevel?.order;
    int rank(CatalogPage p) =>
        target == null ? 0 : (p.level.order - target).abs();
    indexed.sort((a, b) {
      final byRank = rank(a.$2).compareTo(rank(b.$2));
      if (byRank != 0) return byRank;
      final byLevel = a.$2.level.order.compareTo(b.$2.level.order);
      return byLevel != 0 ? byLevel : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}
