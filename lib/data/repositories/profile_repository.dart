import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/client.dart';
import '../supabase/tables/profile.dart';

class ProfileRepository {
  static const _table = 'profiles';
  final SupabaseClient _db = supa;

  Future<Profile?> getMyProfile() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;

    final res = await _db
        .from(_table)
        .select()
        .eq('id', uid) // <-- use id
        .maybeSingle();

    if (res == null) return null;
    return Profile.fromMap(res);
  }

  Future<void> ensureRowExists({
    String? email,
    String? first,
    String? last,
    DateTime? birth,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;

    final existing = await _db
        .from(_table)
        .select('id')
        .eq('id', uid) // <-- id
        .maybeSingle();

    if (existing == null) {
      final birthStr = birth != null
          ? birth.toIso8601String().split('T').first
          : null;
      await _db.from(_table).insert({
        'id': uid,
        'email': email ?? _db.auth.currentUser?.email,
        'first_name': first,
        'last_name': last,
        'birth_date': birthStr,
      });
    }
  }

  Future<void> updateInterests(List<String> topics) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from(_table).update({'interests': topics}).eq('id', uid);
  }

  Future<void> updateGoal(String goal) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from(_table).update({'goal': goal}).eq('id', uid);
  }

  Future<void> updateAvatar(String avatarKey) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from(_table).update({'avatar_key': avatarKey}).eq('id', uid);
  }

  // New: update birth date (used for editing age)
  Future<void> updateBirthDate(DateTime birth) async {
    final uid = _db.auth.currentUser!.id;
    final iso = birth.toIso8601String().split('T').first; // YYYY-MM-DD
    await _db.from(_table).update({'birth_date': iso}).eq('id', uid);
  }

  Future<void> setOnboardingComplete(bool value) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from(_table).update({'onboarding_complete': value}).eq('id', uid);
  }

  Future<Map<String, dynamic>?> getMyProfileRaw() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;

    return await _db
        .from(_table)
        .select(
          'id, email, first_name, last_name, birth_date, goal, interests, avatar_key, onboarding_complete',
        )
        .eq('id', uid)
        .maybeSingle();
  }
}
