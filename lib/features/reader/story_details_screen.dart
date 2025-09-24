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
      return 'the-monkey-and-the-turtle';  // Tagalog version
    } else if (lowerTitle.contains('alamat') && lowerTitle.contains('saging')) {
      return 'alamat-ng-saging';
    } else if (lowerTitle.contains('legend') && lowerTitle.contains('banana')) {
      return 'alamat-ng-saging';  // English version
    } else if (lowerTitle.contains('alamat') && lowerTitle.contains('sampaguita')) {
      return 'alamat-ng-sampaguita';
    } else if (lowerTitle.contains('legend') && lowerTitle.contains('sampaguita')) {
      return 'alamat-ng-sampaguita'; // English version
    } else if (lowerTitle.contains('sky') && lowerTitle.contains('high')) {
      return 'why-the-sky-is-high';
    } else if (lowerTitle.contains('carabao') && lowerTitle.contains('shell')) {
      return 'the-carabao-and-the-shell';
    } else if (lowerTitle.contains('bitter') && lowerTitle.contains('gourd')) {
      return 'the-legend-of-the-bitter-gourd';
    } else if (lowerTitle.contains('ampalaya')) {
      return 'the-legend-of-the-bitter-gourd';  // Tagalog version
    } else if (lowerTitle.contains('rainbow')) {
      return 'the-legend-of-the-rainbow';
    } else if ((lowerTitle.contains('salty') && lowerTitle.contains('sea')) ||
              (lowerTitle.contains('ocean') && lowerTitle.contains('salt'))) {
      return 'why-the-ocean-is-salty';
    } else if (lowerTitle.contains('juan') && lowerTitle.contains('tamad')) {
      return 'stories-of-juan-tamad';
    } else if (lowerTitle.contains('lion') && lowerTitle.contains('mouse')) {
      return 'the-lion-and-the-mouse';
    } else if (lowerTitle.contains('ant') && lowerTitle.contains('grasshopper')) {
      return 'the-ant-and-the-grasshopper';
    } else if (lowerTitle.contains('pineapple') || lowerTitle.contains('piña')) {
      return 'legend-of-the-pineapple';
    }
    
    // If no special case matches, normalize the string
    final normalized = lowerTitle
      .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars
      .replaceAll(RegExp(r'\s+'), '-');    // Replace spaces with hyphens
    
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

                                      // Try to load story content from assets
                                      String text = 'Let\'s read ${story.title}.';  // Default text
                                      bool contentLoaded = false;
                                      
                                      try {
                                        // First, determine if we have this story in assets
                                        final storySlug = _slugifyTitle(story.title);
                                        // Language is either 'tl' or defaults to 'en'
                                        final language = story.language.toLowerCase() == 'tl' ? 'tl' : 'en';
                                        
                                        print('📚 --------- STORY LOADING ----------');
                                        print('📚 Story title: "${story.title}" (ID: ${story.id})');
                                        print('📚 Story slug: "$storySlug", language: "$language"');
                                        print('📚 ---------------------------------');
                                        
                                        // DIRECT APPROACH: Try loading directly by slug
                                        try {
                                          print('📚 ATTEMPT 1: Direct loading with slug');
                                          text = await StoryAssetService.loadPageContent(
                                            slug: storySlug,
                                            language: language,
                                          );
                                          print('📚 ✅ SUCCESS: Content loaded directly, length: ${text.length} chars');
                                          contentLoaded = true;
                                        } catch (directError) {
                                          print('📚 ❌ FAILED direct loading: $directError');
                                          
                                          // SEARCH APPROACH: Search through index
                                          print('📚 ATTEMPT 2: Searching index for matching story');
                                          bool foundInAssets = false;
                                          
                                          for (var item in StoriesIndex.items) {
                                            print('📚 Checking index: "${item.title}" (${item.slug}) [${item.language}]');
                                            
                                            // Method 1: Direct slug match
                                            if (item.slug == storySlug && item.language == language) {
                                              print('📚 ✓ MATCH! (direct slug match)');
                                              foundInAssets = true;
                                            } 
                                            // Method 2: Title-derived slug match
                                            else if (_slugifyTitle(item.title) == storySlug && item.language == language) {
                                              print('📚 ✓ MATCH! (title-derived slug match)');
                                              foundInAssets = true;
                                            }
                                            // Method 3: Title contains match
                                            else if (item.title.toLowerCase().contains(story.title.toLowerCase()) && 
                                                   item.language == language) {
                                              print('📚 ✓ MATCH! (title contains match)');
                                              foundInAssets = true;
                                            }
                                            
                                            if (foundInAssets) {
                                              try {
                                                print('📚 Loading content from: ${item.page1Path}');
                                                text = await StoryAssetService.loadPageContent(
                                                  slug: item.slug,
                                                  language: language,
                                                );
                                                print('📚 ✅ Content loaded, length: ${text.length} chars');
                                                contentLoaded = true;
                                                break;
                                              } catch (loadError) {
                                                print('📚 ❌ Failed to load content: $loadError');
                                                foundInAssets = false; // Reset to try other matches
                                              }
                                            }
                                          }
                                          
                                          // Fallbacks if not found in assets
                                          if (!foundInAssets) {
                                            print('📚 ❌ Story not found in assets, using fallbacks');
                                            
                                            // FALLBACK 1: StoryContent hardcoded mapping
                                            if (StoryContent.hasContent(story.id)) {
                                              print('📚 FALLBACK 1: Using legacy content mapping');
                                              final pages = StoryContent.getPagesById(story.id);
                                              if (pages != null && pages.isNotEmpty) {
                                                text = pages.first;
                                                print('📚 ✅ Using legacy page content: ${text.length} chars');
                                                contentLoaded = true;
                                              } else {
                                                final content = StoryContent.getContentById(story.id);
                                                if (content != null) {
                                                  text = content;
                                                  print('📚 ✅ Using legacy story content: ${text.length} chars');
                                                  contentLoaded = true;
                                                }
                                              }
                                            }
                                            
                                            // FALLBACK 2: Synopsis
                                            if (!contentLoaded && story.synopsis?.isNotEmpty == true) {
                                              print('📚 FALLBACK 2: Using synopsis');
                                              text = story.synopsis!;
                                              print('📚 ✅ Using synopsis: ${text.length} chars');
                                              contentLoaded = true;
                                            }
                                          }
                                        }
                                      } catch (e) {
                                        // If any errors in the overall process
                                        print('❌ Error in story loading process: $e');
                                        if (!contentLoaded && story.synopsis?.isNotEmpty == true) {
                                          text = story.synopsis!;
                                          print('📚 Emergency fallback: Using synopsis: ${text.length} chars');
                                        }
                                      }
                                      
                                      // Final text check
                                      if (text == 'Let\'s read ${story.title}.') {
                                        print('❗ WARNING: Using default text - no content was loaded');
                                      }
                                      
                                      // Use reading page for all stories
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReadingPageV3(
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

  /// Converts a story title to a slug format for asset lookup


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
