import 'package:flutter/material.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storytots Games'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _GameCard(
            title: 'Word Match',
            description:
                'Match each word to its picture. Learn new words from stories!',
            icon: Icons.extension,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WordMatchGame()),
            ),
          ),
          const SizedBox(height: 24),
          _GameCard(
            title: 'Story Sequence',
            description:
                'Arrange the story in the correct order. Build your story skills!',
            icon: Icons.timeline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StorySequenceGame()),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 48, color: const Color(0xFF6C63FF)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Game 1: Word Match ---
class WordMatchGame extends StatefulWidget {
  const WordMatchGame({super.key});

  @override
  State<WordMatchGame> createState() => _WordMatchGameState();
}

class _WordMatchGameState extends State<WordMatchGame> {
  final List<_WordMatchItem> items = [
    _WordMatchItem(word: 'Cat', image: 'assets/background/images/cat.png'),
    _WordMatchItem(word: 'Dog', image: 'assets/background/images/dog.png'),
    _WordMatchItem(word: 'Girl', image: 'assets/background/images/girl.png'),
    _WordMatchItem(word: 'Boy', image: 'assets/background/images/boy.png'),
  ];
  final Map<String, String?> matches = {};
  String? draggedWord;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Match'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            'Drag each word to its matching picture!',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Words to drag
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: items.map((item) {
                    final matched = matches[item.word] != null;
                    return Draggable<String>(
                      data: item.word,
                      feedback: _WordChip(word: item.word, dragging: true),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _WordChip(word: item.word),
                      ),
                      child: matched
                          ? const SizedBox(height: 40)
                          : _WordChip(word: item.word),
                    );
                  }).toList(),
                ),
                // Images to drop on
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: items.map((item) {
                    final matched = matches[item.word] == item.image;
                    return DragTarget<String>(
                      builder: (context, candidate, rejected) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: matched ? Colors.green : Colors.grey,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                item.image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                              if (matched)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 32,
                                ),
                            ],
                          ),
                        );
                      },
                      onWillAccept: (data) => data == item.word,
                      onAccept: (data) {
                        setState(() {
                          matches[data] = item.image;
                        });
                        if (matches.length == items.length) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Great job!'),
                                content: const Text(
                                  'You matched all the words!',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WordMatchItem {
  final String word;
  final String image;
  const _WordMatchItem({required this.word, required this.image});
}

class _WordChip extends StatelessWidget {
  final String word;
  final bool dragging;
  const _WordChip({required this.word, this.dragging = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: dragging ? Colors.purple[200] : Colors.purple[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Text(
        word,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// --- Game 2: Story Sequence ---
class StorySequenceGame extends StatefulWidget {
  const StorySequenceGame({super.key});

  @override
  State<StorySequenceGame> createState() => _StorySequenceGameState();
}

class _StorySequenceGameState extends State<StorySequenceGame> {
  final List<_SequenceItem> items = [
    _SequenceItem(
      text: 'The cat sat on the mat.',
      image: 'assets/background/images/cat.png',
    ),
    _SequenceItem(
      text: 'The dog barked.',
      image: 'assets/background/images/dog.png',
    ),
    _SequenceItem(
      text: 'The boy played.',
      image: 'assets/background/images/boy.png',
    ),
    _SequenceItem(
      text: 'The girl laughed.',
      image: 'assets/background/images/girl.png',
    ),
  ];
  late List<_SequenceItem> shuffled;

  @override
  void initState() {
    super.initState();
    shuffled = List<_SequenceItem>.from(items)..shuffle();
  }

  bool get isCorrect {
    for (int i = 0; i < items.length; i++) {
      if (shuffled[i].text != items[i].text) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Sequence'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            'Tap to arrange the story in order!',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = shuffled.removeAt(oldIndex);
                  shuffled.insert(newIndex, item);
                });
              },
              children: [
                for (final item in shuffled)
                  ListTile(
                    key: ValueKey(item.text),
                    leading: Image.asset(item.image, width: 48, height: 48),
                    title: Text(
                      item.text,
                      style: const TextStyle(fontSize: 17),
                    ),
                    tileColor: Colors.purple[50],
                  ),
              ],
            ),
          ),
          if (isCorrect)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Great job! You arranged the story.',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }
}

class _SequenceItem {
  final String text;
  final String image;
  const _SequenceItem({required this.text, required this.image});
}
