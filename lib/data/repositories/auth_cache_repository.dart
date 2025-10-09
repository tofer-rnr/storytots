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
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    // Cache session data
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    await prefs.setString(_sessionDateKey, today);
    await prefs.setString(_userIdKey, session.user.id);

    // Debug
    // ignore: avoid_print
    print('[AuthCache] Session cached for date: $today');
  }

  /// Check if we have a valid cached session for today
  Future<bool> hasValidCachedSession() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedDate = prefs.getString(_sessionDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Check if we have a session cached for today
    if (cachedDate != today) {
      // ignore: avoid_print
      print(
        '[AuthCache] No valid session for today (cached: $cachedDate, today: $today)',
      );
      await clearCache(); // Clear old cache
      return false;
    }

    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson == null) {
      // ignore: avoid_print
      print('[AuthCache] No cached session data found');
      return false;
    }

    // ignore: avoid_print
    print('[AuthCache] Valid cached session found for today');
    return true;
  }

  /// Restore session from cache if valid. Returns true if session restored.
  Future<bool> restoreSession() async {
    if (!await hasValidCachedSession()) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);
      if (sessionJson == null) return false;

      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;

      // Use refresh_token to restore a fresh session
      final refreshToken = sessionData['refresh_token'] as String?;
      if (refreshToken == null || refreshToken.isEmpty) {
        // ignore: avoid_print
        print('[AuthCache] No refresh_token in cached session');
        return false;
      }

      await _supabase.auth.setSession(refreshToken);

      // ignore: avoid_print
      print('[AuthCache] Session restored successfully');
      return true;
    } catch (e) {
      // ignore: avoid_print
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
    // ignore: avoid_print
    print('[AuthCache] Cache cleared');
  }

  /// Get cached user ID if available
  Future<String?> getCachedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Initialize auth cache - call this in main() or app startup
  Future<void> initialize() async {
    // ignore: avoid_print
    print('[AuthCache] Initializing...');

    // If cache date is not today, enforce re-login by clearing and signing out
    final hasValidForToday = await hasValidCachedSession();
    if (!hasValidForToday) {
      await _supabase.auth.signOut();
    } else {
      // Try to restore session when valid cache exists
      await restoreSession();
    }

    // Always attach listener to keep cache in sync with auth state
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        cacheCurrentSession();
      } else {
        clearCache();
      }
    });
  }
}
