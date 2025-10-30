import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Progress {
  final String userId;
  final String storyId;
  final String? pageId;
  final int sentenceIndex;
  final bool isCompleted;
  final DateTime updatedAt;
  final Map<String, dynamic>? meta;

  Progress({
    required this.userId,
    required this.storyId,
    this.pageId,
    required this.sentenceIndex,
    required this.isCompleted,
    required this.updatedAt,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'story_id': storyId,
    'page_id': pageId,
    'sentence_index': sentenceIndex,
    'is_completed': isCompleted,
    'updated_at': updatedAt.toIso8601String(),
    'meta': meta,
  };

  factory Progress.fromJson(Map<String, dynamic> m) => Progress(
    userId: m['user_id'] as String,
    storyId: m['story_id'] as String,
    pageId: m['page_id'] as String?,
    sentenceIndex: (m['sentence_index'] as num).toInt(),
    isCompleted: m['is_completed'] as bool,
    updatedAt: DateTime.parse(m['updated_at'] as String),
    meta: (m['meta'] as Map?)?.cast<String, dynamic>(),
  );
}

class ProgressRepository {
  final supa = Supabase.instance.client;
  static const _progressKeyPrefix = 'progress:';
  static const _pendingQueueKey = 'pending_progress_queue';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _localKey(String userId, String storyId, String? pageId) {
    final pid = pageId ?? '';
    return '$_progressKeyPrefix$userId:$storyId:$pid';
  }

  Future<Progress?> getLocalProgress(String storyId, {String? pageId}) async {
    final user = supa.auth.currentUser;
    if (user == null) return null;
    final prefs = await _prefs;
    final key = _localKey(user.id, storyId, pageId);
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;
    try {
      final m = json.decode(jsonStr) as Map<String, dynamic>;
      return Progress.fromJson(m);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLocalProgress(Progress p) async {
    final prefs = await _prefs;
    final key = _localKey(p.userId, p.storyId, p.pageId);
    await prefs.setString(key, json.encode(p.toJson()));
  }

  Future<List<Map<String, dynamic>>> _readPendingQueue() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_pendingQueueKey);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List;
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writePendingQueue(List<Map<String, dynamic>> q) async {
    final prefs = await _prefs;
    await prefs.setString(_pendingQueueKey, json.encode(q));
  }

  Future<void> enqueueForSync(Progress p) async {
    final q = await _readPendingQueue();
    q.add(p.toJson());
    await _writePendingQueue(q);
  }

  Future<void> flushPendingProgress() async {
    final user = supa.auth.currentUser;
    if (user == null) return;

    final q = await _readPendingQueue();
    if (q.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];

    for (final item in q) {
      try {
        // Only attempt to sync items that belong to the currently logged-in user.
        final itemUserId = item['user_id'] as String?;
        if (itemUserId != user.id) {
          // Keep other users' items in the queue.
          remaining.add(item);
          continue;
        }

        await supa
            .from('reading_progress')
            .upsert(item, onConflict: 'user_id,story_id,page_id');
      } catch (e) {
        // keep remaining to retry later
        remaining.add(item);
      }
    }

    await _writePendingQueue(remaining);
  }

  Future<Progress?> fetchServerProgress(
    String storyId, {
    String? pageId,
  }) async {
    final user = supa.auth.currentUser;
    if (user == null) return null;

    // Query rows for this user/story, filter pageId in Dart to avoid passing nullable to .eq()
    final rowsRaw = await supa
        .from('reading_progress')
        .select('*')
        .eq('user_id', user.id)
        .eq('story_id', storyId);

    final rowsList = (rowsRaw as List?) ?? const [];
    if (rowsList.isEmpty) return null;

    Map<String, dynamic>? matched;
    for (final r in rowsList) {
      final map = (r as Map).cast<String, dynamic>();
      final pid = map['page_id'] as String?;
      if (pid == pageId) {
        matched = map;
        break;
      }
    }

    if (matched == null) return null;
    return Progress.fromJson(matched);
  }

  Future<void> upsertServerProgress(Progress p) async {
    await supa
        .from('reading_progress')
        .upsert(p.toJson(), onConflict: 'user_id,story_id,page_id');
  }
}
