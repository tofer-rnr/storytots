// Simplified Azure Speech-to-Text Engine for Build Compatibility
import 'engine.dart';

class AzureSpeechEngine implements SpeechEngine {
  // Azure Configuration - Replace with your actual subscription key
  static const String _subscriptionKey = 'YOUR_AZURE_SUBSCRIPTION_KEY';

  bool _isListening = false;
  void Function(List<String> words)? _onWords;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> init() async {
    try {
      print(
        '[AzureSpeech] Initializing Azure Speech Service (simplified mode)...',
      );

      // Check if Azure key is configured
      if (_subscriptionKey == 'YOUR_AZURE_SUBSCRIPTION_KEY') {
        print('[AzureSpeech] Azure subscription key not configured');
        return false;
      }

      print('[AzureSpeech] Azure Speech service initialized');
      return true;
    } catch (e) {
      print('[AzureSpeech] Initialization failed: $e');
      return false;
    }
  }

  @override
  Future<void> start({
    required void Function(List<String> words) onWords,
    String? localeId,
  }) async {
    if (_isListening) return;

    print('[AzureSpeech] Starting speech recognition...');
    _onWords = onWords;

    // For build compatibility, we'll show a message that recording is not available
    print(
      '[AzureSpeech] Note: Audio recording requires record package (disabled for build)',
    );

    _isListening = true;

    // Send a mock result to show it would work
    await Future.delayed(const Duration(seconds: 1));
    _onWords?.call(['Azure', 'Speech', 'service', 'would', 'work', 'here']);
  }

  @override
  Future<void> stop() async {
    if (!_isListening) return;

    print('[AzureSpeech] Stopping speech recognition...');
    _isListening = false;
    _onWords = null;
  }
}
