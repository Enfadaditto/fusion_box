import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/entities/pokemon_stats.dart';

class FusionModel extends Fusion {
  const FusionModel({
    required super.headPokemon,
    required super.bodyPokemon,
    required super.availableSprites,
    required super.types,
    super.primarySprite,
    super.stats,
  });

  factory FusionModel.fromJson(Map<String, dynamic> json) {
    return FusionModel(
      headPokemon: Pokemon(
        pokedexNumber: json['headPokemon']['pokedexNumber'] as int,
        name: json['headPokemon']['name'] as String,
        types: List<String>.from(json['headPokemon']['types'] as List),
      ),
      bodyPokemon: Pokemon(
        pokedexNumber: json['bodyPokemon']['pokedexNumber'] as int,
        name: json['bodyPokemon']['name'] as String,
        types: List<String>.from(json['bodyPokemon']['types'] as List),
      ),
      availableSprites: List<String>.from(json['availableSprites'] as List),
      types: List<String>.from(json['types'] as List),
      stats: json['stats'] != null 
          ? PokemonStats(
              hp: json['stats']['hp'] as int,
              attack: json['stats']['attack'] as int,
              defense: json['stats']['defense'] as int,
              specialAttack: json['stats']['specialAttack'] as int,
              specialDefense: json['stats']['specialDefense'] as int,
              speed: json['stats']['speed'] as int,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headPokemon': {
        'pokedexNumber': headPokemon.pokedexNumber,
        'name': headPokemon.name,
        'types': headPokemon.types,
      },
      'bodyPokemon': {
        'pokedexNumber': bodyPokemon.pokedexNumber,
        'name': bodyPokemon.name,
        'types': bodyPokemon.types,
      },
      'availableSprites': availableSprites,
      'types': types,
      'stats': stats != null ? {
        'hp': stats!.hp,
        'attack': stats!.attack,
        'defense': stats!.defense,
        'specialAttack': stats!.specialAttack,
        'specialDefense': stats!.specialDefense,
        'speed': stats!.speed,
      } : null,
    };
  }

  factory FusionModel.fromEntity(Fusion fusion) {
    return FusionModel(
      headPokemon: fusion.headPokemon,
      bodyPokemon: fusion.bodyPokemon,
      availableSprites: fusion.availableSprites,
      types: fusion.types,
      primarySprite: fusion.primarySprite,
      stats: fusion.stats,
    );
  }
}
