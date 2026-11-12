import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_engine.dart';

class JustAudioEngine implements AudioEngine {
  final StreamController<void> _interruptions = StreamController.broadcast();
  AudioSession? _session;

  Future<AudioSession> _ensureSession() async {
    final existing = _session;
    if (existing != null) return existing;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((event) {
      if (event.begin) _interruptions.add(null);
    });
    session.becomingNoisyEventStream.listen((_) => _interruptions.add(null));
    return _session = session;
  }

  @override
  Future<bool> activate() async {
    try {
      final session = await _ensureSession();
      return await session.setActive(true);
    } catch (_) {
      // Sin sesión de audio se intenta reproducir igualmente.
      return true;
    }
  }

  @override
  Stream<void> get interruptions => _interruptions.stream;

  @override
  AudioTrack createTrack() => _JustAudioTrack();
}

class _JustAudioTrack implements AudioTrack {
  // Las interrupciones las coordina ChapterAudioController: tras una
  // interrupción solo se reanuda por acción del usuario.
  final AudioPlayer _player = AudioPlayer(handleInterruptions: false);

  @override
  Future<void> load(String asset) async {
    await _player.setAsset(asset);
  }

  @override
  Future<void> setLooping(bool looping) =>
      _player.setLoopMode(looping ? LoopMode.one : LoopMode.off);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> play() async {
    // play() de just_audio termina cuando acaba la pista: no se espera.
    unawaited(_player.play().catchError((Object _) {}));
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekToStart() => _player.seek(Duration.zero);

  @override
  Stream<void> get onCompleted => _player.processingStateStream
      .where((s) => s == ProcessingState.completed)
      .map((_) {});

  @override
  Future<void> dispose() => _player.dispose();
}
