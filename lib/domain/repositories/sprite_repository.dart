import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:image/image.dart' as img;


abstract class SpriteRepository {
  Future<String?> getSpritesheetPath(int headPokemonId);
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
  Future<SpriteData?> getSpecificSpriteFromSpritesheet(
    String spritesheetPath,
    img.Image spritesheet,
    int headPokemonId,
    int bodyPokemonId, {
    String variant = '',
  });
  Future<List<SpriteData>> getAllSpriteVariants(
    int headPokemonId,
    int bodyPokemonId,
  );

  /// Obtiene un sprite autogenerado como fallback
  Future<SpriteData?> getAutogenSprite(int headPokemonId, int bodyPokemonId);
}
