import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _simpleIconsKey = 'use_simple_icons';

  static Future<bool> getUseSimpleIcons() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_simpleIconsKey) ?? false;
  }

  static Future<void> setUseSimpleIcons(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simpleIconsKey, value);
  }
}
