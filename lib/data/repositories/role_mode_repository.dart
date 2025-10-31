// lib/data/repositories/role_mode_repository.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local role mode persistence to gate UI between Parent and Kid.
/// Values: 'parent' or 'kid' (default: 'kid').
class RoleModeRepository {
  static const _key = 'app_role_mode';

  Future<String> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'kid';
  }

  Future<bool> isParentMode() async {
    final mode = await getMode();
    return mode == 'parent';
  }

  Future<void> setMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == 'parent' ? 'parent' : 'kid');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
