import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants.dart';
import '../../../data/repositories/stories_repository.dart';
import '../../reader/story_details_screen.dart';
import '../../reader/reading_page_v3.dart';
import '../../reader/speech/speech_service_factory.dart';
import '../widgets/story_card.dart';
import 'browse_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storiesRepo = StoriesRepository();

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final row = await Supabase.instance.client
        .from('profiles')
        .select('interests, avatar_key')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;

    final interests = <String>[];
    final raw = row['interests'];
    if (raw is List) {
      for (final v in raw) {
        if (v is String) interests.add(v);
      }
    }

    final avatarKey = row['avatar_key'] as String?;
    return {
      'interests': interests,
      'avatarPath': _avatarAssetFromKey(avatarKey),
    };
  }

  Future<Map<String, List<Story>>> _loadSections(List<String> interests) async {
    final Map<String, List<Story>> out = {};
    for (final topic in interests) {
      out[topic] = await _storiesRepo.listByTopic(topic, limit: 6);
    }
    return out;
  }

  Future<List<Story>> _loadContinueReading() async {
    return _storiesRepo.listReadingHistory(limit: 6);
  }

  static String _avatarAssetFromKey(String? key) {
    switch (key) {
      case 'boy':
        return 'assets/images/boy.png';
      case 'girl':
        return 'assets/images/girl.png';
      case 'dog':
        return 'assets/images/dog.png';
      case 'cat':
        return 'assets/images/cat.png';
      case 'hamster':
        return 'assets/images/hamster.png';
      case 'chimpmuck':
        return 'assets/images/chimpmuck.png';
      case 'pup':
        return 'assets/images/dog.png';
      case 'cub':
        return 'assets/images/hamster.png';
      case 'owl':
        return 'assets/images/cat.png';
      case 'bunny':
        return 'assets/images/hamster.png';
      default:
        return 'assets/images/avatar_placeholder.png';
    }
  }

  void _openReader({String? topic}) {
    final sample = (topic == null)
        ? "Kapag nakita ni Luna ang maliwanag na buwan, bumulong siya ng 'hello' at ngumiti."
        : "Basahin natin tungkol sa $topic. Dahan-dahan nating basahin ang bawat salita.";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingPageV3(
          pageText: sample,
          storyId: 'demo',
          storyTitle: topic ?? 'Demo Story',
          coverUrl: '',
          speechServiceType: SpeechServiceType.deviceSTT,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadProfile(),
      builder: (context, snap) {
        final loadingProfile = snap.connectionState != ConnectionState.done;
        final data = snap.data;
        final interests =
            (data?['interests'] as List<String>?) ?? const <String>[];
        final avatarPath =
            (data?['avatarPath'] as String?) ??
            'assets/images/avatar_placeholder.png';

        return FutureBuilder<Map<String, List<Story>>>(
          future: loadingProfile ? null : _loadSections(interests),
          builder: (context, secSnap) {
            final loadingSections =
                loadingProfile ||
                (secSnap.connectionState != ConnectionState.done &&
                    interests.isNotEmpty);
            final sections = secSnap.data ?? const <String, List<Story>>{};

            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(brandPurple),
                foregroundColor: Colors.white,
                title: const Text(
                  'storytots',
                  style: TextStyle(
                    fontFamily: 'Growback',
                    fontSize: 24,
                    letterSpacing: 1.5,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: AssetImage(avatarPath),
                      onBackgroundImageError: (_, __) {},
                    ),
                  ),
                ],
              ),
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/storytots_background.png',
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.white.withOpacity(0.92)),

                  if (loadingSections)
                    const Center(child: CircularProgressIndicator())
                  else
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        // Search
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.menu_book_rounded),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Explore stories and collections',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BrowseScreen(),
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(brandPurple),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Browse more'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Header banner
                        GestureDetector(
                          onTap: () => _openReader(),
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withOpacity(.2),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 6),
                                ),
                              ],
                              image: const DecorationImage(
                                image: AssetImage(
                                  'assets/images/covers/header_banner.png',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        _sectionTitle('CONTINUE READING'),
                        const SizedBox(height: 10),

                        // ✅ Continue Reading driven by DB (FIFO)
                        _continueReadingSection(),

                        const SizedBox(height: 20),

                        ..._interestsSection(interests, sections),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _continueReadingSection() {
    return FutureBuilder<List<Story>>(
      future: _loadContinueReading(),
      builder: (context, crSnap) {
        if (crSnap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final stories = crSnap.data ?? [];
        if (stories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              "No reading yet — let’s start an adventure! 📚✨\nTap any story to begin.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          );
        }
        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final story = stories[i];
              return StoryCard(
                story: story,
                onTap: () {
                  _storiesRepo.touchReadingHistory(story.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryDetailsScreen(storyId: story.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _interestsSection(
    List<String> interests,
    Map<String, List<Story>> sections,
  ) {
    if (interests.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Topics of Interest',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'RustyHooks',
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Personalize StoryTots by selecting topics your child loves.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(brandPurple),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Pick topics'),
              ),
            ],
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final topic in interests) {
      widgets.add(const SizedBox(height: 20));
      widgets.add(
        _sectionTitle(
          topic,
          trailing: Icons.chevron_right_rounded,
          onTap: () {},
        ),
      );
      widgets.add(const SizedBox(height: 10));
      widgets.add(_storyRow(sections[topic] ?? const []));
    }
    return widgets;
  }

  Widget _sectionTitle(String text, {IconData? trailing, VoidCallback? onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
              fontFamily: 'RustyHooks',
              fontSize: 20,
            ),
          ),
        ),
        if (trailing != null)
          IconButton(onPressed: onTap, icon: Icon(trailing)),
      ],
    );
  }

  Widget _storyRow(List<Story> stories) {
    if (stories.isEmpty) {
      return SizedBox(
        height: 150,
        child: Row(
          children: [
            Expanded(child: _emptyCard()),
            const SizedBox(width: 12),
            Expanded(child: _emptyCard()),
            const SizedBox(width: 12),
            Expanded(child: _emptyCard()),
          ],
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => StoryCard(
          story: stories[i],
          onTap: () {
            _storiesRepo.touchReadingHistory(stories[i].id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoryDetailsScreen(storyId: stories[i].id),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
    );
  }
}
