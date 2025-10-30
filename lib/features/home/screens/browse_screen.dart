import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../data/repositories/stories_repository.dart';
import '../../reader/story_details_screen.dart';
import '../../../data/cover_assets.dart';

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
                    fontFamily: 'RustyHooks',
                    fontSize: 18,
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
                                      final raw = story.coverUrl?.trim();
                                      final isNetwork =
                                          raw != null &&
                                          (raw.startsWith('http://') ||
                                              raw.startsWith('https://'));

                                      if (isNetwork) {
                                        return Image.network(
                                          raw,
                                          width: 120,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
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

                                      // Resolve asset path
                                      String? assetPath;
                                      if (raw != null && raw.isNotEmpty) {
                                        assetPath = raw.startsWith('assets/')
                                            ? raw
                                            : 'assets/images/covers/$raw';
                                      } else {
                                        assetPath = coverAssetForTitle(
                                          story.title,
                                        );
                                      }

                                      // Use asset when known; else fallback placeholder
                                      if (assetPath != null) {
                                        return Image.asset(
                                          assetPath,
                                          width: 120,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  Container(
                                                    width: 120,
                                                    color: Colors.grey.shade200,
                                                  ),
                                        );
                                      }

                                      return Image.asset(
                                        'assets/images/arts.png',
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
                                style: const TextStyle(
                                  fontFamily: 'OddlyCalming',
                                  fontSize: 14,
                                  height: 1.2,
                                ),
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
