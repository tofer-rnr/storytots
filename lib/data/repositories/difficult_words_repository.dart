import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DifficultWord {
  final String word;
  final int count;
  final DateTime lastSeen;

  DifficultWord({
    required this.word,
    required this.count,
    required this.lastSeen,
  });
}

/// Local-first store for tracking words the child struggled with during reading.
/// Namespaced per user via userId to keep parent reports accurate per account.
class DifficultWordsRepository {
  String _keyFor(String userId) =>
      'difficult_words:${userId.isEmpty ? 'guest' : userId}';
  String _storyKey(String userId, String storyId) =>
      'difficult_by_story:${userId.isEmpty ? 'guest' : userId}:$storyId';
  final _db = Supabase.instance.client;

  Future<void> addWord({required String word, String userId = ''}) async {
    if (word.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(userId);
    final raw = prefs.getString(key);
    Map<String, dynamic> m = {};
    if (raw != null) {
      try {
        m = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    final now = DateTime.now().toIso8601String();
    final entry =
        (m[word] as Map<String, dynamic>?) ?? {'count': 0, 'lastSeen': now};
    final next = (entry['count'] as num?)?.toInt() ?? 0;
    m[word] = {'count': next + 1, 'lastSeen': now};
    await prefs.setString(key, json.encode(m));
  }

  // New: track by specific story
  Future<void> addWordForStory({
    required String word,
    required String storyId,
    String userId = '',
  }) async {
    if (word.trim().isEmpty || storyId.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _storyKey(userId, storyId);
    final raw = prefs.getString(key);
    Map<String, dynamic> m = {};
    if (raw != null) {
      try {
        m = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    final now = DateTime.now().toIso8601String();
    final entry =
        (m[word] as Map<String, dynamic>?) ?? {'count': 0, 'lastSeen': now};
    final next = (entry['count'] as num?)?.toInt() ?? 0;
    m[word] = {'count': next + 1, 'lastSeen': now};
    await prefs.setString(key, json.encode(m));
  }

  Future<List<DifficultWord>> topWords({
    String userId = '',
    int limit = 30,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userId));
    if (raw == null) return [];
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      final list = m.entries.map((e) {
        final v = e.value as Map<String, dynamic>;
        final c = (v['count'] as num?)?.toInt() ?? 0;
        final ls =
            DateTime.tryParse((v['lastSeen'] as String?) ?? '') ??
            DateTime.now();
        return DifficultWord(word: e.key, count: c, lastSeen: ls);
      }).toList();
      list.sort((a, b) => b.count.compareTo(a.count));
      if (list.length > limit) return list.sublist(0, limit);
      return list;
    } catch (_) {
      return [];
    }
  }

  // New: local top words for a story
  Future<List<DifficultWord>> topWordsForStory({
    required String storyId,
    String userId = '',
    int limit = 30,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storyKey(userId, storyId));
    if (raw == null) return [];
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      final list = m.entries.map((e) {
        final v = e.value as Map<String, dynamic>;
        final c = (v['count'] as num?)?.toInt() ?? 0;
        final ls =
            DateTime.tryParse((v['lastSeen'] as String?) ?? '') ??
            DateTime.now();
        return DifficultWord(word: e.key, count: c, lastSeen: ls);
      }).toList();
      list.sort((a, b) => b.count.compareTo(a.count));
      if (list.length > limit) return list.sublist(0, limit);
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> clearAll({String userId = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(userId));
  }

  // --- Supabase sync -------------------------------------------------------
  static const _table =
      'difficult_words'; // Columns: user_id uuid, word text, count int, last_seen timestamptz
  static const _tableByStory =
      'difficult_words_by_story'; // Columns: user_id uuid, story_id text, word text, count int, last_seen timestamptz

  /// Attempt to push local difficult words to Supabase and merge counts.
  /// Safe to call repeatedly; will fetch existing row per word and sum counts, and set last_seen to max.
  Future<void> flushToServer({required String userId}) async {
    if (userId.isEmpty) return; // skip anonymous
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userId));
    if (raw == null) return;
    Map<String, dynamic> local;
    try {
      local = json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    for (final entry in local.entries) {
      final word = entry.key;
      final v = (entry.value as Map<String, dynamic>?);
      if (v == null) continue;
      final lCount = (v['count'] as num?)?.toInt() ?? 0;
      final lLast =
          DateTime.tryParse((v['lastSeen'] as String?) ?? '') ?? DateTime.now();
      try {
        // Fetch existing row (if any)
        final row = await _db
            .from(_table)
            .select('count, last_seen')
            .eq('user_id', userId)
            .eq('word', word)
            .maybeSingle();

        int newCount = lCount;
        DateTime newLast = lLast;
        if (row != null) {
          final sCount = (row['count'] as num?)?.toInt() ?? 0;
          final sLast =
              DateTime.tryParse((row['last_seen'] as String?) ?? '') ?? lLast;
          newCount = sCount + lCount;
          newLast = sLast.isAfter(lLast) ? sLast : lLast;
        }

        await _db.from(_table).upsert({
          'user_id': userId,
          'word': word,
          'count': newCount,
          'last_seen': newLast.toIso8601String(),
        }, onConflict: 'user_id,word');
      } catch (_) {
        // swallow and continue other words
      }
    }
  }

  /// Push per-story difficult words to Supabase table difficult_words_by_story (optional if table exists).
  Future<void> flushToServerByStory({
    required String userId,
    required String storyId,
  }) async {
    if (userId.isEmpty || storyId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storyKey(userId, storyId));
    if (raw == null) return;
    Map<String, dynamic> local;
    try {
      local = json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    for (final entry in local.entries) {
      final word = entry.key;
      final v = (entry.value as Map<String, dynamic>?);
      if (v == null) continue;
      final lCount = (v['count'] as num?)?.toInt() ?? 0;
      final lLast =
          DateTime.tryParse((v['lastSeen'] as String?) ?? '') ?? DateTime.now();
      try {
        final row = await _db
            .from(_tableByStory)
            .select('count, last_seen')
            .eq('user_id', userId)
            .eq('story_id', storyId)
            .eq('word', word)
            .maybeSingle();

        int newCount = lCount;
        DateTime newLast = lLast;
        if (row != null) {
          final sCount = (row['count'] as num?)?.toInt() ?? 0;
          final sLast =
              DateTime.tryParse((row['last_seen'] as String?) ?? '') ?? lLast;
          newCount = sCount + lCount;
          newLast = sLast.isAfter(lLast) ? sLast : lLast;
        }

        await _db.from(_tableByStory).upsert({
          'user_id': userId,
          'story_id': storyId,
          'word': word,
          'count': newCount,
          'last_seen': newLast.toIso8601String(),
        }, onConflict: 'user_id,story_id,word');
      } catch (_) {}
    }
  }

  /// Try to read top words from Supabase first, falling back to local.
  Future<List<DifficultWord>> topWordsDbFirst({
    required String userId,
    int limit = 30,
  }) async {
    if (userId.isNotEmpty) {
      try {
        final rows = await _db
            .from(_table)
            .select('word, count, last_seen')
            .eq('user_id', userId)
            .order('count', ascending: false)
            .limit(limit);
        final list = (rows as List?) ?? const [];
        if (list.isNotEmpty) {
          return list.map((e) {
            final m = (e as Map).cast<String, dynamic>();
            return DifficultWord(
              word: (m['word'] as String?) ?? '',
              count: (m['count'] as num?)?.toInt() ?? 0,
              lastSeen:
                  DateTime.tryParse((m['last_seen'] as String?) ?? '') ??
                  DateTime.now(),
            );
          }).toList();
        }
      } catch (_) {}
    }
    // fallback to local
    return topWords(userId: userId, limit: limit);
  }

  /// DB-first per-story words, fallback to local per-story
  Future<List<DifficultWord>> topWordsForStoryDbFirst({
    required String userId,
    required String storyId,
    int limit = 30,
  }) async {
    if (userId.isNotEmpty) {
      try {
        final rows = await _db
            .from(_tableByStory)
            .select('word, count, last_seen')
            .eq('user_id', userId)
            .eq('story_id', storyId)
            .order('count', ascending: false)
            .limit(limit);
        final list = (rows as List?) ?? const [];
        if (list.isNotEmpty) {
          return list.map((e) {
            final m = (e as Map).cast<String, dynamic>();
            return DifficultWord(
              word: (m['word'] as String?) ?? '',
              count: (m['count'] as num?)?.toInt() ?? 0,
              lastSeen:
                  DateTime.tryParse((m['last_seen'] as String?) ?? '') ??
                  DateTime.now(),
            );
          }).toList();
        }
      } catch (_) {}
    }
    return topWordsForStory(storyId: storyId, userId: userId, limit: limit);
  }
}
