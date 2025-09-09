import 'package:flutter/material.dart';
import 'speech/engine.dart';
import 'speech/stt_engine.dart';

enum WordStatus { pending, current, correct, incorrect }

class KaraokeText extends StatelessWidget {
  const KaraokeText({
    super.key,
    required this.tokens,
    required this.statuses,
    this.currentIndex = 0,
  });

  final List<String> tokens;
  final Map<int, WordStatus> statuses;
  final int currentIndex;

  Color _colorFor(int i) {
    final s = statuses[i] ?? WordStatus.pending;
    switch (s) {
      case WordStatus.current:
        return Colors.deepPurple;
      case WordStatus.correct:
        return Colors.green;
      case WordStatus.incorrect:
        return Colors.red;
      case WordStatus.pending:
        return Colors.black87;
    }
  }

  FontWeight _weightFor(int i) {
    final s = statuses[i] ?? WordStatus.pending;
    return s == WordStatus.current ? FontWeight.w800 : FontWeight.w600;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: List.generate(tokens.length, (i) {
        return Text(
          tokens[i],
          style: TextStyle(
            color: _colorFor(i),
            fontWeight: _weightFor(i),
            fontSize: 18,
            height: 1.35,
          ),
        );
      }),
    );
  }
}

class KaraokeReadingPage extends StatefulWidget {
  const KaraokeReadingPage({
    super.key,
    required this.targetText,
  });

  final String targetText;

  @override
  State<KaraokeReadingPage> createState() => _KaraokeReadingPageState();
}

class _KaraokeReadingPageState extends State<KaraokeReadingPage> {
  // Switch to engine-based STT
  // Using the abstraction ensures consistent behavior and delta-word delivery
  late final SpeechEngine _engine;
  bool _engineReady = false;
  bool _isListening = false;
  String? _localeId; // allow system default when null

  late List<String> _targetTokens;
  Map<int, WordStatus> _wordStatuses = {};
  int _currentIndex = 0;
  String _recognizedText = '';

  // Buffer to store recent words for better matching
  final List<String> _recentWords = [];
  static const int _bufferSize = 8;

  String _lang = 'Auto'; // Auto, English, Filipino

  @override
  void initState() {
    super.initState();
    _engine = SpeechToTextEngine();
    _prepareText();
    _initEngine();
  }

  Future<void> _initEngine() async {
    final ok = await _engine.init();
    setState(() {
      _engineReady = ok;
    });
  }

  void _prepareText() {
    // Clean and tokenize the target text
    _targetTokens = widget.targetText
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (_targetTokens.isNotEmpty) {
      _wordStatuses[0] = WordStatus.current;
    }
  }

  String? get _resolvedLocaleFromToggle {
    switch (_lang) {
      case 'English':
        return 'en_US';
      case 'Filipino':
        return 'fil-PH';
      case 'Auto':
      default:
        return null; // let engine auto-resolve
    }
  }

  void _startListening() async {
    if (!_engineReady) return;
    // ignore: avoid_print
    print('[KaraokePage] Start listening (lang=$_lang, locale=${_resolvedLocaleFromToggle ?? 'auto'})');
    await _engine.start(
      onWords: (List<String> newWords) {
        if (newWords.isEmpty) return;
        // Debug transcript
        _recognizedText = (_recognizedText + ' ' + newWords.join(' ')).trim();
        // ignore: avoid_print
        print('[KaraokePage] +${newWords.length} word(s): ${newWords.join(' ')}');

        for (final w in newWords) {
          if (_recentWords.isEmpty || _recentWords.last != w) {
            _recentWords.add(_cleanWord(w));
            if (_recentWords.length > _bufferSize) {
              _recentWords.removeRange(0, _recentWords.length - _bufferSize);
            }
          }
        }
        _processWords();
        if (mounted) setState(() {});
      },
      localeId: _resolvedLocaleFromToggle,
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    // ignore: avoid_print
    print('[KaraokePage] Stop listening');
    await _engine.stop();
    setState(() => _isListening = false);
  }

  void _processWords() {
    if (_currentIndex >= _targetTokens.length) return;
    final currentTargetWord = _cleanWord(_targetTokens[_currentIndex]);

    bool foundMatch = false;
    for (int i = _recentWords.length - 1; i >= 0; i--) {
      final spokenWord = _recentWords[i];
      if (_wordsMatch(spokenWord, currentTargetWord)) {
        foundMatch = true;
        break;
      }
    }

    setState(() {
      if (foundMatch) {
        _wordStatuses[_currentIndex] = WordStatus.correct;
        _currentIndex++;
        if (_currentIndex < _targetTokens.length) {
          _wordStatuses[_currentIndex] = WordStatus.current;
        }
      } else {
        if (_recentWords.isNotEmpty) {
          final lastSpokenWord = _recentWords.last;
          final targetWord = currentTargetWord;
          if (!_wordsPartialMatch(lastSpokenWord, targetWord)) {
            _wordStatuses[_currentIndex] = WordStatus.incorrect;
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted && _currentIndex < _targetTokens.length) {
                setState(() {
                  _wordStatuses[_currentIndex] = WordStatus.current;
                });
              }
            });
          }
        }
      }
    });

    if (_currentIndex >= _targetTokens.length) {
      _showCompletionDialog();
    }
  }

  String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase().trim();
  }

  bool _wordsMatch(String spoken, String target) {
    if (spoken == target) return true;
    final spokenVariations = _getWordVariations(spoken);
    final targetVariations = _getWordVariations(target);
    for (final s in spokenVariations) {
      for (final t in targetVariations) {
        if (s == t) return true;
      }
    }
    return false;
  }

  bool _wordsPartialMatch(String spoken, String target) {
    if (spoken.length < 2 || target.length < 2) return spoken == target;
    final similarity = _calculateSimilarity(spoken, target);
    return similarity > 0.6;
  }

  List<String> _getWordVariations(String word) {
    final variations = <String>[word];
    final commonReplacements = {
      'you': ['u', 'yu'],
      'to': ['too', 'two'],
      'for': ['four', 'fore'],
      'there': ['their', "they're"],
      'your': ["you're", 'ur'],
    };
    commonReplacements.forEach((key, values) {
      if (word == key) {
        variations.addAll(values);
      } else if (values.contains(word)) {
        variations.add(key);
      }
    });
    return variations;
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    final maxLength = a.length > b.length ? a.length : b.length;
    if (maxLength == 0) return 1.0;
    return (maxLength - _levenshteinDistance(a, b)) / maxLength;
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );
    for (int i = 0; i <= a.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= b.length; j++) matrix[0][j] = j;
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[a.length][b.length];
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: const Text('You have completed the reading!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetKaraoke();
            },
            child: const Text('Read Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _resetKaraoke() {
    setState(() {
      _wordStatuses.clear();
      _currentIndex = 0;
      _recentWords.clear();
      _recognizedText = '';
      if (_targetTokens.isNotEmpty) {
        _wordStatuses[0] = WordStatus.current;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karaoke Reading'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
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
                  if (_isListening) {
                    _stopListening();
                    _startListening();
                  }
                },
                icon: const Icon(Icons.language),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: _targetTokens.isEmpty ? 0.0 : _currentIndex / _targetTokens.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            const SizedBox(height: 16),
            Text(
              'Progress: $_currentIndex / ${_targetTokens.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: KaraokeText(
                tokens: _targetTokens,
                statuses: _wordStatuses,
                currentIndex: _currentIndex,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You said:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recognizedText.isEmpty ? 'Start speaking...' : _recognizedText,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontStyle: _recognizedText.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _engineReady ? (_isListening ? _stopListening : _startListening) : null,
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  label: Text(_isListening ? 'Stop' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _resetKaraoke,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Legend:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: const [
                _LegendItem(color: Colors.deepPurple, label: 'Current'),
                _LegendItem(color: Colors.green, label: 'Correct'),
                _LegendItem(color: Colors.red, label: 'Incorrect'),
                _LegendItem(color: Colors.black87, label: 'Pending'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}