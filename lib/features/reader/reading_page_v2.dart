// lib/features/reader/reading_page_v2.dart
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
    this.speechServiceType = SpeechServiceType.deviceSTT, // Toggle this
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
  }

  @override
  void dispose() {
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

  // ---------- Speech Service ----------
  Future<void> _initSpeechService() async {
    // Handle permissions for both services
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
    }

    final ok = await _speechService.init();
    setState(() => _serviceReady = ok);

    if (!ok && mounted) {
      final serviceName = SpeechServiceFactory.getServiceName(
        widget.speechServiceType,
      );
      final errorMsg = widget.speechServiceType == SpeechServiceType.azureSpeech
          ? '$serviceName is not available. Please check your network connection and configuration.'
          : '$serviceName is not available. Please check your device settings.';
      _showServiceNotReadyDialog(errorMsg);
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
      case SpeechServiceType.azureSpeech:
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
      case SpeechServiceType.azureSpeech:
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
        if (widget.speechServiceType == SpeechServiceType.azureSpeech) {
          return 'en-US';
        } else {
          return 'en_US'; // Device STT
        }
      case 'Filipino':
        if (widget.speechServiceType == SpeechServiceType.azureSpeech) {
          return 'fil-PH';
        } else {
          return 'fil-PH'; // Device STT
        }
      case 'Auto':
      default:
        return null;
    }
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
    final currentNum = min(_cursor + 1, total);
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
            tooltip: _listening ? 'Stop listening' : 'Start listening',
            icon: Icon(_listening ? Icons.mic_off : Icons.mic),
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
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Score + progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Accuracy: ${(_accuracy * 100).toStringAsFixed(0)}%'),
                  Text('Word $currentNum/$total'),
                ],
              ),
              const SizedBox(height: 8),

              // Debug: heard text
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _lastHeard.isEmpty ? '—' : 'Heard: $_lastHeard',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 12),

              // Helper text
              if (!_listening)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '👆 Tap any word to mark it as correct, or use the mic to read aloud',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Karaoke (tap word to mark as read, or use mic)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  child: Stack(
                    children: [
                      // Tap handler
                      if (!_listening)
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(
                                      _displayTokens.length,
                                      (i) => GestureDetector(
                                        onTap: () {
                                          if (i == _cursor) {
                                            _speakCurrent(); // Play word
                                            setState(() {
                                              if (_status[i] !=
                                                  WordStatus.correct) {
                                                _status[i] = WordStatus.correct;
                                                _correct++;
                                              }
                                              _cursor++;
                                              if (_cursor <
                                                  _matchTokens.length) {
                                                _status[_cursor] =
                                                    WordStatus.current;
                                              }
                                            });
                                          }
                                        },
                                        child: SizedBox(
                                          height: 32,
                                          child: Text(_displayTokens[i]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),

                      // Actual karaoke display
                      KaraokeText(
                        tokens: _displayTokens,
                        statuses: _status,
                        currentIndex: _cursor,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

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
}
