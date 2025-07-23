import 'package:equatable/equatable.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';

abstract class PokemonListState extends Equatable {
  const PokemonListState();

  @override
  List<Object> get props => [];
}

class PokemonListInitial extends PokemonListState {}

class PokemonListLoading extends PokemonListState {}

class PokemonListLoaded extends PokemonListState {
  final List<Pokemon> allPokemon;
  final List<Pokemon> filteredPokemon;
  final List<Pokemon> selectedPokemon;
  final String searchQuery;

  const PokemonListLoaded({
    required this.allPokemon,
    required this.filteredPokemon,
    required this.selectedPokemon,
    this.searchQuery = '',
  });

  @override
  List<Object> get props => [
    allPokemon,
    filteredPokemon,
    selectedPokemon,
    searchQuery,
  ];

  PokemonListLoaded copyWith({
    List<Pokemon>? allPokemon,
    List<Pokemon>? filteredPokemon,
    List<Pokemon>? selectedPokemon,
    String? searchQuery,
  }) {
    return PokemonListLoaded(
      allPokemon: allPokemon ?? this.allPokemon,
      filteredPokemon: filteredPokemon ?? this.filteredPokemon,
      selectedPokemon: selectedPokemon ?? this.selectedPokemon,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class PokemonListError extends PokemonListState {
  final String message;

  const PokemonListError(this.message);

  @override
  List<Object> get props => [message];
}
