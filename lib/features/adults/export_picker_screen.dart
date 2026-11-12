import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../data/local/drawings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../gallery/drawing_preview.dart';
import 'export_service.dart';

/// El adulto elige una obra guardada y saca una copia PNG con un diálogo
/// del sistema. Cancelar no cambia nada.
class ExportPickerScreen extends StatefulWidget {
  const ExportPickerScreen({super.key});

  @override
  State<ExportPickerScreen> createState() => _ExportPickerScreenState();
}

class _ExportPickerScreenState extends State<ExportPickerScreen> {
  String? _selectedPageKey;
  bool _busy = false;

  // El resultado se muestra sobre los botones, sin taparlos.
  ExportResult? _result;

  static String _key(StoredDrawing d) => '${d.chapterId}/${d.pageId}';

  Future<void> _export(StoredDrawing drawing, ExportMode mode) async {
    final exporter = AppScope.of(context).exporter;
    setState(() {
      _busy = true;
      _result = null;
    });
    final result = await exporter.export(
      drawing.chapterId,
      drawing.pageId,
      mode,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = contentLanguage(context);
    final catalog = AppScope.of(context).catalog;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: DrawingsBuilder(
                builder: (context, drawings) {
                  StoredDrawing? selected;
                  for (final d in drawings ?? const <StoredDrawing>[]) {
                    if (_key(d) == _selectedPageKey) selected = d;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TukiBackHeader(backLabel: l.back, caption: l.adultsTitle),
                      const SizedBox(height: 14),
                      Semantics(
                        header: true,
                        child: Text(
                          l.exportDrawing,
                          style: tukiText(28, weight: 700),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: drawings == null
                            ? const Center(child: CircularProgressIndicator())
                            : drawings.isEmpty
                            ? Center(
                                child: Text(
                                  l.exportEmpty,
                                  key: const ValueKey('export-empty'),
                                  textAlign: TextAlign.center,
                                  style: tukiText(19),
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                children: [
                                  Text(l.exportChoose, style: tukiText(18)),
                                  const SizedBox(height: 10),
                                  for (final d in drawings) ...[
                                    _Choice(
                                      key: ValueKey('export-${d.pageId}'),
                                      drawing: d,
                                      title: catalog
                                          .chapterById(d.chapterId)!
                                          .pageById(d.pageId)!
                                          .title
                                          .of(lang),
                                      selected: _key(d) == _selectedPageKey,
                                      onTap: () => setState(
                                        () => _selectedPageKey = _key(d),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                      ),
                      if (drawings != null && drawings.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        if (_busy)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: LinearProgressIndicator(),
                          ),
                        if (_result != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                switch (_result!) {
                                  ExportResult.done => l.exportDone,
                                  ExportResult.canceled => l.exportCanceled,
                                  ExportResult.failed => l.exportFailed,
                                },
                                key: const ValueKey('export-result'),
                                textAlign: TextAlign.center,
                                style: tukiText(
                                  17,
                                  weight: 600,
                                  color: _result == ExportResult.failed
                                      ? TukiColors.error
                                      : TukiColors.turquoise,
                                ),
                              ),
                            ),
                          ),
                        TukiPrimaryButton(
                          key: const ValueKey('export-save'),
                          compact: true,
                          icon: Icons.save_alt_rounded,
                          label: l.exportSave,
                          onPressed: selected == null || _busy
                              ? null
                              : () => _export(selected!, ExportMode.save),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const ValueKey('export-share'),
                          onPressed: selected == null || _busy
                              ? null
                              : () => _export(selected!, ExportMode.share),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(64, 52),
                            foregroundColor: TukiColors.turquoise,
                            side: const BorderSide(
                              color: TukiColors.turquoise,
                              width: 2,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: Text(
                            l.exportShare,
                            style: tukiText(
                              19,
                              weight: 700,
                              color: TukiColors.turquoise,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.drawing,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final StoredDrawing drawing;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final page = AppScope.of(context).catalog
        .chapterById(drawing.chapterId)!
        .pageById(drawing.pageId)!;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      child: TukiCard(
        selected: selected,
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Center(
                child: DrawingPreview(page: page, drawing: drawing),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: tukiText(21, weight: 700))),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: TukiColors.turquoise,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
