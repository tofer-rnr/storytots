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
      
      // Find story in index
      final item = StoriesIndex.items.firstWhere(
        (item) => item.slug == slug && item.language == language,
        orElse: () {
          print('❌ Story not found in index: $slug ($language)');
          throw Exception('Story not found: $slug ($language)');
        },
      );
      
      // Use the pre-defined path from the index
      final pagePath = pageNumber == 1 ? item.page1Path : 
        item.page1Path.replaceAll('/001.txt', '/${pageNumber.toString().padLeft(3, '0')}.txt');
      
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
          print('✓ Successfully loaded ${content.length} chars with underscore path');
          return content;
        } catch (_) {
          // Try approach 3: Normalize to lowercase path
          String altPath2 = pagePath.toLowerCase();
          try {
            print('📄 Trying alternative path (lowercase): $altPath2');
            final content = await rootBundle.loadString(altPath2);
            print('✓ Successfully loaded ${content.length} chars with lowercase path');
            return content;
          } catch (finalError) {
            // If all approaches fail, rethrow with detailed error message
            print('❌ All loading attempts failed');
            throw Exception('All attempts to load asset failed: $finalError');
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
}
