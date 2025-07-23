import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/repositories/pokemon_repository.dart';

class GetPokemonList {
  final PokemonRepository repository;

  GetPokemonList({required this.repository});

  Future<List<Pokemon>> call() async {
    return await repository.getAllPokemon();
  }

  Future<List<Pokemon>> search(String query) async {
    if (query.isEmpty) {
      return await repository.getAllPokemon();
    }
    return await repository.searchPokemon(query);
  }
}
