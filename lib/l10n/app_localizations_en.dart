// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeSubtitle =>
      'An illustrated guide to color the nature of Costa Rica';

  @override
  String get explore => 'Explore';

  @override
  String get continueDrawing => 'Continue my drawing';

  @override
  String get tabChapters => 'Chapters';

  @override
  String get tabGallery => 'My drawings';

  @override
  String get settings => 'Grown-ups settings';

  @override
  String get back => 'Back';

  @override
  String get listen => 'Listen';

  @override
  String get pauseNarration => 'Pause';

  @override
  String get sounds => 'Sounds';

  @override
  String get pauseSounds => 'Pause sounds';

  @override
  String get audioUnavailable => 'Audio unavailable';

  @override
  String get audioOff => 'Turned off';

  @override
  String narrationSemantics(String state) {
    return 'Narration: $state';
  }

  @override
  String ambienceSemantics(String state) {
    return 'Forest sounds: $state';
  }

  @override
  String get colorIn => 'Color';

  @override
  String get choosePage => 'Choose a page';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyDetailed => 'Detailed';

  @override
  String pageCardSemantics(String title, String difficulty) {
    return '$title. Difficulty: $difficulty';
  }

  @override
  String get undo => 'Undo';

  @override
  String get tools => 'Tools';

  @override
  String get toolFill => 'Fill';

  @override
  String get toolBrush => 'Brush';

  @override
  String get toolEraser => 'Eraser';

  @override
  String get colors => 'Colors';

  @override
  String get strokeSize => 'Size';

  @override
  String get sizeSmall => 'Thin';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Thick';

  @override
  String get selected => 'selected';

  @override
  String get saveSaving => 'Saving';

  @override
  String get saveSaved => 'Saved';

  @override
  String get saveError => 'Couldn\'t save';

  @override
  String get retry => 'Try again';

  @override
  String get nextPage => 'Next page';

  @override
  String get backToPages => 'Back to pages';

  @override
  String canvasSemantics(String title) {
    return 'Canvas for $title. Touch to paint. Use two fingers to zoom and move.';
  }

  @override
  String get resetZoom => 'See the whole drawing';

  @override
  String get saveErrorTitle => 'We couldn\'t save';

  @override
  String get saveErrorBody =>
      'Your drawing is still open. Tap Try again to save it.';

  @override
  String get keepPainting => 'Keep painting';

  @override
  String get loadErrorTitle => 'We couldn\'t open this drawing';

  @override
  String get loadErrorBody =>
      'Your saved drawing was not changed. You can go back or try again.';

  @override
  String get templateMissingBody =>
      'This page changed version and can\'t be opened here. Your drawing is still saved.';

  @override
  String get galleryEmpty =>
      'Your drawings will show up here once you start coloring.';

  @override
  String get exploreChapters => 'Explore chapters';

  @override
  String get keepColoring => 'Keep coloring';

  @override
  String drawingSemantics(String title) {
    return 'Drawing: $title';
  }

  @override
  String get adultsTitle => 'For grown-ups';

  @override
  String get language => 'Language';

  @override
  String get sound => 'Sound';

  @override
  String get narration => 'Narration';

  @override
  String get narrationHint => 'Available in the chosen language';

  @override
  String get forestSounds => 'Forest sounds';

  @override
  String get forestSoundsHint => 'Started by hand on the cover';

  @override
  String get drawings => 'Drawings';

  @override
  String get exportDrawing => 'Export a drawing';

  @override
  String get exportChoose => 'Choose the drawing you want to export';

  @override
  String get exportSave => 'Save PNG';

  @override
  String get exportShare => 'Share';

  @override
  String get exportDone => 'PNG copy exported.';

  @override
  String get exportCanceled =>
      'Export canceled. The drawing is still in the gallery.';

  @override
  String get exportFailed =>
      'Couldn\'t export. The drawing is still in the gallery.';

  @override
  String get exportEmpty => 'There are no saved drawings to export yet.';

  @override
  String get colorRed => 'Red';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorLeafGreen => 'Leaf green';

  @override
  String get colorForestGreen => 'Forest green';

  @override
  String get colorTurquoise => 'Turquoise';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorWhite => 'White';
}
