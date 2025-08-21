import 'package:equatable/equatable.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_state.dart';

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

class UpdateMovesFilter extends PokemonListEvent {
  final List<String> moves;

  const UpdateMovesFilter(this.moves);

  @override
  List<Object> get props => [moves];
}

class UpdateTypesFilter extends PokemonListEvent {
  final List<String> types;

  const UpdateTypesFilter(this.types);

  @override
  List<Object> get props => [types];
}

class UpdatePokemonSort extends PokemonListEvent {
  final PokemonSortKey sortKey;
  final PokemonSortOrder sortOrder;

  const UpdatePokemonSort({required this.sortKey, required this.sortOrder});

  @override
  List<Object> get props => [sortKey, sortOrder];
}
