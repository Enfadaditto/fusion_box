import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:fusion_box/domain/repositories/pokemon_repository.dart';
import 'package:fusion_box/domain/repositories/sprite_repository.dart';

class GetFusion {
  final SpriteRepository spriteRepository;
  final PokemonRepository pokemonRepository;

  GetFusion({required this.spriteRepository, required this.pokemonRepository});

  Future<Fusion?> call(int headId, int bodyId) async {
    try {
      final headPokemon = await pokemonRepository.getPokemonById(headId);
      final bodyPokemon = await pokemonRepository.getPokemonById(bodyId);

      if (headPokemon == null || bodyPokemon == null) {
        return null;
      }

      final sprites = await spriteRepository.getFusionSprites(headId, bodyId);
      final spritePaths = sprites.map((sprite) => sprite.spritePath).toList();

      // Obtener el sprite específico para esta fusión
      SpriteData? primarySprite = await spriteRepository.getSpecificSprite(
        headId,
        bodyId,
      );

      // Si no se encuentra el sprite personalizado, usar autogenerado como fallback
      primarySprite ??= await spriteRepository.getAutogenSprite(headId, bodyId);

      final fusionTypes = _calculateFusionTypes(headPokemon, bodyPokemon);

      return Fusion(
        headPokemon: headPokemon,
        bodyPokemon: bodyPokemon,
        availableSprites: spritePaths,
        types: fusionTypes,
        primarySprite: primarySprite,
      );
    } catch (e) {
      return null;
    }
  }

  List<String> _calculateFusionTypes(Pokemon head, Pokemon body) {
    final types = <String>[];
    if (head.types.isNotEmpty) types.add(head.types.first);

    final bool bodyIsDualType = body.types.length > 1;

    if (bodyIsDualType) {
      if (!types.contains(body.types[1])) {
        types.add(body.types[1]);
      } else {
        types.add(body.types[0]);
      }
    } else {
      if (!types.contains(body.types[0])) {
        types.add(body.types[0]);
      }
    }

    return types;
  }
}
