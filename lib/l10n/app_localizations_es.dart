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
}
