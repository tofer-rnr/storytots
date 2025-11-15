import 'dart:convert';
import 'package:flutter/services.dart';
import 'stories_index.dart';

class StoryAssetService {
  /// Load story page content from assets folder
  static Future<String> loadPageContent({
    required String slug,
    required String language, // 'en' or 'tl'
    int pageNumber = 1,
  }) async {
    try {
      print('🔍 Searching for story: $slug ($language)');
      String? pagePath;

      // Try the index first
      final indexItem = StoriesIndex.items.where(
        (it) => it.slug == slug && it.language == language,
      );
      if (indexItem.isNotEmpty) {
        final item = indexItem.first;
        pagePath = pageNumber == 1
            ? item.page1Path
            : item.page1Path.replaceAll(
                '/001.txt',
                '/${pageNumber.toString().padLeft(3, '0')}.txt',
              );
      } else {
        // No index entry: try resolving directly from AssetManifest
        print('ℹ️ No index entry for $slug ($language). Searching manifest...');
        pagePath = await _findPageInManifest(
          slug: slug,
          language: language,
          pageNumber: pageNumber,
        );
        if (pagePath == null) {
          print('❌ Story not found in index or manifest: $slug ($language)');
          throw Exception('Story not found: $slug ($language)');
        }
      }

      try {
        print('📄 Attempting to load: $pagePath');
        final content = await rootBundle.loadString(pagePath);
        print('✓ Successfully loaded ${content.length} chars from $pagePath');
        return content;
  } catch (assetError) {
        // If the asset can't be loaded with the original path, try alternative approaches
        print('⚠️ Asset loading failed with primary path: $assetError');

        // Try approach 2: Replace spaces with underscores
        String altPath1 = pagePath.replaceAll(' ', '_');
        try {
          print('📄 Trying alternative path (underscores): $altPath1');
          final content = await rootBundle.loadString(altPath1);
          print(
            '✓ Successfully loaded ${content.length} chars with underscore path',
          );
          return content;
        } catch (_) {
          // Try approach 3: Normalize to lowercase path
          String altPath2 = pagePath.toLowerCase();
          try {
            print('📄 Trying alternative path (lowercase): $altPath2');
            final content = await rootBundle.loadString(altPath2);
            print(
              '✓ Successfully loaded ${content.length} chars with lowercase path',
            );
            return content;
          } catch (_) {
            // Try approach 4: Search AssetManifest.json for a matching path
            try {
              final resolved = await _findPageInManifest(
                slug: slug,
                language: language,
                pageNumber: pageNumber,
              );
              if (resolved != null) {
                print('📄 Trying manifest-discovered path: $resolved');
                final content = await rootBundle.loadString(resolved);
                print('✓ Successfully loaded ${content.length} chars via manifest');
                return content;
              } else {
                throw Exception('No matching asset found in manifest');
              }
            } catch (finalError) {
              // If all approaches fail, rethrow with detailed error message
              print('❌ All loading attempts failed');
              throw Exception('All attempts to load asset failed: $finalError');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error loading page content: $e');
      throw Exception('Failed to load page content for $slug ($language): $e');
    }
  }

  /// Load story synopsis from assets folder
  static Future<String> loadSynopsis({
    required String slug,
    required String language, // 'en' or 'tl'
  }) async {
    // Find story in index
    final item = StoriesIndex.items.firstWhere(
      (item) => item.slug == slug && item.language == language,
      orElse: () => throw Exception('Synopsis not found: $slug ($language)'),
    );

    try {
      return await rootBundle.loadString(item.synopsisPath);
    } catch (e) {
      print('Error loading synopsis: $e');
      return 'Synopsis not available.';
    }
  }

  /// Get the index entry for a story by ID
  static StoryIndexItem? findBySlug(String slug, String language) {
    try {
      return StoriesIndex.items.firstWhere(
        (item) => item.slug == slug && item.language == language,
      );
    } catch (_) {
      return null;
    }
  }

  /// Search AssetManifest.json for a plausible story page path when direct
  /// lookup fails. This supports folders with spaces/casing differences like
  /// `assets/stories/The Carabao and the Shell/en/pages/001.txt`.
  static Future<String?> _findPageInManifest({
    required String slug,
    required String language,
    required int pageNumber,
  }) async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestJson);

      final wantedFile = '${pageNumber.toString().padLeft(3, '0')}.txt';
      // Normalize slug to a set of words
      final slugWords = slug
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\-\s]'), ' ')
          .split(RegExp(r'[\s\-]+'))
          .where((w) => w.isNotEmpty)
          .toList();
      final stop = <String>{'the', 'a', 'an', 'ng', 'ang', 'sa', 'si', 'ni', 'mga', 'at', 'of', 'and'};
      final contentWords = slugWords.where((w) => !stop.contains(w)).toList();

      bool matchesAllWords(String keyLower, List<String> words) =>
          words.every((w) => keyLower.contains(w));

      List<String> keysWhere(bool Function(String) pred) => manifest.keys
          .where((k) {
            final keyLower = k.toLowerCase();
            if (!keyLower.startsWith('assets/stories/')) return false;
            if (!keyLower.contains('/$language/')) return false;
            if (!keyLower.contains('/pages/')) return false;
            if (!keyLower.endsWith('/$wantedFile')) return false;
            return pred(keyLower);
          })
          .toList();

      // Pass 1: require all meaningful words (or all slug words if none remain)
      var candidates = keysWhere(
        (keyLower) => matchesAllWords(
          keyLower,
          contentWords.isEmpty ? slugWords : contentWords,
        ),
      );

      // Pass 2: if none, require at least 2 matches from slug words
      if (candidates.isEmpty) {
        candidates = keysWhere((keyLower) {
          int matches = 0;
          for (final w in slugWords) {
            if (keyLower.contains(w)) matches++;
          }
          return matches >= 2 || (slugWords.length == 1 && matches >= 1);
        });
      }

      // Pass 3: if still none, require at least 1 match from content words
      if (candidates.isEmpty && contentWords.isNotEmpty) {
        candidates = keysWhere((keyLower) => contentWords.any((w) => keyLower.contains(w)));
      }

      if (candidates.isEmpty) return null;

      // Prefer non-normalized paths first (without _normalized_stories), then shortest
      candidates.sort((a, b) {
        final aNorm = a.contains('_normalized_stories') ? 1 : 0;
        final bNorm = b.contains('_normalized_stories') ? 1 : 0;
        final cmp = aNorm.compareTo(bNorm);
        if (cmp != 0) return cmp;
        return a.length.compareTo(b.length);
      });

      return candidates.first;
    } catch (e) {
      print('⚠️ Manifest search failed: $e');
      return null;
    }
  }
}
