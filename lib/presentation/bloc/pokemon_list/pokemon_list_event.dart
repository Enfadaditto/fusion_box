import 'package:equatable/equatable.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';

abstract class PokemonListEvent extends Equatable {
  const PokemonListEvent();

  @override
  List<Object> get props => [];
}

class LoadPokemonList extends PokemonListEvent {}

class SearchPokemon extends PokemonListEvent {
  final String query;

  const SearchPokemon(this.query);

  @override
  List<Object> get props => [query];
}

class TogglePokemonSelection extends PokemonListEvent {
  final Pokemon pokemon;

  const TogglePokemonSelection(this.pokemon);

  @override
  List<Object> get props => [pokemon];
}

class ClearSelectedPokemon extends PokemonListEvent {}

class RemoveSelectedPokemon extends PokemonListEvent {
  final Pokemon pokemon;

  const RemoveSelectedPokemon(this.pokemon);

  @override
  List<Object> get props => [pokemon];
}

class SortSelectedByName extends PokemonListEvent {}

class SortSelectedByDex extends PokemonListEvent {}

class ReorderSelectedPokemon extends PokemonListEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderSelectedPokemon(this.oldIndex, this.newIndex);

  @override
  List<Object> get props => [oldIndex, newIndex];
}
