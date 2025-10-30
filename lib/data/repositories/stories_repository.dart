import 'package:supabase_flutter/supabase_flutter.dart';

class Story {
  final String id;
  final String title;
  final String language;
  final List<String> topics;
  final String? readingAge;

  // details (optional)
  final String? coverUrl;
  final String? synopsis;
  final String? writtenBy;
  final String? illustratedBy;
  final String? publishedBy;

  Story({
    required this.id,
    required this.title,
    required this.language,
    required this.topics,
    this.readingAge,
    this.coverUrl,
    this.synopsis,
    this.writtenBy,
    this.illustratedBy,
    this.publishedBy,
  });

  factory Story.fromMap(Map<String, dynamic> m) {
    return Story(
      id: m['id'] as String,
      title: (m['title'] ?? '') as String,
      language: (m['language'] ?? 'en') as String,
      topics: (m['topics'] as List?)?.whereType<String>().toList() ?? const [],
      readingAge: m['reading_age'] as String?,
      coverUrl: m['cover_url'] as String?,
      synopsis: m['synopsis'] as String?,
      writtenBy: m['written_by'] as String?,
      illustratedBy: m['illustrated_by'] as String?,
      publishedBy: m['published_by'] as String?,
    );
  }

  factory Story.fromJson(Map<String, dynamic> json) => Story.fromMap(json);
}

class StoriesRepository {
  final supa = Supabase.instance.client;

  Future<List<Story>> listByTopic(String topic, {int limit = 6}) async {
    final rows = await supa
        .from('stories')
        .select('*')
        .contains('topics', [topic]) // text[] contains "topic"
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (rows as List?) ?? const [];
    return list.map((e) => Story.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Story?> getById(String id) async {
    final row = await supa
        .from('stories')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return Story.fromMap(row);
  }

  /// Returns stories the user has opened, oldest -> newest (FIFO).
  /// Requires a FK reading_history.story_id -> stories.id in your DB.
  ///
  /// reading_history fields expected:
  /// - user_id (uuid)
  /// - story_id (uuid/text)
  /// - last_read_at (timestamp)
  Future<List<Story>> listReadingHistory({int limit = 6}) async {
    final user = supa.auth.currentUser;
    if (user == null) return [];

    // If FK is set, Supabase can join via select('story:stories(*)')
    final rows = await supa
        .from('reading_history')
        .select('story:stories(*), last_read_at')
        .eq('user_id', user.id)
        .order('last_read_at', ascending: true) // FIFO
        .limit(limit);

    final list = (rows as List?) ?? const [];
    return list
        .map((row) => (row as Map<String, dynamic>)['story'])
        .where((s) => s != null)
        .map<Story>((s) => Story.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  /// Optional helper to upsert progress whenever a story is opened.
  Future<void> touchReadingHistory(String storyId) async {
    final user = supa.auth.currentUser;
    if (user == null) return;
    await supa.from('reading_history').upsert({
      'user_id': user.id,
      'story_id': storyId,
      'last_read_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,story_id');
  }

  Future<List<Story>> listByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await supa
        .from('stories')
        .select('*')
        .filter('id', 'in', '(${ids.map((e) => '"$e"').join(',')})');
    final list = (rows as List?) ?? const [];
    return list.map((e) => Story.fromMap(e as Map<String, dynamic>)).toList();
  }
}
