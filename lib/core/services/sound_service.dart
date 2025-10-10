import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

/// Global sound service to play short UI sounds with very low latency.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  late final Soundpool _pool = Soundpool.fromOptions(
    options: const SoundpoolOptions(
      maxStreams: 12,
      streamType: StreamType.music,
    ),
  );

  int? _clickSoundId;
  bool _initialized = false;

  // Prefer uncompressed WAV for zero-latency. Fallback to MP3 if WAV missing.
  static const String _wavPath = 'assets/sounds/Pop_sound.wav';
  static const String _mp3Path = 'assets/sounds/Pop_sound.mp3';

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Try WAV first
      ByteData bd;
      try {
        bd = await rootBundle.load(_wavPath);
      } catch (_) {
        bd = await rootBundle.load(_mp3Path);
      }
      _clickSoundId = await _pool.load(bd);
      _initialized = true;

      // Warm-up: play once silently so subsequent plays are instant
      try {
        final sid = await _pool.play(_clickSoundId!);
        await _pool.setVolume(streamId: sid, volume: 0.0);
        await _pool.stop(sid);
      } catch (_) {}
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> playClick() async {
    try {
      if (_initialized && _clickSoundId != null) {
        await _pool.play(_clickSoundId!);
      } else {
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _pool.release();
    } catch (_) {}
  }
}
