// Simple demo/test page for the new branch system
import 'package:flutter/material.dart';
import 'reading_page_v2.dart';
import 'speech/speech_service_factory.dart';

class ReadingPageDemo extends StatelessWidget {
  const ReadingPageDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const sampleText =
        "The quick brown fox jumps over the lazy dog. This is a test sentence for speech recognition. Let's see how well it works with different services.";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Service Demo'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Your Speech Recognition Service:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test both services to see which works better for your use case.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Device STT Option
            Card(
              color: Colors.green[50],
              child: ListTile(
                leading: Icon(
                  Icons.phone_android,
                  color: Colors.green[700],
                  size: 32,
                ),
                title: const Text('Device Speech Recognition'),
                subtitle: const Text(
                  'Uses your device\'s built-in speech service (default)',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReadingPageV2(
                      pageText: sampleText,
                      speechServiceType: SpeechServiceType.deviceSTT,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Azure Speech Option
            Card(
              color: Colors.blue[50],
              child: ListTile(
                leading: Icon(
                  Icons.cloud_queue,
                  color: Colors.blue[700],
                  size: 32,
                ),
                title: const Text('Azure Speech-to-Text'),
                subtitle: const Text(
                  'Real-time cloud-based speech recognition',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReadingPageV2(
                      pageText: sampleText,
                      speechServiceType: SpeechServiceType.azureSpeech,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Setup Instructions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Device STT: Ready to use (no setup required)\n'
                      '• Azure Speech: Real-time cloud recognition with high accuracy\n'
                      '• Both support tap-to-progress when mic is off\n'
                      '• Ensure microphone permissions are granted',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
