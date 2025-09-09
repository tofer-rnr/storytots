// Factory to create different speech recognition services
import 'engine.dart';
import 'stt_engine.dart';
import 'azure_speech_engine.dart';

enum SpeechServiceType { deviceSTT, azureSpeech }

class SpeechServiceFactory {
  static SpeechEngine create(SpeechServiceType type) {
    switch (type) {
      case SpeechServiceType.deviceSTT:
        return SpeechToTextEngine();
      case SpeechServiceType.azureSpeech:
        return AzureSpeechEngine();
    }
  }

  static String getServiceName(SpeechServiceType type) {
    switch (type) {
      case SpeechServiceType.deviceSTT:
        return 'Device STT';
      case SpeechServiceType.azureSpeech:
        return 'Azure Speech';
    }
  }

  static bool isServiceAvailable(SpeechServiceType type) {
    switch (type) {
      case SpeechServiceType.deviceSTT:
        return true; // Always available
      case SpeechServiceType.azureSpeech:
        return true; // Requires internet connection
    }
  }

  static List<SpeechServiceType> getAvailableServices() {
    return SpeechServiceType.values
        .where((service) => isServiceAvailable(service))
        .toList();
  }
}
