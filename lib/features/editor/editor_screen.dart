import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../chapters/catalog.dart';
import '../chapters/pages_screen.dart';
import 'drawing_canvas.dart';
import 'drawing_document.dart';
import 'editor_controller.dart';
import 'editor_tools.dart';
import 'save_coordinator.dart';

/// Pantalla desde la que se abrió el editor. Volver regresa a ella.
enum EditorOrigin { pages, home, gallery }

enum _LoadState { loading, ready, readError, templateMissing }

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.chapterId,
    required this.pageId,
    required this.origin,
  });

  final String chapterId;
  final String pageId;
  final EditorOrigin origin;

  static Route<void> route({
    required String chapterId,
    required String pageId,
    required EditorOrigin origin,
  }) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: 'editor/$chapterId/$pageId'),
      builder: (_) =>
          EditorScreen(chapterId: chapterId, pageId: pageId, origin: origin),
    );
  }

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  _LoadState _state = _LoadState.loading;
  EditorController? _controller;
  SaveCoordinator? _saver;
  late Chapter _chapter;
  late CatalogPage _page;
  bool _started = false;

  // Conserva zoom y gesto al pasar de vertical a horizontal.
  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();
  bool _navigating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final deps = AppScope.of(context);
    _chapter = deps.catalog.chapterById(widget.chapterId)!;
    _page = _chapter.pageById(widget.pageId)!;
    _load();
  }

  Future<void> _load() async {
    final deps = AppScope.of(context);
    setState(() => _state = _LoadState.loading);
    try {
      // Un error de lectura nunca abre un lienzo en blanco: así no se puede
      // sobrescribir la obra guardada.
      final stored = await deps.drawings.find(widget.chapterId, widget.pageId);
      final template = await deps.catalogRepository.loadTemplate(
        _page,
        revision: stored?.templateRevision,
      );
      if (!mounted) return;
      final saver = SaveCoordinator(
        repository: deps.drawings,
        chapterId: widget.chapterId,
        pageId: widget.pageId,
        templateRevision: template.revision,
        existing: stored,
      );
      setState(() {
        _saver = saver;
        _controller = EditorController(
          template: template,
          initial: stored?.document ?? DrawingDocument.empty,
          onCommit: saver.submit,
        );
        _state = _LoadState.ready;
      });
    } on TemplateRevisionMissing {
      if (mounted) setState(() => _state = _LoadState.templateMissing);
    } catch (_) {
      if (mounted) setState(() => _state = _LoadState.readError);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _saver?.dispose();
    super.dispose();
  }

  /// Espera el guardado de la última acción. Si falla, ofrece Reintentar y
  /// mantiene la obra abierta.
  Future<bool> _ensureSaved() async {
    final saver = _saver;
    if (saver == null) return true;
    _controller?.cancelStroke();
    while (true) {
      if (await saver.flush()) return true;
      if (!mounted) return false;
      final l = AppLocalizations.of(context);
      final retry = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.saveErrorTitle),
          content: Text(l.saveErrorBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.keepPainting, style: tukiText(17, weight: 600)),
            ),
            FilledButton(
              key: const ValueKey('dialog-retry'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l.retry,
                style: tukiText(17, weight: 600, color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (retry != true) return false;
      await saver.retry();
    }
  }

  Future<void> _guarded(Future<void> Function(NavigatorState nav) go) async {
    if (_navigating) return;
    _navigating = true;
    try {
      final nav = Navigator.of(context);
      if (await _ensureSaved() && mounted) await go(nav);
    } finally {
      _navigating = false;
    }
  }

  Future<void> _back() => _guarded((nav) async => nav.pop());

  /// Siguiente lámina: guarda y avanza conservando el origen para Volver.
  /// En la última, vuelve a Láminas.
  Future<void> _next() => _guarded((nav) async {
    final next = _chapter.nextPage(widget.pageId);
    if (next != null) {
      await nav.pushReplacement(
        EditorScreen.route(
          chapterId: widget.chapterId,
          pageId: next.id,
          origin: widget.origin,
        ),
      );
    } else if (widget.origin == EditorOrigin.pages) {
      nav.pop();
    } else {
      await nav.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PagesScreen(chapterId: widget.chapterId),
        ),
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = _page.title.of(contentLanguage(context));

    if (_state != _LoadState.ready) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TukiBackHeader(backLabel: l.back, caption: title),
                Expanded(
                  child: Center(
                    child: _state == _LoadState.loading
                        ? const CircularProgressIndicator()
                        : _LoadProblem(
                            templateMissing:
                                _state == _LoadState.templateMissing,
                            onRetry: _load,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller!;
    final saver = _saver!;
    final isLast = _chapter.nextPage(widget.pageId) == null;

    final canvas = Container(
      decoration: BoxDecoration(
        color: TukiColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TukiColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(6),
      child: DrawingCanvas(
        key: _canvasKey,
        controller: controller,
        semanticLabel: l.canvasSemantics(title),
        resetZoomLabel: l.resetZoom,
      ),
    );
    final backButton = TukiRoundButton(
      key: const ValueKey('editor-back'),
      icon: Icons.arrow_back_rounded,
      label: l.back,
      onPressed: _back,
    );
    final undoButton = ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TukiRoundButton(
        key: const ValueKey('editor-undo'),
        icon: Icons.undo_rounded,
        label: l.undo,
        onPressed: controller.canUndo ? controller.undo : null,
      ),
    );
    final nextButton = TukiPrimaryButton(
      key: const ValueKey('editor-next'),
      compact: true,
      label: isLast ? l.backToPages : l.nextPage,
      onPressed: _next,
    );
    final status = SaveStatusView(saver: saver);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          // Los controles admiten texto ampliado, con un tope para que el
          // lienzo conserve espacio para pintar.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > constraints.maxHeight;
                if (wide) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  backButton,
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tukiText(26, weight: 700),
                                      ),
                                    ),
                                  ),
                                  undoButton,
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(child: canvas),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: (constraints.maxWidth * 0.32).clamp(
                            250.0,
                            340.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: TukiColors.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: TukiColors.divider,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(12),
                                    child: EditorToolPanel(
                                      controller: controller,
                                      vertical: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              status,
                              const SizedBox(height: 6),
                              nextButton,
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          backButton,
                          const SizedBox(width: 8),
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: TukiTitleBadge(title),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          undoButton,
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: canvas),
                      const SizedBox(height: 8),
                      // Con texto muy ampliado los controles se desplazan;
                      // el lienzo conserva al menos la mitad del alto.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * 0.5,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              EditorToolPanel(
                                controller: controller,
                                vertical: false,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(child: status),
                                  const SizedBox(width: 8),
                                  Flexible(flex: 2, child: nextButton),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadProblem extends StatelessWidget {
  const _LoadProblem({required this.templateMissing, required this.onRetry});

  final bool templateMissing;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sentiment_dissatisfied_rounded,
            size: 64,
            color: TukiColors.turquoise,
          ),
          const SizedBox(height: 12),
          Text(
            l.loadErrorTitle,
            textAlign: TextAlign.center,
            style: tukiText(24, weight: 700),
          ),
          const SizedBox(height: 8),
          Text(
            templateMissing ? l.templateMissingBody : l.loadErrorBody,
            textAlign: TextAlign.center,
            style: tukiText(18),
          ),
          const SizedBox(height: 16),
          if (!templateMissing)
            TukiPrimaryButton(
              compact: true,
              label: l.retry,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(l.back, style: tukiText(18, weight: 600)),
          ),
        ],
      ),
    );
  }
}

class SaveStatusView extends StatelessWidget {
  const SaveStatusView({super.key, required this.saver});

  final SaveCoordinator saver;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: saver,
      builder: (context, _) {
        final status = saver.status;
        if (status == SaveStatus.clean && !saver.exists) {
          return const SizedBox(height: 48);
        }
        final (IconData icon, String text, Color color) = switch (status) {
          SaveStatus.saving => (
            Icons.sync_rounded,
            l.saveSaving,
            TukiColors.turquoise,
          ),
          SaveStatus.error => (
            Icons.error_outline_rounded,
            l.saveError,
            TukiColors.error,
          ),
          _ => (Icons.check_rounded, l.saveSaved, TukiColors.turquoise),
        };
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Semantics(
                liveRegion: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        text,
                        key: const ValueKey('save-status'),
                        style: tukiText(17, weight: 600, color: color),
                      ),
                    ),
                  ],
                ),
              ),
              if (status == SaveStatus.error)
                TextButton(
                  key: const ValueKey('save-retry'),
                  onPressed: saver.retry,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: TukiColors.turquoise,
                  ),
                  child: Text(
                    l.retry,
                    style: tukiText(
                      17,
                      weight: 700,
                      color: TukiColors.turquoise,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
