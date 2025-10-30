import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores which stories have an available assessment (completed readings)
class AssessmentRepository {
  static const _completedKey = 'assessments:completed_story_ids';
  static const _table =
      'completed_stories'; // Supabase table: user_id, story_id, completed_at

  final supa = Supabase.instance.client;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // --- Local helpers -------------------------------------------------------
  Future<List<String>> _getLocalIds() async {
    final p = await _prefs;
    final raw = p.getString(_completedKey);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List;
      return list.whereType<String>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _setLocalIds(List<String> ids) async {
    final p = await _prefs;
    await p.setString(_completedKey, json.encode(ids));
  }

  // --- Sync helpers --------------------------------------------------------
  Future<void> _syncLocalToServer() async {
    final user = supa.auth.currentUser;
    if (user == null) return;
    try {
      final local = await _getLocalIds();
      if (local.isEmpty) return;
      for (final id in local) {
        try {
          await supa.from(_table).upsert({
            'user_id': user.id,
            'story_id': id,
            'completed_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,story_id');
        } catch (_) {}
      }
    } catch (_) {}
  }

  // --- Public API ----------------------------------------------------------
  /// DB-first list of completed story IDs for the signed-in user.
  /// Falls back to local storage when offline/not signed-in.
  Future<List<String>> getCompletedStoryIds() async {
    final user = supa.auth.currentUser;
    if (user == null) return _getLocalIds();

    await _syncLocalToServer();

    try {
      final rows = await supa
          .from(_table)
          .select('story_id')
          .eq('user_id', user.id);
      final list = (rows as List?) ?? const [];
      final ids = list
          .map((r) => (r as Map<String, dynamic>)['story_id'])
          .whereType<String>()
          .toList();
      // Keep local in sync with server copy
      await _setLocalIds(ids);
      return ids;
    } catch (_) {
      return _getLocalIds();
    }
  }

  Future<void> addCompletedStory(String storyId) async {
    // Update local first
    final ids = await _getLocalIds();
    if (!ids.contains(storyId)) {
      ids.add(storyId);
      await _setLocalIds(ids);
    }

    // Best-effort server upsert
    final user = supa.auth.currentUser;
    if (user != null) {
      try {
        await supa.from(_table).upsert({
          'user_id': user.id,
          'story_id': storyId,
          'completed_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,story_id');
      } catch (_) {}
    }
  }

  Future<void> removeCompletedStory(String storyId) async {
    final ids = await _getLocalIds();
    ids.remove(storyId);
    await _setLocalIds(ids);

    final user = supa.auth.currentUser;
    if (user != null) {
      try {
        await supa
            .from(_table)
            .delete()
            .eq('user_id', user.id)
            .eq('story_id', storyId);
      } catch (_) {}
    }
  }
}
