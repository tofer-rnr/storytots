import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DictionaryService {
  static const _baseEn = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  Future<String> define(String word, {String lang = 'en'}) async {
    final w = word.trim().toLowerCase();
    if (w.isEmpty) return '';
    final cacheKey = 'dict:$lang:$w';
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      if (lang == 'en') {
        final res = await http.get(Uri.parse('$_baseEn/$w'));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data is List && data.isNotEmpty) {
            final first = data.first as Map<String, dynamic>;
            final meanings = (first['meanings'] as List?) ?? const [];
            for (final m in meanings) {
              final defs = (m['definitions'] as List?) ?? const [];
              if (defs.isNotEmpty) {
                final def = (defs.first as Map)['definition'] as String?;
                if (def != null && def.isNotEmpty) {
                  await prefs.setString(cacheKey, def);
                  return def;
                }
              }
            }
          }
        }
      }
      // Fallback for unsupported language or failure
      const fallback = 'Definition not available yet. We\'re working on it!';
      await prefs.setString(cacheKey, fallback);
      return fallback;
    } catch (_) {
      const offline =
          'Couldn\'t fetch definition right now. Please try again later.';
      await prefs.setString(cacheKey, offline);
      return offline;
    }
  }
}
