import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuki_little_adventures/features/chapters/catalog.dart';
import 'package:tuki_little_adventures/features/editor/page_template.dart';

import 'support/assets.dart';

/// Catálogo en memoria para probar la validación.
CatalogRepository memoryCatalog(Map<String, Object> files) =>
    CatalogRepository((path) async {
      final v = files[path];
      if (v == null) throw FileSystemException('no existe', path);
      return v is String ? v : jsonEncode(v);
    });

Map<String, dynamic> validChapter() => {
  'schemaVersion': 1,
  'id': 'c1',
  'cover': 'cover.webp',
  'title': {'es': 'T', 'en': 'T'},
  'intro': {'es': 'I', 'en': 'I'},
  'narration': {'es': 'a/es.mp3', 'en': 'a/en.mp3'},
  'ambience': 'a/amb.mp3',
  'pages': [
    {
      'id': 'p1',
      'difficulty': 'easy',
      'title': {'es': 'P', 'en': 'P'},
      'template': 'pages/p1-v2.json',
      'previousTemplates': {'1': 'pages/p1-v1.json'},
    },
  ],
};

Map<String, dynamic> validTemplate({int revision = 1}) => {
  'schemaVersion': 1,
  'revision': revision,
  'viewBox': [0, 0, 100, 100],
  'regions': [
    {'id': 'a', 'path': 'M0 0 L50 0 L50 50 L0 50 Z'},
  ],
  'outlines': [
    {'path': 'M0 0 L50 0', 'width': 2},
  ],
};

Map<String, Object> files({
  Map<String, dynamic>? chapter,
  Map<String, dynamic>? template,
}) => {
  'assets/chapters/catalog.json': {
    'schemaVersion': 1,
    'chapters': ['c1/chapter.json'],
  },
  'assets/chapters/c1/chapter.json': chapter ?? validChapter(),
  'assets/chapters/c1/pages/p1-v2.json': template ?? validTemplate(revision: 2),
  'assets/chapters/c1/pages/p1-v1.json': validTemplate(revision: 1),
};

void main() {
  group('assets empaquetados', () {
    late Catalog catalog;
    late CatalogRepository repo;

    setUpAll(() async {
      repo = legacyCatalog();
      catalog = await repo.load();
    });

    test('el capítulo declara las tres láminas en orden', () {
      expect(catalog.chapters.map((c) => c.id), ['bosque-nuboso']);
      final chapter = catalog.chapters.single;
      expect(chapter.pages.map((p) => p.id), [
        'rana-en-la-hoja',
        'quetzal',
        'sendero',
      ]);
      expect(chapter.pages.map((p) => p.level.id), [
        'easy',
        'medium',
        'detailed',
      ]);
      expect(chapter.title.of('es'), 'El bosque nuboso');
      expect(chapter.title.of('en'), 'The Cloud Forest');
      expect(chapter.nextPage('rana-en-la-hoja')!.id, 'quetzal');
      expect(chapter.nextPage('quetzal')!.id, 'sendero');
      expect(chapter.nextPage('sendero'), isNull);
    });

    test('todas las rutas declaradas existen y están en pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final chapter in catalog.chapters) {
        final assets = [
          chapter.coverAsset,
          chapter.ambienceAsset,
          ...chapter.narrationAssets.values,
          for (final p in chapter.pages) ...[
            p.templateAsset,
            ...p.previousTemplateAssets.values,
          ],
        ];
        for (final asset in assets) {
          final file = File(asset);
          expect(file.existsSync(), true, reason: asset);
          expect(file.lengthSync(), greaterThan(0), reason: asset);
          final dir = asset.substring(0, asset.lastIndexOf('/') + 1);
          expect(pubspec.contains('- $dir'), true, reason: 'pubspec: $dir');
        }
        expect(chapter.narrationAssets.keys.toSet(), {'es', 'en'});
      }
    });

    test('las plantillas son válidas y su dificultad crece', () async {
      final counts = <int>[];
      for (final page in catalog.chapters.single.pages) {
        final t = await repo.loadTemplate(page);
        expect(t.revision, 1, reason: page.id);
        expect(t.viewBox.width > 0 && t.viewBox.height > 0, true);
        expect(t.regions.map((r) => r.id).toSet().length, t.regions.length);
        expect(t.outlines, isNotEmpty);
        for (final r in t.regions) {
          final b = r.path.getBounds();
          expect(b.isEmpty, false, reason: '${page.id}/${r.id}');
          expect(b.isFinite, true, reason: '${page.id}/${r.id}');
          // Cada región es alcanzable: algún punto la selecciona.
          expect(
            _someVisiblePoint(t, r.id),
            true,
            reason: '${page.id}/${r.id} queda tapada por completo',
          );
        }
        counts.add(t.regions.length);
      }
      expect(counts[0] < counts[1] && counts[1] < counts[2], true);
    });

    test('la interfaz está traducida por completo en ARB', () {
      Map<String, dynamic> arb(String f) =>
          jsonDecode(File('lib/l10n/$f').readAsStringSync())
              as Map<String, dynamic>;
      Set<String> keys(Map<String, dynamic> m) =>
          m.keys.where((k) => !k.startsWith('@')).toSet();
      final es = arb('app_es.arb'), en = arb('app_en.arb');
      expect(keys(en), keys(es));
      for (final k in keys(es)) {
        expect((es[k] as String).trim(), isNotEmpty, reason: k);
        expect((en[k] as String).trim(), isNotEmpty, reason: k);
      }
    });
  });

  group('validación del contrato', () {
    Future<void> expectInvalid(Map<String, Object> f, {bool template = false}) {
      final repo = memoryCatalog(f);
      return expectLater(
        () async {
          final c = await repo.load();
          if (template) await repo.loadTemplate(c.chapters.first.pages.first);
        },
        throwsA(
          anyOf(isA<CatalogFormatException>(), isA<TemplateFormatException>()),
        ),
      );
    }

    test('acepta un catálogo válido', () async {
      final repo = memoryCatalog(files());
      final c = await repo.load();
      expect(
        c.chapters.single.pages.single.templateAsset,
        'assets/chapters/c1/pages/p1-v2.json',
      );
      expect(c.chapters.single.coverAsset, 'assets/chapters/c1/cover.webp');
    });

    test('rechaza versiones de esquema desconocidas', () async {
      await expectInvalid(
        files(chapter: validChapter()..['schemaVersion'] = 2),
      );
      await expectInvalid(
        files(template: validTemplate()..['schemaVersion'] = 9),
        template: true,
      );
      await expectInvalid({
        ...files(),
        'assets/chapters/catalog.json': {'schemaVersion': 3, 'chapters': []},
      });
    });

    test('rechaza traducciones incompletas', () async {
      await expectInvalid(
        files(chapter: validChapter()..['title'] = {'es': 'T'}),
      );
      await expectInvalid(
        files(chapter: validChapter()..['intro'] = {'es': 'I', 'en': '  '}),
      );
      await expectInvalid(
        files(chapter: validChapter()..['narration'] = {'en': 'a.mp3'}),
      );
    });

    test('rechaza IDs repetidos y dificultades desconocidas', () async {
      final page = (validChapter()['pages'] as List).first as Map;
      await expectInvalid(
        files(chapter: validChapter()..['pages'] = [page, page]),
      );
      await expectInvalid(
        files(
          chapter: validChapter()
            ..['pages'] = [
              {...page, 'difficulty': 'imposible'},
            ],
        ),
      );
      await expectInvalid(
        files(
          template: validTemplate()
            ..['regions'] = [
              {'id': 'a', 'path': 'M0 0 L5 0 L5 5 Z'},
              {'id': 'a', 'path': 'M0 0 L5 0 L5 5 Z'},
            ],
        ),
        template: true,
      );
    });

    test('rechaza rutas que salen del directorio', () async {
      await expectInvalid(
        files(chapter: validChapter()..['cover'] = '../cover.webp'),
      );
      await expectInvalid(
        files(chapter: validChapter()..['ambience'] = '/abs.mp3'),
      );
    });

    test('rechaza plantillas con geometría inválida', () async {
      final cases = <Map<String, dynamic>>[
        validTemplate()..['viewBox'] = [0, 0, 0, 100],
        validTemplate()..['viewBox'] = [0, 0, -5, 100],
        validTemplate()..['viewBox'] = [0, 0, 100],
        validTemplate()..['revision'] = 0,
        validTemplate()
          ..['regions'] = [
            {'id': 'abierta', 'path': 'M0 0 L50 0 L50 50'},
          ],
        validTemplate()
          ..['regions'] = [
            {'id': 'arco', 'path': 'M0 0 A5 5 0 0 1 9 9 Z'},
          ],
        validTemplate()..['regions'] = [],
        validTemplate()
          ..['outlines'] = [
            {'path': 'M0 0 L5 5', 'width': 0},
          ],
        validTemplate()
          ..['outlines'] = [
            {'path': 'M0 0 L1e999 5', 'width': 1},
          ],
      ];
      for (final t in cases) {
        await expectInvalid(files(template: t), template: true);
      }
    });

    test('resuelve plantillas por revisión y avisa si falta', () async {
      final repo = memoryCatalog(files());
      final page = (await repo.load()).chapters.single.pages.single;
      expect((await repo.loadTemplate(page)).revision, 2);
      expect((await repo.loadTemplate(page, revision: 2)).revision, 2);
      // La revisión anterior sigue accesible para obras ya guardadas.
      expect((await repo.loadTemplate(page, revision: 1)).revision, 1);
      await expectLater(
        repo.loadTemplate(page, revision: 7),
        throwsA(isA<TemplateRevisionMissing>()),
      );
    });
  });
}

bool _someVisiblePoint(PageTemplate t, String id) {
  final region = t.regions.firstWhere((r) => r.id == id);
  final b = region.path.getBounds().intersect(t.viewBox);
  const steps = 60;
  for (var i = 0; i <= steps; i++) {
    for (var j = 0; j <= steps; j++) {
      final p = Offset(
        b.left + b.width * i / steps,
        b.top + b.height * j / steps,
      );
      if (t.regionAt(p) == id) return true;
    }
  }
  return false;
}
