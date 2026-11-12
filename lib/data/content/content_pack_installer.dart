import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Un archivo de un paquete de contenido, con su tamaño y huella esperados.
class PackFile {
  const PackFile({
    required this.path,
    required this.sizeBytes,
    required this.sha256,
  });

  /// Ruta relativa descendente dentro del paquete (p. ej. `pages/x-v1.json`).
  final String path;
  final int sizeBytes;

  /// SHA-256 en hexadecimal, minúsculas.
  final String sha256;
}

/// Descripción versionada de un capítulo descargable.
class PackDescriptor {
  const PackDescriptor({
    required this.chapterId,
    required this.version,
    required this.files,
  });

  final String chapterId;
  final int version;
  final List<PackFile> files;

  factory PackDescriptor.fromJson(Map<String, dynamic> json) {
    final files = json['files'];
    final chapterId = json['chapterId'];
    final version = json['version'];
    if (chapterId is! String || version is! int || files is! List) {
      throw const FormatException('Descriptor de paquete inválido');
    }
    return PackDescriptor(
      chapterId: chapterId,
      version: version,
      files: [
        for (final f in files.cast<Map<String, dynamic>>())
          PackFile(
            path: f['path'] as String,
            sizeBytes: f['size'] as int,
            sha256: (f['sha256'] as String).toLowerCase(),
          ),
      ],
    );
  }
}

/// Origen de los bytes de un paquete. Esta entrega no incluye ninguno de
/// red: el primer capítulo va empaquetado en la app.
abstract class PackFetcher {
  /// Bytes de [file] a partir de [offset] (para reanudar una descarga).
  Stream<List<int>> fetch(PackDescriptor pack, PackFile file, {int offset});
}

class PackIntegrityException implements Exception {
  PackIntegrityException(this.path, this.reason);
  final String path;
  final String reason;
  @override
  String toString() => 'PackIntegrityException($path): $reason';
}

/// Instala paquetes de contenido en almacenamiento privado.
///
/// - Cada archivo se descarga a `*.part` y, si la descarga se corta, el
///   siguiente intento continúa desde los bytes ya recibidos.
/// - Nada se da por instalado sin comprobar tamaño y SHA-256 de cada archivo.
/// - El paquete se publica con un único cambio de nombre de carpeta: una
///   versión está completa o no está.
/// - Las versiones anteriores se conservan hasta que [removeVersion] las
///   retire, para que las obras guardadas con ellas sigan abriéndose.
class ContentPackInstaller {
  ContentPackInstaller(this.root);

  /// Carpeta privada de la app para paquetes.
  final Directory root;

  Directory _staging(PackDescriptor pack) =>
      Directory(p.join(root.path, '.staging', _name(pack)));

  Directory versionDir(String chapterId, int version) =>
      Directory(p.join(root.path, _safe(chapterId), 'v$version'));

  static String _name(PackDescriptor pack) =>
      '${_safe(pack.chapterId)}-v${pack.version}';

  static String _safe(String id) {
    if (!RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(id)) {
      throw PackIntegrityException(id, 'identificador inválido');
    }
    return id;
  }

  static List<String> _segments(String path) {
    final parts = path.split('/');
    if (path.isEmpty ||
        path.contains('\\') ||
        path.contains(':') ||
        parts.any((s) => s.isEmpty || s == '.' || s == '..')) {
      throw PackIntegrityException(path, 'ruta inválida');
    }
    return parts;
  }

  bool isInstalled(String chapterId, int version) =>
      versionDir(chapterId, version).existsSync();

  /// Versiones instaladas de [chapterId], en orden creciente.
  List<int> installedVersions(String chapterId) {
    final dir = Directory(p.join(root.path, _safe(chapterId)));
    if (!dir.existsSync()) return const [];
    final out = <int>[
      for (final e in dir.listSync().whereType<Directory>())
        if (RegExp(r'^v\d+$').hasMatch(p.basename(e.path)))
          int.parse(p.basename(e.path).substring(1)),
    ]..sort();
    return out;
  }

  /// Archivo de una versión instalada, para leer manifiestos y plantillas.
  File installedFile(String chapterId, int version, String path) => File(
    p.joinAll([versionDir(chapterId, version).path, ..._segments(path)]),
  );

  static Future<String> _hash(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();

  /// Descarga, verifica y publica [pack]. Si se interrumpe, lanza el error
  /// del origen y conserva lo descargado; volver a llamar lo reanuda.
  Future<void> install(PackDescriptor pack, PackFetcher fetcher) async {
    if (isInstalled(pack.chapterId, pack.version)) return;
    final staging = _staging(pack);
    for (final file in pack.files) {
      final target = File(p.joinAll([staging.path, ..._segments(file.path)]));
      if (target.existsSync()) continue; // ya verificado en un intento previo
      await target.parent.create(recursive: true);
      final part = File('${target.path}.part');
      var have = part.existsSync() ? part.lengthSync() : 0;
      if (have > file.sizeBytes) {
        part.deleteSync();
        have = 0;
      }
      if (have < file.sizeBytes) {
        // Lo recibido antes de un corte queda en disco para reanudar.
        final out = await part.open(mode: FileMode.append);
        try {
          await for (final chunk in fetcher.fetch(pack, file, offset: have)) {
            await out.writeFrom(chunk);
          }
        } finally {
          await out.close();
        }
      }
      if (part.lengthSync() != file.sizeBytes) {
        // Truncado: se conserva para reanudar. Más largo: se descarta.
        if (part.lengthSync() > file.sizeBytes) part.deleteSync();
        throw PackIntegrityException(file.path, 'tamaño incorrecto');
      }
      if (await _hash(part) != file.sha256) {
        part.deleteSync();
        throw PackIntegrityException(file.path, 'SHA-256 no coincide');
      }
      await part.rename(target.path);
    }
    await File(p.join(staging.path, 'installed.json')).writeAsString(
      jsonEncode({'chapterId': pack.chapterId, 'version': pack.version}),
      flush: true,
    );
    final destination = versionDir(pack.chapterId, pack.version);
    await destination.parent.create(recursive: true);
    await staging.rename(destination.path);
  }

  /// Retira una versión que ya no usa ninguna obra. Nunca borra la más
  /// reciente.
  Future<bool> removeVersion(String chapterId, int version) async {
    final versions = installedVersions(chapterId);
    if (versions.isEmpty || version == versions.last) return false;
    final dir = versionDir(chapterId, version);
    if (!dir.existsSync()) return false;
    await dir.delete(recursive: true);
    return true;
  }
}
