import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../chapters/level_widgets.dart';

/// Opciones de rango de edad: las del catálogo y «Prefiero no indicar».
///
/// [selected] es el `id` del rango, o [noAnswer].
class AgeRangeOptions extends StatelessWidget {
  const AgeRangeOptions({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const String noAnswer = 'none';

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final catalog = AppScope.of(context).catalog;
    final lang = contentLanguage(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final range in catalog.ageRanges) ...[
          _Option(
            key: ValueKey('age-${range.id}'),
            label: ageLabel(l, range.minAge, range.maxAge),
            detail: catalog.levelById(range.recommendedLevelId)?.name.of(lang),
            leaves: (
              catalog.levelById(range.recommendedLevelId)?.order ?? 0,
              catalog.levels.length,
            ),
            selected: selected == range.id,
            onTap: () => onSelected(range.id),
          ),
          const SizedBox(height: 8),
        ],
        _Option(
          key: const ValueKey('age-none'),
          label: l.ageNoAnswer,
          selected: selected == noAnswer,
          onTap: () => onSelected(noAnswer),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
    this.leaves,
  });

  final String label;
  final String? detail;
  final (int, int)? leaves;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: detail == null ? label : '$label. $detail',
      excludeSemantics: true,
      child: Material(
        color: selected ? TukiColors.selectedTint : TukiColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? TukiColors.turquoise : TukiColors.divider,
            width: selected ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: TukiColors.turquoise,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(label, style: tukiText(20, weight: 700)),
                        if (detail != null) Text(detail!, style: tukiText(16)),
                      ],
                    ),
                  ),
                  if (leaves != null)
                    LevelLeaves(step: leaves!.$1, total: leaves!.$2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Configuración inicial, breve y opcional, pensada para un adulto. Se
/// muestra una sola vez; después se cambia desde «Para adultos».
class AgeSetupScreen extends StatefulWidget {
  const AgeSetupScreen({super.key});

  @override
  State<AgeSetupScreen> createState() => _AgeSetupScreenState();
}

class _AgeSetupScreenState extends State<AgeSetupScreen> {
  String? _selected;

  Future<void> _finish(String? choice) {
    final id = choice == AgeRangeOptions.noAnswer ? null : choice;
    return AppScope.of(context).preferences.setAgeRange(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.supervisor_account_rounded,
                      color: TukiColors.turquoise,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.adultsTitle,
                        style: tukiText(18, weight: 600),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('age-skip'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: TukiColors.turquoise,
                      ),
                      onPressed: () => _finish(null),
                      child: Text(
                        l.skip,
                        style: tukiText(
                          18,
                          weight: 700,
                          color: TukiColors.turquoise,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text(
                    l.ageSetupTitle,
                    style: tukiText(28, weight: 700, height: 1.15),
                  ),
                ),
                const SizedBox(height: 8),
                Text(l.ageSetupHint, style: tukiText(16)),
                const SizedBox(height: 16),
                AgeRangeOptions(
                  selected: _selected,
                  onSelected: (id) => setState(() => _selected = id),
                ),
                const SizedBox(height: 18),
                TukiPrimaryButton(
                  key: const ValueKey('age-continue'),
                  label: l.continueLabel,
                  onPressed: _selected == null
                      ? null
                      : () => _finish(_selected),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
