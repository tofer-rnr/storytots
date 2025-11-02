import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/scheduler.dart';

import '../../data/repositories/achievements_repository.dart' as ach;
import '../../data/repositories/reading_activity_repository.dart';
import '../../data/services/profile_stats_service.dart';

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
    // Story-specific: Why the Ocean Is Salty
    if (_isWhyOceanIsSalty(s)) {
      return _whyOceanIsSaltyQuestions();
    }
    // Story-specific: The Monkey and the Turtle
    if (_isMonkeyAndTurtle(s)) {
      return _monkeyTurtleQuestions();
    }
    // Story-specific: The Lion and the Mouse
    if (_isLionAndMouse(s)) {
      return _lionMouseQuestions();
    }
    // Story-specific: The Legend of the Rainbow
    if (_isLegendOfTheRainbow(s)) {
      return _legendOfTheRainbowQuestions();
    }
    // Story-specific: The Legend of the Bitter Gourd (Ampalaya)
    if (_isBitterGourd(s)) {
      return _bitterGourdQuestions();
    }
    // Story-specific: The Carabao and the Shell
    if (_isCarabaoAndShell(s)) {
      return _carabaoShellQuestions();
    }
    // Story-specific: The Ant and the Grasshopper
    if (_isAntAndGrasshopper(s)) {
      return _antGrasshopperQuestions();
    }
    // Story-specific: Stories of Juan Tamad
    if (_isStoriesOfJuanTamad(s)) {
      return _juanTamadQuestions();
    }
    // Story-specific: Legend of the Pineapple (Pinya)
    if (_isLegendOfThePineapple(s)) {
      return _legendOfThePineappleQuestions();
    }
    // Story-specific: Alamat ng Sampaguita
    if (_isAlamatNgSampaguita(s)) {
      return _alamatNgSampaguitaQuestions();
    }
    // Story-specific: Alamat ng Saging (Banana)
    if (_isAlamatNgSaging(s)) {
      return _alamatNgSagingQuestions();
    }

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

  bool _isWhyOceanIsSalty(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return title.contains('why the ocean is salty') ||
  id.contains('why_the_ocean_is_salty') ||
  id.contains('why-the-ocean-is-salty') ||
        (title.contains('ocean') && title.contains('salty'));
  }

  List<_Question> _whyOceanIsSaltyQuestions() {
    return [
      _Question(
        prompt: '1. Who was Ang-ngalo?',
        options: const [
          'The god of wind',
          'The son of the god of building',
          'The ruler of the ocean',
          'The king of salt',
        ],
        correct: 'The son of the god of building',
      ),
      _Question(
        prompt: '2. What did Ang-ngalo love to do?',
        options: const [
          'Sleep all day',
          'Eat and rest',
          'Travel and work hard',
          'Sing and dance',
        ],
        correct: 'Travel and work hard',
      ),
      _Question(
        prompt: '3. Where did Ang-ngalo live?',
        options: const ['In the ocean', 'In the mountains', 'In the sky', 'In a palace'],
        correct: 'In the mountains',
      ),
      _Question(
        prompt:
            '4. Who was the goddess of the wind that Ang-ngalo protected his caves from?',
        options: const ['Sipgnet', 'Asin', 'Angin', 'Ocean'],
        correct: 'Angin',
      ),
      _Question(
        prompt: '5. What did Ang-ngalo see across the ocean one bright morning?',
        options: const [
          'A golden palace',
          'A beautiful maid',
          'A big mountain',
          'A giant fish',
        ],
        correct: 'A beautiful maid',
      ),
      _Question(
        prompt: '6. What was the name of the beautiful maid?',
        options: const ['Asin', 'Angin', 'Sipgnet', 'Ocean'],
        correct: 'Sipgnet',
      ),
      _Question(
        prompt: '7. What did Sipgnet ask Ang-ngalo to build for her?',
        options: const ['A bridge', 'A white mansion', 'A cave', 'A ship'],
        correct: 'A white mansion',
      ),
      _Question(
        prompt: '8. What material did Ang-ngalo use to build the mansion?',
        options: const ['Marble', 'Salt bricks', 'Stones', 'Gold'],
        correct: 'Salt bricks',
      ),
      _Question(
        prompt: '9. Who helped Ang-ngalo get the white bricks of salt?',
        options: const ['Ocean', 'Asin', 'Angin', 'Sipgnet'],
        correct: 'Asin',
      ),
      _Question(
        prompt: '10. Why is the ocean salty today, according to the story?',
        options: const [
          'Because of the tears of goddesses',
          'Because of the dissolved salt bricks',
          'Because of the wind',
          'Because of rain',
        ],
        correct: 'Because of the dissolved salt bricks',
      ),
    ];
  }

  bool _isMonkeyAndTurtle(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return (title.contains('monkey') && title.contains('turtle')) ||
        (id.contains('monkey') && id.contains('turtle'));
  }

  List<_Question> _monkeyTurtleQuestions() {
    return [
      _Question(
        prompt:
            '1. Who did the monkey meet while walking by the river?',
        options: const ['A rabbit', 'A turtle', 'A farmer', 'A crocodile'],
        correct: 'A turtle',
      ),
      _Question(
        prompt: '2. Why was the monkey feeling sad?',
        options: const ['He was lost', 'He was hungry', 'He was hurt', 'He missed his family'],
        correct: 'He was hungry',
      ),
      _Question(
        prompt: '3. What did the turtle suggest they steal?',
        options: const ['Corn plants', 'Banana plants', 'Squash plants', 'Mango plants'],
        correct: 'Banana plants',
      ),
      _Question(
        prompt: '4. Where did the monkey plant his banana plant?',
        options: const ['In the ground', 'On a mountain', 'In a tree', 'Near the river'],
        correct: 'In a tree',
      ),
      _Question(
        prompt: '5. Where did the turtle plant his banana plant?',
        options: const ['In the ground', 'In a pot', 'On the tree', "Near the monkey’s plant"],
        correct: 'In the ground',
      ),
      _Question(
        prompt: '6. What happened to the monkey’s banana plant?',
        options: const ['It grew fast', 'It died', 'It had many fruits', 'It turned into a tree'],
        correct: 'It died',
      ),
      _Question(
        prompt:
            '7. What did the monkey do when the turtle’s plant bore fruit?',
        options: const [
          'He helped the turtle',
          'He gave all the fruits to the turtle',
          'He climbed the tree and ate all the ripe bananas',
          'He shared them with other monkeys',
        ],
        correct: 'He climbed the tree and ate all the ripe bananas',
      ),
      _Question(
        prompt: '8. How did the turtle punish the monkey?',
        options: const [
          'He threw stones at him',
          'He scared him by shouting “Crocodile is coming!”',
          'He pushed him into the water',
          'He took away the bananas',
        ],
        correct: 'He scared him by shouting “Crocodile is coming!”',
      ),
      _Question(
        prompt: '9. What happened to the monkey after he fell from the tree?',
        options: const ['He ran away', 'He was hurt but survived', 'He fell on sharp bamboo and died', 'He turned into a turtle'],
        correct: 'He fell on sharp bamboo and died',
      ),
      _Question(
        prompt: '10. What is the lesson (moral) of the story?',
        options: const [
          'Never plant trees',
          'Don’t trust turtles',
          'Don’t be greedy and lazy',
          'Always eat bananas',
        ],
        correct: 'Don’t be greedy and lazy',
      ),
    ];
  }

  bool _isLionAndMouse(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return (title.contains('lion') && title.contains('mouse')) ||
        (id.contains('lion') && id.contains('mouse'));
  }

  List<_Question> _lionMouseQuestions() {
    return [
      _Question(
        prompt: '1. Where was the lion when the story began?',
        options: const [
          'At the river',
          'In the forest sleeping',
          'In a zoo',
          'Chasing the mouse',
        ],
        correct: 'In the forest sleeping',
      ),
      _Question(
        prompt: '2. What did the mouse accidentally do to the lion?',
        options: const [
          'Bit his tail',
          'Ran across his nose',
          'Took his food',
          'Woke him by shouting',
        ],
        correct: 'Ran across his nose',
      ),
      _Question(
        prompt: '3. How did the lion react when the mouse woke him up?',
        options: const [
          'He laughed',
          'He ignored her',
          'He caught her with his paw',
          'He ran away',
        ],
        correct: 'He caught her with his paw',
      ),
      _Question(
        prompt: '4. What did the mouse beg the lion to do?',
        options: const [
          'Give her food',
          'Let her go free',
          'Teach her to roar',
          'Take her home',
        ],
        correct: 'Let her go free',
      ),
      _Question(
        prompt: '5. What did the mouse promise the lion?',
        options: const [
          'She would help him one day',
          'She would bring him food',
          'She would tell the other animals about him',
          'She would stay away forever',
        ],
        correct: 'She would help him one day',
      ),
      _Question(
        prompt: '6. Why did the lion laugh at the mouse’s promise?',
        options: const [
          'He thought she was too small to help him',
          'He didn’t understand her',
          'He was very hungry',
          'He wanted to play with her',
        ],
        correct: 'He thought she was too small to help him',
      ),
      _Question(
        prompt: '7. What happened to the lion later in the story?',
        options: const [
          'He fell into a river',
          'He was caught in a hunter’s net',
          'He got lost in the forest',
          'He chased the mouse again',
        ],
        correct: 'He was caught in a hunter’s net',
      ),
      _Question(
        prompt: '8. How did the mouse help the lion escape?',
        options: const [
          'She called other animals',
          'She bit the hunter',
          'She gnawed through the ropes',
          'She scared the hunters away',
        ],
        correct: 'She gnawed through the ropes',
      ),
      _Question(
        prompt: '9. What did the lion realize after being freed?',
        options: const [
          'The mouse was his best friend',
          'Even small creatures can be helpful',
          'He should never sleep again',
          'Hunters are very strong',
        ],
        correct: 'Even small creatures can be helpful',
      ),
      _Question(
        prompt: '10. What is the moral or lesson of the story?',
        options: const [
          'Always roar loudly',
          'Never sleep in the forest',
          'Kindness and helping others are never wasted',
          'Big animals are stronger than small ones',
        ],
        correct: 'Kindness and helping others are never wasted',
      ),
    ];
  }

  bool _isLegendOfTheRainbow(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return title.contains('legend of the rainbow') ||
        id.contains('legend_of_the_rainbow') ||
        title.contains('rainbow');
  }

  List<_Question> _legendOfTheRainbowQuestions() {
    return [
      _Question(
        prompt:
            '1. What were the colors doing at the beginning of the story?',
        options: const [
          'Playing together',
          'Quarreling and arguing',
          'Painting the sky',
          'Singing a song',
        ],
        correct: 'Quarreling and arguing',
      ),
      _Question(
        prompt: '2. What did Green say made it the most important color?',
        options: const [
          'It is the color of the ocean',
          'It gives life to grass, leaves, and trees',
          'It makes people happy',
          'It is the color of bravery',
        ],
        correct: 'It gives life to grass, leaves, and trees',
      ),
      _Question(
        prompt: '3. Which color said it represented the sky and sea?',
        options: const ['Blue', 'Yellow', 'Red', 'Orange'],
        correct: 'Blue',
      ),
      _Question(
        prompt: '4. Which color brings laughter and sunshine to the world?',
        options: const ['Green', 'Yellow', 'Purple', 'Indigo'],
        correct: 'Yellow',
      ),
      _Question(
        prompt:
            '5. Which color said it gives health and strength and is seen in carrots and pumpkins?',
        options: const ['Orange', 'Red', 'Blue', 'Green'],
        correct: 'Orange',
      ),
      _Question(
        prompt:
            '6. Which color claimed to be the ruler and symbol of bravery and love?',
        options: const ['Purple', 'Red', 'Indigo', 'Yellow'],
        correct: 'Red',
      ),
      _Question(
        prompt: '7. Which color stood tall and said it was for royalty and power?',
        options: const ['Blue', 'Purple', 'Orange', 'Green'],
        correct: 'Purple',
      ),
      _Question(
        prompt:
            '8. Which color spoke softly and said it represented silence and peace?',
        options: const ['Red', 'Indigo', 'Yellow', 'Green'],
        correct: 'Indigo',
      ),
      _Question(
        prompt: '9. Who appeared when the colors were fighting loudly?',
        options: const ['The Sun', 'The Wind', 'The Rain', 'The Moon'],
        correct: 'The Rain',
      ),
      _Question(
        prompt:
            '10. What did the rain tell the colors to do so they could live in peace?',
        options: const [
          'Go away and hide',
          'Join hands and form a rainbow',
          'Stop shining',
          'Stay in the sky forever',
        ],
        correct: 'Join hands and form a rainbow',
      ),
    ];
  }

  bool _isBitterGourd(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return title.contains('bitter gourd') ||
        id.contains('bitter_gourd') ||
        title.contains('ampalaya');
  }

  List<_Question> _bitterGourdQuestions() {
    return [
      _Question(
        prompt: '1. Where did the story take place?',
        options: const ['In a Green Garden', 'In a forest', 'In a mountain'],
        correct: 'In a Green Garden',
      ),
      _Question(
        prompt: '2. What kinds of plants grew in the garden?',
        options: const ['Only flowers', 'All sorts of vegetables', 'Only fruits'],
        correct: 'All sorts of vegetables',
      ),
      _Question(
        prompt: '3. What did the pumpkins have that made them special?',
        options: const ['Sweetness', 'Sourness', 'Spiciness'],
        correct: 'Sweetness',
      ),
      _Question(
        prompt: '4. What color were the eggplants in the story?',
        options: const ['Green', 'Purple', 'Red'],
        correct: 'Purple',
      ),
      _Question(
        prompt: '5. What kind of vegetable was shy and made people cry?',
        options: const ['Onion', 'Ginger', 'Tomato'],
        correct: 'Onion',
      ),
      _Question(
        prompt: '6. How did the little gourd (ampalaya) feel about herself?',
        options: const ['Proud and happy', 'Sad and jealous', 'Brave and strong'],
        correct: 'Sad and jealous',
      ),
      _Question(
        prompt: '7. What did the ampalaya do one night?',
        options: const [
          'She watered the garden',
          'She took the other vegetables’ good qualities',
          'She sang to the moon',
        ],
        correct: 'She took the other vegetables’ good qualities',
      ),
      _Question(
        prompt: '8. What happened the next day after she took their qualities?',
        options: const [
          'She became beautiful and everyone admired her',
          'She ran away from the garden',
          'She turned into a flower',
        ],
        correct: 'She became beautiful and everyone admired her',
      ),
      _Question(
        prompt:
            '9. Who did the vegetables bring the ampalaya to when they found out?',
        options: const [
          'The Fairy Queen of the Green Garden',
          'The farmer',
          'The Sun',
        ],
        correct: 'The Fairy Queen of the Green Garden',
      ),
      _Question(
        prompt: '10. What was the Fairy Queen’s punishment for ampalaya?',
        options: const [
          'To lose all her color and become invisible',
          'To have dark, warty skin and a bitter taste forever',
          'To be turned into a stone',
        ],
        correct: 'To have dark, warty skin and a bitter taste forever',
      ),
    ];
  }

  bool _isCarabaoAndShell(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return (title.contains('carabao') && title.contains('shell')) ||
        (id.contains('carabao') && id.contains('shell'));
  }

  List<_Question> _carabaoShellQuestions() {
    return [
      _Question(
        prompt: '1. What did the carabao do on a very hot day?',
        options: const [
          'Went swimming in the river to bathe',
          'Took a nap under a tree',
          'Ate some grass',
        ],
        correct: 'Went swimming in the river to bathe',
      ),
      _Question(
        prompt: '2. Who did the carabao meet in the river?',
        options: const ['A fish', 'A shell', 'A frog'],
        correct: 'A shell',
      ),
      _Question(
        prompt: '3. What did the carabao say to the shell?',
        options: const [
          '“You are very fast.”',
          '“You are very slow.”',
          '“Let’s go swimming.”',
        ],
        correct: '“You are very slow.”',
      ),
      _Question(
        prompt: '4. What did the shell say in return?',
        options: const [
          '“I can beat you in a race!”',
          '“I am too small.”',
          '“I don’t want to race.”',
        ],
        correct: '“I can beat you in a race!”',
      ),
      _Question(
        prompt: '5. What did they decide to do?',
        options: const ['Take a nap', 'Race each other', 'Go fishing'],
        correct: 'Race each other',
      ),
      _Question(
        prompt: '6. Where did the race happen?',
        options: const ['In the forest', 'On the riverbank', 'Inside the water'],
        correct: 'On the riverbank',
      ),
      _Question(
        prompt: '7. What happened when the carabao stopped and called, “Shell!”?',
        options: const [
          'Another shell answered, “Here I am!”',
          'No one answered',
          'The carabao heard an echo',
        ],
        correct: 'Another shell answered, “Here I am!”',
      ),
      _Question(
        prompt: '8. Why did the carabao think the shell was fast?',
        options: const [
          'Because he saw it running',
          'Because every time he called, a shell answered',
          'Because it flew over him',
        ],
        correct: 'Because every time he called, a shell answered',
      ),
      _Question(
        prompt: '9. What did the carabao do to try to win?',
        options: const [
          'He ran faster and faster',
          'He stopped and rested',
          'He asked for help',
        ],
        correct: 'He ran faster and faster',
      ),
      _Question(
        prompt: '10. What happened to the carabao at the end?',
        options: const [
          'He won the race',
          'He dropped dead from running too hard',
          'He went back to the river to rest',
        ],
        correct: 'He dropped dead from running too hard',
      ),
    ];
  }

  bool _isAntAndGrasshopper(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return title.contains('ant') && title.contains('grasshopper') ||
        id.contains('ant') && id.contains('grasshopper');
  }

  List<_Question> _antGrasshopperQuestions() {
    return [
      _Question(
        prompt: '1. Who were the two main characters in the story?',
        options: const [
          'A dog and a cat',
          'An ant and a grasshopper',
          'A bird and a fish',
        ],
        correct: 'An ant and a grasshopper',
      ),
      _Question(
        prompt: '2. What did the ant do during the summer?',
        options: const [
          'Slept all day',
          'Collected wheat grains and worked hard',
          'Sang and danced',
        ],
        correct: 'Collected wheat grains and worked hard',
      ),
      _Question(
        prompt: '3. What did the grasshopper like to do?',
        options: const [
          'Help the ant collect food',
          'Sing and dance all day',
          'Build a house',
        ],
        correct: 'Sing and dance all day',
      ),
      _Question(
        prompt: '4. What did the grasshopper say to the ant?',
        options: const [
          '“Let’s sing and dance instead of working!”',
          '“Let’s build a new home.”',
          '“Let’s go swimming.”',
        ],
        correct: '“Let’s sing and dance instead of working!”',
      ),
      _Question(
        prompt: '5. What did the ant tell the grasshopper?',
        options: const [
          '“We should save food for the cold season.”',
          '“Let’s eat all the food now.”',
          '“We don’t need to work.”',
        ],
        correct: '“We should save food for the cold season.”',
      ),
      _Question(
        prompt: '6. What happened when winter came?',
        options: const [
          'It became very hot.',
          'It started to snow and became very cold.',
          'The grasshopper built a new home.',
        ],
        correct: 'It started to snow and became very cold.',
      ),
      _Question(
        prompt: '7. How did the grasshopper feel during winter?',
        options: const [
          'Warm and happy',
          'Cold and hungry',
          'Busy and excited',
        ],
        correct: 'Cold and hungry',
      ),
      _Question(
        prompt: '8. Who did the grasshopper visit for help?',
        options: const [
          'The farmer',
          'The ant',
          'The bird',
        ],
        correct: 'The ant',
      ),
      _Question(
        prompt: '9. What did the ant say when the grasshopper asked for food?',
        options: const [
          '“You can have everything.”',
          '“I told you to work and save food.”',
          '“Let’s dance together.”',
        ],
        correct: '“I told you to work and save food.”',
      ),
      _Question(
        prompt: '10. What lesson did the grasshopper learn?',
        options: const [
          'It’s good to work and save for the future.',
          'It’s okay to be lazy all the time.',
          'Singing is better than working.',
        ],
        correct: 'It’s good to work and save for the future.',
      ),
    ];
  }

  bool _isStoriesOfJuanTamad(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return id.contains('juan') || title.contains('juan tamad');
  }

  List<_Question> _juanTamadQuestions() {
    return [
      _Question(
        prompt: '1. What was the name of the boy in the story?',
        options: const ['Pedro', 'Juan', 'Diego'],
        correct: 'Juan',
      ),
      _Question(
        prompt: '2. What was Juan known for in the village?',
        options: const ['His kindness', 'His bravery', 'His laziness'],
        correct: 'His laziness',
      ),
      _Question(
        prompt: '3. Where did Juan like to rest every day?',
        options: const [
          'On the roof',
          'In his hammock under a mango tree',
          'Beside the river',
        ],
        correct: 'In his hammock under a mango tree',
      ),
      _Question(
        prompt: '4. What did Juan’s mother always tell him?',
        options: const [
          '“You need to learn how to work.”',
          '“Go play all day.”',
          '“Never help anyone.”',
        ],
        correct: '“You need to learn how to work.”',
      ),
      _Question(
        prompt: '5. Who announced the contest in the village?',
        options: const ['The king', 'The village elder', 'Juan’s father'],
        correct: 'The village elder',
      ),
      _Question(
        prompt: '6. What was the contest about?',
        options: const [
          'Catching the biggest fish',
          'Bringing water from the river to the village square without spilling',
          'Climbing the tallest tree',
        ],
        correct:
            'Bringing water from the river to the village square without spilling',
      ),
      _Question(
        prompt: '7. What was Juan’s first reaction when he heard about the contest?',
        options: const [
          'He got very excited',
          'He said it sounded like too much work',
          'He started practicing right away',
        ],
        correct: 'He said it sounded like too much work',
      ),
      _Question(
        prompt: '8. What made Juan change his mind and join the contest?',
        options: const [
          'He wanted to prove he could do it',
          'He saw how happy the other villagers were',
          'His hammock broke',
        ],
        correct: 'He saw how happy the other villagers were',
      ),
      _Question(
        prompt: '9. What happened when Juan joined the contest?',
        options: const [
          'He spilled all the water',
          'He quit halfway',
          'He finished and brought the jug full of water to the village square',
        ],
        correct:
            'He finished and brought the jug full of water to the village square',
      ),
      _Question(
        prompt: '10. What did Juan learn at the end of the story?',
        options: const [
          'That resting is better than working',
          'That hard work can be rewarding',
          'That contests are boring',
        ],
        correct: 'That hard work can be rewarding',
      ),
    ];
  }

  bool _isLegendOfThePineapple(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return title.contains('pineapple') ||
        id.contains('pineapple') ||
        title.contains('pinya');
  }

  List<_Question> _legendOfThePineappleQuestions() {
    return [
      _Question(
        prompt: '1. Who were the two people living in the small hut?',
        options: const [
          'A father and son',
          'A mother and her daughter Pina',
          'Two sisters',
        ],
        correct: 'A mother and her daughter Pina',
      ),
      _Question(
        prompt: '2. What kind of child was Pina?',
        options: const [
          'Helpful and kind',
          'Lazy and spoiled',
          'Brave and hardworking',
        ],
        correct: 'Lazy and spoiled',
      ),
      _Question(
        prompt: '3. What did Pina like to do all day?',
        options: const [
          'Help her mother cook',
          'Play in the backyard',
          'Read books',
        ],
        correct: 'Play in the backyard',
      ),
      _Question(
        prompt:
            '4. What excuse did Pina always use when her mother asked her to help?',
        options: const [
          '“I’m too tired.”',
          '“I can’t find it.”',
          '“I’m hungry.”',
        ],
        correct: '“I can’t find it.”',
      ),
      _Question(
        prompt:
            '5. When her mother got sick, what did she ask Pina to cook?',
        options: const [
          'Rice and fish',
          'Porridge',
          'Soup and bread',
        ],
        correct: 'Porridge',
      ),
      _Question(
        prompt: '6. Why didn’t Pina cook the porridge?',
        options: const [
          'She didn’t like porridge',
          'She forgot how to cook',
          'She said she couldn’t find the ladle',
        ],
        correct: 'She said she couldn’t find the ladle',
      ),
      _Question(
        prompt: '7. What did the mother say in anger?',
        options: const [
          '“I wish you’d listen to me!”',
          '“I wish you would grow a thousand eyes all over your head!”',
          '“I wish you would go to school!”',
        ],
        correct: '“I wish you would grow a thousand eyes all over your head!”',
      ),
      _Question(
        prompt: '8. What happened after the mother said those words?',
        options: const [
          'Pina disappeared',
          'Pina cooked right away',
          'Pina went to the market',
        ],
        correct: 'Pina disappeared',
      ),
      _Question(
        prompt:
            '9. What did the mother find growing in the backyard later on?',
        options: const [
          'A flower',
          'A tree',
          'A strange plant with fruit that looked like it had many eyes',
        ],
        correct: 'A strange plant with fruit that looked like it had many eyes',
      ),
      _Question(
        prompt: '10. What is the name of the fruit today?',
        options: const [
          'Banana',
          'Pineapple (Pinya)',
          'Mango',
        ],
        correct: 'Pineapple (Pinya)',
      ),
    ];
  }

  bool _isAlamatNgSampaguita(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return (id.contains('alamat') && id.contains('sampaguita')) ||
        (title.contains('alamat') && title.contains('sampaguita'));
  }

  List<_Question> _alamatNgSampaguitaQuestions() {
    return [
      _Question(
        prompt: '1. Who came to Liwayway’s place from the north?',
        options: const [
          'A group of dancers',
          'A group of hunters',
          'A group of farmers',
        ],
        correct: 'A group of hunters',
      ),
      _Question(
        prompt: '2. What happened to Tanggol while hunting?',
        options: const [
          'He caught a wild pig',
          'He got lost in the forest',
          'He was hurt by a wild pig',
        ],
        correct: 'He was hurt by a wild pig',
      ),
      _Question(
        prompt: '3. Who helped take care of Tanggol’s wound?',
        options: const [
          'Liwayway’s mother',
          'Liwayway’s father',
          'Liwayway’s teacher',
        ],
        correct: 'Liwayway’s father',
      ),
      _Question(
        prompt: '4. How did Liwayway and Tanggol get to know each other?',
        options: const [
          'While treating Tanggol’s wound',
          'At a festival',
          'In the marketplace',
        ],
        correct: 'While treating Tanggol’s wound',
      ),
      _Question(
        prompt: '5. What did Tanggol promise before leaving?',
        options: const [
          'He would come back with gifts',
          'He would return with his parents to marry Liwayway',
          'He would never come back',
        ],
        correct: 'He would return with his parents to marry Liwayway',
      ),
      _Question(
        prompt: '6. Did Tanggol return right away as he promised?',
        options: const [
          'Yes',
          'No',
        ],
        correct: 'No',
      ),
      _Question(
        prompt: '7. What did the jealous suitor say about Tanggol?',
        options: const [
          'That he was rich',
          'That he already had a wife',
          'That he moved to another town',
        ],
        correct: 'That he already had a wife',
      ),
      _Question(
        prompt:
            '8. What happened to Liwayway because of her sadness and anger?',
        options: const [
          'She became happy again',
          'She became sick and died',
          'She forgot Tanggol',
        ],
        correct: 'She became sick and died',
      ),
      _Question(
        prompt: '9. What were Liwayway’s last words before she died?',
        options: const [
          '“Goodbye, Tanggol.”',
          '“I love you.”',
          '“I curse you! Curse you…”',
        ],
        correct: '“I curse you! Curse you…”',
      ),
      _Question(
        prompt:
            '10. What grew on Liwayway’s grave after she died?',
        options: const [
          'A mango tree',
          'A small plant with a sweet smell',
          'A rose bush',
        ],
        correct: 'A small plant with a sweet smell',
      ),
    ];
  }

  bool _isAlamatNgSaging(Story s) {
    final id = s.id.toLowerCase();
    final title = s.title.toLowerCase();
    return (id.contains('alamat') && id.contains('saging')) ||
        (title.contains('alamat') && title.contains('saging'));
  }

  List<_Question> _alamatNgSagingQuestions() {
    return [
      _Question(
        prompt:
            '1. Who were the two people who loved each other very much?',
        options: const [
          'Maria and Jose',
          'Juana and Aging',
          'Ana and Pedro',
        ],
        correct: 'Juana and Aging',
      ),
      _Question(
        prompt: '2. Why did Juana and Aging meet in secret?',
        options: const [
          'Because they liked surprises',
          'Because Juana’s parents didn’t like their love',
          'Because they were shy',
        ],
        correct: 'Because Juana’s parents didn’t like their love',
      ),
      _Question(
        prompt: '3. What did Juana’s father do when he caught them?',
        options: const [
          'He gave them gifts',
          'He cooked food for them',
          'He got angry and chased Aging',
        ],
        correct: 'He got angry and chased Aging',
      ),
      _Question(
        prompt: '4. What happened to Aging’s arm?',
        options: const [
          'It was hurt and cut off',
          'It became strong',
          'It turned into a tree right away',
        ],
        correct: 'It was hurt and cut off',
      ),
      _Question(
        prompt: '5. What did Juana do with Aging’s arm?',
        options: const [
          'She threw it away',
          'She buried it in the backyard',
          'She gave it to her father',
        ],
        correct: 'She buried it in the backyard',
      ),
      _Question(
        prompt:
            '6. What grew in the place where the arm was buried?',
        options: const [
          'A flower',
          'A big tree with apples',
          'A plant with a fruit that looked like a hand',
        ],
        correct: 'A plant with a fruit that looked like a hand',
      ),
      _Question(
        prompt: '7. What fruit came from that plant?',
        options: const [
          'Banana',
          'Mango',
          'Coconut',
        ],
        correct: 'Banana',
      ),
      _Question(
        prompt:
            '8. What did Juana softly say when she saw the plant?',
        options: const [
          '“This tree is Aging.”',
          '“This is my favorite fruit.”',
          '“I will eat this fruit.”',
        ],
        correct: '“This tree is Aging.”',
      ),
      _Question(
        prompt: '9. What was the plant first called?',
        options: const [
          'Mango tree',
          'Aging',
          'Coconut tree',
        ],
        correct: 'Aging',
      ),
      _Question(
        prompt: '10. What is the plant called today?',
        options: const [
          'Saging (banana tree)',
          'Grape vine',
          'Papaya tree',
        ],
        correct: 'Saging (banana tree)',
      ),
    ];
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
      _showAssessmentResultDialog(score: _score, total: _questions.length);
    }
  }

  Future<void> _showAssessmentResultDialog({required int score, required int total}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final stats = await ProfileStatsService().getStatsDbFirst();
    final today = await ReadingActivityRepository().getTodayLanguageStats();
    final repo = ach.AchievementsRepository();
    // Compute newly earned badges by diffing before/after
    final before = await repo.listEarned(userId);
    final after = await repo.evaluateAndSave(
      userId: userId,
      stats: stats,
      today: today,
      practicedTrickyWords: 0,
    );
    final beforeIds = before.map((b) => b.id).toSet();
    final newly = after.where((b) => !beforeIds.contains(b.id)).toList();
    // Prefer to show a "completed book" style badge (first_read) if applicable
    ach.Badge? completedBadge = after.firstWhere(
      (b) => b.id == 'first_read',
      orElse: () => newly.isNotEmpty ? newly.first : (after.isNotEmpty ? after.first : ach.AchievementsRepository.all.first),
    );

    if (!mounted) return;
    // Show a fun animated dialog
    // ignore: use_build_context_synchronously
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssessmentResultDialog(
        score: score,
        total: total,
        badge: completedBadge,
      ),
    );
  }
}

class _AssessmentResultDialog extends StatefulWidget {
  final int score;
  final int total;
  final ach.Badge? badge;
  const _AssessmentResultDialog({required this.score, required this.total, this.badge});

  @override
  State<_AssessmentResultDialog> createState() => _AssessmentResultDialogState();
}

class _AssessmentResultDialogState extends State<_AssessmentResultDialog> {
  static const _icons = [
    'assets/images/icon.png',
    'assets/images/icon1.png',
    'assets/images/icon2.png',
  ];
  int _frame = 0;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((elapsed) {
      // Swap frame every ~450ms
      if (!mounted) return;
      final idx = (elapsed.inMilliseconds ~/ 450) % _icons.length;
      if (idx != _frame) setState(() => _frame = idx);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.score / (widget.total == 0 ? 1 : widget.total));
    final nice = pct >= 0.8
        ? 'Amazing reader!'
        : pct >= 0.5
            ? 'Great effort!'
            : 'You did it!';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Container(
                key: ValueKey(_frame),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    Colors.deepPurple.shade300,
                    Colors.purple.shade400,
                  ]),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Image.asset(_icons[_frame], width: 88, height: 88),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              nice,
              style: const TextStyle(
                fontFamily: 'RustyHooks',
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your score: ${widget.score} / ${widget.total}',
              style: const TextStyle(
                fontFamily: 'OddlyCalming',
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            // Badge row
            if (widget.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(widget.badge!.iconAsset, width: 28, height: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Badge: ${widget.badge!.title}',
                      style: const TextStyle(
                        fontFamily: 'OddlyCalming',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Positive message
            const Text(
              'Reading is fun! Keep exploring stories and quizzes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'OddlyCalming',
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Keep Reading'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
