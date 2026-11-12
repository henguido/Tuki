import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio_engine.dart';

enum TrackStatus {
  /// Lista para reproducir (detenida o en pausa).
  ready,
  playing,

  /// Falta la pista o falló: el resto de la pantalla sigue disponible.
  unavailable,
}

/// Coordina la narración y el ambiente de la portada.
///
/// - Solo reproduce tras una acción del usuario.
/// - El ambiente suena en bucle y baja de volumen mientras habla la voz.
/// - [stopAll] detiene ambas pistas (salir de la portada, segundo plano o
///   interrupción del sistema). Solo se reanuda por acción del usuario.
class ChapterAudioController extends ChangeNotifier {
  ChapterAudioController({
    required AudioEngine engine,
    required String narrationAsset,
    required String ambienceAsset,
  }) : _engine = engine,
       _narrationAsset = narrationAsset,
       _ambienceAsset = ambienceAsset {
    _narration = engine.createTrack();
    _ambience = engine.createTrack();
    _completedSub = _narration.onCompleted.listen((_) => _onNarrationDone());
    _interruptSub = engine.interruptions.listen((_) => stopAll());
    unawaited(_prepareNarration());
  }

  static const double ambienceVolume = 0.8;
  static const double duckedVolume = 0.2;
  static const double narrationVolume = 1.0;

  final AudioEngine _engine;
  late final AudioTrack _narration;
  late final AudioTrack _ambience;
  late final StreamSubscription<void> _completedSub;
  late final StreamSubscription<void> _interruptSub;

  String _narrationAsset;
  final String _ambienceAsset;

  TrackStatus _narrationStatus = TrackStatus.ready;
  TrackStatus _ambienceStatus = TrackStatus.ready;
  String? _loadedNarration;
  bool _ambienceLoaded = false;
  Future<void> _queue = Future.value();
  bool _disposed = false;

  TrackStatus get narrationStatus => _narrationStatus;
  TrackStatus get ambienceStatus => _ambienceStatus;
  String get narrationAsset => _narrationAsset;

  /// Encadena operaciones para que no se crucen entre sí.
  Future<void> _run(Future<void> Function() action) {
    final next = _queue.then((_) => _disposed ? null : action());
    _queue = next.catchError((Object _) {});
    return next;
  }

  void _set({TrackStatus? narration, TrackStatus? ambience}) {
    var changed = false;
    if (narration != null && narration != _narrationStatus) {
      _narrationStatus = narration;
      changed = true;
    }
    if (ambience != null && ambience != _ambienceStatus) {
      _ambienceStatus = ambience;
      changed = true;
    }
    if (changed && !_disposed) notifyListeners();
  }

  Future<void> _applyAmbienceVolume() async {
    if (!_ambienceLoaded) return;
    await _ambience.setVolume(
      _narrationStatus == TrackStatus.playing ? duckedVolume : ambienceVolume,
    );
  }

  Future<bool> _loadNarration() async {
    if (_loadedNarration == _narrationAsset) return true;
    try {
      await _narration.load(_narrationAsset);
      await _narration.setLooping(false);
      await _narration.setVolume(narrationVolume);
      _loadedNarration = _narrationAsset;
      if (_narrationStatus == TrackStatus.unavailable) {
        _set(narration: TrackStatus.ready);
      }
      return true;
    } catch (_) {
      _loadedNarration = null;
      _set(narration: TrackStatus.unavailable);
      await _applyAmbienceVolume();
      return false;
    }
  }

  /// Deja lista la pista del idioma actual sin reproducirla.
  Future<void> _prepareNarration() => _run(() async {
    await _loadNarration();
  });

  /// Cambia la pista de narración (cambio de idioma): detiene la anterior y
  /// deja preparada la nueva.
  Future<void> setNarrationAsset(String asset) {
    if (asset == _narrationAsset) return Future.value();
    _narrationAsset = asset;
    return _run(() async {
      if (_narrationStatus == TrackStatus.playing) {
        try {
          await _narration.pause();
        } catch (_) {}
      }
      _set(narration: TrackStatus.ready);
      await _applyAmbienceVolume();
      await _loadNarration();
    });
  }

  Future<void> toggleNarration() => _run(() async {
    if (_narrationStatus == TrackStatus.playing) {
      try {
        await _narration.pause();
      } catch (_) {}
      _set(narration: TrackStatus.ready);
      await _applyAmbienceVolume();
      return;
    }
    if (!await _loadNarration()) return;
    try {
      await _engine.activate();
      _set(narration: TrackStatus.playing);
      await _applyAmbienceVolume();
      await _narration.play();
    } catch (_) {
      _loadedNarration = null;
      _set(narration: TrackStatus.unavailable);
      await _applyAmbienceVolume();
    }
  });

  Future<void> toggleAmbience() => _run(() async {
    if (_ambienceStatus == TrackStatus.playing) {
      try {
        await _ambience.pause();
      } catch (_) {}
      _set(ambience: TrackStatus.ready);
      return;
    }
    try {
      if (!_ambienceLoaded) {
        await _ambience.load(_ambienceAsset);
        await _ambience.setLooping(true);
        _ambienceLoaded = true;
      }
      await _engine.activate();
      await _applyAmbienceVolume();
      await _ambience.play();
      _set(ambience: TrackStatus.playing);
    } catch (_) {
      _ambienceLoaded = false;
      _set(ambience: TrackStatus.unavailable);
    }
  });

  void _onNarrationDone() {
    _run(() async {
      if (_narrationStatus != TrackStatus.playing) return;
      try {
        await _narration.pause();
        await _narration.seekToStart();
      } catch (_) {}
      _set(narration: TrackStatus.ready);
      await _applyAmbienceVolume();
    });
  }

  /// Detiene ambas pistas y las deja al inicio.
  Future<void> stopAll() => _run(() async {
    if (_narrationStatus == TrackStatus.playing ||
        _loadedNarration != null && _narrationStatus == TrackStatus.ready) {
      try {
        await _narration.pause();
        await _narration.seekToStart();
      } catch (_) {}
    }
    if (_ambienceLoaded) {
      try {
        await _ambience.pause();
        await _ambience.seekToStart();
      } catch (_) {}
    }
    _set(
      narration: _narrationStatus == TrackStatus.playing
          ? TrackStatus.ready
          : null,
      ambience: _ambienceStatus == TrackStatus.playing
          ? TrackStatus.ready
          : null,
    );
    await _applyAmbienceVolume();
  });

  @override
  void dispose() {
    _disposed = true;
    _completedSub.cancel();
    _interruptSub.cancel();
    // Fuera de la cola: liberar ya los reproductores detiene el sonido.
    unawaited(_narration.dispose().catchError((Object _) {}));
    unawaited(_ambience.dispose().catchError((Object _) {}));
    super.dispose();
  }
}
