import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages authentication session caching with daily expiration for security
class AuthCacheRepository {
  static const String _sessionKey = 'auth_session_cache';
  static const String _sessionDateKey = 'auth_session_date';
  static const String _userIdKey = 'auth_user_id';

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Save current session to cache if user is authenticated
  Future<void> cacheCurrentSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split(
      'T',
    )[0]; // YYYY-MM-DD format

    // Cache session data
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    await prefs.setString(_sessionDateKey, today);
    await prefs.setString(_userIdKey, session.user.id);

    print('[AuthCache] Session cached for date: $today');
  }

  /// Check if we have a valid cached session for today
  Future<bool> hasValidCachedSession() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedDate = prefs.getString(_sessionDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Check if we have a session cached for today
    if (cachedDate != today) {
      print(
        '[AuthCache] No valid session for today (cached: $cachedDate, today: $today)',
      );
      await clearCache(); // Clear old cache
      return false;
    }

    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson == null) {
      print('[AuthCache] No cached session data found');
      return false;
    }

    print('[AuthCache] Valid cached session found for today');
    return true;
  }

  /// Restore session from cache if valid
  Future<bool> restoreSession() async {
    if (!await hasValidCachedSession()) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);

      if (sessionJson == null) return false;

      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;

      // Set the session directly using setSession
      await _supabase.auth.setSession(sessionData['access_token'] as String);

      print('[AuthCache] Session restored successfully');
      return true;
    } catch (e) {
      print('[AuthCache] Failed to restore session: $e');
      await clearCache();
      return false;
    }
  }

  /// Clear all cached session data
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_sessionDateKey);
    await prefs.remove(_userIdKey);
    print('[AuthCache] Cache cleared');
  }

  /// Get cached user ID if available
  Future<String?> getCachedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Check if the current session should be refreshed (for next day login requirement)
  bool shouldRequireReLogin() {
    final session = _supabase.auth.currentSession;
    if (session == null) return true;

    // For daily login requirement, we'll rely on our cache date check
    // The cache is cleared daily, so if we get here, the session is still valid for today
    return false;
  }

  /// Initialize auth cache - call this in main() or app startup
  Future<void> initialize() async {
    print('[AuthCache] Initializing...');

    // Try to restore session first
    final restored = await restoreSession();

    if (!restored) {
      print('[AuthCache] No valid session to restore');
      return;
    }

    // Set up listener to cache session changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // Cache new sessions
        cacheCurrentSession();
      } else {
        // Clear cache when user logs out
        clearCache();
      }
    });
  }
}
