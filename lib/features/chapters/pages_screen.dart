import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../data/local/drawings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../editor/editor_screen.dart';
import '../gallery/drawing_preview.dart';
import 'catalog.dart';
import 'level_widgets.dart';
import 'recommendation.dart';

/// Selección de lámina. Todas las láminas están disponibles siempre; el
/// rango de edad elegido por un adulto solo ordena y preselecciona el filtro.
class PagesScreen extends StatefulWidget {
  const PagesScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  State<PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends State<PagesScreen> {
  /// `null` = Todas.
  String? _filter;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // El filtro sugerido se aplica al entrar; después manda quien usa la app.
    final deps = AppScope.of(context);
    _filter = PageRecommender(
      deps.catalog,
      ageRangeId: deps.preferences.ageRangeId,
    ).initialFilter(deps.catalog.chapterById(widget.chapterId)!);
  }

  StoredDrawing? _drawingOf(List<StoredDrawing>? drawings, CatalogPage page) {
    for (final d in drawings ?? const <StoredDrawing>[]) {
      if (d.chapterId == widget.chapterId && d.pageId == page.id) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = contentLanguage(context);
    final deps = AppScope.of(context);
    final chapter = deps.catalog.chapterById(widget.chapterId)!;
    final recommender = PageRecommender(
      deps.catalog,
      ageRangeId: deps.preferences.ageRangeId,
    );
    final pages = recommender.pagesFor(chapter, levelId: _filter);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TukiBackHeader(
                    backLabel: l.back,
                    caption: chapter.title.of(lang),
                  ),
                  const SizedBox(height: 8),
                  // Título y filtros se desplazan con las tarjetas: con texto
                  // ampliado en un teléfono pequeño todo sigue al alcance.
                  Expanded(
                    child: DrawingsBuilder(
                      builder: (context, drawings) => CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.only(top: 6),
                            sliver: SliverList.list(
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    l.choosePage,
                                    style: tukiText(28, weight: 700),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _FilterBar(
                                  levels: deps.catalog.levels,
                                  selected: _filter,
                                  onSelected: (id) =>
                                      setState(() => _filter = id),
                                ),
                                const SizedBox(height: 10),
                                if (pages.isEmpty)
                                  _EmptyLevel(
                                    onShowAll: () =>
                                        setState(() => _filter = null),
                                  ),
                              ],
                            ),
                          ),
                          // Con 60 láminas las tarjetas se construyen al
                          // desplazarse, no todas de una vez.
                          SliverPadding(
                            padding: const EdgeInsets.only(bottom: 16),
                            sliver: SliverList.builder(
                              itemCount: pages.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PageCard(
                                  chapterId: widget.chapterId,
                                  page: pages[i],
                                  drawing: _drawingOf(drawings, pages[i]),
                                  // La marca distingue láminas solo cuando
                                  // se ven todos los niveles.
                                  recommended:
                                      _filter == null &&
                                      recommender.isRecommended(pages[i]),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.levels,
    required this.selected,
    required this.onSelected,
  });

  final List<DifficultyLevel> levels;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = contentLanguage(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            key: const ValueKey('filter-all'),
            label: l.filterAll,
            semanticLabel: l.filterSemantics(l.filterAll),
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final level in levels) ...[
            const SizedBox(width: 8),
            _FilterChip(
              key: ValueKey('filter-${level.id}'),
              label: level.name.of(lang),
              semanticLabel: l.filterSemantics(
                l.levelSemantics(
                  level.name.of(lang),
                  level.order,
                  levels.length,
                ),
              ),
              leaves: (level.order, levels.length),
              selected: selected == level.id,
              onTap: () => onSelected(level.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    this.leaves,
  });

  final String label;
  final String semanticLabel;
  final (int, int)? leaves;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : TukiColors.turquoise;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: selected ? TukiColors.turquoise : TukiColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? TukiColors.ink : TukiColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leaves != null) ...[
                    LevelLeaves(
                      step: leaves!.$1,
                      total: leaves!.$2,
                      size: 15,
                      color: foreground,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: tukiText(17, weight: 700, color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyLevel extends StatelessWidget {
  const _EmptyLevel({required this.onShowAll});

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.eco_rounded,
              size: 56,
              color: TukiColors.turquoise,
            ),
            const SizedBox(height: 10),
            Text(
              l.filterEmpty,
              key: const ValueKey('filter-empty'),
              textAlign: TextAlign.center,
              style: tukiText(20, weight: 600),
            ),
            const SizedBox(height: 14),
            TukiPrimaryButton(
              key: const ValueKey('filter-show-all'),
              compact: true,
              label: l.showAll,
              onPressed: onShowAll,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.chapterId,
    required this.page,
    required this.drawing,
    required this.recommended,
  });

  final String chapterId;
  final CatalogPage page;
  final StoredDrawing? drawing;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = contentLanguage(context);
    final title = page.title.of(lang);
    final age = ageLabel(l, page.minAge, page.maxAge);
    final semantics = [
      l.pageCardSemantics(title, page.level.name.of(lang)),
      age,
      if (recommended) l.recommended,
      if (drawing != null) l.inProgress,
    ].join('. ');

    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: TukiCard(
        key: ValueKey('page-${page.id}'),
        selected: recommended,
        onTap: () => Navigator.of(context).push(
          EditorScreen.route(
            chapterId: chapterId,
            pageId: page.id,
            origin: EditorOrigin.pages,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: Center(
                child: DrawingPreview(page: page, drawing: drawing),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tukiText(22, weight: 700, height: 1.15)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LevelBadge(level: page.level),
                      Text(age, style: tukiText(16, weight: 500)),
                    ],
                  ),
                  if (recommended || drawing != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        if (recommended)
                          _Tag(
                            key: ValueKey('recommended-${page.id}'),
                            icon: Icons.star_rounded,
                            text: l.recommended,
                          ),
                        if (drawing != null)
                          _Tag(
                            key: ValueKey('progress-${page.id}'),
                            icon: Icons.brush_rounded,
                            text: l.inProgress,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: TukiColors.turquoise,
              size: 34,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: TukiColors.orange),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: tukiText(15, weight: 600, color: TukiColors.turquoise),
          ),
        ),
      ],
    );
  }
}
