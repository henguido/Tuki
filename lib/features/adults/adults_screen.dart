import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../store/adventures_screen.dart';
import 'age_setup.dart';
import 'export_picker_screen.dart';

/// Área de adultos: idioma, edad sugerida, sonido, exportación y aventuras.
class AdultsScreen extends StatelessWidget {
  const AdultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prefs = AppScope.of(context).preferences;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListenableBuilder(
              listenable: prefs,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TukiBackHeader(backLabel: l.back, caption: l.tabChapters),
                  const SizedBox(height: 14),
                  Semantics(
                    header: true,
                    child: Text(
                      l.adultsTitle,
                      style: tukiText(30, weight: 700),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(l.language),
                  Row(
                    children: [
                      for (final (code, name) in const [
                        ('es', 'Español'),
                        ('en', 'English'),
                      ]) ...[
                        if (code == 'en') const SizedBox(width: 10),
                        Expanded(
                          child: _LanguageButton(
                            key: ValueKey('language-$code'),
                            name: name,
                            selected: prefs.languageCode == code,
                            onTap: () => prefs.setLanguage(code),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(l.suggestedAge),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(l.suggestedAgeHint, style: tukiText(15)),
                  ),
                  AgeRangeOptions(
                    selected: prefs.ageRangeId ?? AgeRangeOptions.noAnswer,
                    onSelected: (id) => prefs.setAgeRange(
                      id == AgeRangeOptions.noAnswer ? null : id,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(l.sound),
                  TukiCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          key: const ValueKey('switch-narration'),
                          title: Text(
                            l.narration,
                            style: tukiText(18, weight: 600),
                          ),
                          subtitle: Text(l.narrationHint, style: tukiText(15)),
                          value: prefs.narrationEnabled,
                          onChanged: prefs.setNarrationEnabled,
                        ),
                        const Divider(
                          color: TukiColors.divider,
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        SwitchListTile(
                          key: const ValueKey('switch-ambience'),
                          title: Text(
                            l.forestSounds,
                            style: tukiText(18, weight: 600),
                          ),
                          subtitle: Text(
                            l.forestSoundsHint,
                            style: tukiText(15),
                          ),
                          value: prefs.ambienceEnabled,
                          onChanged: prefs.setAmbienceEnabled,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(l.drawings),
                  TukiCard(
                    key: const ValueKey('export-open'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ExportPickerScreen(),
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.ios_share_rounded,
                            color: TukiColors.turquoise,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              l.exportDrawing,
                              style: tukiText(
                                19,
                                weight: 700,
                                color: TukiColors.turquoise,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(l.adventures),
                  TukiCard(
                    key: const ValueKey('adventures-open'),
                    onTap: () => openAdventures(context),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            color: TukiColors.turquoise,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              l.adventuresOpen,
                              style: tukiText(
                                19,
                                weight: 700,
                                color: TukiColors.turquoise,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      header: true,
      child: Text(text, style: tukiText(19, weight: 700)),
    ),
  );
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: Material(
        color: selected ? TukiColors.selectedTint : TukiColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded, color: TukiColors.ink),
                  const SizedBox(width: 6),
                ],
                Flexible(child: Text(name, style: tukiText(19, weight: 700))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
