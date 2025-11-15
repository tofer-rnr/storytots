import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssessmentProgress {
  final String storyId;
  final int currentIndex; // 0-based
  final int score;
  final List<int?> selectedIndices; // per question selected option index
  final DateTime updatedAt;

  AssessmentProgress({
    required this.storyId,
    required this.currentIndex,
    required this.score,
    required this.selectedIndices,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'currentIndex': currentIndex,
        'score': score,
        'selectedIndices': selectedIndices,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static AssessmentProgress? fromJson(dynamic json) {
    if (json is String) {
      try {
        json = jsonDecode(json);
      } catch (_) {
        return null;
      }
    }
    if (json is! Map<String, dynamic>) return null;
    return AssessmentProgress(
      storyId: json['storyId'] as String,
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      selectedIndices: ((json['selectedIndices'] as List?) ?? const [])
          .map((e) => e == null ? null : (e as num).toInt())
          .toList(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class AssessmentProgressRepository {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();
  final supa = Supabase.instance.client;

  String _key(String storyId) => 'assessments:progress:$storyId';

  Future<AssessmentProgress?> getProgress(String storyId) async {
    // Local
    final p = await _prefs;
    final rawLocal = p.getString(_key(storyId));
    final local = rawLocal == null ? null : AssessmentProgress.fromJson(rawLocal);

    // Server (DB-first when signed-in)
    AssessmentProgress? remote;
    final user = supa.auth.currentUser;
    if (user != null) {
      try {
        final row = await supa
            .from('assessment_progress')
            .select('story_id,current_index,score,selected_indices,updated_at')
            .eq('user_id', user.id)
            .eq('story_id', storyId)
            .maybeSingle();
        if (row != null) {
          remote = AssessmentProgress(
            storyId: (row['story_id'] as String?) ?? storyId,
            currentIndex: (row['current_index'] as num?)?.toInt() ?? 0,
            score: (row['score'] as num?)?.toInt() ?? 0,
            selectedIndices: ((row['selected_indices'] as List?) ?? const [])
                .map((e) => e == null ? null : (e as num).toInt())
                .toList(),
            updatedAt: DateTime.tryParse(row['updated_at'] ?? '') ?? DateTime.now(),
          );
        }
      } catch (_) {}
    }

    // Choose the newest
    final chosen = _newerOf(local, remote);

    // Keep local in sync with remote/newer
    if (chosen != null) {
      await p.setString(_key(storyId), jsonEncode(chosen.toJson()));
    }
    return chosen;
  }

  Future<void> saveProgress(AssessmentProgress progress) async {
    // Local first
    final p = await _prefs;
    await p.setString(_key(progress.storyId), jsonEncode(progress.toJson()));

    // Remote best-effort
    final user = supa.auth.currentUser;
    if (user != null) {
      try {
        await supa.from('assessment_progress').upsert({
          'user_id': user.id,
          'story_id': progress.storyId,
          'current_index': progress.currentIndex,
          'score': progress.score,
          'selected_indices': progress.selectedIndices,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,story_id');
      } catch (_) {}
    }
  }

  Future<void> clear(String storyId) async {
    final p = await _prefs;
    await p.remove(_key(storyId));

    final user = supa.auth.currentUser;
    if (user != null) {
      try {
        await supa
            .from('assessment_progress')
            .delete()
            .eq('user_id', user.id)
            .eq('story_id', storyId);
      } catch (_) {}
    }
  }

  AssessmentProgress? _newerOf(AssessmentProgress? a, AssessmentProgress? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.updatedAt.isAfter(b.updatedAt) ? a : b;
  }
}
