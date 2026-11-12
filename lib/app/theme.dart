import 'package:flutter/material.dart';

/// Marca visible: igual en español e inglés.
const String kBrandName = 'TUKI — Little Adventures';

abstract final class TukiColors {
  /// Fondo.
  static const Color aqua = Color(0xFFD7F8F7);

  /// Selección.
  static const Color turquoise = Color(0xFF006C70);

  /// Acción principal.
  static const Color orange = Color(0xFFE64E24);

  /// Texto e iconos sobre fondos claros.
  static const Color ink = Color(0xFF17383A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color selectedTint = Color(0xFFBDEFEC);
  static const Color divider = Color(0xFFB7E3E1);
  static const Color error = Color(0xFFB3261E);
}

/// Texto con la tipografía redondeada de la app. Fredoka es variable: el
/// peso se fija también por eje para que se aplique en todas las plataformas.
TextStyle tukiText(
  double size, {
  int weight = 500,
  Color color = TukiColors.ink,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Fredoka',
    fontSize: size,
    height: height,
    color: color,
    fontWeight: FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)],
    fontVariations: [FontVariation('wght', weight.toDouble())],
  );
}

ThemeData buildTukiTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: TukiColors.turquoise,
    primary: TukiColors.turquoise,
    onPrimary: Colors.white,
    secondary: TukiColors.orange,
    onSecondary: Colors.white,
    surface: TukiColors.surface,
    onSurface: TukiColors.ink,
    error: TukiColors.error,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: TukiColors.aqua,
    fontFamily: 'Fredoka',
    textTheme: TextTheme(
      bodyMedium: tukiText(16),
      bodyLarge: tukiText(18),
      titleMedium: tukiText(18, weight: 600),
      labelLarge: tukiText(16, weight: 600),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TukiColors.ink,
      contentTextStyle: tukiText(16, color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: TukiColors.surface,
      titleTextStyle: tukiText(22, weight: 600),
      contentTextStyle: tukiText(17),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Colors.white
            : TukiColors.turquoise,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? TukiColors.turquoise
            : TukiColors.surface,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(TukiColors.turquoise),
    ),
  );
}

/// Contraste WCAG entre dos colores opacos.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
