import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../data/local/drawings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../editor/editor_screen.dart';
import '../gallery/drawing_preview.dart';
import 'catalog.dart';

String difficultyLabel(AppLocalizations l, Difficulty d) => switch (d) {
  Difficulty.easy => l.difficultyEasy,
  Difficulty.medium => l.difficultyMedium,
  Difficulty.detailed => l.difficultyDetailed,
};

/// Selección de lámina: tres tarjetas disponibles desde el principio.
class PagesScreen extends StatelessWidget {
  const PagesScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = contentLanguage(context);
    final chapter = AppScope.of(context).catalog.chapterById(chapterId)!;

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
                  const SizedBox(height: 14),
                  Semantics(
                    header: true,
                    child: Text(l.choosePage, style: tukiText(28, weight: 700)),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: DrawingsBuilder(
                      builder: (context, drawings) => ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16, top: 2),
                        itemCount: chapter.pages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final page = chapter.pages[i];
                          StoredDrawing? drawing;
                          for (final d in drawings ?? const <StoredDrawing>[]) {
                            if (d.chapterId == chapterId &&
                                d.pageId == page.id) {
                              drawing = d;
                            }
                          }
                          return _PageCard(
                            chapterId: chapterId,
                            page: page,
                            drawing: drawing,
                          );
                        },
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

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.chapterId,
    required this.page,
    required this.drawing,
  });

  final String chapterId;
  final CatalogPage page;
  final StoredDrawing? drawing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = page.title.of(contentLanguage(context));
    final difficulty = difficultyLabel(l, page.difficulty);
    final chipColor = switch (page.difficulty) {
      Difficulty.easy => TukiColors.selectedTint,
      Difficulty.medium => const Color(0xFFFFE2B8),
      Difficulty.detailed => const Color(0xFFFFD3C7),
    };

    return Semantics(
      button: true,
      label: l.pageCardSemantics(title, difficulty),
      excludeSemantics: true,
      child: TukiCard(
        key: ValueKey('page-${page.id}'),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(difficulty, style: tukiText(16, weight: 600)),
                  ),
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
