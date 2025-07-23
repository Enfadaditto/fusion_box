import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fusion_box/core/errors/exceptions.dart';

abstract class GameLocalDataSource {
  Future<String?> getGamePath();
  Future<void> setGamePath(String path);
  Future<bool> validateGamePath(String path);
}

class GameLocalDataSourceImpl implements GameLocalDataSource {
  static const String _gamePathKey = 'game_path';

  @override
  Future<String?> getGamePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_gamePathKey);
    } catch (e) {
      throw DataSourceException('Failed to get game path: $e');
    }
  }

  @override
  Future<void> setGamePath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_gamePathKey, path);
    } catch (e) {
      throw DataSourceException('Failed to set game path: $e');
    }
  }

  @override
  Future<bool> validateGamePath(String path) async {
    try {
      final gameDir = Directory(path);
      if (!await gameDir.exists()) {
        return false;
      }

      // Verificar que existe la carpeta de sprites
      final spritesDir = Directory(
        '$path/Graphics/CustomBattlers/spritesheets/spritesheets_custom',
      );
      return await spritesDir.exists();
    } catch (e) {
      return false;
    }
  }
}
