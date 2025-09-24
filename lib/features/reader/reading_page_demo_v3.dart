// lib/features/reader/reading_page_demo_v3.dart
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'reading_page_v3.dart';
import 'speech/speech_service_factory.dart';

class ReadingPageDemoV3 extends StatelessWidget {
  const ReadingPageDemoV3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
        title: const Text('Speech Recognition V3 Demo'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/storytots_background.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.white.withOpacity(0.95)),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'Enhanced Speech-to-Text',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(brandPurple),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Features list
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Features:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildFeature('🎯 Sentence-level speech recognition'),
                          _buildFeature(
                            '📝 Natural speaking patterns supported',
                          ),
                          _buildFeature(
                            '🔄 Smart word matching with similarity scoring',
                          ),
                          _buildFeature('🗣️ Better pronunciation feedback'),
                          _buildFeature(
                            '⏱️ 3-second timeout for sentence completion',
                          ),
                          _buildFeature(
                            '✅ Word-level accuracy within sentences',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Demo stories
                  Text(
                    'Try These Demo Stories:',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Short story button
                  FilledButton(
                    onPressed: () =>
                        _openDemo(context, _shortStory, 'Short Story'),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Short Story (2 sentences)'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Medium story button
                  FilledButton(
                    onPressed: () =>
                        _openDemo(context, _mediumStory, 'Medium Story'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Medium Story (4 sentences)'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Complex story button
                  FilledButton(
                    onPressed: () =>
                        _openDemo(context, _complexStory, 'Complex Story'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Complex Story (6 sentences)'),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _openDemo(BuildContext context, String text, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingPageV3(
          pageText: text,
          storyId: 'demo-${title.toLowerCase().replaceAll(' ', '-')}',
          storyTitle: title,
          speechServiceType: SpeechServiceType.deviceSTT,
          minAccuracy: 0.7, // Slightly more forgiving for demo
        ),
      ),
    );
  }

  static const _shortStory = '''
The cat sat on the mat. It was a sunny day and the cat was happy.
''';

  static const _mediumStory = '''
Once upon a time, there was a little rabbit who lived in a garden. The rabbit loved to eat fresh carrots every morning. One day, the rabbit found a magical carrot that glowed with golden light. The rabbit ate the magical carrot and suddenly could fly through the clouds.
''';

  static const _complexStory = '''
Emma walked through the enchanted forest on a beautiful autumn morning. She discovered a hidden pathway covered with colorful leaves that sparkled like diamonds. At the end of the path stood a magnificent castle with tall towers reaching toward the sky. Inside the castle lived a friendly dragon who loved to read books and tell stories. The dragon invited Emma to stay for tea and shared tales of adventure from faraway lands. Emma and the dragon became the very best of friends and promised to meet again soon.
''';
}
