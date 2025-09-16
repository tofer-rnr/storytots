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

  // Continuous listening support
  bool _continuous = false;
  String? _requestedLocale;
  void Function(List<String>)? _onWords;

  // Track tokens delivered to avoid duplicates across partials/restarts
  List<String> _prevTokens = <String>[];

  static const double _minConfidence = 0.35;

  @override
  bool get isListening => _stt.isListening;

  @override
  Future<bool> init() async {
    if (_ready) return true;
    _log('Initializing…');
    _ready = await _stt.initialize(
      onStatus: (status) async {
        _log('status: $status');
        // If the platform stops listening (silence, end of utterance), keep it alive
        if (!_stt.isListening && _continuous && _onWords != null) {
          // Small delay to let the engine settle
          await Future.delayed(const Duration(milliseconds: 150));
          if (_continuous && !_stt.isListening) {
            _log('Auto-restart listening');
            await _beginListening();
          }
        }
      },
      onError: (err) {
        _log('error: $err');
      },
    );
    _log('Initialized: $_ready');
    return _ready;
  }

  Future<void> _beginListening() async {
    // NOTE: don't reference SpeechRecognitionResult type directly.
    // Use `dynamic` so analyzer won’t complain across versions.
    await _stt.listen(
      onResult: (dynamic res) {
        final transcript = (res.recognizedWords ?? '').toString();
        if (transcript.trim().isEmpty) return;

        // Accept partials by default (iOS often missing confidence)
        bool isFinal = false;
        try {
          isFinal = (res.finalResult ?? false) as bool;
        } catch (_) {}

        bool acceptPartial = true;
        try {
          final hasConf = (res.hasConfidenceRating ?? false) as bool;
          final conf = (res.confidence ?? 0.0) as double;
          if (hasConf) acceptPartial = conf >= _minConfidence;
        } catch (_) {}

        if (!isFinal && !acceptPartial) return;

        // Compute deltas vs the last delivered tokens
        final currTokens = _normalizeAndTokenize(transcript);
        int i = 0;
        final limit = _prevTokens.length < currTokens.length ? _prevTokens.length : currTokens.length;
        while (i < limit && _prevTokens[i] == currTokens[i]) {
          i++;
        }
        final delta = currTokens.sublist(i);
        _prevTokens = currTokens;

        if (delta.isEmpty) return;
        _log('onResult: +${delta.length} new word(s) | total=${currTokens.length}');
        _onWords?.call(delta);
      },
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      cancelOnError: false,
      localeId: _requestedLocale, // e.g. 'en-US' / 'fil-PH'
      listenMode: stt.ListenMode.dictation,
    );
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

    _onWords = onWords;
    _requestedLocale = localeId;
    _continuous = true;
    _prevTokens = <String>[]; // fresh session

    _log('Starting listen (locale: ${_requestedLocale ?? 'system default'})');
    await _beginListening();
  }

  @override
  Future<void> stop() async {
    _log('Stopping listen');
    _continuous = false;
    await _stt.stop();
  }

  List<String> _normalizeAndTokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s']"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }
}
