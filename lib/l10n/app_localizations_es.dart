// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get homeSubtitle =>
      'Guía ilustrada para colorear la naturaleza de Costa Rica';

  @override
  String get explore => 'Explorar';

  @override
  String get continueDrawing => 'Continuar mi dibujo';

  @override
  String get tabChapters => 'Capítulos';

  @override
  String get tabGallery => 'Mis dibujos';

  @override
  String get settings => 'Ajustes para adultos';

  @override
  String get back => 'Volver';

  @override
  String get listen => 'Escuchar';

  @override
  String get pauseNarration => 'Pausar';

  @override
  String get sounds => 'Sonidos';

  @override
  String get pauseSounds => 'Pausar sonidos';

  @override
  String get audioUnavailable => 'Audio no disponible';

  @override
  String get audioOff => 'Desactivado';

  @override
  String narrationSemantics(String state) {
    return 'Narración: $state';
  }

  @override
  String ambienceSemantics(String state) {
    return 'Sonidos del bosque: $state';
  }

  @override
  String get colorIn => 'Colorear';

  @override
  String get choosePage => 'Elige una lámina';

  @override
  String get difficultyEasy => 'Fácil';

  @override
  String get difficultyMedium => 'Media';

  @override
  String get difficultyDetailed => 'Detallada';

  @override
  String pageCardSemantics(String title, String difficulty) {
    return '$title. Dificultad: $difficulty';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get tools => 'Herramientas';

  @override
  String get toolFill => 'Rellenar';

  @override
  String get toolBrush => 'Pincel';

  @override
  String get toolEraser => 'Borrador';

  @override
  String get colors => 'Colores';

  @override
  String get strokeSize => 'Grosor';

  @override
  String get sizeSmall => 'Fino';

  @override
  String get sizeMedium => 'Medio';

  @override
  String get sizeLarge => 'Grueso';

  @override
  String get selected => 'seleccionado';

  @override
  String get saveSaving => 'Guardando';

  @override
  String get saveSaved => 'Guardado';

  @override
  String get saveError => 'Error al guardar';

  @override
  String get retry => 'Reintentar';

  @override
  String get nextPage => 'Siguiente lámina';

  @override
  String get backToPages => 'Volver a las láminas';

  @override
  String canvasSemantics(String title) {
    return 'Lienzo de $title. Toca para pintar. Usa dos dedos para ampliar y mover.';
  }

  @override
  String get resetZoom => 'Ver todo el dibujo';

  @override
  String get saveErrorTitle => 'No pudimos guardar';

  @override
  String get saveErrorBody =>
      'Tu dibujo sigue abierto. Toca Reintentar para guardarlo.';

  @override
  String get keepPainting => 'Seguir pintando';

  @override
  String get loadErrorTitle => 'No pudimos abrir este dibujo';

  @override
  String get loadErrorBody =>
      'Tu dibujo guardado no se ha modificado. Puedes volver o intentarlo otra vez.';

  @override
  String get templateMissingBody =>
      'Esta lámina cambió de versión y no se puede abrir aquí. Tu dibujo sigue guardado.';

  @override
  String get galleryEmpty =>
      'Aquí aparecerán tus dibujos cuando empieces a colorear.';

  @override
  String get exploreChapters => 'Explorar capítulos';

  @override
  String get keepColoring => 'Seguir coloreando';

  @override
  String drawingSemantics(String title) {
    return 'Dibujo: $title';
  }

  @override
  String get adultsTitle => 'Para adultos';

  @override
  String get language => 'Idioma';

  @override
  String get sound => 'Sonido';

  @override
  String get narration => 'Narración';

  @override
  String get narrationHint => 'Disponible en el idioma elegido';

  @override
  String get forestSounds => 'Sonidos del bosque';

  @override
  String get forestSoundsHint => 'Activación manual en la portada';

  @override
  String get drawings => 'Dibujos';

  @override
  String get exportDrawing => 'Exportar un dibujo';

  @override
  String get exportChoose => 'Elige el dibujo que quieres exportar';

  @override
  String get exportSave => 'Guardar PNG';

  @override
  String get exportShare => 'Compartir';

  @override
  String get exportDone => 'Copia PNG exportada.';

  @override
  String get exportCanceled =>
      'Exportación cancelada. El dibujo sigue en la galería.';

  @override
  String get exportFailed =>
      'No se pudo exportar. El dibujo sigue en la galería.';

  @override
  String get exportEmpty => 'Todavía no hay dibujos guardados para exportar.';

  @override
  String get colorRed => 'Rojo';

  @override
  String get colorOrange => 'Naranja';

  @override
  String get colorYellow => 'Amarillo';

  @override
  String get colorLeafGreen => 'Verde hoja';

  @override
  String get colorForestGreen => 'Verde bosque';

  @override
  String get colorTurquoise => 'Turquesa';

  @override
  String get colorBlue => 'Azul';

  @override
  String get colorPurple => 'Morado';

  @override
  String get colorPink => 'Rosa';

  @override
  String get colorBrown => 'Café';

  @override
  String get colorBlack => 'Negro';

  @override
  String get colorWhite => 'Blanco';

  @override
  String get ageSetupTitle => '¿Para qué edad buscas aventuras?';

  @override
  String get ageSetupHint =>
      'Es opcional y solo sirve para sugerir láminas: todas siguen disponibles. Solo se guarda el rango en este dispositivo y puedes cambiarlo en Para adultos.';

  @override
  String ageRangeClosed(int min, int max) {
    return '$min–$max años';
  }

  @override
  String ageRangeOpen(int min) {
    return '$min+ años';
  }

  @override
  String get ageNoAnswer => 'Prefiero no indicar';

  @override
  String get skip => 'Omitir';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get suggestedAge => 'Edad sugerida';

  @override
  String get suggestedAgeHint =>
      'Ordena y sugiere láminas. No bloquea ninguna.';

  @override
  String get filterAll => 'Todas';

  @override
  String filterSemantics(String name) {
    return 'Filtro: $name';
  }

  @override
  String levelSemantics(String name, int step, int total) {
    return 'Nivel $name, $step de $total';
  }

  @override
  String get recommended => 'Sugerida';

  @override
  String get inProgress => 'En progreso';

  @override
  String get filterEmpty => 'Pronto habrá láminas de este nivel.';

  @override
  String get showAll => 'Ver todas';

  @override
  String get moreColors => 'Más colores';

  @override
  String get funFactTitle => '¿Sabías que…?';

  @override
  String get funFactButton => 'Curiosidad';

  @override
  String get adventures => 'Aventuras';

  @override
  String get adventuresOpen => 'Ver aventuras';

  @override
  String get adultGateTitle => 'Solo para adultos';

  @override
  String adultGateQuestion(int a, int b) {
    return '¿Cuánto es $a × $b?';
  }

  @override
  String get adultGateAnswer => 'Respuesta';

  @override
  String get adultGateWrong => 'No es correcto. Inténtalo de nuevo.';

  @override
  String get chapterFree => 'Incluido gratis';

  @override
  String get chapterOwned => 'Desbloqueado';

  @override
  String get chapterLocked => 'No incluido';

  @override
  String pagesAvailable(int count, int total) {
    return '$count de $total láminas disponibles';
  }

  @override
  String get storeUnavailable =>
      'Las compras no están disponibles en esta versión.';

  @override
  String get noAds => 'TUKI no muestra anuncios.';

  @override
  String get buy => 'Comprar';

  @override
  String get purchaseDone => 'Compra completada.';

  @override
  String get purchaseCanceled => 'Compra cancelada.';

  @override
  String get purchaseFailed => 'No se pudo completar la compra.';

  @override
  String bundleIncludes(String chapters) {
    return 'Incluye: $chapters';
  }
}
