import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../data/repositories/stories_repository.dart';
import '../../data/cover_assets.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _assessRepo = AssessmentRepository();
  final _storiesRepo = StoriesRepository();
  late Future<List<Story>> _completedStoriesFuture;

  @override
  void initState() {
    super.initState();
    _completedStoriesFuture = _loadCompletedStories();
  }

  Future<List<Story>> _loadCompletedStories() async {
    final ids = await _assessRepo.getCompletedStoryIds();
    if (ids.isEmpty) return [];
    // Fetch story details for display
    return _storiesRepo.listByIds(ids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
        title: const Text(
          'Assessments',
          style: TextStyle(
            fontFamily: 'RustyHooks',
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      body: FutureBuilder<List<Story>>(
        future: _completedStoriesFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final stories = snap.data ?? [];
          if (stories.isEmpty) {
            return _emptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final s = stories[i];
              final cover = s.coverUrl ?? coverAssetForTitle(s.title);
              final isNetwork =
                  cover != null &&
                  (cover.startsWith('http://') || cover.startsWith('https://'));
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openAssessment(context, s),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                        child: SizedBox(
                          width: 90,
                          height: 90,
                          child: isNetwork
                              ? Image.network(cover, fit: BoxFit.cover)
                              : Image.asset(
                                  cover ?? 'assets/images/arts.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'OddlyCalming',
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Quick assessment based on this story',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.play_circle_fill, size: 32),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.videogame_asset_rounded, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No assessments yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Finish reading a story to unlock a fun assessment here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  void _openAssessment(BuildContext context, Story story) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryAssessmentScreen(story: story)),
    );
  }
}

class StoryAssessmentScreen extends StatefulWidget {
  const StoryAssessmentScreen({super.key, required this.story});
  final Story story;

  @override
  State<StoryAssessmentScreen> createState() => _StoryAssessmentScreenState();
}

class _StoryAssessmentScreenState extends State<StoryAssessmentScreen> {
  int _score = 0;
  int _current = 0;

  late List<_Question> _questions;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions(widget.story);
  }

  List<_Question> _generateQuestions(Story s) {
    // Simple placeholder questions based on title words. Replace with real bank later.
    final words = s.title
        .split(RegExp(r"\s+"))
        .where((w) => w.isNotEmpty)
        .take(4)
        .toList();
    final qs = <_Question>[];
    if (words.isNotEmpty) {
      qs.add(
        _Question(
          prompt: 'Which word appears in the title?',
          options: List<String>.from(words)
            ..add('Banana')
            ..shuffle(),
          correct: words.first,
        ),
      );
    }
    if (words.length >= 2) {
      qs.add(
        _Question(
          prompt: 'Tap the first word of the title',
          options: List<String>.from(words)..shuffle(),
          correct: words.first,
        ),
      );
    }
    // Add two generic questions
    qs.addAll([
      _Question(
        prompt: 'Did you enjoy the story?',
        options: const ['Yes', 'No', 'Maybe'],
        correct: 'Yes',
      ),
      _Question(
        prompt: 'Would you recommend it to a friend?',
        options: const ['Yes', 'No'],
        correct: 'Yes',
      ),
    ]);
    return qs;
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_current];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
        title: Text('Assessment: ${widget.story.title}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_current + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              color: const Color(brandPurple),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.prompt,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'RustyHooks',
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final opt in q.options)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ElevatedButton(
                          onPressed: () => _answer(opt == q.correct),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              opt,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'OddlyCalming',
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Score: $_score',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _answer(bool correct) {
    if (correct) _score++;
    if (_current < _questions.length - 1) {
      setState(() => _current++);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Assessment complete!'),
          content: Text('Your score: $_score / ${_questions.length}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

class _Question {
  final String prompt;
  final List<String> options;
  final String correct;
  _Question({
    required this.prompt,
    required this.options,
    required this.correct,
  });
}
