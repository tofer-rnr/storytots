import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Global sound service to play short UI sounds with very low latency.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  AudioPlayer? _player;
  bool _initialized = false;
  String? _assetToUse; // e.g., 'sounds/Pop_Sound.WAV' or 'sounds/Pop_sound.mp3'
  double _sfxVolume = 1.0; // 0.0 - 1.0

  static const _prefsKey = 'sfxVolume';

  // Prefer uncompressed WAV for lowest latency. Fallback to MP3 if WAV missing.
  static const String _wavAssetBundlePath = 'assets/sounds/Pop_sound.wav';
  static const String _mp3AssetBundlePath = 'assets/sounds/Pop_sound.mp3';

  bool get isInitialized => _initialized;
  double get currentSfxVolume => _sfxVolume;

  Future<void> init() async {
    if (_initialized) return;

    // Load persisted volume
    try {
      final prefs = await SharedPreferences.getInstance();
      _sfxVolume = (prefs.getDouble(_prefsKey) ?? 1.0).clamp(0.0, 1.0);
    } catch (_) {}

    // Resolve actual asset path robustly (case-insensitive, WAV preferred)
    final resolved = await _resolvePopAssetRelative();
    if (resolved == null) {
      _initialized = false;
      return;
    }
    _assetToUse = resolved; // relative to assets/

    // Dedicated low-latency player for SFX
    final p = AudioPlayer();
    try {
      // Use media stream to avoid OEM sonification restrictions in release
      await p.setAudioContext(
        const AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            isSpeakerphoneOn: false,
            stayAwake: false,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: [AVAudioSessionOptions.mixWithOthers],
          ),
        ),
      );

      await p.setReleaseMode(ReleaseMode.stop);
      await p.setVolume(_sfxVolume);

      // Set source once and warm up: resume/pause to prebuffer
      await p.setSource(AssetSource(_assetToUse!));
      await p.setVolume(0.0);
      await p.resume();
      await p.pause();
      await p.setVolume(_sfxVolume);

      _player = p;
      _initialized = true;
    } catch (_) {
      try {
        await p.dispose();
      } catch (_) {}
      _player = null;
      _initialized = false;
    }
  }

  Future<void> setSfxVolume(double v) async {
    _sfxVolume = v.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(_sfxVolume);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsKey, _sfxVolume);
    } catch (_) {}
  }

  Future<void> playClick() async {
    try {
      if (!_initialized) {
        await init();
      }
      if (_player != null) {
        try {
          // Restart from beginning and resume
          await _player!.setVolume(_sfxVolume);
          await _player!.seek(Duration.zero);
          await _player!.resume();
        } catch (_) {
          // Fallback: attempt direct play using AssetSource once
          if (_assetToUse != null) {
            try {
              await _player!.play(AssetSource(_assetToUse!));
            } catch (_) {}
          }
        }
      } else {
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
  }

  // Discover the correct pop sound asset from AssetManifest and return path relative to 'assets/' for AssetSource
  Future<String?> _resolvePopAssetRelative() async {
    try {
      // Fast path: try our known paths first
      try {
        await rootBundle.load(_wavAssetBundlePath);
        return 'sounds/Pop_sound.wav';
      } catch (_) {}
      try {
        await rootBundle.load(_mp3AssetBundlePath);
        return 'sounds/Pop_sound.mp3';
      } catch (_) {}

      // Inspect manifest for any matching asset (handles case differences like Pop_Sound.WAV)
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = jsonDecode(manifestJson);
      final keys = manifest.keys.toList();

      String? pick(List<String> candidates) {
        for (final c in candidates) {
          final match = keys.firstWhere(
            (k) => k.toLowerCase() == c.toLowerCase(),
            orElse: () => '',
          );
          if (match.isNotEmpty) {
            // strip leading 'assets/'
            return match.startsWith('assets/') ? match.substring(7) : match;
          }
        }
        return null;
      }

      // Prefer WAV names, then MP3
      final wav = pick([
        'assets/sounds/Pop_Sound.WAV',
        'assets/sounds/Pop_sound.wav',
        'assets/sounds/pop_sound.wav',
      ]);
      if (wav != null) return wav;

      final mp3 = pick([
        'assets/sounds/Pop_sound.mp3',
        'assets/sounds/pop_sound.mp3',
      ]);
      return mp3;
    } catch (_) {
      return null;
    }
  }
}
