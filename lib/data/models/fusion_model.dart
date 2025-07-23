import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';

class FusionModel extends Fusion {
  const FusionModel({
    required super.headPokemon,
    required super.bodyPokemon,
    required super.availableSprites,
    required super.types,
    super.primarySprite,
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
    };
  }

  factory FusionModel.fromEntity(Fusion fusion) {
    return FusionModel(
      headPokemon: fusion.headPokemon,
      bodyPokemon: fusion.bodyPokemon,
      availableSprites: fusion.availableSprites,
      types: fusion.types,
      primarySprite: fusion.primarySprite,
    );
  }
}
