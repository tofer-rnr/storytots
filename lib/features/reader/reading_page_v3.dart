// lib/features/reader/reading_page_v3.dart
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

class ReadingPageV3 extends StatefulWidget {
  const ReadingPageV3({
    super.key,
    required this.pageText,
    this.minAccuracy = 0.75,
    this.speechServiceType = SpeechServiceType.deviceSTT,
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
  State<ReadingPageV3> createState() => _ReadingPageV3State();
}

class _ReadingPageV3State extends State<ReadingPageV3> {
  // Text processing - sentences and words
  late final List<String> _sentences;
  late final List<List<String>> _sentenceWords; // Display words per sentence
  late final List<List<String>> _sentenceMatchWords; // Normalized words for matching
  
  // Progress tracking
  int _currentSentence = 0;
  final Map<int, Map<int, WordStatus>> _wordStatus = {}; // sentence -> word -> status
  final Map<int, bool> _sentenceCompleted = {}; // sentence completion status
  
  // Speech service
  late final SpeechEngine _speechService;
  bool _serviceReady = false;
  bool _listening = false;
  String _lang = 'Auto';
  
  // Speech processing - enhanced for sentences
  String _currentTranscript = '';
  String _expectedSentence = '';
  String _heardSentence = '';
  List<String> _incorrectWords = [];
  Map<String, String> _pronunciationGuide = {};
  bool _isProcessingSentence = false;
  Timer? _sentenceTimeout;
  static const Duration _sentenceTimeoutDuration = Duration(seconds: 3);
  
  // TTS
  final _tts = FlutterTts();
  
  // UI state
  final _libraryRepo = LibraryRepository();
  bool? _isFavorite;
  Timer? _statusTimer;
  
  // Enhanced pronunciation feedback
  Map<String, String> _mispronunciationFeedback = {};
  List<String> _currentSentenceMistakes = [];

  @override
  void initState() {
    super.initState();
    _speechService = SpeechServiceFactory.create(widget.speechServiceType);
    _prepareSentences(widget.pageText);
    _initializeWordStatus();
    _initTts();
    _initSpeechService();
    _loadFavorite();
    
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
    _sentenceTimeout?.cancel();
    _stopListen();
    _tts.stop();
    super.dispose();
  }

  // ---------- Text Preparation ----------
  void _prepareSentences(String text) {
    // Split text into sentences
    _sentences = text
        .trim()
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    
    // Extract words for each sentence
    _sentenceWords = [];
    _sentenceMatchWords = [];
    
    for (String sentence in _sentences) {
      final displayWords = sentence
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      
      final matchWords = displayWords
          .map((w) => w.toLowerCase().replaceAll(RegExp(r"[^\w']"), ''))
          .where((w) => w.isNotEmpty)
          .toList();
      
      _sentenceWords.add(displayWords);
      _sentenceMatchWords.add(matchWords);
    }
    
    print('📚 Prepared ${_sentences.length} sentences for reading');
  }

  void _initializeWordStatus() {
    for (int s = 0; s < _sentences.length; s++) {
      _wordStatus[s] = {};
      _sentenceCompleted[s] = false;
      for (int w = 0; w < _sentenceWords[s].length; w++) {
        _wordStatus[s]![w] = s == 0 && w == 0 ? WordStatus.current : WordStatus.pending;
      }
    }
  }

  // ---------- TTS ----------
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage(_lang == 'Filipino' ? 'fil-PH' : 'en-US');
    } catch (_) {}
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  Future<void> _speakCurrentSentence() async {
    if (_currentSentence >= _sentences.length) return;
    await _tts.stop();
    await _tts.speak(_sentences[_currentSentence]);
  }



  Future<void> _speakPronunciation(String word) async {
    final pronunciation = _generatePronunciationHint(word);
    await _tts.stop();
    await _tts.speak("$word is pronounced as $pronunciation");
  }

  // ---------- Speech Service ----------
  Future<void> _initSpeechService() async {
    // Handle permissions
    if (Platform.isAndroid) {
      final mic = await Permission.microphone.status;
      if (!mic.isGranted) {
        final res = await Permission.microphone.request();
        if (!res.isGranted) {
          setState(() => _serviceReady = false);
          _showServiceNotReadyDialog('Microphone permission is required for speech recognition.');
          return;
        }
      }
    } else if (Platform.isIOS) {
      final mic = await Permission.microphone.status;
      final speech = await Permission.speech.status;
      if (!mic.isGranted) await Permission.microphone.request();
      if (!speech.isGranted) await Permission.speech.request();
      final micOk = await Permission.microphone.isGranted;
      final speechOk = await Permission.speech.isGranted;
      if (!micOk || !speechOk) {
        setState(() => _serviceReady = false);
        _showServiceNotReadyDialog('Please allow Microphone and Speech Recognition in Settings.');
        return;
      }
    }

    final ok = await _speechService.init();
    setState(() => _serviceReady = ok);

    if (!ok && mounted) {
      final serviceName = SpeechServiceFactory.getServiceName(widget.speechServiceType);
      _showServiceNotReadyDialog('$serviceName is not available. Please check your settings.');
    }

    // Initialize expected sentence for current position
    if (ok && _currentSentence < _sentences.length) {
      _expectedSentence = _sentences[_currentSentence];
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

  String? get _resolvedLocaleFromToggle {
    switch (_lang) {
      case 'English':
        return Platform.isIOS ? 'en-US' : 'en_US';
      case 'Filipino':
        return 'fil-PH';
      case 'Auto':
      default:
        return null;
    }
  }

  Future<void> _startListen() async {
    if (!_serviceReady) return;
    
    _currentTranscript = '';
    _heardSentence = '';
    _incorrectWords.clear();
    _pronunciationGuide.clear();
    _currentSentenceMistakes.clear();
    
    // Set expected sentence
    if (_currentSentence < _sentences.length) {
      _expectedSentence = _sentences[_currentSentence];
    }
    
    print('[ReadingPageV3] Start listening for sentence: $_expectedSentence');

    await _speechService.start(
      onWords: (words) {
        if (words.isEmpty) return;
        
        // Build sentence transcript
        final newWords = words.join(' ');
        _currentTranscript = (_currentTranscript + ' ' + newWords).trim();
        _heardSentence = _currentTranscript;
        
        // Analyze in real-time for feedback
        _analyzeRealTime();
        
        // Reset sentence timeout
        _sentenceTimeout?.cancel();
        _sentenceTimeout = Timer(_sentenceTimeoutDuration, () {
          _processSentenceComplete();
        });
        
        if (mounted) setState(() {});
        print('[ReadingPageV3] Transcript: $_currentTranscript');
      },
      localeId: _resolvedLocaleFromToggle,
    );
    setState(() => _listening = true);
  }

  Future<void> _stopListen() async {
    print('[ReadingPageV3] Stop listening');
    _sentenceTimeout?.cancel();
    await _speechService.stop();
    if (mounted) setState(() => _listening = false);
  }

  // ---------- Enhanced Sentence Processing ----------
  void _analyzeRealTime() {
    if (_currentSentence >= _sentences.length) return;
    
    final spokenWords = _normalizeWords(_currentTranscript);
    final expectedWords = _sentenceMatchWords[_currentSentence];
    
    // Clear previous analysis
    _incorrectWords.clear();
    _pronunciationGuide.clear();
    
    // Quick word-by-word comparison for real-time feedback
    for (int i = 0; i < expectedWords.length && i < spokenWords.length; i++) {
      final expected = expectedWords[i];
      final spoken = spokenWords[i];
      
      final similarity = _calculateSimilarity(expected, spoken);
      if (similarity < 0.7) { // Not a good match
        _incorrectWords.add(expected);
        _pronunciationGuide[expected] = _generatePronunciationHint(expected);
      }
    }
    
    // Check for missing words
    if (spokenWords.length < expectedWords.length) {
      for (int i = spokenWords.length; i < expectedWords.length; i++) {
        final expected = expectedWords[i];
        if (!_incorrectWords.contains(expected)) {
          _incorrectWords.add(expected);
          _pronunciationGuide[expected] = _generatePronunciationHint(expected);
        }
      }
    }
  }

  void _processSentenceComplete() {
    if (_currentSentence >= _sentences.length || _isProcessingSentence) return;
    
    _isProcessingSentence = true;
    print('[ReadingPageV3] Processing complete sentence: $_currentTranscript');
    
    _analyzeSentence(_currentTranscript);
    
    setState(() {
      _currentTranscript = '';
      _isProcessingSentence = false;
    });
  }

  void _analyzeSentence(String transcript) {
    if (_currentSentence >= _sentences.length) return;
    
    final spokenWords = _normalizeWords(transcript);
    final expectedWords = _sentenceMatchWords[_currentSentence];
    
    print('[ReadingPageV3] Analyzing - Expected: $expectedWords, Spoken: $spokenWords');
    
    _currentSentenceMistakes.clear();
    
    // Word-level analysis within the sentence
    final results = _compareWordSequences(expectedWords, spokenWords);
    
    // Update word status based on analysis
    for (int i = 0; i < expectedWords.length; i++) {
      final result = results[i];
      WordStatus status;
      
      switch (result.status) {
        case MatchStatus.correct:
          status = WordStatus.correct;
          break;
        case MatchStatus.incorrect:
          status = WordStatus.incorrect;
          _currentSentenceMistakes.add(expectedWords[i]);
          // Store pronunciation feedback
          _mispronunciationFeedback[expectedWords[i]] = result.spokenAs ?? 'not detected';
          break;
        case MatchStatus.missing:
          status = WordStatus.incorrect;
          _currentSentenceMistakes.add(expectedWords[i]);
          break;
      }
      
      _wordStatus[_currentSentence]![i] = status;
    }
    
    // Check if sentence is completed successfully
    final correctWords = results.where((r) => r.status == MatchStatus.correct).length;
    final accuracy = correctWords / expectedWords.length;
    
    print('[ReadingPageV3] Sentence accuracy: ${(accuracy * 100).toStringAsFixed(1)}%');
    
    if (accuracy >= widget.minAccuracy) {
      _sentenceCompleted[_currentSentence] = true;
      _moveToNextSentence();
    } else {
      _showSentenceFeedback();
    }
  }

  List<WordMatchResult> _compareWordSequences(List<String> expected, List<String> spoken) {
    final results = <WordMatchResult>[];
    
    // Simple approach: try to match each expected word with spoken words
    for (int i = 0; i < expected.length; i++) {
      final expectedWord = expected[i];
      final bestMatch = _findBestMatch(expectedWord, spoken);
      
      if (bestMatch != null && bestMatch.similarity >= 0.7) {
        results.add(WordMatchResult(
          expectedWord: expectedWord,
          spokenAs: bestMatch.word,
          status: MatchStatus.correct,
          similarity: bestMatch.similarity,
        ));
      } else {
        results.add(WordMatchResult(
          expectedWord: expectedWord,
          spokenAs: bestMatch?.word,
          status: bestMatch != null ? MatchStatus.incorrect : MatchStatus.missing,
          similarity: bestMatch?.similarity ?? 0.0,
        ));
      }
    }
    
    return results;
  }

  WordMatch? _findBestMatch(String target, List<String> candidates) {
    if (candidates.isEmpty) return null;
    
    WordMatch? best;
    double bestSimilarity = 0.0;
    
    for (String candidate in candidates) {
      final similarity = _calculateSimilarity(target, candidate);
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        best = WordMatch(word: candidate, similarity: similarity);
      }
    }
    
    return best;
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    
    final maxLen = max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    
    final distance = _levenshteinDistance(a, b);
    return (maxLen - distance) / maxLen;
  }

  int _levenshteinDistance(String a, String b) {
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
        ].reduce(min);
      }
    }
    
    return d[m][n];
  }

  List<String> _normalizeWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s']"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  void _moveToNextSentence() {
    if (_currentSentence < _sentences.length - 1) {
      setState(() {
        _currentSentence++;
        // Mark first word of next sentence as current
        if (_sentenceWords[_currentSentence].isNotEmpty) {
          _wordStatus[_currentSentence]![0] = WordStatus.current;
        }
        // Set new expected sentence
        _expectedSentence = _sentences[_currentSentence];
        // Clear feedback
        _heardSentence = '';
        _incorrectWords.clear();
        _pronunciationGuide.clear();
      });
      
      // Show success feedback
      _showSuccessMessage();
    } else {
      // Story completed!
      _showCompletionDialog();
    }
  }

  void _showSentenceFeedback() {
    if (_currentSentenceMistakes.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.school, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Let\'s Practice!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Let\'s work on these words:'),
            const SizedBox(height: 12),
            ...(_currentSentenceMistakes.take(3).map((word) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('• $word', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: Icon(Icons.volume_up, color: Colors.blue),
                      onPressed: () => _speakPronunciation(word),
                    ),
                  ],
                ),
              )
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _speakCurrentSentence();
            },
            child: const Text('Listen & Repeat'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Great job! Next sentence...'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Story Complete!'),
          ],
        ),
        content: const Text('Congratulations! You\'ve finished reading the story.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context)..pop()..pop(),
            child: const Text('Back to Stories'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context)..pop()..pop(),
            child: const Text('Read Another'),
          ),
        ],
      ),
    );
  }

  String _generatePronunciationHint(String word) {
    final normalized = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (normalized.isEmpty) return word;
    
    const vowels = 'aeiou';
    final buffer = StringBuffer();
    
    for (int i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      buffer.write(char);
      if (vowels.contains(char) && i < normalized.length - 1) {
        buffer.write('-');
      }
    }
    
    return buffer.toString().replaceAll(RegExp(r'-+'), '-');
  }

  // ---------- Favorites ----------
  Future<void> _loadFavorite() async {
    if (widget.storyId == null) return;
    try {
      final entry = await _libraryRepo.getByStoryId(widget.storyId!);
      setState(() => _isFavorite = entry?.isFavorite ?? false);
    } catch (_) {
      setState(() => _isFavorite = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
        title: Text('Reading Practice'),
        actions: [
          if (widget.storyId != null)
            IconButton(
              icon: Icon(_isFavorite == true ? Icons.favorite : Icons.favorite_border),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset('assets/images/storytots_background.png', fit: BoxFit.cover),
          Container(color: Colors.white.withOpacity(0.95)),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                
                // Story content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildStoryContent(),
                  ),
                ),
                
                // Controls
                _buildControlsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _currentSentence / max(1, _sentences.length);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sentence ${_currentSentence + 1} of ${_sentences.length}'),
              Text('${(progress * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(const Color(brandPurple)),
          ),
          
          // Expected vs Heard feedback section
          if (_expectedSentence.isNotEmpty || _heardSentence.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expected sentence
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _expectedSentence.isNotEmpty ? _expectedSentence : '____',
                          style: TextStyle(color: Colors.green[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Heard sentence
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heard: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _heardSentence.isNotEmpty ? _heardSentence : '______',
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                      ),
                    ],
                  ),
                  
                  // Pronunciation guidance for incorrect words
                  if (_incorrectWords.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Practice these words:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _incorrectWords.take(3).map((word) => 
                        GestureDetector(
                          onTap: () => _speakPronunciation(word),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  word,
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.volume_up,
                                  size: 16,
                                  color: Colors.orange[600],
                                ),
                              ],
                            ),
                          ),
                        )
                      ).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    return Column(
      children: [
        for (int s = 0; s < _sentences.length; s++) ...[
          _buildSentenceWidget(s),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSentenceWidget(int sentenceIndex) {
    final isCurrentSentence = sentenceIndex == _currentSentence;
    final isCompleted = _sentenceCompleted[sentenceIndex] == true;
    final words = _sentenceWords[sentenceIndex];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentSentence ? Colors.blue[50] : 
               isCompleted ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentSentence ? Colors.blue : 
                 isCompleted ? Colors.green : Colors.grey[300]!,
          width: isCurrentSentence ? 2 : 1,
        ),
      ),
      child: Wrap(
        children: [
          for (int w = 0; w < words.length; w++) ...[
            _buildWordWidget(sentenceIndex, w),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildWordWidget(int sentenceIndex, int wordIndex) {
    final word = _sentenceWords[sentenceIndex][wordIndex];
    final status = _wordStatus[sentenceIndex]?[wordIndex] ?? WordStatus.pending;
    
    Color backgroundColor;
    Color textColor = Colors.black;
    
    switch (status) {
      case WordStatus.current:
        backgroundColor = Colors.yellow[200]!;
        break;
      case WordStatus.correct:
        backgroundColor = Colors.green[200]!;
        textColor = Colors.green[800]!;
        break;
      case WordStatus.incorrect:
        backgroundColor = Colors.red[200]!;
        textColor = Colors.red[800]!;
        break;
      case WordStatus.pending:
        backgroundColor = Colors.transparent;
        break;
    }
    
    return GestureDetector(
      onTap: status == WordStatus.incorrect ? () => _speakPronunciation(word) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          word,
          style: TextStyle(
            fontSize: 18,
            fontWeight: status == WordStatus.current ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Instructions
          if (!_listening) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Click "Start Speaking" and say the sentence naturally',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Control buttons
          Row(
            children: [
              // Start/Stop speaking button
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _serviceReady ? (_listening ? _stopListen : _startListen) : null,
                  icon: Icon(
                    _listening ? Icons.mic : Icons.mic_none,
                    size: 24,
                  ),
                  label: Text(
                    _listening ? 'Stop Speaking' : 'Start Speaking',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _listening ? Colors.red[600] : const Color(brandPurple),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Replay sentence button
              Expanded(
                child: FilledButton.icon(
                  onPressed: _speakCurrentSentence,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Listen'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    // Implementation similar to original
  }
}

// Supporting classes
enum MatchStatus { correct, incorrect, missing }

class WordMatchResult {
  final String expectedWord;
  final String? spokenAs;
  final MatchStatus status;
  final double similarity;
  
  WordMatchResult({
    required this.expectedWord,
    this.spokenAs,
    required this.status,
    required this.similarity,
  });
}

class WordMatch {
  final String word;
  final double similarity;
  
  WordMatch({required this.word, required this.similarity});
}
