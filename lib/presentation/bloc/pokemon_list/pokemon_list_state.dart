import 'package:equatable/equatable.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';

enum PokemonSortKey {
  none,
  total,
  hp,
  attack,
  defense,
  specialAttack,
  specialDefense,
  speed,
}

enum PokemonSortOrder { descending, ascending }

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
  final List<String> movesFilter;
  final List<String> typesFilter;
  final PokemonSortKey sortKey;
  final PokemonSortOrder sortOrder;

  const PokemonListLoaded({
    required this.allPokemon,
    required this.filteredPokemon,
    required this.selectedPokemon,
    this.searchQuery = '',
    this.movesFilter = const [],
    this.typesFilter = const [],
    this.sortKey = PokemonSortKey.none,
    this.sortOrder = PokemonSortOrder.descending,
  });

  @override
  List<Object> get props => [
    allPokemon,
    filteredPokemon,
    selectedPokemon,
    searchQuery,
    movesFilter,
    typesFilter,
    sortKey,
    sortOrder,
  ];

  PokemonListLoaded copyWith({
    List<Pokemon>? allPokemon,
    List<Pokemon>? filteredPokemon,
    List<Pokemon>? selectedPokemon,
    String? searchQuery,
    List<String>? movesFilter,
    List<String>? typesFilter,
    PokemonSortKey? sortKey,
    PokemonSortOrder? sortOrder,
  }) {
    return PokemonListLoaded(
      allPokemon: allPokemon ?? this.allPokemon,
      filteredPokemon: filteredPokemon ?? this.filteredPokemon,
      selectedPokemon: selectedPokemon ?? this.selectedPokemon,
      searchQuery: searchQuery ?? this.searchQuery,
      movesFilter: movesFilter ?? this.movesFilter,
      typesFilter: typesFilter ?? this.typesFilter,
      sortKey: sortKey ?? this.sortKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class PokemonListError extends PokemonListState {
  final String message;

  const PokemonListError(this.message);

  @override
  List<Object> get props => [message];
}
