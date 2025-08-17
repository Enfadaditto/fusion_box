import 'package:shared_preferences/shared_preferences.dart';

class PreferredSpriteService {
  static const String _prefix = 'preferred_sprite_variant_v1';

  static String _keyFor(int headId, int bodyId) => '$_prefix:$headId-$bodyId';

  /// Returns the stored variant for a fusion (headId-bodyId), or null if none.
  static Future<String?> getPreferredVariant(int headId, int bodyId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(headId, bodyId);
    final value = prefs.getString(key);
    // Permitir cadena vacía ('') como variante base seleccionada
    return value;
  }

  /// Stores the preferred variant for a fusion. Use empty string for base.
  static Future<void> setPreferredVariant(
    int headId,
    int bodyId,
    String variant,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(headId, bodyId);
    await prefs.setString(key, variant);
  }
}


