import 'package:supabase_flutter/supabase_flutter.dart';

class LibraryEntry {
  final String storyId;
  final String? storyTitle;
  final String? coverUrl;
  final bool isFavorite;
  final DateTime? lastOpened;

  LibraryEntry({
    required this.storyId,
    this.storyTitle,
    this.coverUrl,
    required this.isFavorite,
    this.lastOpened,
  });

  factory LibraryEntry.fromMap(Map<String, dynamic> m) => LibraryEntry(
        storyId: m['story_id'] as String,
        storyTitle: m['story_title'] as String?,
        coverUrl: m['cover_url'] as String?,
        isFavorite: (m['is_favorite'] as bool?) ?? false,
        lastOpened:
            m['last_opened'] != null ? DateTime.parse(m['last_opened'] as String) : null,
      );
}

class LibraryRepository {
  final _db = Supabase.instance.client;
  static const _table = 'library';

  Future<void> recordOpen({
    required String storyId,
    required String title,
    String? coverUrl,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;

    // Upsert the row and bump last_opened
    await _db.from(_table).upsert({
      'user_id': uid,
      'story_id': storyId,
      'story_title': title,
      'cover_url': coverUrl,
      'last_opened': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,story_id');
  }

  Future<void> ensureRow({
    required String storyId,
    required String title,
    String? coverUrl,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from(_table).upsert({
      'user_id': uid,
      'story_id': storyId,
      'story_title': title,
      'cover_url': coverUrl,
      'is_favorite': false,
    }, onConflict: 'user_id,story_id');
  }

  Future<LibraryEntry?> getByStoryId(String storyId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final rows = await _db
        .from(_table)
        .select()
        .eq('user_id', uid)
        .eq('story_id', storyId)
        .limit(1);
    if (rows is List && rows.isNotEmpty) {
      return LibraryEntry.fromMap(rows.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> toggleFavorite(String storyId, bool makeFavorite) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db
        .from(_table)
        .update({'is_favorite': makeFavorite})
        .eq('user_id', uid)
        .eq('story_id', storyId);
  }

  Future<List<LibraryEntry>> listAll() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _db
        .from(_table)
        .select()
        .eq('user_id', uid)
        .order('story_title', ascending: true);
    return (rows as List).map((m) => LibraryEntry.fromMap(m)).toList();
  }

  Future<List<LibraryEntry>> listFavorites() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _db
        .from(_table)
        .select()
        .eq('user_id', uid)
        .eq('is_favorite', true)
        .order('story_title', ascending: true);
    return (rows as List).map((m) => LibraryEntry.fromMap(m)).toList();
  }

  Future<List<LibraryEntry>> listHistory() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _db
        .from(_table)
        .select()
        .eq('user_id', uid)
        .order('last_opened', ascending: false);
    return (rows as List).map((m) => LibraryEntry.fromMap(m)).toList();
  }
}
