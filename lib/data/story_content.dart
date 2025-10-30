// lib/data/story_content.dart

/// Story content mapping based on story IDs
/// This allows adding book content without dealing with JSON files
class StoryContent {
  /// Get the full story content by story ID
  static String? getContentById(String storyId) => _storyContent[storyId];

  /// Get story pages (if content is structured in pages)
  static List<String>? getPagesById(String storyId) {
    // First check if we have pre-defined pages
    final predefinedPages = _storyPages[storyId];
    if (predefinedPages != null) return predefinedPages;

    // Otherwise, split content by double newlines to create pages
    final content = _storyContent[storyId];
    if (content == null) return null;

    return content
        .split('\n\n')
        .where((page) => page.trim().isNotEmpty)
        .toList();
  }

  /// Check if story content exists
  static bool hasContent(String storyId) => _storyContent.containsKey(storyId);

  /// Get all available story IDs with content
  static List<String> getAvailableStoryIds() => _storyContent.keys.toList();
}

/// Story content mapping - Add your book content here
/// Key: Story ID, Value: Full story text
const Map<String, String> _storyContent = {
  // Example story content - replace with your actual stories
  'story_1':
      '''Once upon a time, in a small village, there lived a kind little girl named Maria.

Maria loved to help her mother in the garden every morning. She would water the plants and pick the ripe vegetables.

One day, Maria found a tiny seed that sparkled like a diamond. She planted it carefully in the soft soil.

The next morning, a magical tree had grown overnight! Its leaves shimmered in the sunlight, and its fruits were golden and sweet.

Maria shared the magical fruits with everyone in the village, and they all lived happily ever after.''',

  'story_2':
      '''In the deep blue ocean, there lived a curious little fish named Bubbles.

Bubbles loved to explore the coral reef and make friends with all the sea creatures.

One day, while swimming near the surface, Bubbles saw something amazing - a beautiful rainbow reflected in the water.

"I want to find where the rainbow ends!" thought Bubbles excitedly.

So Bubbles swam and swam, following the colorful reflection through the ocean waves.

Finally, Bubbles discovered that the most beautiful thing was not at the end of the rainbow, but the journey itself and all the friends made along the way.''',

  // Add content for stories that might exist in your database
  // The Ant and the Grasshopper - Classic fable
  'the-ant-and-grasshopper':
      '''In a field one summer's day a Grasshopper was hopping about, chirping and singing to its heart's content.

An Ant passed by, bearing along with great toil an ear of corn he was taking to the nest.

"Why not come and chat with me," said the Grasshopper, "instead of toiling and moiling in that way?"

"I am helping to lay up food for the winter," said the Ant, "and recommend you to do the same."

"Why bother about winter?" said the Grasshopper. "We have got plenty of food at present."

But the Ant went on its way and continued its toil.

When the winter came the Grasshopper had no food and found itself dying of hunger.

Meanwhile it saw the ants distributing corn and grain from the stores they had collected in the summer.

Then the Grasshopper knew: It is best to prepare for days of need.''',

  // Sample Tagalog story - Alamat ng Saging
  'alamat-ng-saging':
      '''Noong unang panahon, may isang matandang lalaki na nakatira sa isang maliit na baryo.

Ang matandang lalaki ay may isang anak na babae na napakaganda at mabait na nagngangalang Maria.

Isang araw, dumating sa kanilang baryo ang isang mahiwagang fairy na nakasuot ng puting damit.

Sinabi ng fairy kay Maria: "Bibigyan kita ng isang mahiwagang binhi. Itanim mo ito at mag-aabang ka ng himala."

Tinanggap ni Maria ang binhi at itinago ito sa kanyang bulsa nang mabuti.

Kinabukasan, nagtanim si Maria ng binhi sa likod ng kanilang bahay at inalagaan ito araw-araw.

Pagkaraan ng ilang linggo, lumaki ang binhi at naging isang puno ng saging na puno ng masasarap na prutas.

Nang makita ng mga tao sa baryo ang puno ng saging, nagalak silang lahat at nagpasalamat kay Maria.

Mula noon, ang saging ay naging pagkaing pangunahin ng mga tao sa baryo.

At yan ang kwento kung paano nagsimula ang alamat ng saging.''',

  // Add more stories here using their actual IDs from your database
  // You can get the story IDs from your Supabase database or dashboard
};

/// Sample pages structure (alternative to splitting by double newlines)
/// You can use this if you want more control over page breaks
const Map<String, List<String>> _storyPages = {
  'story_1': [
    'Once upon a time, in a small village, there lived a kind little girl named Maria.',
    'Maria loved to help her mother in the garden every morning. She would water the plants and pick the ripe vegetables.',
    'One day, Maria found a tiny seed that sparkled like a diamond. She planted it carefully in the soft soil.',
    'The next morning, a magical tree had grown overnight! Its leaves shimmered in the sunlight, and its fruits were golden and sweet.',
    'Maria shared the magical fruits with everyone in the village, and they all lived happily ever after.',
  ],

  // Add more paginated stories here
};
