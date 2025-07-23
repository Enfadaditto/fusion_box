import 'package:fusion_box/domain/entities/pokemon.dart';

class PokemonModel extends Pokemon {
  const PokemonModel({
    required super.pokedexNumber,
    required super.name,
    required super.types,
  });

  factory PokemonModel.fromJson(Map<String, dynamic> json) {
    return PokemonModel(
      pokedexNumber: json['pokedexNumber'] as int,
      name: json['name'] as String,
      types: List<String>.from(json['types'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {'pokedexNumber': pokedexNumber, 'name': name, 'types': types};
  }

  factory PokemonModel.fromEntity(Pokemon pokemon) {
    return PokemonModel(
      pokedexNumber: pokemon.pokedexNumber,
      name: pokemon.name,
      types: pokemon.types,
    );
  }
}
