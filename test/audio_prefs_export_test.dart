import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuki_little_adventures/app/theme.dart';
import 'package:tuki_little_adventures/data/local/drawings_repository.dart';
import 'package:tuki_little_adventures/data/local/preferences.dart';
import 'package:tuki_little_adventures/features/adults/export_service.dart';
import 'package:tuki_little_adventures/features/chapters/audio/chapter_audio_controller.dart';
import 'package:tuki_little_adventures/features/editor/drawing_document.dart';
import 'package:tuki_little_adventures/features/editor/drawing_renderer.dart';
import 'package:tuki_little_adventures/features/editor/page_template.dart';

import 'editor_engine_test.dart' show pointIn;
import 'support/assets.dart';
import 'support/fakes.dart';

const es = 'audio/intro_es.mp3', en = 'audio/intro_en.mp3';
const amb = 'audio/bosque.mp3';

void main() {
  group('audio de la portada (A08)', () {
    late FakeAudioEngine engine;
    late ChapterAudioController audio;

    setUp(() async {
      engine = FakeAudioEngine();
      audio = ChapterAudioController(
        engine: engine,
        narrationAsset: es,
        ambienceAsset: amb,
      );
      await pumpEventQueue();
    });

    test('no reproduce nada sin interacción y deja la voz preparada', () {
      expect(engine.narration.asset, es);
      expect(engine.narration.playing, false);
      expect(engine.ambience.playing, false);
      expect(engine.activations, 0);
      expect(audio.narrationStatus, TrackStatus.ready);
      expect(audio.ambienceStatus, TrackStatus.ready);
    });

    test(
      'los dos controles son independientes y alternan reproducir/pausar',
      () async {
        await audio.toggleAmbience();
        expect(engine.ambience.playing, true);
        expect(engine.ambience.looping, true);
        expect(engine.narration.playing, false);
        expect(audio.ambienceStatus, TrackStatus.playing);

        await audio.toggleNarration();
        expect(engine.narration.playing, true);
        expect(engine.narration.looping, false);
        await audio.toggleAmbience();
        expect(engine.ambience.playing, false);
        expect(engine.narration.playing, true);
        await audio.toggleNarration();
        expect(engine.narration.playing, false);
        expect(audio.narrationStatus, TrackStatus.ready);
      },
    );

    test(
      'el ambiente baja con la voz y se restaura al pausar o terminar',
      () async {
        await audio.toggleAmbience();
        expect(engine.ambience.volume, ChapterAudioController.ambienceVolume);
        await audio.toggleNarration();
        expect(engine.ambience.volume, ChapterAudioController.duckedVolume);
        await audio.toggleNarration(); // pausa
        expect(engine.ambience.volume, ChapterAudioController.ambienceVolume);

        await audio.toggleNarration();
        expect(engine.ambience.volume, ChapterAudioController.duckedVolume);
        engine.narration.finish(); // la voz termina sola
        await pumpEventQueue();
        expect(audio.narrationStatus, TrackStatus.ready);
        expect(engine.ambience.volume, ChapterAudioController.ambienceVolume);
        expect(
          engine.ambience.playing,
          true,
          reason: 'el ambiente sigue en bucle',
        );
      },
    );

    test('activar el ambiente durante la voz empieza ya atenuado', () async {
      await audio.toggleNarration();
      await audio.toggleAmbience();
      expect(engine.ambience.volume, ChapterAudioController.duckedVolume);
    });

    test(
      'stopAll detiene ambas pistas y solo se reanuda por el usuario',
      () async {
        await audio.toggleAmbience();
        await audio.toggleNarration();
        await audio.stopAll(); // salir de la portada o segundo plano
        expect(engine.narration.playing, false);
        expect(engine.ambience.playing, false);
        expect(audio.narrationStatus, TrackStatus.ready);
        expect(audio.ambienceStatus, TrackStatus.ready);
        await pumpEventQueue();
        expect(engine.narration.playing, false);
        await audio.toggleAmbience();
        expect(engine.ambience.playing, true);
        expect(engine.ambience.volume, ChapterAudioController.ambienceVolume);
      },
    );

    test('una interrupción del sistema detiene ambas pistas', () async {
      await audio.toggleAmbience();
      await audio.toggleNarration();
      engine.interruptionsController.add(null);
      await pumpEventQueue();
      expect(engine.narration.playing, false);
      expect(engine.ambience.playing, false);
      expect(audio.ambienceStatus, TrackStatus.ready);
    });

    test(
      'al cambiar de idioma detiene la voz y prepara la nueva pista',
      () async {
        await audio.toggleAmbience();
        await audio.toggleNarration();
        await audio.setNarrationAsset(en);
        expect(engine.narration.playing, false);
        expect(engine.narration.asset, en);
        expect(audio.narrationStatus, TrackStatus.ready);
        expect(engine.ambience.playing, true);
        expect(engine.ambience.volume, ChapterAudioController.ambienceVolume);
        await audio.toggleNarration();
        expect(engine.narration.playing, true);
        expect(engine.narration.asset, en);
      },
    );

    test(
      'si falta una pista se marca no disponible y la otra funciona',
      () async {
        engine.missingAssets.add(en);
        await audio.setNarrationAsset(en);
        expect(audio.narrationStatus, TrackStatus.unavailable);
        await audio.toggleNarration();
        expect(engine.narration.playing, false);
        await audio.toggleAmbience();
        expect(audio.ambienceStatus, TrackStatus.playing);
        expect(engine.ambience.volume, ChapterAudioController.ambienceVolume);
        // Volver a un idioma con pista la recupera.
        await audio.setNarrationAsset(es);
        expect(audio.narrationStatus, TrackStatus.ready);

        final broken = FakeAudioEngine()..missingAssets.add(amb);
        final other = ChapterAudioController(
          engine: broken,
          narrationAsset: es,
          ambienceAsset: amb,
        );
        await other.toggleAmbience();
        expect(other.ambienceStatus, TrackStatus.unavailable);
        await other.toggleNarration();
        expect(other.narrationStatus, TrackStatus.playing);
      },
    );

    test('dispose libera los reproductores', () async {
      await audio.toggleAmbience();
      audio.dispose();
      await pumpEventQueue();
      expect(engine.narration.disposed, true);
      expect(engine.ambience.disposed, true);
      expect(engine.ambience.playing, false);
    });
  });

  group('preferencias', () {
    Future<AppPreferences> load(
      String device, [
      Map<String, Object> v = const {},
    ]) {
      SharedPreferences.setMockInitialValues(v);
      return AppPreferences.load(deviceLocale: Locale(device));
    }

    test(
      'primera apertura: idioma del dispositivo si es es/en, si no español',
      () async {
        expect((await load('es')).languageCode, 'es');
        expect((await load('en')).languageCode, 'en');
        expect((await load('fr')).languageCode, 'es');
        expect((await load('de')).languageCode, 'es');
      },
    );

    test('la elección persiste al reiniciar y avisa a la interfaz', () async {
      final prefs = await load('es');
      var notified = 0;
      prefs.addListener(() => notified++);
      await prefs.setLanguage('en');
      await prefs.setNarrationEnabled(false);
      expect(notified, 2);
      // «Reinicio»: nueva instancia sobre el mismo almacenamiento.
      final again = await AppPreferences.load(deviceLocale: const Locale('es'));
      expect(again.languageCode, 'en');
      expect(again.narrationEnabled, false);
      expect(again.ambienceEnabled, true);
    });
  });

  group('exportación PNG (A09)', () {
    late PageTemplate frog;
    late TestHarness h;
    const leafGreen = 0x7CB342, red = 0xE53935;

    Future<ui.Image> decode(WidgetTester tester, List<int> png) async {
      late ui.Image image;
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
        image = (await codec.getNextFrame()).image;
      });
      return image;
    }

    Future<int> pixel(WidgetTester tester, ui.Image image, Offset p) async {
      late int rgb;
      await tester.runAsync(() async {
        final data = (await image.toByteData())!;
        final i = (p.dy.round() * image.width + p.dx.round()) * 4;
        rgb =
            (data.getUint8(i) << 16) |
            (data.getUint8(i + 1) << 8) |
            data.getUint8(i + 2);
      });
      return rgb;
    }

    setUp(() async {
      frog = loadTemplateFile('rana-en-la-hoja-v1.json');
      h = await TestHarness.create();
    });

    testWidgets(
      'contiene la obra guardada con fondo blanco y lado mayor 2048',
      (tester) async {
        final leaf = pointIn(frog, 'hoja');
        final body = pointIn(frog, 'cuerpo');
        final document = DrawingDocument(
          fills: {'hoja': leafGreen, 'cuerpo': red},
        );
        await h.drawings.save(
          DrawingSnapshot(
            drawingId: 'x',
            chapterId: 'bosque-nuboso',
            pageId: 'rana-en-la-hoja',
            templateRevision: 1,
            saveRevision: 1,
            document: document,
            updatedAt: DateTime.utc(2026),
          ),
        );

        late ExportResult result;
        await tester.runAsync(() async {
          result = await h.deps.exporter.export(
            'bosque-nuboso',
            'rana-en-la-hoja',
            ExportMode.save,
          );
        });
        expect(result, ExportResult.done);
        final (name, png) = h.gateway.saved.single;
        expect(name, 'tuki-rana-en-la-hoja.png');
        expect(png.sublist(1, 4), 'PNG'.codeUnits);

        final image = await decode(tester, png);
        expect(image.width, 2048);
        expect(image.height, 2048);
        const k = 2.048;
        expect(await pixel(tester, image, leaf * k), leafGreen);
        expect(await pixel(tester, image, body * k), red);
        // El ojo no se rellenó: se exporta blanco, igual que el fondo.
        final eye = frog.regions.firstWhere((r) => r.id == 'ojo');
        final eyeCorner = eye.path.getBounds().center - const Offset(30, 30);
        expect(frog.regionAt(eyeCorner), 'ojo');
        expect(await pixel(tester, image, eyeCorner * k), 0xFFFFFF);
        expect(await pixel(tester, image, const Offset(4, 4)), 0xFFFFFF);
      },
    );

    testWidgets('conserva la proporción original en láminas verticales', (
      tester,
    ) async {
      final quetzal = loadTemplateFile('quetzal-v1.json');
      final size = DrawingRenderer.pixelSize(quetzal, 2048);
      expect(size.height, 2048);
      expect(size.width, (2048 * 1000 / 1200).round());
      late List<int> png;
      await tester.runAsync(() async {
        png = await DrawingRenderer.toPng(
          quetzal,
          DrawingDocument.empty,
          maxSide: 512,
        );
      });
      final image = await decode(tester, png);
      expect(image.height, 512);
      expect(image.width, 427);
    });

    testWidgets('el pincel y el borrador se exportan como en el editor', (
      tester,
    ) async {
      // pointIn garantiza 8 unidades libres de bordes y contornos.
      final body = pointIn(frog, 'cuerpo');
      final document = DrawingDocument(
        fills: {'cuerpo': red},
        ops: [
          StrokeOp(
            kind: StrokeKind.brush,
            color: 0x1E88E5,
            width: 14,
            points: [body],
          ),
          StrokeOp(
            kind: StrokeKind.eraser,
            width: 4,
            points: [body + const Offset(4, 0)],
          ),
        ],
      );
      late List<int> png;
      await tester.runAsync(() async {
        png = await DrawingRenderer.toPng(frog, document, maxSide: 1000);
      });
      final image = await decode(tester, png);
      // Trazo azul sobre el relleno.
      expect(await pixel(tester, image, body - const Offset(4, 0)), 0x1E88E5);
      expect(await pixel(tester, image, body + const Offset(0, 4)), 0x1E88E5);
      // Zona borrada: reaparece el relleno, no el blanco.
      expect(await pixel(tester, image, body + const Offset(4, 0)), red);
    });

    testWidgets('cancelar no exporta nada ni cambia la obra', (tester) async {
      await h.drawings.save(
        DrawingSnapshot(
          drawingId: 'x',
          chapterId: 'bosque-nuboso',
          pageId: 'quetzal',
          templateRevision: 1,
          saveRevision: 3,
          document: const DrawingDocument(fills: {'pico': 0xFDD835}),
          updatedAt: DateTime.utc(2026),
        ),
      );
      final before = (await h.drawings.all()).single;
      h.gateway.next = ExportResult.canceled;
      late ExportResult result;
      await tester.runAsync(() async {
        result = await h.deps.exporter.export(
          'bosque-nuboso',
          'quetzal',
          ExportMode.share,
        );
      });
      expect(result, ExportResult.canceled);
      expect(h.gateway.saved, isEmpty);
      expect(h.gateway.shared, isEmpty);
      final after = (await h.drawings.all()).single;
      expect(after.saveRevision, before.saveRevision);
      expect(after.document, before.document);
      expect(after.updatedAt, before.updatedAt);
    });

    testWidgets('exportar una obra inexistente falla sin crearla', (
      tester,
    ) async {
      late ExportResult result;
      await tester.runAsync(() async {
        result = await h.deps.exporter.export(
          'bosque-nuboso',
          'sendero',
          ExportMode.save,
        );
      });
      expect(result, ExportResult.failed);
      expect(h.drawings.rows, isEmpty);
    });
  });

  group('contraste de la paleta de interfaz', () {
    test('texto e iconos cumplen WCAG AA', () {
      // Texto normal: >= 4.5.
      expect(contrastRatio(TukiColors.ink, TukiColors.aqua), greaterThan(4.5));
      expect(
        contrastRatio(TukiColors.ink, TukiColors.surface),
        greaterThan(4.5),
      );
      expect(
        contrastRatio(TukiColors.turquoise, TukiColors.surface),
        greaterThan(4.5),
      );
      expect(
        contrastRatio(TukiColors.turquoise, TukiColors.aqua),
        greaterThan(4.5),
      );
      expect(
        contrastRatio(Colors.white, TukiColors.turquoise),
        greaterThan(4.5),
      );
      expect(
        contrastRatio(TukiColors.ink, TukiColors.selectedTint),
        greaterThan(4.5),
      );
      expect(
        contrastRatio(TukiColors.error, TukiColors.aqua),
        greaterThan(4.5),
      );
      // Blanco sobre naranja solo se usa en texto grande y negrita: >= 3.
      expect(contrastRatio(Colors.white, TukiColors.orange), greaterThan(3));
    });
  });
}
