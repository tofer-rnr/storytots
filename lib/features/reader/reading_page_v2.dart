// lib/features/reader/reading_page_v2.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants.dart';
import 'karaoke_text.dart';
import 'speech/engine.dart';
import 'speech/speech_service_factory.dart';
import '../../data/repositories/library_repository.dart';

class ReadingPageV2 extends StatefulWidget {
  const ReadingPageV2({
    super.key,
    required this.pageText,
    this.minAccuracy = 0.85,
    this.speechServiceType =
        SpeechServiceType.deviceSTT, // Always use device STT
    // Optional: provide to enable favorite toggle and library sync
    this.storyId,
    this.storyTitle,
    this.coverUrl,
  });

  final String pageText;
  final double minAccuracy;
  final SpeechServiceType speechServiceType;
  final String? storyId;
  final String? storyTitle;
  final String? coverUrl;

  @override
  State<ReadingPageV2> createState() => _ReadingPageV2State();
}

class _ReadingPageV2State extends State<ReadingPageV2> {
  // Text + statuses
  late final List<String> _displayTokens; // UI casing
  late final List<String> _matchTokens; // normalized for matching
  final Map<int, WordStatus> _status = {};
  int _cursor = 0;
  int _correct = 0;
  int _incorrect = 0;

  // Speech service (can be STT engine or Google Cloud)
  late final SpeechEngine _speechService;
  bool _serviceReady = false;
  bool _listening = false;
  String _lang = 'Auto'; // Auto, English, Filipino

  // TTS
  final _tts = FlutterTts();

  // Speech processing
  final List<String> _heardBuffer = [];
  static const int _bufferSize = 10;
  String _lastHeard = '';

  // Favorite toggle
  final _libraryRepo = LibraryRepository();
  bool? _isFavorite; // null -> unknown/loading

  // Timer for status polling
  Timer? _statusTimer;

  // Track last mispronounced word
  String? _wrongWord;
  String? _wrongHeard;
  String? _wrongHint;

  @override
  void initState() {
    super.initState();
    // Create speech service based on type
    _speechService = SpeechServiceFactory.create(widget.speechServiceType);

    _prepareTokens(widget.pageText);
    if (_displayTokens.isNotEmpty) _status[0] = WordStatus.current;
    _initTts();
    _initSpeechService();
    _loadFavorite();

    // Periodically sync UI with engine listening state
    _statusTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      final ls = _speechService.isListening;
      if (mounted && ls != _listening) {
        setState(() => _listening = ls);
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _stopListen();
    _tts.stop();
    super.dispose();
  }

  // ---------- Prep ----------
  void _prepareTokens(String text) {
    _displayTokens = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    _matchTokens = _displayTokens
        .map((w) => w.toLowerCase().replaceAll(RegExp(r"[^\w']"), ''))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
  }

  // ---------- TTS ----------
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('fil-PH');
    } catch (_) {}
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> _speakCurrent() async {
    if (_cursor < 0 || _cursor >= _displayTokens.length) return;
    await _tts.stop();
    await _tts.speak(_displayTokens[_cursor]);
  }

  // Speak any word with TTS
  Future<void> _speakWord(String w) async {
    await _tts.stop();
    await _tts.speak(w);
  }

  // ---------- Speech Service ----------
  Future<void> _initSpeechService() async {
    // Handle permissions for both platforms
    if (Platform.isAndroid) {
      final mic = await Permission.microphone.status;
      if (!mic.isGranted) {
        final res = await Permission.microphone.request();
        if (!res.isGranted) {
          setState(() => _serviceReady = false);
          _showServiceNotReadyDialog(
            'Microphone permission is required for speech recognition.',
          );
          return;
        }
      }
    } else if (Platform.isIOS) {
      // iOS needs both Speech and Microphone permissions
      final mic = await Permission.microphone.status;
      if (!mic.isGranted) {
        await Permission.microphone.request();
      }
      final speech = await Permission.speech.status;
      if (!speech.isGranted) {
        await Permission.speech.request();
      }
      final micOk = await Permission.microphone.isGranted;
      final speechOk = await Permission.speech.isGranted;
      if (!micOk || !speechOk) {
        setState(() => _serviceReady = false);
        _showServiceNotReadyDialog(
          'Please allow Microphone and Speech Recognition in Settings to enable reading.',
        );
        return;
      }
    }

    final ok = await _speechService.init();
    setState(() => _serviceReady = ok);

    if (!ok && mounted) {
      final serviceName = SpeechServiceFactory.getServiceName(
        widget.speechServiceType,
      );
      final errorMsg =
          widget.speechServiceType == SpeechServiceType.openaiWhisper
          ? '$serviceName is not available. Please check your network connection and configuration.'
          : '$serviceName is not available. Please check your device settings.';
      _showServiceNotReadyDialog(errorMsg);
    }

    // Auto-start listening when ready
    if (ok && mounted && !_listening) {
      await _startListen();
    }
  }

  Future<void> _showServiceNotReadyDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Speech Service Issue'),
          ],
        ),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper methods for service-specific UI styling
  List<Color> _getServiceColor() {
    switch (widget.speechServiceType) {
      case SpeechServiceType.deviceSTT:
        return [Colors.green[100]!, Colors.green[300]!, Colors.green[700]!];
      case SpeechServiceType.openaiWhisper:
        return [Colors.blue[100]!, Colors.blue[300]!, Colors.blue[700]!];
      // case SpeechServiceType.googleCloudAPI:
      //   return [Colors.blue[100]!, Colors.blue[300]!, Colors.blue[700]!];
      // case SpeechServiceType.whisperAI:
      //   return [Colors.purple[100]!, Colors.purple[300]!, Colors.purple[700]!];
      // case SpeechServiceType.openaiWhisper:
      //   return [Colors.orange[100]!, Colors.orange[300]!, Colors.orange[700]!];
    }
  }

  IconData _getServiceIcon() {
    switch (widget.speechServiceType) {
      case SpeechServiceType.deviceSTT:
        return Icons.phone_android;
      case SpeechServiceType.openaiWhisper:
        return Icons.cloud_queue;
      // case SpeechServiceType.googleCloudAPI:
      //   return Icons.cloud;
      // case SpeechServiceType.whisperAI:
      //   return Icons.psychology;
      // case SpeechServiceType.openaiWhisper:
      //   return Icons.auto_awesome;
    }
  }

  String? get _resolvedLocaleFromToggle {
    switch (_lang) {
      case 'English':
        if (Platform.isIOS) return 'en-US';
        return 'en_US';
      case 'Filipino':
        if (Platform.isIOS) return 'fil-PH';
        return 'fil-PH';
      case 'Auto':
      default:
        return null;
    }
  }

  // Provide a simple pronunciation hint for the current word
  String get _pronounceHint {
    if (_cursor >= _displayTokens.length) return '';
    var w = _displayTokens[_cursor].toLowerCase();
    w = w.replaceAll(RegExp(r'[^a-z]'), '');
    if (w.isEmpty) return '';

    const vowels = 'aeiou';
    final buf = StringBuffer();
    for (int i = 0; i < w.length; i++) {
      final ch = w[i];
      buf.write(ch);
      final isVowel = vowels.contains(ch);
      if (isVowel && i < w.length - 1) {
        buf.write('-');
      }
    }
    var hint = buf.toString();
    hint = hint.replaceAll(RegExp(r'-+'), '-');
    if (hint.startsWith('-')) hint = hint.substring(1);
    if (hint.endsWith('-')) hint = hint.substring(0, hint.length - 1);
    return hint;
  }

  // --- similarity helpers for wrong-word diagnostics ---
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    final m = a.length, n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;
    final d = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) d[i][0] = i;
    for (int j = 0; j <= n; j++) d[0][j] = j;
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return d[m][n];
  }

  double _similarity(String a, String b) {
    final maxL = max(a.length, b.length);
    if (maxL == 0) return 1.0;
    return (maxL - _levenshtein(a, b)) / maxL;
  }

  String? _closestInTail(String target, List<String> tail) {
    if (tail.isEmpty) return null;
    String best = tail.last;
    double bestScore = _similarity(best, target);
    for (final w in tail) {
      final s = _similarity(w, target);
      if (s > bestScore) {
        best = w;
        bestScore = s;
      }
    }
    return best;
  }

  Future<void> _startListen() async {
    if (!_serviceReady) return;
    _heardBuffer.clear();
    _lastHeard = '';

    final serviceName = SpeechServiceFactory.getServiceName(
      widget.speechServiceType,
    );
    print('[ReadingPageV2] Start $serviceName listening (lang=$_lang)');

    await _speechService.start(
      onWords: (words) {
        if (words.isEmpty) return;
        _lastHeard = (_lastHeard + ' ' + words.join(' ')).trim();

        for (final w in words) {
          final norm = w.toLowerCase().replaceAll(RegExp(r"[^\w']"), '').trim();
          if (norm.isEmpty) continue;
          if (_heardBuffer.isEmpty || _heardBuffer.last != norm) {
            _heardBuffer.add(norm);
            if (_heardBuffer.length > _bufferSize) {
              _heardBuffer.removeRange(0, _heardBuffer.length - _bufferSize);
            }
          }
        }
        _processHeard();
        if (mounted) setState(() {});
      },
      localeId: _resolvedLocaleFromToggle,
    );
    setState(() => _listening = true);
  }

  Future<void> _stopListen() async {
    print('[ReadingPageV2] Stop listening');
    await _speechService.stop();
    if (mounted) setState(() => _listening = false);
  }

  // ---------- Matching ----------
  void _processHeard() {
    if (_cursor >= _matchTokens.length || _heardBuffer.isEmpty) return;

    final currentTarget = _matchTokens[_cursor];
    final tailSize = min(_bufferSize, _heardBuffer.length);
    final tail = _heardBuffer.sublist(_heardBuffer.length - tailSize);
    final matched = tail.contains(currentTarget);

    setState(() {
      if (matched) {
        // clear wrong diagnostics when correct
        _wrongWord = null;
        _wrongHeard = null;
        _wrongHint = null;
        if (_status[_cursor] != WordStatus.correct) {
          _status[_cursor] = WordStatus.correct;
          _correct++;
        }
        _cursor++;
        if (_cursor < _matchTokens.length) {
          _status[_cursor] = WordStatus.current;
        }
      } else {
        _status[_cursor] = WordStatus.incorrect;
        // capture wrong diagnostics
        final heard = _closestInTail(currentTarget, tail);
        _wrongWord = _displayTokens[_cursor];
        _wrongHeard = heard;
        _wrongHint = _syllablesOf(_wrongWord!);
      }
    });
  }

  double get _accuracy {
    final attempted = max(1, _correct + _incorrect);
    return _correct / attempted;
  }

  bool get _canProceed => _accuracy >= widget.minAccuracy;

  // ---------- Favorites (same as original) ----------
  Future<void> _loadFavorite() async {
    if (widget.storyId == null) return;
    try {
      final entry = await _libraryRepo.getByStoryId(widget.storyId!);
      setState(() => _isFavorite = entry?.isFavorite ?? false);
    } catch (_) {
      setState(() => _isFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final id = widget.storyId;
    if (id == null) return;

    try {
      await _libraryRepo.ensureRow(
        storyId: id,
        title: widget.storyTitle ?? 'Untitled',
        coverUrl: widget.coverUrl,
      );
    } catch (_) {}

    final newVal = !(_isFavorite ?? false);
    setState(() => _isFavorite = newVal);
    try {
      await _libraryRepo.toggleFavorite(id, newVal);
      if (mounted) {
        await _showFavoriteDialog(added: newVal);
      }
    } catch (e) {
      setState(() => _isFavorite = !newVal);
      if (mounted) {
        await _showFavoriteErrorDialog();
      }
    }
  }

  Future<void> _showFavoriteDialog({required bool added}) async {
    final icon = added ? Icons.favorite : Icons.favorite_border;
    final iconColor = added ? Colors.pinkAccent : Colors.grey;
    final title = added ? 'Added to Favorites!' : 'Removed from Favorites';
    final msg = added
        ? 'Great choice! We saved this story in your Favorites. You can find it in the Library.'
        : 'No worries! This story was removed from Favorites. You can add it again anytime.';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(brandPurple).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Text(
            msg,
            style: const TextStyle(color: Colors.black87, height: 1.35),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(brandPurple),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Okay'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFavoriteErrorDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Oops! Something went wrong',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: const Text(
            'We couldn\'t update your Favorites. Please try again.',
            style: TextStyle(color: Colors.black87, height: 1.35),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF607D8B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Okay'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final total = _displayTokens.length;
    final serviceName = SpeechServiceFactory.getServiceName(
      widget.speechServiceType,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
        title: Text('Read Aloud ($serviceName)'),
        actions: [
          // Favorite (if storyId provided)
          if (widget.storyId != null)
            IconButton(
              tooltip: (_isFavorite ?? false)
                  ? 'Unfavorite'
                  : 'Add to favorites',
              icon: Icon(
                (_isFavorite ?? false) ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _lang,
              items: const [
                DropdownMenuItem(value: 'Auto', child: Text('Auto')),
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Filipino', child: Text('Filipino')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _lang = v);
                if (_listening) {
                  _stopListen();
                  _startListen();
                }
              },
              icon: const Icon(Icons.language, color: Colors.white),
              dropdownColor: const Color(brandPurple),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            tooltip: _listening ? 'Listening (tap to stop)' : 'Start listening',
            icon: Icon(_listening ? Icons.mic : Icons.mic_off),
            onPressed: !_serviceReady
                ? null
                : () async {
                    if (_listening) {
                      await _stopListen();
                    } else {
                      await _startListen();
                    }
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getServiceColor()[0],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getServiceColor()[1]),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getServiceIcon(),
                      size: 16,
                      color: _getServiceColor()[2],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Using: $serviceName',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getServiceColor()[2],
                      ),
                    ),
                    if (_listening) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.mic, size: 14, color: Colors.redAccent),
                            SizedBox(width: 4),
                            Text(
                              'Listening…',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Karaoke text display
              Expanded(
                child: SingleChildScrollView(
                  child: GestureDetector(
                    // Long-press to hear pronunciation only (does not mark correct)
                    onLongPress: () {
                      _speakCurrent();
                    },
                    child: KaraokeText(
                      tokens: _displayTokens,
                      statuses: _status,
                      currentIndex: _cursor,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Red mic button in center
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _listening ? Colors.red.shade600 : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: !_serviceReady
                        ? null
                        : () async {
                            if (_listening) {
                              await _stopListen();
                            } else {
                              await _startListen();
                            }
                          },
                    icon: Icon(
                      _listening ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Accuracy information at bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Accuracy: ${(_accuracy * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Word ${min(_cursor + 1, total)}/$total',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_cursor < _matchTokens.length) ...[
                      Text(
                        'Expected: ${_displayTokens[_cursor]}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if ((_status[_cursor] == WordStatus.incorrect) &&
                          _pronounceHint.isNotEmpty)
                        Text(
                          'Say it like: $_pronounceHint',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                    Text(
                      'Heard: ${_lastHeard.isEmpty ? '—' : _lastHeard}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),

                    if (_wrongWord != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Try: ${_wrongWord!}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (_wrongHeard != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'You said: ${_wrongHeard!}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _wrongHint ?? '',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(brandPurple),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _speakWord(_wrongWord!),
                                icon: const Icon(Icons.volume_up),
                                label: const Text('Hear it'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Controls
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip word'),
                      onPressed: () {
                        setState(() {
                          if (_cursor < _matchTokens.length) {
                            _status[_cursor] = WordStatus.incorrect;
                            _incorrect++;
                            _cursor++;
                            if (_cursor < _matchTokens.length) {
                              _status[_cursor] = WordStatus.current;
                            }
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canProceed
                          ? () => Navigator.pop(context, true)
                          : null,
                      child: const Text('Next page'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _syllablesOf(String word) {
    var w = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (w.isEmpty) return '';
    const vowels = 'aeiou';
    final buf = StringBuffer();
    for (int i = 0; i < w.length; i++) {
      final ch = w[i];
      buf.write(ch);
      if (vowels.contains(ch) && i < w.length - 1) buf.write('-');
    }
    var hint = buf.toString().replaceAll(RegExp(r'-+'), '-');
    if (hint.startsWith('-')) hint = hint.substring(1);
    if (hint.endsWith('-')) hint = hint.substring(0, hint.length - 1);
    return hint;
  }
}
