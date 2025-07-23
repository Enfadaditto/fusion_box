import '../entities/pokemon.dart';

abstract class PokemonRepository {
  Future<List<Pokemon>> getAllPokemon();
  Future<Pokemon?> getPokemonById(int id);
  Future<List<Pokemon>> searchPokemon(String query);
}
