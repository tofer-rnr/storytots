import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storytots/data/repositories/assessment_repository.dart';

class DayStat {
  final DateTime date;
  final int totalMinutes;
  final int enMinutes;
  final int tlMinutes;

  DayStat({
    required this.date,
    required this.totalMinutes,
    required this.enMinutes,
    required this.tlMinutes,
  });
}

class ProfileStats {
  final int totalMinutesAllTime;
  final int totalMinutes7d;
  final int enMinutes7d;
  final int tlMinutes7d;
  final int storiesCompleted;
  final int sentencesPracticed;
  final int streakDays;
  final DateTime? lastSessionAt;
  final List<DayStat> weekly; // oldest -> today

  ProfileStats({
    required this.totalMinutesAllTime,
    required this.totalMinutes7d,
    required this.enMinutes7d,
    required this.tlMinutes7d,
    required this.storiesCompleted,
    required this.sentencesPracticed,
    required this.streakDays,
    required this.lastSessionAt,
    required this.weekly,
  });
}

class ProfileStatsService {
  static const String _aggPrefix =
      'reading_minutes:'; // reading_minutes:YYYY-MM-DD:en
  static const String _lastSessionKey = 'reading_last_session_at';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<ProfileStats> getStats() async {
    final prefs = await _prefs;

    // 7-day window (oldest -> today)
    final List<DayStat> weekly = [];
    int sum7d = 0;
    int en7d = 0;
    int tl7d = 0;

    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final key = _dayKey(day);
      final enSec = prefs.getInt('$_aggPrefix$key:en') ?? 0;
      final tlSec = prefs.getInt('$_aggPrefix$key:tl') ?? 0;
      final totalMin = ((enSec + tlSec) / 60).floor();
      final enMin = (enSec / 60).floor();
      final tlMin = (tlSec / 60).floor();
      weekly.add(
        DayStat(
          date: day,
          totalMinutes: totalMin,
          enMinutes: enMin,
          tlMinutes: tlMin,
        ),
      );
      sum7d += totalMin;
      en7d += enMin;
      tl7d += tlMin;
    }

    // All-time scan
    int allSec = 0;
    for (final k in prefs.getKeys()) {
      if (k.startsWith(_aggPrefix)) {
        final v = prefs.getInt(k) ?? 0;
        allSec += v;
      }
    }
    final totalAllTime = (allSec / 60).floor();

    // Stories completed
    final completedIds = await AssessmentRepository().getCompletedStoryIds();
    final completedCount = completedIds.length;

    // Sentences practiced: sum of latest sentenceIndex+1 per story for current user
    final uid = Supabase.instance.client.auth.currentUser?.id;
    int sentencesPracticed = 0;
    if (uid != null) {
      final Map<String, int> maxByStory = {};
      for (final k in prefs.getKeys()) {
        if (k.startsWith('progress:$uid:')) {
          final raw = prefs.getString(k);
          if (raw == null) continue;
          try {
            final m = json.decode(raw) as Map<String, dynamic>;
            final storyId = m['story_id'] as String?;
            final idx = (m['sentence_index'] as num?)?.toInt() ?? 0;
            if (storyId == null) continue;
            final current = maxByStory[storyId] ?? -1;
            if (idx > current) maxByStory[storyId] = idx;
          } catch (_) {}
        }
      }
      for (final v in maxByStory.values) {
        sentencesPracticed += (v + 1);
      }
    }

    // Streak: consecutive days with any minutes from today backwards
    int streak = 0;
    for (int i = 0; ; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      final key = _dayKey(day);
      final enSec = prefs.getInt('$_aggPrefix$key:en') ?? 0;
      final tlSec = prefs.getInt('$_aggPrefix$key:tl') ?? 0;
      if ((enSec + tlSec) > 0) {
        streak++;
      } else {
        break;
      }
    }

    // Last session time
    final lastIso = prefs.getString(_lastSessionKey);
    DateTime? lastSessionAt;
    if (lastIso != null && lastIso.isNotEmpty) {
      lastSessionAt = DateTime.tryParse(lastIso);
    }

    return ProfileStats(
      totalMinutesAllTime: totalAllTime,
      totalMinutes7d: sum7d,
      enMinutes7d: en7d,
      tlMinutes7d: tl7d,
      storiesCompleted: completedCount,
      sentencesPracticed: sentencesPracticed,
      streakDays: streak,
      lastSessionAt: lastSessionAt,
      weekly: weekly,
    );
  }

  Future<ProfileStats> getStatsDbFirst() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;

    if (uid == null) {
      // Fallback to local if not signed in
      return getStats();
    }

    try {
      // 7-day window (today inclusive)
      final today = DateTime.now();
      final start = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(const Duration(days: 6));
      final startStr = _dayKey(start);
      final endStr = _dayKey(today);

      // Fetch last 7 days rows (aggregate client-side)
      final rows = await client
          .from('reading_activity')
          .select('day, language, duration_sec')
          .eq('user_id', uid)
          .gte('day', startStr)
          .lte('day', endStr);

      // Build day -> {enSec, tlSec}
      final Map<String, Map<String, int>> byDay = {};
      for (final r in (rows as List)) {
        final day = (r['day'] as String);
        final lang = (r['language'] as String?)?.toLowerCase() == 'tl'
            ? 'tl'
            : 'en';
        final sec = (r['duration_sec'] as num?)?.toInt() ?? 0;
        byDay.putIfAbsent(day, () => {'en': 0, 'tl': 0});
        byDay[day]![lang] = (byDay[day]![lang] ?? 0) + sec;
      }

      // Compose weekly (oldest -> today)
      final List<DayStat> weekly = [];
      int sum7d = 0, en7d = 0, tl7d = 0;
      for (int i = 6; i >= 0; i--) {
        final d = today.subtract(Duration(days: i));
        final key = _dayKey(d);
        final enSec = byDay[key]?['en'] ?? 0;
        final tlSec = byDay[key]?['tl'] ?? 0;
        final totalMin = ((enSec + tlSec) / 60).floor();
        final enMin = (enSec / 60).floor();
        final tlMin = (tlSec / 60).floor();
        weekly.add(
          DayStat(
            date: d,
            totalMinutes: totalMin,
            enMinutes: enMin,
            tlMinutes: tlMin,
          ),
        );
        sum7d += totalMin;
        en7d += enMin;
        tl7d += tlMin;
      }

      // All-time total minutes (client aggregation)
      final allRows = await client
          .from('reading_activity')
          .select('duration_sec')
          .eq('user_id', uid);
      int allSec = 0;
      for (final r in (allRows as List)) {
        allSec += (r['duration_sec'] as num?)?.toInt() ?? 0;
      }
      final totalAllTime = (allSec / 60).floor();

      // Last session at (max ended_at)
      DateTime? lastSessionAt;
      final last = await client
          .from('reading_activity')
          .select('ended_at')
          .eq('user_id', uid)
          .order('ended_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (last != null && (last['ended_at'] as String?) != null) {
        lastSessionAt = DateTime.tryParse(last['ended_at'] as String);
      }

      // Stories completed and sentences practiced: keep local methods for now
      final completedIds = await AssessmentRepository().getCompletedStoryIds();
      final completedCount = completedIds.length;

      int sentencesPracticed = 0;
      try {
        // Reuse local method to estimate sentences practiced
        final local = await getStats();
        sentencesPracticed = local.sentencesPracticed;
      } catch (_) {}

      return ProfileStats(
        totalMinutesAllTime: totalAllTime,
        totalMinutes7d: sum7d,
        enMinutes7d: en7d,
        tlMinutes7d: tl7d,
        storiesCompleted: completedCount,
        sentencesPracticed: sentencesPracticed,
        streakDays: _computeStreakFromWeekly(weekly),
        lastSessionAt: lastSessionAt,
        weekly: weekly,
      );
    } catch (_) {
      // Fallback to local SharedPreferences if DB fails
      return getStats();
    }
  }

  int _computeStreakFromWeekly(List<DayStat> weekly) {
    int streak = 0;
    for (int i = weekly.length - 1; i >= 0; i--) {
      if (weekly[i].totalMinutes > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
