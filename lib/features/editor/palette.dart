import '../../l10n/app_localizations.dart';

class PaletteColor {
  const PaletteColor(this.rgb, this.name);
  final int rgb;
  final String Function(AppLocalizations l) name;
}

/// Paleta del editor. El blanco permite limpiar visualmente un relleno.
final List<PaletteColor> kPalette = [
  PaletteColor(0xE53935, (l) => l.colorRed),
  PaletteColor(0xFB8C00, (l) => l.colorOrange),
  PaletteColor(0xFDD835, (l) => l.colorYellow),
  PaletteColor(0x7CB342, (l) => l.colorLeafGreen),
  PaletteColor(0x2E7D52, (l) => l.colorForestGreen),
  PaletteColor(0x26A69A, (l) => l.colorTurquoise),
  PaletteColor(0x1E88E5, (l) => l.colorBlue),
  PaletteColor(0x8E44AD, (l) => l.colorPurple),
  PaletteColor(0xF06292, (l) => l.colorPink),
  PaletteColor(0x8D6E63, (l) => l.colorBrown),
  PaletteColor(0x263238, (l) => l.colorBlack),
  PaletteColor(0xFFFFFF, (l) => l.colorWhite),
];

/// Paleta inicial de las láminas fáciles: seis colores bien distintos.
final List<PaletteColor> kStarterPalette = [
  for (final rgb in const [
    0xE53935,
    0xFDD835,
    0x7CB342,
    0x1E88E5,
    0xF06292,
    0x8D6E63,
  ])
    kPalette.firstWhere((c) => c.rgb == rgb),
];

String paletteName(AppLocalizations l, int rgb) {
  for (final c in kPalette) {
    if (c.rgb == rgb) return c.name(l);
  }
  return '';
}
