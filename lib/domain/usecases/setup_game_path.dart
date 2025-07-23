import 'package:fusion_box/data/datasources/local/game_local_datasource.dart';

class SetupGamePath {
  final GameLocalDataSource gameLocalDataSource;

  SetupGamePath({required this.gameLocalDataSource});

  Future<String?> getCurrentPath() async {
    return await gameLocalDataSource.getGamePath();
  }

  Future<bool> setGamePath(String path) async {
    final isValid = await gameLocalDataSource.validateGamePath(path);
    if (isValid) {
      await gameLocalDataSource.setGamePath(path);
      return true;
    }
    return false;
  }

  Future<bool> validatePath(String path) async {
    return await gameLocalDataSource.validateGamePath(path);
  }

  Future<bool> clearGamePath() async {
    try {
      await gameLocalDataSource.setGamePath('');
      return true;
    } catch (e) {
      return false;
    }
  }
}
