import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../data/local/drawings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../adults/adults_screen.dart';
import '../editor/editor_screen.dart';
import '../gallery/drawing_preview.dart';
import '../gallery/gallery_view.dart';
import '../store/adventures_screen.dart';
import 'catalog.dart';
import 'cover_screen.dart';

/// Inicio: alterna entre Capítulos y Mis dibujos.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  const _ChaptersView(),
                  GalleryView(
                    onExploreChapters: () => setState(() => _tab = 0),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _TabBar(
                index: _tab,
                labels: [l.tabChapters, l.tabGallery],
                icons: const [Icons.menu_book_rounded, Icons.image_rounded],
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.index,
    required this.labels,
    required this.icons,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: TukiColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TukiColors.divider),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                label: labels[i],
                excludeSemantics: true,
                child: Material(
                  color: i == index ? TukiColors.turquoise : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('tab-$i'),
                    onTap: () => onChanged(i),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 60),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icons[i],
                              size: 28,
                              color: i == index
                                  ? Colors.white
                                  : TukiColors.turquoise,
                            ),
                            Text(
                              labels[i],
                              textAlign: TextAlign.center,
                              style: tukiText(
                                17,
                                weight: 700,
                                color: i == index
                                    ? Colors.white
                                    : TukiColors.turquoise,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChaptersView extends StatelessWidget {
  const _ChaptersView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final deps = AppScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => DrawingsBuilder(
        builder: (context, drawings) {
          final latest = drawings == null || drawings.isEmpty
              ? null
              : drawings.first;
          // Con «Continuar mi dibujo» la ilustración cede espacio para que
          // todo quepa sin desplazarse en un teléfono.
          final imageHeight =
              (constraints.maxHeight * (latest == null ? 0.48 : 0.31)).clamp(
                150.0,
                460.0,
              );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(child: _Brand()),
                        const SizedBox(width: 12),
                        TukiRoundButton(
                          key: const ValueKey('settings'),
                          icon: Icons.settings_rounded,
                          label: l.settings,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AdultsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(l.homeSubtitle, style: tukiText(17, weight: 500)),
                    const SizedBox(height: 12),
                    for (final chapter in deps.catalog.chapters) ...[
                      _ChapterCard(chapter: chapter, imageHeight: imageHeight),
                      const SizedBox(height: 12),
                    ],
                    if (latest != null) _ContinueCard(drawing: latest),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: kBrandName,
      excludeSemantics: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: TukiColors.turquoise,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TUKI',
                style: tukiText(
                  40,
                  weight: 700,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              Text(
                'Little Adventures',
                style: tukiText(
                  19,
                  weight: 600,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.imageHeight});

  final Chapter chapter;
  final double imageHeight;

  void _open(BuildContext context) {
    // Un capítulo no incluido solo lleva al área protegida para adultos.
    if (!AppScope.of(context).entitlements.isUnlocked(chapter)) {
      openAdventures(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CoverScreen(chapterId: chapter.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = chapter.title.of(contentLanguage(context));
    final unlocked = AppScope.of(context).entitlements.isUnlocked(chapter);
    return Container(
      decoration: BoxDecoration(
        color: TukiColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: GestureDetector(
                onTap: () => _open(context),
                child: Image.asset(
                  chapter.coverAsset,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.2, 0.25),
                ),
              ),
            ),
            Container(
              color: TukiColors.turquoise,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: tukiText(28, weight: 700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TukiPrimaryButton(
                    key: ValueKey('explore-${chapter.id}'),
                    label: unlocked ? l.explore : l.adultsTitle,
                    icon: unlocked ? Icons.brush_rounded : Icons.lock_rounded,
                    onPressed: () => _open(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.drawing});

  final StoredDrawing drawing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final page = AppScope.of(context).catalog
        .chapterById(drawing.chapterId)!
        .pageById(drawing.pageId)!;
    return Semantics(
      button: true,
      label: l.continueDrawing,
      child: TukiCard(
        key: const ValueKey('continue-drawing'),
        onTap: () => Navigator.of(context).push(
          EditorScreen.route(
            chapterId: drawing.chapterId,
            pageId: drawing.pageId,
            origin: EditorOrigin.home,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 84,
              child: Center(
                child: ExcludeSemantics(
                  child: DrawingPreview(page: page, drawing: drawing),
                ),
              ),
            ),
            Container(
              width: 2,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: TukiColors.divider,
            ),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  l.continueDrawing,
                  style: tukiText(
                    24,
                    weight: 700,
                    color: TukiColors.turquoise,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
