import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _simpleIconsKey = 'use_simple_icons';
  static const String _axAFusionsKey = 'use_axa_fusions';
  static const String _autogenSpritesKey = 'use_autogen_sprites';

  static Future<bool> getUseSimpleIcons() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_simpleIconsKey) ?? true;
  }

  static Future<void> setUseSimpleIcons(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simpleIconsKey, value);
  }

  static Future<bool> getUseAxAFusions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_axAFusionsKey) ?? false;
  }

  static Future<void> setUseAxAFusions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_axAFusionsKey, value);
  }

  static Future<bool> getUseAutogenSprites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autogenSpritesKey) ?? true;
  }

  static Future<void> setUseAutogenSprites(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autogenSpritesKey, value);
  }
}
