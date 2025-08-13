import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/usecases/get_pokemon_list.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_event.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_state.dart';
import 'package:fusion_box/core/utils/pokemon_enrichment_loader.dart';

class PokemonListBloc extends Bloc<PokemonListEvent, PokemonListState> {
  final GetPokemonList getPokemonList;

  PokemonListBloc({required this.getPokemonList})
    : super(PokemonListInitial()) {
    on<LoadPokemonList>(_onLoadPokemonList);
    on<SearchPokemon>(_onSearchPokemon);
    on<TogglePokemonSelection>(_onTogglePokemonSelection);
    on<ClearSelectedPokemon>(_onClearSelectedPokemon);
    on<RemoveSelectedPokemon>(_onRemoveSelectedPokemon);
    on<SortSelectedByName>(_onSortSelectedByName);
    on<SortSelectedByDex>(_onSortSelectedByDex);
    on<ReorderSelectedPokemon>(_onReorderSelectedPokemon);
    on<UpdateMovesFilter>(_onUpdateMovesFilter);
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
        var filteredPokemon = await getPokemonList.search(event.query);
        // Apply moves filter if present
        if (currentState.movesFilter.isNotEmpty) {
          filteredPokemon = await _applyMovesFilterToList(
            filteredPokemon,
            currentState.movesFilter,
            allPokemon: currentState.allPokemon,
            activeQuery: event.query,
          );
        }
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

  void _onSortSelectedByName(
    SortSelectedByName event,
    Emitter<PokemonListState> emit,
  ) {
    if (state is PokemonListLoaded) {
      final currentState = state as PokemonListLoaded;
      final selected = List<Pokemon>.from(currentState.selectedPokemon)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(currentState.copyWith(selectedPokemon: selected));
    }
  }

  void _onSortSelectedByDex(
    SortSelectedByDex event,
    Emitter<PokemonListState> emit,
  ) {
    if (state is PokemonListLoaded) {
      final currentState = state as PokemonListLoaded;
      final selected = List<Pokemon>.from(currentState.selectedPokemon)
        ..sort((a, b) => a.pokedexNumber.compareTo(b.pokedexNumber));
      emit(currentState.copyWith(selectedPokemon: selected));
    }
  }

  void _onReorderSelectedPokemon(
    ReorderSelectedPokemon event,
    Emitter<PokemonListState> emit,
  ) {
    if (state is PokemonListLoaded) {
      final currentState = state as PokemonListLoaded;
      final selected = List<Pokemon>.from(currentState.selectedPokemon);
      int newIndex = event.newIndex;
      if (event.newIndex > event.oldIndex) newIndex -= 1;
      final moved = selected.removeAt(event.oldIndex);
      selected.insert(newIndex, moved);
      emit(currentState.copyWith(selectedPokemon: selected));
    }
  }

  Future<void> _onUpdateMovesFilter(
    UpdateMovesFilter event,
    Emitter<PokemonListState> emit,
  ) async {
    if (state is! PokemonListLoaded) return;
    final currentState = state as PokemonListLoaded;
    try {
      // Start from current search query base
      var base = await getPokemonList.search(currentState.searchQuery);
      if (event.moves.isNotEmpty) {
        base = await _applyMovesFilterToList(
          base,
          event.moves,
          allPokemon: currentState.allPokemon,
          activeQuery: currentState.searchQuery,
        );
      }
      emit(
        currentState.copyWith(
          filteredPokemon: base,
          movesFilter: List<String>.from(event.moves),
        ),
      );
    } catch (e) {
      emit(PokemonListError('Failed to apply moves filter: $e'));
    }
  }

  Future<List<Pokemon>> _applyMovesFilterToList(
    List<Pokemon> list,
    List<String> requiredMoves, {
    required List<Pokemon> allPokemon,
    required String activeQuery,
  }) async {
    final lowerRequired = requiredMoves.map((m) => m.toLowerCase()).toList();
    final loader = PokemonEnrichmentLoader();
    final List<Pokemon> out = [];
    for (final p in list) {
      final moves = await loader.getMovesOfPokemon(p);
      final lower = moves.map((m) => m.toLowerCase()).toSet();
      final ok = lowerRequired.every(lower.contains);
      if (ok) out.add(p);
    }
    // Always include Smeargle when filtering by moves, unless the active query
    // is an ability selection (conceptually Smeargle does not gain abilities).
    if (requiredMoves.isNotEmpty) {
      final abilities = await loader.getAllAbilities();
      final isAbilityQuery = abilities.any((a) => a.toLowerCase() == activeQuery.toLowerCase());
      if (!isAbilityQuery) {
        final smeargle = allPokemon.firstWhere(
          (p) => p.name.toLowerCase() == 'smeargle',
          orElse: () => out.isNotEmpty ? out.first : list.first,
        );
        if (!out.contains(smeargle) && smeargle.name.toLowerCase() == 'smeargle') {
          out.add(smeargle);
        }
      }
    }
    return out;
  }

  // bulk visible selection handlers removed
}
