import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../data/local/drawings_repository.dart';
import '../chapters/catalog.dart';
import '../editor/canvas_viewport.dart';
import '../editor/drawing_document.dart';
import '../editor/drawing_renderer.dart';
import '../editor/page_template.dart';

/// Reconsulta las obras guardadas cada vez que cambia el repositorio.
class DrawingsBuilder extends StatefulWidget {
  const DrawingsBuilder({super.key, required this.builder});

  /// `drawings` es `null` mientras carga.
  final Widget Function(BuildContext context, List<StoredDrawing>? drawings)
  builder;

  @override
  State<DrawingsBuilder> createState() => _DrawingsBuilderState();
}

class _DrawingsBuilderState extends State<DrawingsBuilder> {
  DrawingsRepository? _repo;
  List<StoredDrawing>? _drawings;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deps = AppScope.of(context);
    if (!identical(deps.drawings, _repo)) {
      _repo?.changes.removeListener(_reload);
      _repo = deps.drawings..changes.addListener(_reload);
      _reload();
    }
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    final catalog = AppScope.of(context).catalog;
    List<StoredDrawing> list;
    try {
      list = await _repo!.all();
    } catch (_) {
      list = const [];
    }
    // Solo obras cuya lámina sigue en el catálogo.
    list = [
      for (final d in list)
        if (catalog.chapterById(d.chapterId)?.pageById(d.pageId) != null) d,
    ];
    if (mounted && generation == _generation) {
      setState(() => _drawings = list);
    }
  }

  @override
  void dispose() {
    _repo?.changes.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _drawings);
}

/// Miniatura generada a demanda con el mismo render que el editor.
/// Sin [drawing] muestra la lámina en blanco.
class DrawingPreview extends StatefulWidget {
  const DrawingPreview({super.key, required this.page, this.drawing});

  final CatalogPage page;
  final StoredDrawing? drawing;

  @override
  State<DrawingPreview> createState() => _DrawingPreviewState();
}

class _DrawingPreviewState extends State<DrawingPreview> {
  Future<PageTemplate>? _future;
  CatalogRepository? _repo;

  /// Una lámina sin pintar con miniatura propia no necesita cargar la
  /// plantilla: en una lista de 60 tarjetas eso ahorra leer 60 JSON.
  bool get _usesThumbnail =>
      widget.drawing == null && widget.page.thumbnailAsset != null;

  void _resolve() {
    if (_usesThumbnail) {
      _future = null;
      return;
    }
    _future = _repo!.loadTemplate(
      widget.page,
      revision: widget.drawing?.templateRevision,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = AppScope.of(context).catalogRepository;
    if (!identical(repo, _repo)) {
      _repo = repo;
      _resolve();
    }
  }

  @override
  void didUpdateWidget(DrawingPreview old) {
    super.didUpdateWidget(old);
    if (old.page.id != widget.page.id ||
        (old.drawing == null) != (widget.drawing == null) ||
        old.drawing?.templateRevision != widget.drawing?.templateRevision) {
      _resolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_usesThumbnail) {
      return Image.asset(
        widget.page.thumbnailAsset!,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const Icon(
          Icons.image_not_supported_outlined,
          color: TukiColors.turquoise,
          size: 36,
        ),
      );
    }
    return FutureBuilder<PageTemplate>(
      future: _future,
      builder: (context, snapshot) {
        final template = snapshot.data;
        if (template == null) {
          return AspectRatio(
            aspectRatio: 1,
            child: snapshot.hasError
                ? const Icon(
                    Icons.image_not_supported_outlined,
                    color: TukiColors.turquoise,
                    size: 36,
                  )
                : const SizedBox.shrink(),
          );
        }
        return AspectRatio(
          aspectRatio: template.viewBox.width / template.viewBox.height,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _PreviewPainter(
                template,
                widget.drawing?.document ?? DrawingDocument.empty,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.template, this.document);

  final PageTemplate template;
  final DrawingDocument document;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    CanvasViewport(size: size, viewBox: template.viewBox).applyTo(canvas);
    DrawingRenderer.paint(canvas, template, document);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      !identical(old.template, template) || !identical(old.document, document);
}
