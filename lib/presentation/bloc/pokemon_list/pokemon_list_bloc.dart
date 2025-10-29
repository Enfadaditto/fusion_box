import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/usecases/get_pokemon_list.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_event.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_state.dart';
import 'package:fusion_box/core/utils/pokemon_enrichment_loader.dart';
import 'package:fusion_box/core/utils/fusion_stats_calculator.dart';

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
    on<UpdateTypesFilter>(_onUpdateTypesFilter);
    on<UpdatePokemonSort>(_onUpdatePokemonSort);
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
        // Apply types filter first (sync)
        if (currentState.typesFilter.isNotEmpty) {
          filteredPokemon = _applyTypesFilterToList(
            filteredPokemon,
            currentState.typesFilter,
          );
        }
        // Apply moves filter if present
        if (currentState.movesFilter.isNotEmpty) {
          filteredPokemon = await _applyMovesFilterToList(
            filteredPokemon,
            currentState.movesFilter,
            allPokemon: currentState.allPokemon,
            activeQuery: event.query,
          );
        }
        filteredPokemon = await _applySortToList(
          filteredPokemon,
          sortKey: currentState.sortKey,
          sortOrder: currentState.sortOrder,
        );
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
      if (currentState.typesFilter.isNotEmpty) {
        base = _applyTypesFilterToList(base, currentState.typesFilter);
      }
      if (event.moves.isNotEmpty) {
        base = await _applyMovesFilterToList(
          base,
          event.moves,
          allPokemon: currentState.allPokemon,
          activeQuery: currentState.searchQuery,
        );
      }
      base = await _applySortToList(
        base,
        sortKey: currentState.sortKey,
        sortOrder: currentState.sortOrder,
      );
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

  Future<void> _onUpdateTypesFilter(
    UpdateTypesFilter event,
    Emitter<PokemonListState> emit,
  ) async {
    if (state is! PokemonListLoaded) return;
    final currentState = state as PokemonListLoaded;
    try {
      var base = await getPokemonList.search(currentState.searchQuery);
      // Apply types first
      if (event.types.isNotEmpty) {
        base = _applyTypesFilterToList(base, event.types);
      }
      // Then moves if present
      if (currentState.movesFilter.isNotEmpty) {
        base = await _applyMovesFilterToList(
          base,
          currentState.movesFilter,
          allPokemon: currentState.allPokemon,
          activeQuery: currentState.searchQuery,
        );
      }
      base = await _applySortToList(
        base,
        sortKey: currentState.sortKey,
        sortOrder: currentState.sortOrder,
      );
      emit(
        currentState.copyWith(
          filteredPokemon: base,
          typesFilter: List<String>.from(event.types),
        ),
      );
    } catch (e) {
      emit(PokemonListError('Failed to apply types filter: $e'));
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
      final isSmeargle = p.name.toLowerCase() == 'smeargle';
      if (isSmeargle) {
        // By concept, Smeargle can learn any move; the moves filter must never exclude it
        out.add(p);
        continue;
      }
      final moves = await loader.getMovesOfPokemon(p);
      final lower = moves.map((m) => m.toLowerCase()).toSet();
      final ok = lowerRequired.every(lower.contains);
      if (ok) out.add(p);
    }
    return out;
  }

  Future<void> _onUpdatePokemonSort(
    UpdatePokemonSort event,
    Emitter<PokemonListState> emit,
  ) async {
    if (state is! PokemonListLoaded) return;
    final currentState = state as PokemonListLoaded;
    try {
      var base = await getPokemonList.search(currentState.searchQuery);
      if (currentState.typesFilter.isNotEmpty) {
        base = _applyTypesFilterToList(base, currentState.typesFilter);
      }
      if (currentState.movesFilter.isNotEmpty) {
        base = await _applyMovesFilterToList(
          base,
          currentState.movesFilter,
          allPokemon: currentState.allPokemon,
          activeQuery: currentState.searchQuery,
        );
      }
      base = await _applySortToList(
        base,
        sortKey: event.sortKey,
        sortOrder: event.sortOrder,
      );
      emit(
        currentState.copyWith(
          filteredPokemon: base,
          sortKey: event.sortKey,
          sortOrder: event.sortOrder,
        ),
      );
    } catch (e) {
      emit(PokemonListError('Failed to apply sort: $e'));
    }
  }

  Future<List<Pokemon>> _applySortToList(
    List<Pokemon> list, {
    required PokemonSortKey sortKey,
    required PokemonSortOrder sortOrder,
  }) async {
    if (sortKey == PokemonSortKey.none) return list;
    final statsCalc = FusionStatsCalculator();
    final List<MapEntry<Pokemon, int>> entries = [];
    for (final p in list) {
      try {
        final s = await statsCalc.getStatsFromPokemon(p);
        int value;
        switch (sortKey) {
          case PokemonSortKey.none:
            value = 0;
            break;
          case PokemonSortKey.total:
            value = s.hp + s.attack + s.defense + s.specialAttack + s.specialDefense + s.speed;
            break;
          case PokemonSortKey.hp:
            value = s.hp;
            break;
          case PokemonSortKey.attack:
            value = s.attack;
            break;
          case PokemonSortKey.defense:
            value = s.defense;
            break;
          case PokemonSortKey.specialAttack:
            value = s.specialAttack;
            break;
          case PokemonSortKey.specialDefense:
            value = s.specialDefense;
            break;
          case PokemonSortKey.speed:
            value = s.speed;
            break;
        }
        entries.add(MapEntry(p, value));
      } catch (_) {
        entries.add(MapEntry(p, -0x3fffffff));
      }
    }
    entries.sort((a, b) {
      final cmp = a.value.compareTo(b.value);
      return sortOrder == PokemonSortOrder.ascending ? cmp : -cmp;
    });
    return entries.map((e) => e.key).toList(growable: false);
  }
  List<Pokemon> _applyTypesFilterToList(
    List<Pokemon> list,
    List<String> selectedTypes,
  ) {
    if (selectedTypes.isEmpty) return list;
    final selectedLower = selectedTypes.map((t) => t.toLowerCase()).toSet();
    return list.where((p) {
      final typesLower = p.types.map((t) => t.toLowerCase()).toSet();
      return selectedLower.every(typesLower.contains);
    }).toList();
  }

  // bulk visible selection handlers removed
}
