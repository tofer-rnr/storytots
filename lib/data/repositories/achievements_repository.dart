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
  ];

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _keyFor(String userId) => '${_keyPrefix}${userId.isEmpty ? 'guest' : userId}';

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

  Future<List<Badge>> listEarned(String userId) async {
    final ids = await _loadEarnedIds(userId);
    return all.where((b) => ids.contains(b.id)).toList();
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

    if (!before.containsAll(earned) || earned.length != before.length) {
      await _saveEarnedIds(userId, earned);
      // Optional: push to Supabase for cross-device
      // await _syncToServer(userId, earned);
    }

    return all.where((b) => earned.contains(b.id)).toList();
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
