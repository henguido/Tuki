import 'dart:async';

/// Una pista local. Se abstrae para probar la coordinación sin dispositivo.
abstract class AudioTrack {
  /// Prepara el asset. Lanza si falta o no se puede decodificar.
  Future<void> load(String asset);
  Future<void> setLooping(bool looping);
  Future<void> setVolume(double volume);

  /// Empieza o reanuda. No espera al final de la pista.
  Future<void> play();
  Future<void> pause();
  Future<void> seekToStart();

  /// Emite cuando una pista sin bucle llega al final.
  Stream<void> get onCompleted;
  Future<void> dispose();
}

abstract class AudioEngine {
  AudioTrack createTrack();

  /// Pide el foco de audio antes de reproducir.
  Future<bool> activate();

  /// Interrupciones del sistema que impiden reproducir (llamada, otra app
  /// que toma el foco, auriculares desconectados).
  Stream<void> get interruptions;
}
