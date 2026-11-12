// Niveles de dificultad, edad sugerida, recomendaciones, curiosidades,
// derechos de acceso y control de adultos.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuki_little_adventures/data/local/drawings_repository.dart';
import 'package:tuki_little_adventures/data/local/preferences.dart';
import 'package:tuki_little_adventures/features/adults/age_setup.dart';
import 'package:tuki_little_adventures/features/chapters/catalog.dart';
import 'package:tuki_little_adventures/features/chapters/cover_screen.dart';
import 'package:tuki_little_adventures/features/chapters/recommendation.dart';
import 'package:tuki_little_adventures/features/editor/drawing_canvas.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';
import 'package:tuki_little_adventures/features/editor/editor_controller.dart';
import 'package:tuki_little_adventures/features/store/adventures_screen.dart';
import 'package:tuki_little_adventures/features/store/entitlements.dart';

import 'app_flow_test.dart' show chapter, goBack, loadFonts, pumpApp;
import 'support/assets.dart';
import 'support/fakes.dart';

const catalogAsset = 'assets/chapters/catalog.json';
const chapterAsset = 'assets/chapters/bosque-nuboso/chapter.json';
const extraAsset = 'assets/chapters/bosque-nuboso/extra.json';

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Assets reales con algunos archivos JSON sustituidos.
AssetStringLoader assetsWith(Map<String, Map<String, dynamic>> overrides) {
  final base = preloadedAssets();
  return (path) => overrides.containsKey(path)
      ? Future.value(jsonEncode(overrides[path]))
      : base(path);
}

/// Catálogo con un segundo capítulo de pago y un paquete que lo incluye.
AssetStringLoader assetsWithPaidChapter() => assetsWith({
  catalogAsset: readJson(catalogAsset)
    ..['chapters'] = ['bosque-nuboso/chapter.json', 'bosque-nuboso/extra.json']
    ..['bundles'] = [
      {
        'productId': 'tuki.complete',
        'chapters': ['extra'],
      },
    ],
  extraAsset: readJson(chapterAsset)
    ..['id'] = 'extra'
    ..['title'] = {'es': 'La costa', 'en': 'The Coast'}
    ..['access'] = {'type': 'pack', 'productId': 'pack.extra'},
});

class FakePurchaseGateway implements PurchaseGateway {
  @override
  bool available = true;
  PurchaseResult next = PurchaseResult.purchased;
  Set<String> owned = {};
  bool failRestore = false;
  final List<String> bought = [];

  @override
  Future<PurchaseResult> buy(String productId) async {
    bought.add(productId);
    return next;
  }

  @override
  Future<Set<String>> ownedProducts() async {
    if (failRestore) throw const SocketException('sin red');
    return owned;
  }
}

Future<void> openPages(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('explore-$chapter')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('cover-color')));
  await tester.pumpAndSettle();
}

/// Desplaza «Para adultos» hasta dejar a la vista la entrada a Aventuras.
Future<void> showAdventuresEntry(WidgetTester tester) async {
  final entry = find.byKey(const ValueKey('adventures-open'));
  await tester.scrollUntilVisible(
    entry,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(entry);
  await tester.pumpAndSettle();
}

Finder card(String page) => find.byKey(ValueKey('page-$page'));

/// Responde al control de adultos leyendo la pregunta mostrada.
Future<void> answerGate(WidgetTester tester, {bool correct = true}) async {
  final question = tester.widget<Text>(find.textContaining('¿Cuánto es')).data!;
  final m = RegExp(r'(\d+) × (\d+)').firstMatch(question)!;
  final answer = int.parse(m[1]!) * int.parse(m[2]!);
  await tester.enterText(
    find.byKey(const ValueKey('adult-gate-input')),
    '${correct ? answer : answer + 1}',
  );
  await tester.tap(find.byKey(const ValueKey('adult-gate-ok')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  group('catálogo: niveles y metadatos', () {
    late Catalog catalog;
    late Chapter forest;

    setUpAll(() async {
      catalog = await diskCatalog().load();
      forest = catalog.chapterById(chapter)!;
    });

    test('cuatro niveles con su edad sugerida, de menor a mayor', () {
      expect(catalog.levels.map((l) => (l.id, l.minAge, l.maxAge)), [
        ('easy', 2, 4),
        ('medium', 4, 6),
        ('detailed', 6, 8),
        ('advanced', 8, null),
      ]);
      expect(catalog.levels.map((l) => l.name.of('es')), [
        'Fácil',
        'Medio',
        'Detallado',
        'Avanzado',
      ]);
      expect(catalog.levels.map((l) => l.name.of('en')), [
        'Easy',
        'Medium',
        'Detailed',
        'Advanced',
      ]);
      expect(catalog.ageRanges.map((r) => (r.id, r.recommendedLevelId)), [
        ('2-4', 'easy'),
        ('4-6', 'medium'),
        ('6-8', 'detailed'),
        ('8+', 'advanced'),
      ]);
    });

    test('el capítulo declara 15 láminas: 5 por nivel, con estado real', () {
      final all = [
        for (final p in forest.pages) (p.id, p.level.id),
        for (final p in forest.plannedPages) (p.id, p.level.id),
      ];
      expect(all.length, 15);
      expect(all.map((e) => e.$1).toSet().length, 15, reason: 'ids únicos');
      for (final level in ['easy', 'medium', 'detailed']) {
        expect(all.where((e) => e.$2 == level).length, 5, reason: level);
      }
      // Solo se ofrecen las láminas con arte integrado.
      expect(forest.pages.map((p) => p.id), [
        'rana-en-la-hoja',
        'quetzal',
        'sendero',
      ]);
      expect(forest.plannedPages.length, 12);
      expect(forest.access.isFree, true);
    });

    test('cada lámina disponible tiene metadatos completos y bilingües', () {
      for (final p in forest.pages) {
        expect(p.chapterId, chapter);
        expect(p.contentVersion, greaterThanOrEqualTo(1));
        expect(p.minAge, p.level.minAge);
        expect(p.maxAge, p.level.maxAge);
        for (final lang in kLanguages) {
          expect(p.title.of(lang), isNotEmpty);
          expect(p.description!.values[lang], isNotEmpty, reason: p.id);
          expect(p.funFact!.values[lang], isNotEmpty, reason: p.id);
        }
        // Ninguna ruta de narración apunta a un archivo que no existe.
        for (final asset in p.funFactAudioAssets.values) {
          expect(File(asset).existsSync(), true, reason: asset);
        }
      }
    });

    test(
      'un manifiesto anterior, sin niveles ni edades, sigue cargando',
      () async {
        final legacy = readJson(chapterAsset)
          ..remove('contentVersion')
          ..remove('access');
        legacy['pages'] = [
          for (final p
              in (legacy['pages'] as List).cast<Map<String, dynamic>>())
            if (p['status'] != 'planned')
              {
                'id': p['id'],
                'difficulty': p['difficulty'],
                'title': p['title'],
                'template': p['template'],
              },
        ];
        final old = await CatalogRepository(
          assetsWith({
            catalogAsset: {
              'schemaVersion': 1,
              'chapters': ['bosque-nuboso/chapter.json'],
            },
            chapterAsset: legacy,
          }),
        ).load();
        expect(old.levels, kDefaultLevels);
        expect(old.contentVersion, 1);
        final c = old.chapters.single;
        expect(c.pages.map((p) => p.level.id), ['easy', 'medium', 'detailed']);
        expect(c.pages.every((p) => p.funFact == null), true);
        expect(c.access.isFree, true);
      },
    );

    test('se puede añadir un nivel sin tocar la app', () async {
      final index = readJson(catalogAsset);
      (index['levels'] as List).add({
        'id': 'expert',
        'order': 5,
        'name': {'es': 'Experto', 'en': 'Expert'},
        'minAge': 10,
      });
      final manifest = readJson(chapterAsset);
      (manifest['pages'] as List)
              .cast<Map<String, dynamic>>()
              .last['difficulty'] =
          'expert';
      final c = await CatalogRepository(
        assetsWith({catalogAsset: index, chapterAsset: manifest}),
      ).load();
      expect(c.levels.length, 5);
      expect(c.chapters.single.pages.last.level.id, 'expert');
      expect(c.chapters.single.pages.last.minAge, 10);
    });

    test('rechaza niveles, estados y paquetes inválidos', () async {
      Future<void> bad(Map<String, Map<String, dynamic>> o) => expectLater(
        CatalogRepository(assetsWith(o)).load(),
        throwsA(isA<CatalogFormatException>()),
      );
      final manifest = readJson(chapterAsset);
      (manifest['pages'] as List).cast<Map<String, dynamic>>()[1]['status'] =
          'borrador';
      await bad({chapterAsset: manifest});
      await bad({
        catalogAsset: readJson(catalogAsset)
          ..['ageRanges'] = [
            {'id': 'x', 'minAge': 2, 'recommendedLevel': 'no-existe'},
          ],
      });
      // Un paquete no puede prometer capítulos que no están en el catálogo.
      await bad({
        catalogAsset: readJson(catalogAsset)
          ..['bundles'] = [
            {
              'productId': 'tuki.complete',
              'chapters': ['capitulo-futuro'],
            },
          ],
      });
    });
  });

  group('recomendación', () {
    late Catalog catalog;
    late Chapter forest;

    setUpAll(() async {
      catalog = await diskCatalog().load();
      forest = catalog.chapterById(chapter)!;
    });

    List<String> order(String? age, {String? filter}) => [
      for (final p in PageRecommender(
        catalog,
        ageRangeId: age,
      ).pagesFor(forest, levelId: filter))
        p.id,
    ];

    test('sin edad: todas, por dificultad creciente y sin filtro', () {
      expect(order(null), ['rana-en-la-hoja', 'quetzal', 'sendero']);
      final r = PageRecommender(catalog);
      expect(r.recommendedLevel, isNull);
      expect(r.initialFilter(forest), isNull);
    });

    test('2–4 años: primero las fáciles, con su filtro sugerido', () {
      expect(order('2-4'), ['rana-en-la-hoja', 'quetzal', 'sendero']);
      expect(
        PageRecommender(catalog, ageRangeId: '2-4').initialFilter(forest),
        'easy',
      );
    });

    test('6–8 años: primero las detalladas; el resto sigue disponible', () {
      expect(order('6-8'), ['sendero', 'quetzal', 'rana-en-la-hoja']);
      expect(order('4-6').first, 'quetzal');
      expect(order('6-8', filter: 'easy'), ['rana-en-la-hoja']);
      final r = PageRecommender(catalog, ageRangeId: '6-8');
      expect(r.isRecommended(forest.pageById('sendero')!), true);
      expect(r.isRecommended(forest.pageById('quetzal')!), false);
    });

    test('8+ sin láminas avanzadas: no se preselecciona un filtro vacío', () {
      final r = PageRecommender(catalog, ageRangeId: '8+');
      expect(r.recommendedLevel!.id, 'advanced');
      expect(r.initialFilter(forest), isNull);
      expect(order('8+'), ['sendero', 'quetzal', 'rana-en-la-hoja']);
      expect(order('8+', filter: 'advanced'), isEmpty);
    });

    test('un rango desconocido se trata como sin preferencia', () {
      expect(order('99'), ['rana-en-la-hoja', 'quetzal', 'sendero']);
    });
  });

  group('preferencia de edad', () {
    test('se guarda solo el rango y sobrevive a reabrir la app', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.load(deviceLocale: const Locale('es'));
      expect(prefs.ageSetupDone, false);
      expect(prefs.ageRangeId, isNull);
      var notified = 0;
      prefs.addListener(() => notified++);

      await prefs.setAgeRange('4-6');
      expect(notified, 1);
      final store = await SharedPreferences.getInstance();
      expect(store.getKeys(), {'ageRange', 'ageSetupDone'});
      expect(store.getString('ageRange'), '4-6');

      final reopened = await AppPreferences.load(
        deviceLocale: const Locale('es'),
      );
      expect(reopened.ageRangeId, '4-6');
      expect(reopened.ageSetupDone, true);

      await reopened.setAgeRange(null);
      expect(store.containsKey('ageRange'), false);
      expect(reopened.ageSetupDone, true);
    });
  });

  group('configuración inicial', () {
    testWidgets('elegir 6–8 años lleva a Inicio y preselecciona Detallado', (
      tester,
    ) async {
      final h = await TestHarness.create(firstRun: true);
      await pumpApp(tester, h);

      expect(find.byType(AgeSetupScreen), findsOneWidget);
      expect(find.text('¿Para qué edad buscas aventuras?'), findsOneWidget);
      for (final t in [
        '2–4 años',
        '4–6 años',
        '6–8 años',
        '8+ años',
        'Prefiero no indicar',
      ]) {
        expect(find.text(t), findsOneWidget);
      }
      // No se pide ningún dato personal.
      expect(find.byType(TextField), findsNothing);
      // Sin elección no se puede continuar, pero sí omitir.
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: find.byKey(const ValueKey('age-continue')),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('age-6-8')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('age-continue')));
      await tester.tap(find.byKey(const ValueKey('age-continue')));
      await tester.pumpAndSettle();

      expect(find.byType(AgeSetupScreen), findsNothing);
      expect(find.text('Explorar'), findsOneWidget);
      expect(h.deps.preferences.ageRangeId, '6-8');

      await openPages(tester);
      expect(card('sendero'), findsOneWidget);
      expect(card('quetzal'), findsNothing);
      expect(card('rana-en-la-hoja'), findsNothing);

      // El filtro sugerido se cambia con un toque: nada queda bloqueado.
      await tester.tap(find.byKey(const ValueKey('filter-all')));
      await tester.pumpAndSettle();
      final tops = [
        for (final p in ['sendero', 'quetzal', 'rana-en-la-hoja'])
          tester.getTopLeft(card(p)).dy,
      ];
      expect(tops[0] < tops[1] && tops[1] < tops[2], true);
      expect(find.byKey(const ValueKey('recommended-sendero')), findsOneWidget);
      expect(find.byKey(const ValueKey('recommended-quetzal')), findsNothing);

      // Una lámina fuera del rango sugerido se abre igual.
      await tester.tap(find.byKey(const ValueKey('filter-easy')));
      await tester.pumpAndSettle();
      await tester.tap(card('rana-en-la-hoja'));
      await tester.pumpAndSettle();
      expect(find.byType(DrawingCanvas), findsOneWidget);
    });

    testWidgets('omitir no guarda edad y muestra todo en orden creciente', (
      tester,
    ) async {
      final h = await TestHarness.create(firstRun: true);
      await pumpApp(tester, h);
      await tester.tap(find.byKey(const ValueKey('age-skip')));
      await tester.pumpAndSettle();

      expect(find.text('Explorar'), findsOneWidget);
      expect(h.deps.preferences.ageRangeId, isNull);
      expect(h.deps.preferences.ageSetupDone, true);

      await openPages(tester);
      final tops = [
        for (final p in ['rana-en-la-hoja', 'quetzal', 'sendero'])
          tester.getTopLeft(card(p)).dy,
      ];
      expect(tops[0] < tops[1] && tops[1] < tops[2], true);
      expect(find.text('Sugerida'), findsNothing);
    });

    testWidgets('«Prefiero no indicar» equivale a no tener preferencia', (
      tester,
    ) async {
      final h = await TestHarness.create(firstRun: true);
      await pumpApp(tester, h);
      await tester.tap(find.byKey(const ValueKey('age-none')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('age-continue')));
      await tester.tap(find.byKey(const ValueKey('age-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Explorar'), findsOneWidget);
      expect(h.deps.preferences.ageRangeId, isNull);
    });

    testWidgets('no vuelve a aparecer en la siguiente apertura', (
      tester,
    ) async {
      final h = await TestHarness.create(
        firstRun: true,
        prefs: {'ageSetupDone': true, 'ageRange': '2-4'},
      );
      await pumpApp(tester, h);
      expect(find.byType(AgeSetupScreen), findsNothing);
      expect(find.text('Explorar'), findsOneWidget);
    });
  });

  group('Elige una lámina', () {
    testWidgets('filtros Todas | Fácil | Medio | Detallado | Avanzado', (
      tester,
    ) async {
      final h = await TestHarness.create();
      await pumpApp(tester, h);
      await openPages(tester);

      for (final id in ['all', 'easy', 'medium', 'detailed', 'advanced']) {
        expect(find.byKey(ValueKey('filter-$id')), findsOneWidget);
      }
      expect(find.text('Todas'), findsOneWidget);
      // Cada tarjeta: nombre, nivel y edad sugerida.
      for (final (page, age) in [
        ('rana-en-la-hoja', '2–4 años'),
        ('quetzal', '4–6 años'),
        ('sendero', '6–8 años'),
      ]) {
        expect(
          find.descendant(of: card(page), matching: find.text(age)),
          findsOneWidget,
        );
      }

      await tester.tap(find.byKey(const ValueKey('filter-medium')));
      await tester.pumpAndSettle();
      expect(card('quetzal'), findsOneWidget);
      expect(card('rana-en-la-hoja'), findsNothing);
      expect(card('sendero'), findsNothing);

      // Nivel sin láminas todavía: aviso y vuelta a Todas.
      await tester.ensureVisible(find.byKey(const ValueKey('filter-advanced')));
      await tester.tap(find.byKey(const ValueKey('filter-advanced')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('filter-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('page-quetzal')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('filter-show-all')));
      await tester.pumpAndSettle();
      expect(card('rana-en-la-hoja'), findsOneWidget);
      expect(card('sendero'), findsOneWidget);
    });

    testWidgets('con 2–4 años el filtro Fácil llega seleccionado', (
      tester,
    ) async {
      final h = await TestHarness.create(prefs: {'ageRange': '2-4'});
      await pumpApp(tester, h);
      await openPages(tester);
      expect(card('rana-en-la-hoja'), findsOneWidget);
      expect(card('quetzal'), findsNothing);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('filter-easy'))),
        isSemantics(
          label: 'Filtro: Nivel Fácil, 1 de 4',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
        ),
      );
    });

    testWidgets('las obras guardadas antes siguen ahí y marcan progreso', (
      tester,
    ) async {
      // Fila tal como la escribió la versión anterior de la app.
      final repo = MemoryDrawingsRepository();
      await repo.save(
        DrawingSnapshot(
          drawingId: 'd1',
          chapterId: chapter,
          pageId: 'sendero',
          templateRevision: 1,
          saveRevision: 3,
          document: const DrawingDocument(fills: {'cielo': 0x1E88E5}),
          updatedAt: DateTime.utc(2026, 11, 1),
        ),
      );
      final h = await TestHarness.create(drawings: repo);
      await pumpApp(tester, h);
      expect(find.text('Continuar mi dibujo'), findsOneWidget);

      await openPages(tester);
      expect(find.byKey(const ValueKey('progress-sendero')), findsOneWidget);
      expect(find.byKey(const ValueKey('progress-quetzal')), findsNothing);

      await tester.tap(card('sendero'));
      await tester.pumpAndSettle();
      expect(find.byType(DrawingCanvas), findsOneWidget);
      expect(repo.rows['$chapter/sendero']!.document.fills, {
        'cielo': 0x1E88E5,
      });
      expect(repo.rows['$chapter/sendero']!.saveRevision, 3);
    });

    testWidgets('en inglés: niveles y edades traducidos', (tester) async {
      final h = await TestHarness.create(prefs: {'language': 'en'});
      await pumpApp(tester, h);
      await openPages(tester);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(
        find.descendant(
          of: card('rana-en-la-hoja'),
          matching: find.text('Easy'),
        ),
        findsOneWidget,
      );
      expect(find.text('Ages 2–4'), findsOneWidget);
      expect(find.text('The Forest Trail'), findsOneWidget);
    });
  });

  group('área de adultos: edad sugerida', () {
    testWidgets('se cambia y se guarda al momento', (tester) async {
      final h = await TestHarness.create(prefs: {'ageRange': '2-4'});
      await pumpApp(tester, h);
      await tester.tap(find.byKey(const ValueKey('settings')));
      await tester.pumpAndSettle();

      expect(find.text('Edad sugerida'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('age-2-4'))),
        isSemantics(
          label: '2–4 años. Fácil',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
        ),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('age-6-8')));
      await tester.tap(find.byKey(const ValueKey('age-6-8')));
      await tester.pumpAndSettle();
      expect(h.deps.preferences.ageRangeId, '6-8');
      expect(
        (await SharedPreferences.getInstance()).getString('ageRange'),
        '6-8',
      );

      await tester.ensureVisible(find.byKey(const ValueKey('age-none')));
      await tester.tap(find.byKey(const ValueKey('age-none')));
      await tester.pumpAndSettle();
      expect(h.deps.preferences.ageRangeId, isNull);
    });
  });

  group('editor según el nivel de la lámina', () {
    test('tolerancia táctil: un toque junto a una figura la rellena', () {
      final frog = loadTemplateFile('rana-en-la-hoja-v1.json');
      const nearDrop = Offset(277, 310); // fondo, a ~12 unidades de la gota
      expect(frog.regionAt(nearDrop), 'fondo');
      expect(frog.regionNear(nearDrop, 25), 'gota-1');
      // Lejos de cualquier figura sigue siendo el fondo.
      expect(frog.regionNear(const Offset(500, 100), 25), 'fondo');
      // Un toque exacto sobre una figura no cambia.
      expect(frog.regionNear(const Offset(700, 342), 25), 'ojo');
      expect(frog.regionNear(const Offset(-5, 10), 25), isNull);

      final easy = EditorController(template: frog, touchTolerance: 0.025);
      expect(easy.fillAt(nearDrop), true);
      expect(easy.document.fills.keys, ['gota-1']);
      final exact = EditorController(template: frog);
      expect(exact.fillAt(nearDrop), true);
      expect(exact.document.fills.keys, ['fondo']);
    });

    testWidgets('fácil: paleta corta ampliable; medio: paleta completa', (
      tester,
    ) async {
      // La preferencia de edad no decide el editor: lo decide la lámina.
      final h = await TestHarness.create(prefs: {'ageRange': '6-8'});
      await pumpApp(tester, h);
      await openPages(tester);
      await tester.tap(find.byKey(const ValueKey('filter-all')));
      await tester.pumpAndSettle();
      await tester.tap(card('rana-en-la-hoja'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('palette-more')), findsOneWidget);
      expect(find.byKey(const ValueKey('color-e53935')), findsOneWidget);
      expect(find.byKey(const ValueKey('color-26a69a')), findsNothing);
      // Todas las herramientas siguen disponibles.
      for (final tool in ['fill', 'brush', 'eraser']) {
        expect(find.byKey(ValueKey('tool-$tool')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('editor-undo')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('palette-more')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('palette-more')), findsNothing);
      expect(find.byKey(const ValueKey('color-fb8c00')), findsOneWidget);

      // Siguiente lámina: el quetzal (medio) abre con la paleta completa.
      await tester.tap(find.byKey(const ValueKey('editor-next')));
      await tester.pumpAndSettle();
      expect(find.text('El quetzal'), findsOneWidget);
      expect(find.byKey(const ValueKey('palette-more')), findsNothing);
      expect(find.byKey(const ValueKey('color-fb8c00')), findsOneWidget);
    });
  });

  group('curiosidades', () {
    testWidgets('se abre a petición, en el idioma activo y sin audio', (
      tester,
    ) async {
      final h = await TestHarness.create();
      await pumpApp(tester, h);
      await openPages(tester);
      await tester.tap(card('quetzal'));
      await tester.pumpAndSettle();
      final tracksBefore = h.audio.tracks.length;

      expect(find.byKey(const ValueKey('fun-fact-text')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('editor-fun-fact')));
      await tester.pumpAndSettle();
      expect(find.text('¿Sabías que…?'), findsOneWidget);
      expect(
        find.text(
          'El quetzal vive en bosques húmedos y tiene unas plumas de cola '
          'muy largas.',
        ),
        findsOneWidget,
      );
      // Sin narración grabada no se ofrece Escuchar ni se crea ninguna pista.
      expect(find.byKey(const ValueKey('fun-fact-listen')), findsNothing);
      expect(h.audio.tracks.length, tracksBefore);

      await h.deps.preferences.setLanguage('en');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The quetzal lives in humid forests and has very long tail '
          'feathers.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('fun-fact-close')));
      await tester.pumpAndSettle();
      expect(find.byType(DrawingCanvas), findsOneWidget);
    });

    testWidgets('con narración: Escuchar la reproduce y cerrar la libera', (
      tester,
    ) async {
      final manifest = readJson(chapterAsset);
      (manifest['pages'] as List).cast<Map<String, dynamic>>().firstWhere(
        (p) => p['id'] == 'quetzal',
      )['funFactAudio'] = {
        'es': 'audio/quetzal_es.mp3',
        'en': 'audio/quetzal_en.mp3',
      };
      final h = await TestHarness.create(
        assets: assetsWith({chapterAsset: manifest}),
      );
      await pumpApp(tester, h);
      await openPages(tester);
      await tester.tap(card('quetzal'));
      await tester.pumpAndSettle();
      final tracksBefore = h.audio.tracks.length;

      await tester.tap(find.byKey(const ValueKey('editor-fun-fact')));
      await tester.pumpAndSettle();
      // Abrir la curiosidad no reproduce nada.
      expect(h.audio.tracks.length, tracksBefore);
      expect(find.text('Escuchar'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('fun-fact-listen')));
      await tester.pumpAndSettle();
      final track = h.audio.tracks.last;
      expect(h.audio.tracks.length, tracksBefore + 1);
      expect(track.asset, endsWith('bosque-nuboso/audio/quetzal_es.mp3'));
      expect(track.playing, true);
      expect(find.text('Pausar'), findsOneWidget);

      track.finish();
      await tester.pumpAndSettle();
      expect(find.text('Escuchar'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('fun-fact-close')));
      await tester.pumpAndSettle();
      expect(track.disposed, true);
    });

    testWidgets('con la narración desactivada no hay botón de audio', (
      tester,
    ) async {
      final manifest = readJson(chapterAsset);
      (manifest['pages'] as List)
          .cast<Map<String, dynamic>>()
          .first['funFactAudio'] = {
        'es': 'audio/rana_es.mp3',
        'en': 'audio/rana_en.mp3',
      };
      final h = await TestHarness.create(
        prefs: {'narrationEnabled': false},
        assets: assetsWith({chapterAsset: manifest}),
      );
      await pumpApp(tester, h);
      await openPages(tester);
      await tester.tap(card('rana-en-la-hoja'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('editor-fun-fact')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fun-fact-text')), findsOneWidget);
      expect(find.byKey(const ValueKey('fun-fact-listen')), findsNothing);
    });
  });

  group('derechos de acceso', () {
    Future<(Catalog, Entitlements, FakePurchaseGateway)> setup({
      Map<String, Object> prefs = const {},
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      final catalog = await CatalogRepository(assetsWithPaidChapter()).load();
      final gateway = FakePurchaseGateway();
      return (
        catalog,
        await Entitlements.load(catalog: catalog, gateway: gateway),
        gateway,
      );
    }

    test('gratis siempre abierto; de pago cerrado hasta comprarlo', () async {
      final (catalog, e, gateway) = await setup();
      final free = catalog.chapterById(chapter)!;
      final paid = catalog.chapterById('extra')!;
      expect(e.isUnlocked(free), true);
      expect(e.isUnlocked(paid), false);

      gateway.next = PurchaseResult.canceled;
      expect(await e.buy('pack.extra'), PurchaseResult.canceled);
      expect(e.isUnlocked(paid), false);

      gateway.next = PurchaseResult.purchased;
      expect(await e.buy('pack.extra'), PurchaseResult.purchased);
      expect(e.isUnlocked(paid), true);

      // La compra queda guardada: el capítulo abre sin conexión.
      final offline = await Entitlements.load(
        catalog: catalog,
        gateway: const DisabledPurchaseGateway(),
      );
      expect(offline.isUnlocked(paid), true);
    });

    test('un paquete desbloquea solo los capítulos que enumera', () async {
      final (catalog, e, _) = await setup();
      final paid = catalog.chapterById('extra')!;
      expect(e.bundlesFor(paid).single.chapterIds, ['extra']);
      expect(await e.buy('tuki.complete'), PurchaseResult.purchased);
      expect(e.isUnlocked(paid), true);
    });

    test('sin tienda no se puede comprar', () async {
      SharedPreferences.setMockInitialValues({});
      final catalog = await CatalogRepository(assetsWithPaidChapter()).load();
      final e = await Entitlements.load(
        catalog: catalog,
        gateway: const DisabledPurchaseGateway(),
      );
      expect(e.storeAvailable, false);
      expect(await e.buy('pack.extra'), PurchaseResult.unavailable);
      expect(e.isUnlocked(catalog.chapterById('extra')!), false);
      expect(await e.restore(), false);
    });

    test('restaurar suma compras y un fallo de red no retira nada', () async {
      final (catalog, e, gateway) = await setup(
        prefs: {
          'ownedProducts': ['pack.extra'],
        },
      );
      final paid = catalog.chapterById('extra')!;
      expect(e.isUnlocked(paid), true);
      gateway.failRestore = true;
      expect(await e.restore(), false);
      expect(e.isUnlocked(paid), true);
      gateway
        ..failRestore = false
        ..owned = {'tuki.complete'};
      expect(await e.restore(), true);
      expect(e.isUnlocked(paid), true);
    });
  });

  group('control de adultos y área comercial', () {
    Future<void> openAdults(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('settings')));
      await tester.pumpAndSettle();
      await showAdventuresEntry(tester);
      await tester.tap(find.byKey(const ValueKey('adventures-open')));
      await tester.pumpAndSettle();
    }

    testWidgets('Aventuras solo se abre con la respuesta correcta', (
      tester,
    ) async {
      final h = await TestHarness.create();
      await pumpApp(tester, h);
      await openAdults(tester);

      expect(find.text('Solo para adultos'), findsOneWidget);
      expect(find.byType(AdventuresScreen), findsNothing);
      await answerGate(tester, correct: false);
      expect(find.text('No es correcto. Inténtalo de nuevo.'), findsOneWidget);
      expect(find.byType(AdventuresScreen), findsNothing);

      await tester.tap(find.byKey(const ValueKey('adult-gate-cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(AdventuresScreen), findsNothing);
      expect(find.byKey(const ValueKey('adventures-open')), findsOneWidget);

      await showAdventuresEntry(tester);
      await tester.tap(find.byKey(const ValueKey('adventures-open')));
      await tester.pumpAndSettle();
      await answerGate(tester);
      expect(find.byType(AdventuresScreen), findsOneWidget);

      // Estado real del catálogo, sin precios ni botones de compra.
      expect(find.text('Incluido gratis'), findsOneWidget);
      expect(find.text('3 de 15 láminas disponibles'), findsOneWidget);
      expect(find.text('TUKI no muestra anuncios.'), findsOneWidget);
      expect(find.text('Comprar'), findsNothing);
    });

    testWidgets('capítulo de pago: Inicio lleva al control, no al contenido', (
      tester,
    ) async {
      final gateway = FakePurchaseGateway();
      final h = await TestHarness.create(
        assets: assetsWithPaidChapter(),
        gateway: gateway,
      );
      await pumpApp(tester, h);

      final locked = find.byKey(const ValueKey('explore-extra'));
      await tester.ensureVisible(locked);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: locked, matching: find.text('Para adultos')),
        findsOneWidget,
      );
      await tester.tap(locked);
      await tester.pumpAndSettle();
      expect(find.byType(CoverScreen), findsNothing);
      expect(find.text('Solo para adultos'), findsOneWidget);
      expect(gateway.bought, isEmpty);

      await answerGate(tester);
      expect(find.byType(AdventuresScreen), findsOneWidget);
      expect(find.text('No incluido'), findsOneWidget);
      expect(find.text('Incluye: La costa'), findsOneWidget);

      gateway.next = PurchaseResult.canceled;
      await tester.ensureVisible(find.byKey(const ValueKey('buy-pack.extra')));
      await tester.tap(find.byKey(const ValueKey('buy-pack.extra')));
      await tester.pumpAndSettle();
      expect(find.text('Compra cancelada.'), findsOneWidget);
      expect(find.text('No incluido'), findsOneWidget);

      gateway.next = PurchaseResult.purchased;
      await tester.ensureVisible(find.byKey(const ValueKey('buy-pack.extra')));
      await tester.tap(find.byKey(const ValueKey('buy-pack.extra')));
      await tester.pumpAndSettle();
      expect(gateway.bought, ['pack.extra', 'pack.extra']);
      expect(find.text('Desbloqueado'), findsOneWidget);
      expect(find.text('Comprar'), findsNothing);

      await goBack(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(locked);
      await tester.pumpAndSettle();
      await tester.tap(locked);
      await tester.pumpAndSettle();
      expect(find.byType(CoverScreen), findsOneWidget);
    });

    testWidgets('sin tienda: el capítulo de pago no ofrece compra', (
      tester,
    ) async {
      final h = await TestHarness.create(assets: assetsWithPaidChapter());
      await pumpApp(tester, h);
      await openAdults(tester);
      await answerGate(tester);
      expect(find.text('No incluido'), findsOneWidget);
      expect(
        find.text('Las compras no están disponibles en esta versión.'),
        findsOneWidget,
      );
      expect(find.text('Comprar'), findsNothing);
    });
  });

  group('sin publicidad ni rastreo', () {
    // SDK de anuncios, analítica, atribución y compras (nombre o prefijo).
    const banned = [
      'google_mobile_ads',
      'firebase',
      'facebook',
      'appsflyer',
      'adjust_sdk',
      'amplitude',
      'mixpanel',
      'sentry',
      'unity_ads',
      'applovin',
      'in_app_purchase',
      'webview_flutter',
    ];
    // Clientes de red y de enlaces externos que la app podría llamar.
    const bannedExact = ['http', 'dio', 'url_launcher'];

    test('ninguna dependencia de anuncios, analítica, red o compras', () {
      final packages = RegExp(r'^  ([a-z0-9_]+):$', multiLine: true)
          .allMatches(File('pubspec.lock').readAsStringSync())
          .map((m) => m[1]!)
          .toSet();
      expect(packages, isNotEmpty);
      for (final name in packages) {
        expect(
          bannedExact.contains(name) ||
              banned.any((b) => name == b || name.startsWith('${b}_')),
          false,
          reason: name,
        );
      }
    });

    test('la app no declara permisos de publicidad ni seguimiento', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      for (final p in [
        'AD_ID',
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'RECORD_AUDIO',
        'CAMERA',
        'READ_CONTACTS',
      ]) {
        expect(manifest.contains(p), false, reason: p);
      }
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      for (final k in [
        'NSUserTrackingUsageDescription',
        'NSLocationWhenInUseUsageDescription',
        'NSCameraUsageDescription',
        'NSMicrophoneUsageDescription',
        'SKAdNetworkItems',
      ]) {
        expect(plist.contains(k), false, reason: k);
      }
    });

    test('el código de la app no contiene direcciones web', () {
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        expect(
          RegExp(r'https?://').hasMatch(f.readAsStringSync()),
          false,
          reason: f.path,
        );
      }
    });
  });
}
