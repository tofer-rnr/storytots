import 'package:audioplayers/audioplayers.dart';

/// Plays looped background music across the whole app, with the ability
/// to temporarily suspend it (e.g., while reading a story) and resume later.
class BackgroundMusicService {
  BackgroundMusicService._();
  static final BackgroundMusicService instance = BackgroundMusicService._();

  final AudioPlayer _player = AudioPlayer();

  bool _initialized = false;
  bool _isPlaying = false;
  double _volume = 0.35; // default gentle volume

  // Suspension handling so multiple pages can request silence safely
  int _suspendCount = 0;
  bool _wasPlayingBeforeSuspend = false;

  Future<void> init({double? volume}) async {
    if (_initialized) return;
    if (volume != null) _volume = volume.clamp(0.0, 1.0);

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_volume);
    try {
      await _player.setSource(AssetSource('sounds/backgroundmusic.mp3'));
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> start() async {
    if (!_initialized) {
      await init();
      if (!_initialized) return; // bail if asset missing
    }
    if (_suspendCount > 0) return; // respect active suspension
    if (_isPlaying) return;
    try {
      await _player.resume(); // resume is faster if already prepared
      _isPlaying = true;
    } catch (_) {
      try {
        await _player.play(AssetSource('sounds/backgroundmusic.mp3'));
        _isPlaying = true;
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (_) {}
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
    } catch (_) {}
  }

  /// Call when entering a context that should be silent (e.g., ReadingPage).
  Future<void> suspend() async {
    if (_suspendCount == 0) {
      _wasPlayingBeforeSuspend = _isPlaying;
      if (_isPlaying) {
        await pause();
      }
    }
    _suspendCount++;
  }

  /// Call when leaving the silent context. Balances [suspend].
  Future<void> resumeFromSuspend() async {
    if (_suspendCount == 0) return;
    _suspendCount--;
    if (_suspendCount == 0 && _wasPlayingBeforeSuspend) {
      _wasPlayingBeforeSuspend = false;
      await start();
    }
  }
}
