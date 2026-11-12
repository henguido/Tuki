import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../data/local/drawings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../editor/editor_screen.dart';
import 'drawing_preview.dart';

/// Mis dibujos: obras guardadas, ordenadas por última edición.
class GalleryView extends StatelessWidget {
  const GalleryView({super.key, required this.onExploreChapters});

  final VoidCallback onExploreChapters;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l.tabGallery, style: tukiText(30, weight: 700)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: DrawingsBuilder(
              builder: (context, drawings) {
                if (drawings == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (drawings.isEmpty) {
                  return _Empty(onExploreChapters: onExploreChapters);
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = (constraints.maxWidth / 380).ceil().clamp(
                      1,
                      4,
                    );
                    const gap = 14.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final d in drawings)
                            SizedBox(
                              width: width,
                              child: _DrawingCard(drawing: d),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onExploreChapters});

  final VoidCallback onExploreChapters;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.palette_rounded,
              size: 84,
              color: TukiColors.turquoise,
            ),
            const SizedBox(height: 12),
            Text(
              l.galleryEmpty,
              key: const ValueKey('gallery-empty'),
              textAlign: TextAlign.center,
              style: tukiText(20),
            ),
            const SizedBox(height: 18),
            TukiPrimaryButton(
              key: const ValueKey('gallery-explore'),
              label: l.exploreChapters,
              icon: Icons.menu_book_rounded,
              compact: true,
              onPressed: onExploreChapters,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawingCard extends StatelessWidget {
  const _DrawingCard({required this.drawing});

  final StoredDrawing drawing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = contentLanguage(context);
    final chapter = AppScope.of(context).catalog
        .chapterById(drawing.chapterId)!;
    final page = chapter.pageById(drawing.pageId)!;
    final title = page.title.of(lang);

    void open() => Navigator.of(context).push(
      EditorScreen.route(
        chapterId: drawing.chapterId,
        pageId: drawing.pageId,
        origin: EditorOrigin.gallery,
      ),
    );

    return TukiCard(
      key: ValueKey('gallery-${drawing.pageId}'),
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            image: true,
            label: l.drawingSemantics(title),
            child: SizedBox(
              height: 220,
              child: Center(
                child: DrawingPreview(page: page, drawing: drawing),
              ),
            ),
          ),
          const Divider(color: TukiColors.divider),
          Text(title, style: tukiText(22, weight: 700)),
          Text(chapter.title.of(lang), style: tukiText(15)),
          const SizedBox(height: 10),
          TukiPrimaryButton(
            compact: true,
            icon: Icons.brush_rounded,
            label: l.keepColoring,
            onPressed: open,
          ),
        ],
      ),
    );
  }
}
