import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../data/repositories/stories_repository.dart';
import '../../reader/story_details_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _storiesRepo = StoriesRepository();
  late Future<List<Story>> _allStoriesFuture;

  @override
  void initState() {
    super.initState();
    _allStoriesFuture = _listAllStories();
  }

  Future<List<Story>> _listAllStories() async {
    // Supabase table 'stories' may be large; use pagination if necessary.
    final rows = await _storiesRepo.supa
        .from('stories')
        .select('*')
        .order('created_at', ascending: false);
    final list = (rows as List?) ?? const [];
    return list.map((e) => Story.fromMap(e as Map<String, dynamic>)).toList();
  }

  Map<String, List<Story>> _groupByTopic(List<Story> stories) {
    final Map<String, List<Story>> out = {};
    for (final s in stories) {
      final topics = s.topics.isEmpty ? ['Uncategorized'] : s.topics;
      for (final t in topics) {
        out.putIfAbsent(t, () => []).add(s);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Stories'),
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Story>>(
        future: _allStoriesFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final stories = snap.data ?? [];
          final grouped = _groupByTopic(stories);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in grouped.entries) ...[
                Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: entry.value.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final story = entry.value[i];
                      return SizedBox(
                        width: 120,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StoryDetailsScreen(storyId: story.id),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Builder(
                                    builder: (context) {
                                      final cover = story.coverUrl;
                                      final isNetwork =
                                          cover != null &&
                                          (cover.startsWith('http://') ||
                                              cover.startsWith('https://'));

                                      if (isNetwork) {
                                        return Image.network(
                                          cover,
                                          width: 120,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          // show a light grey box while loading
                                          loadingBuilder:
                                              (context, child, progress) {
                                                if (progress == null)
                                                  return child;
                                                return Container(
                                                  width: 120,
                                                  color: Colors.grey.shade200,
                                                );
                                              },
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  Container(
                                                    width: 120,
                                                    color: Colors.grey.shade200,
                                                  ),
                                        );
                                      }

                                      // fallback to asset or a grey box
                                      final assetPath = () {
                                        if (cover == null ||
                                            cover.trim().isEmpty)
                                          return 'assets/images/book_cover_placeholder.png';
                                        final c = cover.trim();
                                        // already a network url handled earlier
                                        if (c.startsWith('assets/')) return c;
                                        // if it's an absolute filesystem-like path, strip leading '/'
                                        if (c.startsWith('/'))
                                          return 'assets/images/covers/${c.substring(1)}';
                                        // if it's likely a filename (e.g. 'The_Monkey_and_the_Turtle.png'), prefix covers dir
                                        if (!c.contains('/'))
                                          return 'assets/images/covers/$c';
                                        // if it's a relative path like 'covers/name.jpg' or 'images/covers/name.jpg'
                                        if (c.contains('covers/')) {
                                          // ensure it starts with assets/
                                          return c.startsWith('assets/')
                                              ? c
                                              : 'assets/images/${c.split('covers/').last.isEmpty ? '' : 'covers/${c.split('covers/').last}'}';
                                        }
                                        // fallback
                                        return 'assets/images/covers/$c';
                                      }();
                                      return Image.asset(
                                        assetPath,
                                        width: 120,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) =>
                                            Container(
                                              width: 120,
                                              color: Colors.grey.shade200,
                                            ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                story.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          );
        },
      ),
    );
  }
}
