import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storytots/core/constants.dart';
import 'package:storytots/data/cover_assets.dart';
import 'package:storytots/data/repositories/stories_repository.dart';
import 'package:storytots/data/repositories/library_repository.dart';
import 'package:storytots/data/story_content.dart';
import 'package:storytots/data/story_asset_service.dart';
import 'package:storytots/data/stories_index.dart';
import 'reading_page_v3.dart';
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

  // Helper to convert a title to a slug for asset lookup
  String _slugifyTitle(String title) {
    // First handle special cases with direct lookup
    final lowerTitle = title.toLowerCase();

    // Handle special cases - story titles
    if (lowerTitle.contains('monkey') && lowerTitle.contains('turtle')) {
      return 'the-monkey-and-the-turtle';
    } else if (lowerTitle.contains('unggoy') && lowerTitle.contains('pagong')) {
      return 'the-monkey-and-the-turtle'; // Tagalog version
    } else if (lowerTitle.contains('alamat') && lowerTitle.contains('saging')) {
      return 'alamat-ng-saging';
    } else if (lowerTitle.contains('legend') && lowerTitle.contains('banana')) {
      return 'alamat-ng-saging'; // English version
    } else if (lowerTitle.contains('alamat') &&
        lowerTitle.contains('sampaguita')) {
      return 'alamat-ng-sampaguita';
    } else if (lowerTitle.contains('legend') &&
        lowerTitle.contains('sampaguita')) {
      return 'alamat-ng-sampaguita'; // English version
    } else if (lowerTitle.contains('sky') && lowerTitle.contains('high')) {
      return 'why-the-sky-is-high';
    } else if (lowerTitle.contains('carabao') && lowerTitle.contains('shell')) {
      return 'the-carabao-and-the-shell';
    } else if (lowerTitle.contains('bitter') && lowerTitle.contains('gourd')) {
      return 'the-legend-of-the-bitter-gourd';
    } else if (lowerTitle.contains('ampalaya')) {
      return 'the-legend-of-the-bitter-gourd'; // Tagalog version
    } else if (lowerTitle.contains('rainbow')) {
      return 'the-legend-of-the-rainbow';
    } else if ((lowerTitle.contains('salty') && lowerTitle.contains('sea')) ||
        (lowerTitle.contains('ocean') && lowerTitle.contains('salt'))) {
      return 'why-the-ocean-is-salty';
    } else if (lowerTitle.contains('juan') && lowerTitle.contains('tamad')) {
      return 'stories-of-juan-tamad';
    } else if (lowerTitle.contains('lion') && lowerTitle.contains('mouse')) {
      return 'the-lion-and-the-mouse';
    } else if (lowerTitle.contains('ant') &&
        lowerTitle.contains('grasshopper')) {
      return 'the-ant-and-the-grasshopper';
    } else if (lowerTitle.contains('pineapple') ||
        lowerTitle.contains('piña')) {
      return 'legend-of-the-pineapple';
    } else if (lowerTitle.contains('bahay') && lowerTitle.contains('kubo')) {
      return 'bahay-kubo';
    } else if (lowerTitle.contains('sandosenang') && lowerTitle.contains('sapatos')) {
      return 'sandosenang-sapatos';
    } else if (lowerTitle.contains('mats')) {
      return 'the-mats';
    } else if ((lowerTitle.contains('barumbadong') && lowerTitle.contains('bus')) ||
        (lowerTitle.contains('barumbado') && lowerTitle.contains('bus'))) {
      return 'ang-barumbadong-bus';
    }

    // If no special case matches, normalize the string
    final normalized = lowerTitle
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), '-'); // Replace spaces with hyphens

    print('📚 Title: "$title" => Slug: "$normalized" (no special case match)');
    return normalized;
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
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/storytots_background.png',
                fit: BoxFit.cover,
              ),
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
                          _CoverBox(
                            title: story.title,
                            coverUrl: story.coverUrl,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(brandPurple),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              story.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'OddlyCalming',
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _roundIconButton(
                                (_isFavorite ?? false)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                isFilled: _isFavorite ?? false,
                                onTap: () async {
                                  // mirror AppBar favorite toggle for convenience
                                  final favNow = !(_isFavorite ?? false);
                                  setState(() => _isFavorite = favNow);
                                  try {
                                    await libraryRepo.ensureRow(
                                      storyId: story.id,
                                      title: story.title,
                                      coverUrl:
                                          story.coverUrl ??
                                          coverAssetForTitle(story.title),
                                    );
                                    await libraryRepo.toggleFavorite(
                                      story.id,
                                      favNow,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            favNow
                                                ? 'Added to favorites'
                                                : 'Removed from favorites',
                                          ),
                                        ),
                                      );
                                    }
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () async {
                                      try {
                                        await libraryRepo.recordOpen(
                                          storyId: story.id,
                                          title: story.title,
                                          coverUrl:
                                              (story.coverUrl?.isNotEmpty ==
                                                  true)
                                              ? story.coverUrl
                                              : coverAssetForTitle(story.title),
                                        );
                                      } catch (_) {}

                                      // Load ENGLISH content by default
                                      String text =
                                          "Let's read ${story.title}.";
                                      bool contentLoaded = false;

                                      try {
                                        final storySlug = _slugifyTitle(
                                          story.title,
                                        );

                                        // Try English directly
                                        try {
                                          text =
                                              await StoryAssetService.loadPageContent(
                                                slug: storySlug,
                                                language: 'en',
                                              );
                                          contentLoaded = true;
                                        } catch (_) {
                                          // Try via index
                                          for (var item in StoriesIndex.items) {
                                            final matchesSlug =
                                                item.slug == storySlug ||
                                                _slugifyTitle(item.title) ==
                                                    storySlug;
                                            if (matchesSlug &&
                                                item.language == 'en') {
                                              try {
                                                text =
                                                    await StoryAssetService.loadPageContent(
                                                      slug: item.slug,
                                                      language: 'en',
                                                    );
                                                contentLoaded = true;
                                                break;
                                              } catch (_) {}
                                            }
                                          }
                                        }

                                        // Fallbacks
                                        if (!contentLoaded &&
                                            StoryContent.hasContent(story.id)) {
                                          final pages =
                                              StoryContent.getPagesById(
                                                story.id,
                                              );
                                          if (pages != null &&
                                              pages.isNotEmpty) {
                                            text = pages.first;
                                            contentLoaded = true;
                                          } else {
                                            final content =
                                                StoryContent.getContentById(
                                                  story.id,
                                                );
                                            if (content != null) {
                                              text = content;
                                              contentLoaded = true;
                                            }
                                          }
                                        }

                                        if (!contentLoaded &&
                                            (story.synopsis?.isNotEmpty ==
                                                true)) {
                                          text = story.synopsis!;
                                          contentLoaded = true;
                                        }
                                      } catch (_) {}

                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReadingPageV3(
                                            pageText: text,
                                            pageTextEn:
                                                text, // mark as English for TTS
                                            storyId: story.id,
                                            storyTitle: story.title,
                                            coverUrl:
                                                story.coverUrl ??
                                                coverAssetForTitle(story.title),
                                            speechServiceType:
                                                SpeechServiceType.deviceSTT,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Read'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // New Filipino button opens Tagalog page
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(brandPurple),
                                        width: 2,
                                      ),
                                      foregroundColor: const Color(brandPurple),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () async {
                                      String? textTl;
                                      try {
                                        final slug = _slugifyTitle(story.title);
                                        // Try direct TL
                                        try {
                                          textTl =
                                              await StoryAssetService.loadPageContent(
                                                slug: slug,
                                                language: 'tl',
                                              );
                                        } catch (_) {
                                          // Try via index lookup
                                          for (final item
                                              in StoriesIndex.items) {
                                            final matches =
                                                item.slug == slug ||
                                                _slugifyTitle(item.title) ==
                                                    slug;
                                            if (matches &&
                                                item.language == 'tl') {
                                              try {
                                                textTl =
                                                    await StoryAssetService.loadPageContent(
                                                      slug: item.slug,
                                                      language: 'tl',
                                                    );
                                                break;
                                              } catch (_) {}
                                            }
                                          }
                                        }
                                      } catch (_) {}

                                      if (textTl == null ||
                                          textTl.trim().isEmpty) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Tagalog version is not available yet.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReadingPageV3(
                                            pageText: textTl!,
                                            pageTextTl:
                                                textTl, // mark as Filipino for TTS
                                            storyId: story.id,
                                            storyTitle: story.title,
                                            coverUrl:
                                                story.coverUrl ??
                                                coverAssetForTitle(story.title),
                                            speechServiceType:
                                                SpeechServiceType.deviceSTT,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Filipino'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Synopsis of the story:',
                                  style: TextStyle(
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w800,
                                  ),
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
            TextSpan(
              text: '• $k ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: v?.isNotEmpty == true ? v! : '—'),
          ],
        ),
      ),
    );
  }

  /// Converts a story title to a slug format for asset lookup

  Widget _roundIconButton(
    IconData icon, {
    required VoidCallback onTap,
    bool isFilled = false,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: isFilled ? const Color(brandPurple) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Icon(
            icon,
            color: isFilled ? Colors.white : const Color(brandPurple),
          ),
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
    final raw = coverUrl?.trim();
    final isNetwork =
        raw != null &&
        (raw.startsWith('http://') || raw.startsWith('https://'));

    // Determine best asset fallback from title
    final mappedAsset = coverAssetForTitle(title);

    Widget child;
    if (isNetwork) {
      child = Image.network(
        raw,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          mappedAsset ?? 'assets/images/arts.png',
          fit: BoxFit.cover,
        ),
      );
    } else {
      String? assetPath = mappedAsset;
      if (raw != null && raw.isNotEmpty) {
        assetPath = raw.startsWith('assets/')
            ? raw
            : 'assets/images/covers/$raw';
      }
      child = Image.asset(
        assetPath ?? 'assets/images/arts.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/arts.png', fit: BoxFit.cover),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(aspectRatio: 16 / 10, child: child),
    );
  }
}
