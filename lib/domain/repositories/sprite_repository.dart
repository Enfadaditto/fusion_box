import 'package:fusion_box/domain/entities/sprite_data.dart';

abstract class SpriteRepository {
  Future<List<SpriteData>> getFusionSprites(
    int headPokemonId,
    int bodyPokemonId,
  );
  Future<List<String>> getAvailableVariants(
    int headPokemonId,
    int bodyPokemonId,
  );
  Future<SpriteData?> getSpecificSprite(
    int headPokemonId,
    int bodyPokemonId, {
    String variant = '',
  });

  /// Obtiene un sprite autogenerado como fallback
  Future<SpriteData?> getAutogenSprite(int headPokemonId, int bodyPokemonId);
}
