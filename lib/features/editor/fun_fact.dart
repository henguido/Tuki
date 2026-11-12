import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/dependencies.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../chapters/audio/audio_engine.dart';
import '../chapters/catalog.dart';

/// Muestra la curiosidad de [page]. El audio nunca empieza solo: hay que
/// tocar Escuchar, y se detiene al cerrar o al pasar a segundo plano.
Future<void> showFunFact(BuildContext context, CatalogPage page) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TukiColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _FunFactSheet(page: page),
  );
}

class _FunFactSheet extends StatefulWidget {
  const _FunFactSheet({required this.page});
  final CatalogPage page;

  @override
  State<_FunFactSheet> createState() => _FunFactSheetState();
}

class _FunFactSheetState extends State<_FunFactSheet>
    with WidgetsBindingObserver {
  AudioTrack? _track;
  String? _loadedAsset;
  StreamSubscription<void>? _completed;
  StreamSubscription<void>? _interruptions;
  bool _playing = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _completed?.cancel();
    _interruptions?.cancel();
    _track?.dispose();
    super.dispose();
  }

  Future<void> _pause() async {
    if (!_playing) return;
    setState(() => _playing = false);
    await _track?.pause();
  }

  Future<void> _toggle(String asset) async {
    if (_playing) return _pause();
    final engine = AppScope.of(context).audio;
    try {
      if (!await engine.activate()) return;
      var track = _track;
      if (track == null) {
        track = _track = engine.createTrack();
        _completed = track.onCompleted.listen((_) {
          if (mounted) setState(() => _playing = false);
        });
        _interruptions = engine.interruptions.listen((_) => _pause());
      }
      // Cambiar de idioma con la hoja abierta carga la otra narración.
      if (_loadedAsset != asset) {
        await track.load(asset);
        _loadedAsset = asset;
      } else {
        await track.seekToStart();
      }
      await track.play();
      if (mounted) setState(() => _playing = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = contentLanguage(context);
    final prefs = AppScope.of(context).preferences;
    final asset = widget.page.funFactAudioFor(lang);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  color: TukiColors.orange,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l.funFactTitle,
                      style: tukiText(24, weight: 700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.page.funFact!.of(lang),
              key: const ValueKey('fun-fact-text'),
              style: tukiText(21, height: 1.3),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Solo hay botón de audio cuando existe la narración.
                if (asset != null && prefs.narrationEnabled && !_failed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton.icon(
                      key: const ValueKey('fun-fact-listen'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 52),
                        foregroundColor: TukiColors.turquoise,
                        side: const BorderSide(
                          color: TukiColors.turquoise,
                          width: 2,
                        ),
                      ),
                      onPressed: () => _toggle(asset),
                      icon: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.volume_up_rounded,
                      ),
                      label: Text(
                        _playing ? l.pauseNarration : l.listen,
                        style: tukiText(
                          19,
                          weight: 700,
                          color: TukiColors.turquoise,
                        ),
                      ),
                    ),
                  ),
                FilledButton(
                  key: const ValueKey('fun-fact-close'),
                  style: FilledButton.styleFrom(
                    backgroundColor: TukiColors.turquoise,
                    minimumSize: const Size(64, 52),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l.close,
                    style: tukiText(19, weight: 700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
