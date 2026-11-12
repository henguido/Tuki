import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

import '../data/local/database.dart';
import '../data/local/drawings_repository.dart';
import '../data/local/open_database.dart';
import '../data/local/preferences.dart';
import '../features/adults/export_service.dart';
import '../features/chapters/audio/audio_engine.dart';
import '../features/chapters/audio/just_audio_engine.dart';
import '../features/chapters/catalog.dart';
import '../features/store/entitlements.dart';

/// Dependencias compuestas al iniciar. Todo es local: no hay red.
class AppDependencies {
  AppDependencies({
    required this.catalogRepository,
    required this.catalog,
    required this.drawings,
    required this.preferences,
    required this.audio,
    required this.entitlements,
    required ExportGateway exportGateway,
    PngRenderer? exportRenderer,
  }) : exporter = ExportService(
         catalog: catalogRepository,
         drawings: drawings,
         gateway: exportGateway,
         render: exportRenderer,
       );

  final CatalogRepository catalogRepository;
  final Catalog catalog;
  final DrawingsRepository drawings;
  final AppPreferences preferences;
  final AudioEngine audio;
  final Entitlements entitlements;
  final ExportService exporter;

  /// Cierra la base de datos (pruebas de integración).
  Future<void> close() async {
    final repo = drawings;
    if (repo is DriftDrawingsRepository) await repo.close();
  }

  static Future<AppDependencies> create({
    String databaseName = 'tuki.sqlite',
  }) async {
    final catalogRepository = CatalogRepository(rootBundle.loadString);
    final catalog = await catalogRepository.load();
    final preferences = await AppPreferences.load(
      deviceLocale: PlatformDispatcher.instance.locale,
    );
    return AppDependencies(
      catalogRepository: catalogRepository,
      catalog: catalog,
      drawings: DriftDrawingsRepository(
        TukiDatabase(openTukiExecutor(databaseName)),
      ),
      preferences: preferences,
      audio: JustAudioEngine(),
      // Sin tienda en esta etapa: no hay compras ni cobros.
      entitlements: await Entitlements.load(
        catalog: catalog,
        gateway: const DisabledPurchaseGateway(),
      ),
      exportGateway: SystemExportGateway(),
    );
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.deps, required super.child});

  final AppDependencies deps;

  static AppDependencies of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.deps;

  @override
  bool updateShouldNotify(AppScope oldWidget) => deps != oldWidget.deps;
}

/// Código de idioma activo ('es' | 'en') para el contenido del catálogo.
String contentLanguage(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'es';
