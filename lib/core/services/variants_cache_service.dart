import 'package:shared_preferences/shared_preferences.dart';

class VariantsCacheService {
  static const String _prefix = 'variants_cache_v1';

  static String _keyForHead(int headId) => '$_prefix:$headId';

  static Future<List<String>?> getCachedVariants(int headId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForHead(headId);
    final list = prefs.getStringList(key);
    if (list == null) return null;
    // Ensure unique and stable order: '' first, then sorted others
    final baseFirst = <String>[];
    if (list.contains('')) baseFirst.add('');
    baseFirst.addAll(list.where((v) => v.isNotEmpty).toSet().toList()..sort());
    return baseFirst;
  }

  static Future<void> setCachedVariants(int headId, List<String> variants) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForHead(headId);
    // Deduplicate
    final dedup = <String>{...variants}.toList();
    await prefs.setStringList(key, dedup);
  }

  static Future<void> addVariant(int headId, String variant) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForHead(headId);
    final current = prefs.getStringList(key) ?? <String>[];
    if (!current.contains(variant)) {
      current.add(variant);
      await prefs.setStringList(key, current);
    }
  }

  // Elimina todas las entradas de la caché de variantes
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final k in keys) {
      if (k.startsWith(_prefix)) {
        await prefs.remove(k);
      }
    }
  }
}


