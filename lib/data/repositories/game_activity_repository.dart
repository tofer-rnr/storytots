import 'package:shared_preferences/shared_preferences.dart';

class GameActivityRepository {
  static const _prefix = 'game_minutes:'; // game_minutes:YYYY-MM-DD (seconds)

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> addGameTime(Duration delta) async {
    final prefs = await _prefs;
    final key = '$_prefix${_dayKey(DateTime.now())}';
    final sec = delta.inSeconds;
    if (sec <= 0) return;
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + sec);
  }

  Future<int> getTodayGameMinutes() async {
    final prefs = await _prefs;
    final key = '$_prefix${_dayKey(DateTime.now())}';
    final sec = prefs.getInt(key) ?? 0;
    return (sec / 60).floor();
  }
}
