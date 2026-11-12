import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @homeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Guía ilustrada para colorear la naturaleza de Costa Rica'**
  String get homeSubtitle;

  /// No description provided for @explore.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get explore;

  /// No description provided for @continueDrawing.
  ///
  /// In es, this message translates to:
  /// **'Continuar mi dibujo'**
  String get continueDrawing;

  /// No description provided for @tabChapters.
  ///
  /// In es, this message translates to:
  /// **'Capítulos'**
  String get tabChapters;

  /// No description provided for @tabGallery.
  ///
  /// In es, this message translates to:
  /// **'Mis dibujos'**
  String get tabGallery;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes para adultos'**
  String get settings;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @listen.
  ///
  /// In es, this message translates to:
  /// **'Escuchar'**
  String get listen;

  /// No description provided for @pauseNarration.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get pauseNarration;

  /// No description provided for @sounds.
  ///
  /// In es, this message translates to:
  /// **'Sonidos'**
  String get sounds;

  /// No description provided for @pauseSounds.
  ///
  /// In es, this message translates to:
  /// **'Pausar sonidos'**
  String get pauseSounds;

  /// No description provided for @audioUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Audio no disponible'**
  String get audioUnavailable;

  /// No description provided for @audioOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get audioOff;

  /// No description provided for @narrationSemantics.
  ///
  /// In es, this message translates to:
  /// **'Narración: {state}'**
  String narrationSemantics(String state);

  /// No description provided for @ambienceSemantics.
  ///
  /// In es, this message translates to:
  /// **'Sonidos del bosque: {state}'**
  String ambienceSemantics(String state);

  /// No description provided for @colorIn.
  ///
  /// In es, this message translates to:
  /// **'Colorear'**
  String get colorIn;

  /// No description provided for @choosePage.
  ///
  /// In es, this message translates to:
  /// **'Elige una lámina'**
  String get choosePage;

  /// No description provided for @difficultyEasy.
  ///
  /// In es, this message translates to:
  /// **'Fácil'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get difficultyMedium;

  /// No description provided for @difficultyDetailed.
  ///
  /// In es, this message translates to:
  /// **'Detallada'**
  String get difficultyDetailed;

  /// No description provided for @pageCardSemantics.
  ///
  /// In es, this message translates to:
  /// **'{title}. Dificultad: {difficulty}'**
  String pageCardSemantics(String title, String difficulty);

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @tools.
  ///
  /// In es, this message translates to:
  /// **'Herramientas'**
  String get tools;

  /// No description provided for @toolFill.
  ///
  /// In es, this message translates to:
  /// **'Rellenar'**
  String get toolFill;

  /// No description provided for @toolBrush.
  ///
  /// In es, this message translates to:
  /// **'Pincel'**
  String get toolBrush;

  /// No description provided for @toolEraser.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get toolEraser;

  /// No description provided for @colors.
  ///
  /// In es, this message translates to:
  /// **'Colores'**
  String get colors;

  /// No description provided for @strokeSize.
  ///
  /// In es, this message translates to:
  /// **'Grosor'**
  String get strokeSize;

  /// No description provided for @sizeSmall.
  ///
  /// In es, this message translates to:
  /// **'Fino'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In es, this message translates to:
  /// **'Medio'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In es, this message translates to:
  /// **'Grueso'**
  String get sizeLarge;

  /// No description provided for @selected.
  ///
  /// In es, this message translates to:
  /// **'seleccionado'**
  String get selected;

  /// No description provided for @saveSaving.
  ///
  /// In es, this message translates to:
  /// **'Guardando'**
  String get saveSaving;

  /// No description provided for @saveSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get saveSaved;

  /// No description provided for @saveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar'**
  String get saveError;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @nextPage.
  ///
  /// In es, this message translates to:
  /// **'Siguiente lámina'**
  String get nextPage;

  /// No description provided for @backToPages.
  ///
  /// In es, this message translates to:
  /// **'Volver a las láminas'**
  String get backToPages;

  /// No description provided for @canvasSemantics.
  ///
  /// In es, this message translates to:
  /// **'Lienzo de {title}. Toca para pintar. Usa dos dedos para ampliar y mover.'**
  String canvasSemantics(String title);

  /// No description provided for @resetZoom.
  ///
  /// In es, this message translates to:
  /// **'Ver todo el dibujo'**
  String get resetZoom;

  /// No description provided for @saveErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar'**
  String get saveErrorTitle;

  /// No description provided for @saveErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Tu dibujo sigue abierto. Toca Reintentar para guardarlo.'**
  String get saveErrorBody;

  /// No description provided for @keepPainting.
  ///
  /// In es, this message translates to:
  /// **'Seguir pintando'**
  String get keepPainting;

  /// No description provided for @loadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir este dibujo'**
  String get loadErrorTitle;

  /// No description provided for @loadErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Tu dibujo guardado no se ha modificado. Puedes volver o intentarlo otra vez.'**
  String get loadErrorBody;

  /// No description provided for @templateMissingBody.
  ///
  /// In es, this message translates to:
  /// **'Esta lámina cambió de versión y no se puede abrir aquí. Tu dibujo sigue guardado.'**
  String get templateMissingBody;

  /// No description provided for @galleryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán tus dibujos cuando empieces a colorear.'**
  String get galleryEmpty;

  /// No description provided for @exploreChapters.
  ///
  /// In es, this message translates to:
  /// **'Explorar capítulos'**
  String get exploreChapters;

  /// No description provided for @keepColoring.
  ///
  /// In es, this message translates to:
  /// **'Seguir coloreando'**
  String get keepColoring;

  /// No description provided for @drawingSemantics.
  ///
  /// In es, this message translates to:
  /// **'Dibujo: {title}'**
  String drawingSemantics(String title);

  /// No description provided for @adultsTitle.
  ///
  /// In es, this message translates to:
  /// **'Para adultos'**
  String get adultsTitle;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @sound.
  ///
  /// In es, this message translates to:
  /// **'Sonido'**
  String get sound;

  /// No description provided for @narration.
  ///
  /// In es, this message translates to:
  /// **'Narración'**
  String get narration;

  /// No description provided for @narrationHint.
  ///
  /// In es, this message translates to:
  /// **'Disponible en el idioma elegido'**
  String get narrationHint;

  /// No description provided for @forestSounds.
  ///
  /// In es, this message translates to:
  /// **'Sonidos del bosque'**
  String get forestSounds;

  /// No description provided for @forestSoundsHint.
  ///
  /// In es, this message translates to:
  /// **'Activación manual en la portada'**
  String get forestSoundsHint;

  /// No description provided for @drawings.
  ///
  /// In es, this message translates to:
  /// **'Dibujos'**
  String get drawings;

  /// No description provided for @exportDrawing.
  ///
  /// In es, this message translates to:
  /// **'Exportar un dibujo'**
  String get exportDrawing;

  /// No description provided for @exportChoose.
  ///
  /// In es, this message translates to:
  /// **'Elige el dibujo que quieres exportar'**
  String get exportChoose;

  /// No description provided for @exportSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar PNG'**
  String get exportSave;

  /// No description provided for @exportShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get exportShare;

  /// No description provided for @exportDone.
  ///
  /// In es, this message translates to:
  /// **'Copia PNG exportada.'**
  String get exportDone;

  /// No description provided for @exportCanceled.
  ///
  /// In es, this message translates to:
  /// **'Exportación cancelada. El dibujo sigue en la galería.'**
  String get exportCanceled;

  /// No description provided for @exportFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo exportar. El dibujo sigue en la galería.'**
  String get exportFailed;

  /// No description provided for @exportEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay dibujos guardados para exportar.'**
  String get exportEmpty;

  /// No description provided for @colorRed.
  ///
  /// In es, this message translates to:
  /// **'Rojo'**
  String get colorRed;

  /// No description provided for @colorOrange.
  ///
  /// In es, this message translates to:
  /// **'Naranja'**
  String get colorOrange;

  /// No description provided for @colorYellow.
  ///
  /// In es, this message translates to:
  /// **'Amarillo'**
  String get colorYellow;

  /// No description provided for @colorLeafGreen.
  ///
  /// In es, this message translates to:
  /// **'Verde hoja'**
  String get colorLeafGreen;

  /// No description provided for @colorForestGreen.
  ///
  /// In es, this message translates to:
  /// **'Verde bosque'**
  String get colorForestGreen;

  /// No description provided for @colorTurquoise.
  ///
  /// In es, this message translates to:
  /// **'Turquesa'**
  String get colorTurquoise;

  /// No description provided for @colorBlue.
  ///
  /// In es, this message translates to:
  /// **'Azul'**
  String get colorBlue;

  /// No description provided for @colorPurple.
  ///
  /// In es, this message translates to:
  /// **'Morado'**
  String get colorPurple;

  /// No description provided for @colorPink.
  ///
  /// In es, this message translates to:
  /// **'Rosa'**
  String get colorPink;

  /// No description provided for @colorBrown.
  ///
  /// In es, this message translates to:
  /// **'Café'**
  String get colorBrown;

  /// No description provided for @colorBlack.
  ///
  /// In es, this message translates to:
  /// **'Negro'**
  String get colorBlack;

  /// No description provided for @colorWhite.
  ///
  /// In es, this message translates to:
  /// **'Blanco'**
  String get colorWhite;

  /// No description provided for @ageSetupTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Para qué edad buscas aventuras?'**
  String get ageSetupTitle;

  /// No description provided for @ageSetupHint.
  ///
  /// In es, this message translates to:
  /// **'Es opcional y solo sirve para sugerir láminas: todas siguen disponibles. Solo se guarda el rango en este dispositivo y puedes cambiarlo en Para adultos.'**
  String get ageSetupHint;

  /// No description provided for @ageRangeClosed.
  ///
  /// In es, this message translates to:
  /// **'{min}–{max} años'**
  String ageRangeClosed(int min, int max);

  /// No description provided for @ageRangeOpen.
  ///
  /// In es, this message translates to:
  /// **'{min}+ años'**
  String ageRangeOpen(int min);

  /// No description provided for @ageNoAnswer.
  ///
  /// In es, this message translates to:
  /// **'Prefiero no indicar'**
  String get ageNoAnswer;

  /// No description provided for @skip.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get skip;

  /// No description provided for @continueLabel.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @suggestedAge.
  ///
  /// In es, this message translates to:
  /// **'Edad sugerida'**
  String get suggestedAge;

  /// No description provided for @suggestedAgeHint.
  ///
  /// In es, this message translates to:
  /// **'Ordena y sugiere láminas. No bloquea ninguna.'**
  String get suggestedAgeHint;

  /// No description provided for @filterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get filterAll;

  /// No description provided for @filterSemantics.
  ///
  /// In es, this message translates to:
  /// **'Filtro: {name}'**
  String filterSemantics(String name);

  /// No description provided for @levelSemantics.
  ///
  /// In es, this message translates to:
  /// **'Nivel {name}, {step} de {total}'**
  String levelSemantics(String name, int step, int total);

  /// No description provided for @recommended.
  ///
  /// In es, this message translates to:
  /// **'Sugerida'**
  String get recommended;

  /// No description provided for @inProgress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get inProgress;

  /// No description provided for @filterEmpty.
  ///
  /// In es, this message translates to:
  /// **'Pronto habrá láminas de este nivel.'**
  String get filterEmpty;

  /// No description provided for @showAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get showAll;

  /// No description provided for @moreColors.
  ///
  /// In es, this message translates to:
  /// **'Más colores'**
  String get moreColors;

  /// No description provided for @funFactTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Sabías que…?'**
  String get funFactTitle;

  /// No description provided for @funFactButton.
  ///
  /// In es, this message translates to:
  /// **'Curiosidad'**
  String get funFactButton;

  /// No description provided for @adventures.
  ///
  /// In es, this message translates to:
  /// **'Aventuras'**
  String get adventures;

  /// No description provided for @adventuresOpen.
  ///
  /// In es, this message translates to:
  /// **'Ver aventuras'**
  String get adventuresOpen;

  /// No description provided for @adultGateTitle.
  ///
  /// In es, this message translates to:
  /// **'Solo para adultos'**
  String get adultGateTitle;

  /// No description provided for @adultGateQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto es {a} × {b}?'**
  String adultGateQuestion(int a, int b);

  /// No description provided for @adultGateAnswer.
  ///
  /// In es, this message translates to:
  /// **'Respuesta'**
  String get adultGateAnswer;

  /// No description provided for @adultGateWrong.
  ///
  /// In es, this message translates to:
  /// **'No es correcto. Inténtalo de nuevo.'**
  String get adultGateWrong;

  /// No description provided for @chapterFree.
  ///
  /// In es, this message translates to:
  /// **'Incluido gratis'**
  String get chapterFree;

  /// No description provided for @chapterOwned.
  ///
  /// In es, this message translates to:
  /// **'Desbloqueado'**
  String get chapterOwned;

  /// No description provided for @chapterLocked.
  ///
  /// In es, this message translates to:
  /// **'No incluido'**
  String get chapterLocked;

  /// No description provided for @pagesAvailable.
  ///
  /// In es, this message translates to:
  /// **'{count} de {total} láminas disponibles'**
  String pagesAvailable(int count, int total);

  /// No description provided for @storeUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Las compras no están disponibles en esta versión.'**
  String get storeUnavailable;

  /// No description provided for @noAds.
  ///
  /// In es, this message translates to:
  /// **'TUKI no muestra anuncios.'**
  String get noAds;

  /// No description provided for @buy.
  ///
  /// In es, this message translates to:
  /// **'Comprar'**
  String get buy;

  /// No description provided for @purchaseDone.
  ///
  /// In es, this message translates to:
  /// **'Compra completada.'**
  String get purchaseDone;

  /// No description provided for @purchaseCanceled.
  ///
  /// In es, this message translates to:
  /// **'Compra cancelada.'**
  String get purchaseCanceled;

  /// No description provided for @purchaseFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la compra.'**
  String get purchaseFailed;

  /// No description provided for @bundleIncludes.
  ///
  /// In es, this message translates to:
  /// **'Incluye: {chapters}'**
  String bundleIncludes(String chapters);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
