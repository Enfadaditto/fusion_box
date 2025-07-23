import 'package:fusion_box/core/errors/failures.dart';
import 'package:fusion_box/data/datasources/local/pokemon_local_datasource.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/repositories/pokemon_repository.dart';

class PokemonRepositoryImpl implements PokemonRepository {
  final PokemonLocalDataSource localDataSource;

  PokemonRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Pokemon>> getAllPokemon() async {
    try {
      final pokemonModels = await localDataSource.getAllPokemon();
      return pokemonModels.map((model) => model as Pokemon).toList();
    } catch (e) {
      throw DataFailure('Failed to get all Pokemon: $e');
    }
  }

  @override
  Future<Pokemon?> getPokemonById(int id) async {
    try {
      final pokemonModel = await localDataSource.getPokemonById(id);
      return pokemonModel;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Pokemon>> searchPokemon(String query) async {
    try {
      final pokemonModels = await localDataSource.searchPokemon(query);
      return pokemonModels.map((model) => model as Pokemon).toList();
    } catch (e) {
      throw DataFailure('Failed to search Pokemon: $e');
    }
  }
}
