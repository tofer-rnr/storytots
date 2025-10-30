// Factory to create different speech recognition services
import 'engine.dart';
import 'stt_engine.dart';
// import 'openai_whisper_engine.dart'; // Removed - using device STT only

enum SpeechServiceType { deviceSTT, openaiWhisper }

class SpeechServiceFactory {
  static SpeechEngine create(SpeechServiceType type) {
    switch (type) {
      case SpeechServiceType.deviceSTT:
        return SpeechToTextEngine();
      case SpeechServiceType.openaiWhisper:
        // Route to device STT for now (Whisper removed due to cost)
        return SpeechToTextEngine();
    }
  }

  static String getServiceName(SpeechServiceType type) {
    switch (type) {
      case SpeechServiceType.deviceSTT:
        return 'Device STT';
      case SpeechServiceType.openaiWhisper:
        return 'Device STT'; // Whisper unavailable
    }
  }

  static bool isServiceAvailable(SpeechServiceType type) {
    switch (type) {
      case SpeechServiceType.deviceSTT:
        return true; // Always available
      case SpeechServiceType.openaiWhisper:
        return false; // Disabled - using device STT only
    }
  }

  static List<SpeechServiceType> getAvailableServices() {
    return [SpeechServiceType.deviceSTT]; // Only device STT available
  }
}
