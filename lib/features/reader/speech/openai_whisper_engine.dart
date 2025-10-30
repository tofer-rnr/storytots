// lib/features/reader/speech/openai_whisper_engine.dart
// Stubbed OpenAI Whisper Engine - Removed due to API costs
// This implementation routes to device STT instead

import 'engine.dart';

class OpenAIWhisperEngine implements SpeechEngine {
  @override
  bool get isListening => throw UnsupportedError(
    'OpenAI Whisper is not available. Using device STT instead.',
  );

  @override
  Future<bool> init() async {
    throw UnsupportedError(
      'OpenAI Whisper is not available. Using device STT instead.',
    );
  }

  @override
  Future<void> start({
    required void Function(List<String>) onWords,
    String? localeId,
  }) async {
    throw UnsupportedError(
      'OpenAI Whisper is not available. Using device STT instead.',
    );
  }

  @override
  Future<void> stop() async {
    throw UnsupportedError(
      'OpenAI Whisper is not available. Using device STT instead.',
    );
  }
}
