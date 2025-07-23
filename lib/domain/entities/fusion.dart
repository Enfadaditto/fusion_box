import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';

class Fusion {
  final Pokemon headPokemon;
  final Pokemon bodyPokemon;
  final List<String> availableSprites;
  final List<String> types;
  final SpriteData? primarySprite;

  const Fusion({
    required this.headPokemon,
    required this.bodyPokemon,
    required this.availableSprites,
    required this.types,
    this.primarySprite,
  });

  String get fusionId =>
      '${headPokemon.pokedexNumber}-${bodyPokemon.pokedexNumber}';
}
