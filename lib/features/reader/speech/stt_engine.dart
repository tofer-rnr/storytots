import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'engine.dart';

class SpeechToTextEngine implements SpeechEngine {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _ready = false;

  // Logging toggle
  bool _logEnabled = true;
  void _log(String msg) {
    if (_logEnabled) {
      // ignore: avoid_print
      print('[STT Engine] $msg');
    }
  }

  // Track last transcript to compute deltas and avoid duplicates
  String _lastTranscript = '';
  static const double _minConfidence = 0.35;

  @override
  bool get isListening => _stt.isListening;

  @override
  Future<bool> init() async {
    if (_ready) return true;
    _log('Initializing…');
    _ready = await _stt.initialize(
      onStatus: (status) {
        _log('status: $status');
      },
      onError: (err) {
        _log('error: $err');
      },
    );
    _log('Initialized: $_ready');
    return _ready;
  }

  @override
  Future<void> start({
    required void Function(List<String>) onWords,
    String? localeId,
  }) async {
    if (!_ready) {
      final ok = await init();
      if (!ok) return;
    }

    _lastTranscript = '';

    final chosenLocale = await _resolveLocale(localeId);
    _log('Starting listen (locale: ${chosenLocale ?? 'system default'})');

    // NOTE: don't reference SpeechRecognitionResult type directly.
    // Use `dynamic` so analyzer won’t complain across versions.
    await _stt.listen(
      onResult: (dynamic res) {
        final transcript = (res.recognizedWords ?? '').toString();
        if (transcript.trim().isEmpty) return;

        // Ignore exact duplicate partials
        if (transcript.trim() == _lastTranscript.trim()) return;

        // Gate: process only final OR partial with reasonable confidence
        bool finalResult = false;
        bool goodPartial = false;
        try {
          finalResult = (res.finalResult ?? false) as bool;
        } catch (_) {}
        try {
          final hasConf = (res.hasConfidenceRating ?? false) as bool;
          final conf = (res.confidence ?? 0.0) as double;
          goodPartial = hasConf && conf >= _minConfidence;
        } catch (_) {}
        if (!finalResult && !goodPartial) return;

        // Compute delta words (new words since last transcript)
        final currTokens = _normalizeAndTokenize(transcript);
        final prevTokens = _normalizeAndTokenize(_lastTranscript);
        int i = 0;
        final limit = prevTokens.length < currTokens.length ? prevTokens.length : currTokens.length;
        while (i < limit && prevTokens[i] == currTokens[i]) {
          i++;
        }
        final delta = currTokens.sublist(i);

        _lastTranscript = transcript;

        if (delta.isEmpty) return;
        _log('onResult: +${delta.length} new word(s) | total=${currTokens.length}');
        onWords(delta);
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      cancelOnError: false,
      localeId: chosenLocale, // e.g. 'en_US' / 'fil-PH'
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<String?> _resolveLocale(String? requested) async {
    if (requested != null && requested.trim().isNotEmpty) return requested;
    try {
      final locales = await _stt.locales();
      stt.LocaleName? sys;
      try {
        sys = await _stt.systemLocale();
      } catch (_) {
        sys = null;
      }

      // Prefer Filipino/Tagalog if available
      stt.LocaleName? chosen;
      for (final l in locales) {
        final id = l.localeId.toLowerCase();
        final name = l.name.toLowerCase();
        if (id.contains('fil') || id.contains('tl-') || id.contains('tl_') ||
            name.contains('filipino') || name.contains('tagalog')) {
          chosen = l;
          break;
        }
      }
      final result = (chosen ?? sys ?? (locales.isNotEmpty ? locales.first : null))?.localeId;
      _log('Resolved locale: ${result ?? 'none'}');
      return result;
    } catch (e) {
      _log('Locale resolution failed: $e');
      return null; // let OS choose
    }
  }

  List<String> _normalizeAndTokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s']"), ' ') // keep letters, digits, underscore and apostrophes
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  @override
  Future<void> stop() async {
    _log('Stopping listen');
    await _stt.stop();
  }
}
