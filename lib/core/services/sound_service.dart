import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// Global sound service to play short UI sounds with very low latency.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    try {
      // Pre-cache by setting source once so it warms up
      await _player.setSource(AssetSource('sounds/Pop_sound.mp3'));
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> playClick() async {
    try {
      if (_initialized) {
        // Using play with AssetSource each time keeps it simple
        await _player.play(AssetSource('sounds/Pop_sound.mp3'), volume: 1.0);
      } else {
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
