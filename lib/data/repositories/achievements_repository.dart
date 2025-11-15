import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storytots/data/services/profile_stats_service.dart';
import 'package:storytots/data/repositories/reading_activity_repository.dart';

class Badge {
  final String id;
  final String title;
  final String description;
  final String iconAsset; // colorful asset suited for kids
  final int points; // reward points to show progress

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.points,
  });
}

class EarnedBadge {
  final String id;
  final DateTime earnedAt;
  const EarnedBadge({required this.id, required this.earnedAt});
}

class AchievementsRepository {
  static const _keyPrefix = 'badges:'; // badges:<userId>
  static const _customKeyPrefix = 'badges:custom:'; // badges:custom:<userId>
  final _db = Supabase.instance.client;

  // Core set of engaging badges
  static const List<Badge> all = [
    Badge(
      id: 'first_read',
      title: 'First Read!',
      description: 'Finish your first story',
      iconAsset: 'assets/images/icon.png',
      points: 10,
    ),
    Badge(
      id: 'streak_3',
      title: '3-Day Streak',
      description: 'Read on 3 days in a row',
      iconAsset: 'assets/images/icon1.png',
      points: 15,
    ),
    Badge(
      id: 'streak_7',
      title: '7-Day Streak',
      description: 'Read on 7 days in a row',
      iconAsset: 'assets/images/icon2.png',
      points: 30,
    ),
    Badge(
      id: 'minute_master_60',
      title: 'Minute Master',
      description: 'Read 60 minutes total',
      iconAsset: 'assets/images/icon1.png',
      points: 20,
    ),
    Badge(
      id: 'speed_reader_100',
      title: 'Speed Reader',
      description: 'Reach 100 WPM today',
      iconAsset: 'assets/images/icon2.png',
      points: 20,
    ),
    Badge(
      id: 'word_warrior_5',
      title: 'Word Warrior',
      description: 'Practice 5 tricky words',
      iconAsset: 'assets/images/icon.png',
      points: 10,
    ),
    // New: Awarded when a quiz score is >= 80%
    Badge(
      id: 'quiz_ace_80',
      title: 'Quiz Ace',
      description: 'Score 80%+ on an assessment',
      iconAsset: 'assets/images/icon.png',
      points: 25,
    ),
  ];

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _keyFor(String userId) => '${_keyPrefix}${userId.isEmpty ? 'guest' : userId}';
  String _customKeyFor(String userId) => '${_customKeyPrefix}${userId.isEmpty ? 'guest' : userId}';

  Future<Set<String>> _loadEarnedIds(String userId) async {
    final p = await _prefs;
    final raw = p.getString(_keyFor(userId));
    if (raw == null) return {};
    try {
      final list = (json.decode(raw) as List).whereType<String>().toList();
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveEarnedIds(String userId, Set<String> ids) async {
    final p = await _prefs;
    await p.setString(_keyFor(userId), json.encode(ids.toList()));
  }

  // --- Custom (per-story) badges -----------------------------------------
  Future<List<Badge>> _loadCustomBadges(String userId) async {
    final p = await _prefs;
    final raw = p.getString(_customKeyFor(userId));
    if (raw == null) return [];
    try {
      final list = (json.decode(raw) as List?) ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((m) => Badge(
                id: m['id'] as String,
                title: m['title'] as String,
                description: (m['description'] as String?) ?? '',
                iconAsset: (m['iconAsset'] as String?) ?? 'assets/images/icon.png',
                points: (m['points'] as num?)?.toInt() ?? 15,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCustomBadges(String userId, List<Badge> list) async {
    final p = await _prefs;
    await p.setString(
      _customKeyFor(userId),
      json.encode(list
          .map((b) => {
                'id': b.id,
                'title': b.title,
                'description': b.description,
                'iconAsset': b.iconAsset,
                'points': b.points,
              })
          .toList()),
    );
  }

  Future<void> awardStoryQuizBadge({required String userId, required String storyId, required String storyTitle}) async {
    final custom = await _loadCustomBadges(userId);
    final id = 'quiz_story_$storyId';
    if (custom.any((b) => b.id == id)) return;
    // Choose a colorful icon deterministically for variety
    final icons = ['assets/images/icon.png', 'assets/images/icon1.png', 'assets/images/icon2.png'];
    final idx = storyId.isEmpty ? storyTitle.length : (storyId.codeUnits.fold<int>(0, (a, c) => (a + c) % icons.length));
    final badge = Badge(
      id: id,
      title: 'Quiz: ${storyTitle.trim().isEmpty ? 'Story' : storyTitle}',
      description: 'Completed the quiz for ${storyTitle.isEmpty ? 'a story' : storyTitle}',
      iconAsset: icons[idx % icons.length],
      points: 20,
    );
    custom.add(badge);
    await _saveCustomBadges(userId, custom);
    // Optional server sync
  try {
      await _db.from('user_badges').upsert({
        'user_id': userId,
        'badge_id': id,
        'earned_at': DateTime.now().toIso8601String(),
        'meta': {
          'title': badge.title,
          'description': badge.description,
          'iconAsset': badge.iconAsset,
          'points': badge.points,
        },
      }, onConflict: 'user_id,badge_id');
  } catch (_) {}
  }

  Future<List<Badge>> listEarned(String userId) async {
    final ids = await _loadEarnedIds(userId);
    final statics = all.where((b) => ids.contains(b.id)).toList();
    final custom = await _loadCustomBadges(userId);
    return [...statics, ...custom];
  }

  Future<List<Badge>> listLocked(String userId) async {
    final ids = await _loadEarnedIds(userId);
    return all.where((b) => !ids.contains(b.id)).toList();
  }

  Future<List<Badge>> evaluateAndSave({
    required String userId,
    required ProfileStats stats,
    required LanguageStats today,
    int practicedTrickyWords = 0,
    double? quizScorePct,
  }) async {
    final earned = await _loadEarnedIds(userId);
    final before = Set<String>.from(earned);

    // Rules
    if (stats.storiesCompleted >= 1) earned.add('first_read');
    if (stats.streakDays >= 3) earned.add('streak_3');
    if (stats.streakDays >= 7) earned.add('streak_7');
    if (stats.totalMinutesAllTime >= 60) earned.add('minute_master_60');
    if (today.wpm >= 100) earned.add('speed_reader_100');
    if (practicedTrickyWords >= 5) earned.add('word_warrior_5');
  if ((quizScorePct ?? 0) >= 80) earned.add('quiz_ace_80');

    if (!before.containsAll(earned) || earned.length != before.length) {
      await _saveEarnedIds(userId, earned);
      // Optional: push to Supabase for cross-device
      // await _syncToServer(userId, earned);
    }

    return all.where((b) => earned.contains(b.id)).toList();
  }

  Future<void> addBadge(String userId, String badgeId) async {
    final earned = await _loadEarnedIds(userId);
    if (earned.contains(badgeId)) return;
    earned.add(badgeId);
    await _saveEarnedIds(userId, earned);
    // optional sync
    try {
      await _db.from('user_badges').upsert({
        'user_id': userId,
        'badge_id': badgeId,
        'earned_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,badge_id');
    } catch (_) {}
  }

  // Optional server sync for cross-device badges. Not called by default.
  Future<void> syncToServer(String userId, Set<String> ids) async {
    try {
      await _db.from('user_badges').upsert(
        ids.map((id) => {
              'user_id': userId,
              'badge_id': id,
              'earned_at': DateTime.now().toIso8601String(),
            }).toList(),
        onConflict: 'user_id,badge_id',
      );
    } catch (_) {}
  }
}
