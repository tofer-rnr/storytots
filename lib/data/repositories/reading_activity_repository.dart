import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LanguageStats {
  final int englishMinutes;
  final int filipinoMinutes;
  final int totalMinutes;
  final double activityPercent; // 0..1 against daily goal
  const LanguageStats({
    required this.englishMinutes,
    required this.filipinoMinutes,
    required this.totalMinutes,
    required this.activityPercent,
  });
}

class ReadingActivityRepository {
  final supa = Supabase.instance.client;
  static const _queueKey = 'reading_activity_queue';
  static const _aggPrefix = 'reading_minutes:'; // reading_minutes:YYYY-MM-DD:en
  static const int dailyGoalMinutes = 60; // can be adjusted later

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> addReadingSegment({
    required String lang, // 'en' or 'tl'
    required Duration duration,
    String? storyId,
    DateTime? startedAt,
    DateTime? endedAt,
  }) async {
    // Normalize language
    final language = (lang == 'tl' || lang.toLowerCase() == 'filipino')
        ? 'tl'
        : 'en';
    final seconds = duration.inSeconds;
    if (seconds <= 0) return;

    // Queue for server sync
    final prefs = await _prefs;
    final raw = prefs.getString(_queueKey);
    final list = raw == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(json.decode(raw));

    final now = DateTime.now();
    final item = {
      'user_id': supa.auth.currentUser?.id,
      'story_id': storyId,
      'language': language,
      'duration_sec': seconds,
      'started_at': (startedAt ?? now.subtract(duration)).toIso8601String(),
      'ended_at': (endedAt ?? now).toIso8601String(),
      'day': _dayKey(now),
    };
    list.add(item);
    await prefs.setString(_queueKey, json.encode(list));

    // Update local daily aggregates for quick UI
    final day = _dayKey(now);
    final aggKey = '$_aggPrefix$day:$language';
    final current = prefs.getInt(aggKey) ?? 0;
    await prefs.setInt(aggKey, current + seconds);
  }

  Future<LanguageStats> getTodayLanguageStats() async {
    final prefs = await _prefs;
    final day = _dayKey(DateTime.now());
    final enSec = prefs.getInt('$_aggPrefix$day:en') ?? 0;
    final tlSec = prefs.getInt('$_aggPrefix$day:tl') ?? 0;
    final totalMin = ((enSec + tlSec) / 60).floor();
    final enMin = (enSec / 60).floor();
    final tlMin = (tlSec / 60).floor();

    final pct = ((enMin + tlMin) / dailyGoalMinutes).clamp(0, 1).toDouble();
    return LanguageStats(
      englishMinutes: enMin,
      filipinoMinutes: tlMin,
      totalMinutes: totalMin,
      activityPercent: pct,
    );
  }

  Future<void> flushQueue() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_queueKey);
    if (raw == null) return;

    List list;
    try {
      list = json.decode(raw) as List;
    } catch (_) {
      return;
    }
    if (list.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final e in list) {
      final item = (e as Map).cast<String, dynamic>();
      try {
        // Skip if not current user
        final uid = supa.auth.currentUser?.id;
        if (uid == null || item['user_id'] != uid) {
          remaining.add(item);
          continue;
        }
        // Best-effort insert (table: reading_activity). If table doesn't exist, ignore.
        await supa.from('reading_activity').insert(item);
      } catch (_) {
        remaining.add(item);
      }
    }

    await prefs.setString(_queueKey, json.encode(remaining));
  }
}
