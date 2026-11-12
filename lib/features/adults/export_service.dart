import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/drawings_repository.dart';
import '../chapters/catalog.dart';
import '../editor/drawing_document.dart';
import '../editor/drawing_renderer.dart';
import '../editor/page_template.dart';

enum ExportResult { done, canceled, failed }

/// Diálogos del sistema para sacar una copia. No requieren acceso general a
/// la galería: el sistema entrega solo el destino que elige el adulto.
abstract class ExportGateway {
  Future<ExportResult> save(Uint8List png, String fileName);
  Future<ExportResult> share(Uint8List png, String fileName);
}

class SystemExportGateway implements ExportGateway {
  @override
  Future<ExportResult> save(Uint8List png, String fileName) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: png,
      mimeType: 'image/png',
    );
    return uri == null ? ExportResult.canceled : ExportResult.done;
  }

  @override
  Future<ExportResult> share(Uint8List png, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'export', fileName));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
    );
    return result.status == ShareResultStatus.dismissed
        ? ExportResult.canceled
        : ExportResult.done;
  }
}

enum ExportMode { save, share }

typedef PngRenderer = Future<Uint8List> Function(
  PageTemplate template,
  DrawingDocument document,
);

/// Exporta la obra persistida elegida como PNG (fondo blanco, proporción
/// original, lado mayor de 2.048 px) con el mismo render que el editor.
class ExportService {
  ExportService({
    required this.catalog,
    required this.drawings,
    required this.gateway,
    PngRenderer? render,
  }) : _render = render ?? _defaultRender;

  static Future<Uint8List> _defaultRender(
    PageTemplate template,
    DrawingDocument document,
  ) => DrawingRenderer.toPng(template, document, maxSide: maxSide);

  final PngRenderer _render;

  static const int maxSide = 2048;

  final CatalogRepository catalog;
  final DrawingsRepository drawings;
  final ExportGateway gateway;

  /// PNG de la versión guardada de la lámina indicada.
  Future<Uint8List> renderPng(String chapterId, String pageId) async {
    final chapter = (await catalog.load()).chapterById(chapterId);
    final page = chapter?.pageById(pageId);
    final stored = await drawings.find(chapterId, pageId);
    if (page == null || stored == null) {
      throw StateError('No existe la obra $chapterId/$pageId');
    }
    final template = await catalog.loadTemplate(
      page,
      revision: stored.templateRevision,
    );
    return _render(template, stored.document);
  }

  Future<ExportResult> export(
    String chapterId,
    String pageId,
    ExportMode mode,
  ) async {
    try {
      final png = await renderPng(chapterId, pageId);
      final name = 'tuki-$pageId.png';
      return switch (mode) {
        ExportMode.save => await gateway.save(png, name),
        ExportMode.share => await gateway.share(png, name),
      };
    } catch (_) {
      return ExportResult.failed;
    }
  }
}
