// Simple index for local story assets (English and Tagalog)
class StoryIndexItem {
  final String slug;
  final String title;
  final String language; // 'en' or 'tl'
  final int pageCount; // currently 1 per story
  final String synopsisPath;
  final String page1Path;
  final String? coverAsset; // optional

  const StoryIndexItem({
    required this.slug,
    required this.title,
    required this.language,
    required this.pageCount,
    required this.synopsisPath,
    required this.page1Path,
    this.coverAsset,
  });
}

class StoriesIndex {
  static const List<StoryIndexItem> items = [
    StoryIndexItem(
      slug: 'the-monkey-and-the-turtle',
      title: 'The Monkey and the Turtle',
      language: 'en',
      pageCount: 1,
      synopsisPath: 'assets/stories/the-monkey-and-the-turtle/en/synopsis.txt',
      page1Path: 'assets/stories/the-monkey-and-the-turtle/en/pages/001.txt',
      coverAsset: 'assets/images/covers/The_Monkey_and_the_Turtle.png',
    ),
    StoryIndexItem(
      slug: 'the-monkey-and-the-turtle',
      title: 'Ang Unggoy at ang Pagong',
      language: 'tl',
      pageCount: 1,
      synopsisPath: 'assets/stories/the-monkey-and-the-turtle/tl/synopsis.txt',
      page1Path: 'assets/stories/the-monkey-and-the-turtle/tl/pages/001.txt',
      coverAsset: 'assets/images/covers/The_Monkey_and_the_Turtle.png',
    ),
    StoryIndexItem(
      slug: 'alamat-ng-saging',
      title: 'Alamat ng Saging (Legend of the Banana)',
      language: 'tl',
      pageCount: 1,
      synopsisPath: 'assets/stories/alamat-ng-saging/tl/synopsis.txt',
      page1Path: 'assets/stories/alamat-ng-saging/tl/pages/001.txt',
      coverAsset: 'assets/images/covers/Alamat_ng_Saging.jpg',
    ),
    StoryIndexItem(
      slug: 'alamat-ng-saging',
      title: 'Legend of the Banana',
      language: 'en',
      pageCount: 1,
      synopsisPath: 'assets/stories/alamat-ng-saging/en/synopsis.txt',
      page1Path: 'assets/stories/alamat-ng-saging/en/pages/001.txt',
      coverAsset: 'assets/images/covers/Alamat_ng_Saging.jpg',
    ),
    StoryIndexItem(
      slug: 'alamat-ng-sampaguita',
      title: 'Alamat ng Sampaguita (Legend of the Sampaguita)',
      language: 'tl',
      pageCount: 1,
      synopsisPath: 'assets/stories/alamat-ng-sampaguita/tl/synopsis.txt',
      page1Path: 'assets/stories/alamat-ng-sampaguita/tl/pages/001.txt',
      coverAsset: 'assets/images/covers/Alamat_ng_Sampaguita.jpg',
    ),
    StoryIndexItem(
      slug: 'alamat-ng-sampaguita',
      title: 'Legend of the Sampaguita',
      language: 'en',
      pageCount: 1,
      synopsisPath: 'assets/stories/alamat-ng-sampaguita/en/synopsis.txt',
      page1Path: 'assets/stories/alamat-ng-sampaguita/en/pages/001.txt',
      coverAsset: 'assets/images/covers/Alamat_ng_Sampaguita.jpg',
    ),
  ];
}
