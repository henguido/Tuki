import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../data/local/preferences.dart';
import '../../l10n/app_localizations.dart';
import 'audio/chapter_audio_controller.dart';
import 'catalog.dart';
import 'pages_screen.dart';

/// Portada del capítulo: ilustración, texto infantil y dos controles de
/// audio independientes. El texto vive fuera de la imagen para poder
/// cambiar de idioma.
class CoverScreen extends StatefulWidget {
  const CoverScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  State<CoverScreen> createState() => _CoverScreenState();
}

class _CoverScreenState extends State<CoverScreen> with WidgetsBindingObserver {
  ChapterAudioController? _audio;
  AppPreferences? _prefs;
  late Chapter _chapter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_audio != null) return;
    final deps = AppScope.of(context);
    _chapter = deps.catalog.chapterById(widget.chapterId)!;
    _prefs = deps.preferences..addListener(_onPreferences);
    _audio = ChapterAudioController(
      engine: deps.audio,
      narrationAsset: _chapter.narrationFor(deps.preferences.languageCode),
      ambienceAsset: _chapter.ambienceAsset,
    );
  }

  void _onPreferences() {
    final prefs = _prefs!;
    final audio = _audio!;
    // Cambio de idioma: se detiene la voz anterior y queda lista la nueva.
    audio.setNarrationAsset(_chapter.narrationFor(prefs.languageCode));
    if (!prefs.narrationEnabled &&
        audio.narrationStatus == TrackStatus.playing) {
      audio.toggleNarration();
    }
    if (!prefs.ambienceEnabled && audio.ambienceStatus == TrackStatus.playing) {
      audio.toggleAmbience();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al salir a segundo plano se detienen ambas pistas.
    if (state != AppLifecycleState.resumed) _audio?.stopAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prefs?.removeListener(_onPreferences);
    _audio?.dispose();
    super.dispose();
  }

  Future<void> _openPages() async {
    // Salir de la portada detiene el audio.
    await _audio!.stopAll();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PagesScreen(chapterId: widget.chapterId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = contentLanguage(context);
    final title = _chapter.title.of(lang);

    final image = Image.asset(
      _chapter.coverAsset,
      fit: BoxFit.cover,
      semanticLabel: title,
    );
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TukiRoundButton(
          icon: Icons.arrow_back_rounded,
          label: l.back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Center(
            heightFactor: 1,
            child: TukiTitleBadge(title, size: 30),
          ),
        ),
        const SizedBox(width: 62),
      ],
    );
    final panel = _Panel(
      intro: _chapter.intro.of(lang),
      audio: _audio!,
      prefs: _prefs!,
      onColor: _openPages,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _audio?.stopAll();
      },
      child: Scaffold(
        body: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return Row(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image,
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: header,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    left: false,
                    child: SizedBox(
                      width: (MediaQuery.sizeOf(context).width * 0.42).clamp(
                        280.0,
                        440.0,
                      ),
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: panel,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            // Vertical: la ilustración ocupa todo el espacio libre y el
            // texto con los controles queda debajo, fuera de la imagen.
            final screen = MediaQuery.sizeOf(context);
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      image,
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: header,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: screen.height * 0.6),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: panel,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.intro,
    required this.audio,
    required this.prefs,
    required this.onColor,
  });

  final String intro;
  final ChapterAudioController audio;
  final AppPreferences prefs;
  final VoidCallback onColor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TukiColors.surface,
        border: Border.all(color: TukiColors.divider),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            intro,
            key: const ValueKey('cover-intro'),
            textAlign: TextAlign.center,
            style: tukiText(21, weight: 500, height: 1.25),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: Listenable.merge([audio, prefs]),
            // Dos mitades fijas: los botones no se mueven al cambiar
            // entre «Escuchar» y «Pausar».
            builder: (context, _) => Row(
              children: [
                Expanded(
                  child: _AudioButton(
                    key: const ValueKey('audio-narration'),
                    status: audio.narrationStatus,
                    enabled: prefs.narrationEnabled,
                    idleLabel: l.listen,
                    activeLabel: l.pauseNarration,
                    idleIcon: Icons.volume_up_rounded,
                    semantics: l.narrationSemantics,
                    onPressed: audio.toggleNarration,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AudioButton(
                    key: const ValueKey('audio-ambience'),
                    status: audio.ambienceStatus,
                    enabled: prefs.ambienceEnabled,
                    idleLabel: l.sounds,
                    activeLabel: l.pauseSounds,
                    idleIcon: Icons.music_note_rounded,
                    semantics: l.ambienceSemantics,
                    onPressed: audio.toggleAmbience,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TukiPrimaryButton(
            key: const ValueKey('cover-color'),
            label: l.colorIn,
            icon: Icons.brush_rounded,
            onPressed: onColor,
          ),
        ],
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  const _AudioButton({
    super.key,
    required this.status,
    required this.enabled,
    required this.idleLabel,
    required this.activeLabel,
    required this.idleIcon,
    required this.semantics,
    required this.onPressed,
  });

  final TrackStatus status;

  /// Preferencia del área de adultos.
  final bool enabled;
  final String idleLabel;
  final String activeLabel;
  final IconData idleIcon;
  final String Function(String state) semantics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final playing = enabled && status == TrackStatus.playing;
    final unavailable = status == TrackStatus.unavailable;
    final usable = enabled && !unavailable;

    final String label;
    final IconData icon;
    if (!enabled) {
      label = idleLabel;
      icon = Icons.volume_off_rounded;
    } else if (unavailable) {
      label = l.audioUnavailable;
      icon = Icons.error_outline_rounded;
    } else if (playing) {
      label = activeLabel;
      icon = Icons.pause_rounded;
    } else {
      label = idleLabel;
      icon = idleIcon;
    }
    final state = !enabled
        ? l.audioOff
        : unavailable
        ? l.audioUnavailable
        : label;
    final foreground = playing ? Colors.white : TukiColors.turquoise;

    return Semantics(
      button: true,
      enabled: usable,
      label: semantics(state),
      excludeSemantics: true,
      child: Opacity(
        opacity: usable ? 1 : 0.6,
        child: Material(
          color: playing ? TukiColors.turquoise : TukiColors.surface,
          shape: const StadiumBorder(
            side: BorderSide(color: TukiColors.turquoise, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: usable ? onPressed : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: foreground, size: 26),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: tukiText(19, weight: 700, color: foreground),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
