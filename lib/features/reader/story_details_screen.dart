import 'package:flutter/material.dart';
import 'package:storytots/core/constants.dart';
import 'package:storytots/data/cover_assets.dart';
import 'package:storytots/data/repositories/stories_repository.dart';
import 'package:storytots/data/repositories/library_repository.dart';
import 'package:storytots/data/story_content.dart';
import 'reading_page_v2.dart';
import 'speech/speech_service_factory.dart';

class StoryDetailsScreen extends StatefulWidget {
  final String storyId;
  const StoryDetailsScreen({super.key, required this.storyId});

  @override
  State<StoryDetailsScreen> createState() => _StoryDetailsScreenState();
}

class _StoryDetailsScreenState extends State<StoryDetailsScreen> {
  final storiesRepo = StoriesRepository();
  final libraryRepo = LibraryRepository();
  bool? _isFavorite; // null while loading

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    try {
      final entry = await libraryRepo.getByStoryId(widget.storyId);
      setState(() => _isFavorite = entry?.isFavorite ?? false);
    } catch (_) {
      setState(() => _isFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Story?>(
      future: storiesRepo.getById(widget.storyId),
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final story = snap.data;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(brandPurple),
            foregroundColor: Colors.white,
            title: const Text('Story'),
            actions: [
              if (!loading && story != null)
                IconButton(
                  tooltip: (_isFavorite ?? false) ? 'Unfavorite' : 'Add to favorites',
                  icon: Icon(
                    (_isFavorite ?? false) ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    // Ensure row exists, then toggle
                    try {
                      await libraryRepo.ensureRow(
                        storyId: story.id,
                        title: story.title,
                        coverUrl: story.coverUrl ?? coverAssetForTitle(story.title),
                      );
                    } catch (_) {}

                    final newVal = !(_isFavorite ?? false);
                    setState(() => _isFavorite = newVal);
                    try {
                      await libraryRepo.toggleFavorite(story.id, newVal);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(newVal ? 'Added to favorites' : 'Removed from favorites'),
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() => _isFavorite = !newVal);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to update favorite')),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/storytots_background.png', fit: BoxFit.cover),
              Container(color: Colors.white.withOpacity(0.94)),
              if (loading || story == null)
                const Center(child: CircularProgressIndicator())
              else
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _CoverBox(title: story.title, coverUrl: story.coverUrl),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(brandPurple),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              story.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _roundIconButton(
                                Icons.favorite,
                                onTap: () async {
                                  // mirror AppBar favorite toggle for convenience
                                  final favNow = !(_isFavorite ?? false);
                                  setState(() => _isFavorite = favNow);
                                  try {
                                    await libraryRepo.ensureRow(
                                      storyId: story.id,
                                      title: story.title,
                                      coverUrl: story.coverUrl ?? coverAssetForTitle(story.title),
                                    );
                                    await libraryRepo.toggleFavorite(story.id, favNow);
                                  } catch (_) {
                                    setState(() => _isFavorite = !favNow);
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(brandPurple),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: () async {
                                      try {
                                        await libraryRepo.recordOpen(
                                          storyId: story.id,
                                          title: story.title,
                                          coverUrl: (story.coverUrl?.isNotEmpty == true)
                                              ? story.coverUrl
                                              : coverAssetForTitle(story.title),
                                        );
                                      } catch (_) {}

                                      // Try to get story content from local mapping first
                                      String text;
                                      if (StoryContent.hasContent(story.id)) {
                                        // Get the first page of the story content
                                        final pages = StoryContent.getPagesById(story.id);
                                        text = pages?.first ?? StoryContent.getContentById(story.id)!;
                                      } else {
                                        // Fallback to synopsis or placeholder
                                        text = story.synopsis?.isNotEmpty == true
                                            ? story.synopsis!
                                            : 'Let\'s read ${story.title}.';
                                      }
                                      
                                      // Use reading page for all stories
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReadingPageV2(
                                            pageText: text,
                                            storyId: story.id,
                                            storyTitle: story.title,
                                            coverUrl: story.coverUrl ?? coverAssetForTitle(story.title),
                                            speechServiceType: SpeechServiceType.deviceSTT,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Read'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _roundIconButton(Icons.add, onTap: () {}),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Synopsis of the story:',
                                  style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text(story.synopsis ?? '—'),
                                const SizedBox(height: 16),
                                _kv('Written by:', story.writtenBy),
                                _kv('Illustrated by:', story.illustratedBy),
                                _kv('Published:', story.publishedBy),
                                _kv('Reading Age:', story.readingAge),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- helpers ---------------------------------------------------------------

  Widget _kv(String k, String? v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, height: 1.35),
          children: [
            TextSpan(text: '• $k ', style: const TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(text: v?.isNotEmpty == true ? v! : '—'),
          ],
        ),
      ),
    );
  }

  Widget _roundIconButton(IconData icon, {required VoidCallback onTap}) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Icon(icon, color: const Color(brandPurple)),
        ),
      ),
    );
  }
}

/// Decides which image to display using your cover_assets map.
class _CoverBox extends StatelessWidget {
  const _CoverBox({required this.title, required this.coverUrl});

  final String title;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final localAsset = _assetForTitle(title); // uses coverAssetForTitle()

    ImageProvider imageProvider;
    if ((coverUrl ?? '').isNotEmpty) {
      imageProvider = NetworkImage(coverUrl!);
    } else if (localAsset != null && localAsset.isNotEmpty) {
      imageProvider = AssetImage(localAsset);
    } else {
      imageProvider = const AssetImage('assets/images/book_cover_placeholder.png');
    }

    return Container(
      width: 220,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
        ],
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    );
  }

  /// Try exact title; if not found, try title without the parenthetical part.
  String? _assetForTitle(String t) {
    final exact = coverAssetForTitle(t);
    if (exact != null) return exact;

    final i = t.indexOf('(');
    if (i != -1) {
      final stripped = t.substring(0, i).trim();
      final alt = coverAssetForTitle(stripped);
      if (alt != null) return alt;
    }
    return null;
  }
}
