abstract class SpeechEngine {
  Future<bool> init();
  Future<void> start({required void Function(List<String> words) onWords, String? localeId});
  Future<void> stop();
  bool get isListening;
}
