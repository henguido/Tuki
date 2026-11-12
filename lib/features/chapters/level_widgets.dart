import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'catalog.dart';

/// «2–4 años» / «8+ años».
String ageLabel(AppLocalizations l, int minAge, int? maxAge) =>
    maxAge == null ? l.ageRangeOpen(minAge) : l.ageRangeClosed(minAge, maxAge);

/// Fondo del distintivo según la posición del nivel.
Color levelTint(DifficultyLevel level) => const [
  TukiColors.selectedTint,
  Color(0xFFFFE2B8),
  Color(0xFFFFD3C7),
  Color(0xFFE3D5F5),
][(level.order - 1).clamp(0, 3)];

/// Dificultad sin leer: tantas hojas llenas como la posición del nivel.
class LevelLeaves extends StatelessWidget {
  const LevelLeaves({
    super.key,
    required this.step,
    required this.total,
    this.size = 18,
    this.color = TukiColors.turquoise,
  });

  final int step;
  final int total;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= total; i++)
            Icon(
              Icons.eco_rounded,
              size: size,
              color: i <= step ? color : color.withValues(alpha: 0.22),
            ),
        ],
      ),
    );
  }
}

/// Distintivo de nivel: hojas + nombre.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level});

  final DifficultyLevel level;

  @override
  Widget build(BuildContext context) {
    final total = AppScope.of(context).catalog.levels.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: levelTint(level),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LevelLeaves(step: level.order, total: total, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              level.name.of(contentLanguage(context)),
              style: tukiText(16, weight: 600),
            ),
          ),
        ],
      ),
    );
  }
}
