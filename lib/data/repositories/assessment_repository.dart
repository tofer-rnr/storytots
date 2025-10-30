import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores which stories have an available assessment (completed readings)
class AssessmentRepository {
  static const _completedKey = 'assessments:completed_story_ids';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<String>> getCompletedStoryIds() async {
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

  Future<void> addCompletedStory(String storyId) async {
    final ids = await getCompletedStoryIds();
    if (ids.contains(storyId)) return;
    ids.add(storyId);
    final p = await _prefs;
    await p.setString(_completedKey, json.encode(ids));
  }

  Future<void> removeCompletedStory(String storyId) async {
    final ids = await getCompletedStoryIds();
    ids.remove(storyId);
    final p = await _prefs;
    await p.setString(_completedKey, json.encode(ids));
  }
}
