import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/usecases/get_pokemon_list.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_event.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_state.dart';

class PokemonListBloc extends Bloc<PokemonListEvent, PokemonListState> {
  final GetPokemonList getPokemonList;

  PokemonListBloc({required this.getPokemonList})
    : super(PokemonListInitial()) {
    on<LoadPokemonList>(_onLoadPokemonList);
    on<SearchPokemon>(_onSearchPokemon);
    on<TogglePokemonSelection>(_onTogglePokemonSelection);
    on<ClearSelectedPokemon>(_onClearSelectedPokemon);
    on<RemoveSelectedPokemon>(_onRemoveSelectedPokemon);
  }

  Future<void> _onLoadPokemonList(
    LoadPokemonList event,
    Emitter<PokemonListState> emit,
  ) async {
    emit(PokemonListLoading());

    try {
      final pokemon = await getPokemonList.call();
      emit(
        PokemonListLoaded(
          allPokemon: pokemon,
          filteredPokemon: pokemon,
          selectedPokemon: const [],
        ),
      );
    } catch (e) {
      emit(PokemonListError('Failed to load Pokemon: $e'));
    }
  }

  Future<void> _onSearchPokemon(
    SearchPokemon event,
    Emitter<PokemonListState> emit,
  ) async {
    if (state is PokemonListLoaded) {
      final currentState = state as PokemonListLoaded;

      try {
        final filteredPokemon = await getPokemonList.search(event.query);
        emit(
          currentState.copyWith(
            filteredPokemon: filteredPokemon,
            searchQuery: event.query,
          ),
        );
      } catch (e) {
        emit(PokemonListError('Failed to search Pokemon: $e'));
      }
    }
  }

  void _onTogglePokemonSelection(
    TogglePokemonSelection event,
    Emitter<PokemonListState> emit,
  ) {
    if (state is PokemonListLoaded) {
      final currentState = state as PokemonListLoaded;
      final selectedPokemon = List<Pokemon>.from(currentState.selectedPokemon);

      if (selectedPokemon.contains(event.pokemon)) {
        selectedPokemon.remove(event.pokemon);
      } else {
        selectedPokemon.add(event.pokemon);
      }

      emit(currentState.copyWith(selectedPokemon: selectedPokemon));
    }
  }

  void _onClearSelectedPokemon(
    ClearSelectedPokemon event,
    Emitter<PokemonListState> emit,
  ) {
    if (state is PokemonListLoaded) {
      final currentState = state as PokemonListLoaded;
      emit(currentState.copyWith(selectedPokemon: const []));
    }
  }

  void _onRemoveSelectedPokemon(
    RemoveSelectedPokemon event,
    Emitter<PokemonListState> emit,
  ) {
    if (state is PokemonListLoaded) {
      final currentState = state as PokemonListLoaded;
      final selectedPokemon = List<Pokemon>.from(currentState.selectedPokemon);
      selectedPokemon.remove(event.pokemon);
      emit(currentState.copyWith(selectedPokemon: selectedPokemon));
    }
  }
}
