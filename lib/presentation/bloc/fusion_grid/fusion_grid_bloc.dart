import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/domain/usecases/generate_fusion_grid.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_event.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_state.dart';
import 'package:fusion_box/domain/entities/fusion.dart';

class FusionGridBloc extends Bloc<FusionGridEvent, FusionGridState> {
  final GenerateFusionGrid generateFusionGrid;

  static const double minZoom = 0.5;
  static const double maxZoom = 3.0;
  static const double zoomStep = 0.2;

  FusionGridBloc({required this.generateFusionGrid})
    : super(FusionGridInitial()) {
    on<GenerateFusionGridEvent>(_onGenerateFusionGrid);
    on<ClearFusionGrid>(_onClearFusionGrid);
    on<ZoomIn>(_onZoomIn);
    on<ZoomOut>(_onZoomOut);
    on<ResetZoom>(_onResetZoom);
    on<ToggleFusionSelection>(_onToggleFusionSelection);
    on<ToggleComparisonMode>(_onToggleComparisonMode);
    on<ClearSelectedFusions>(_onClearSelectedFusions);
    on<SelectAllFusions>(_onSelectAllFusions);
    on<UpdateFusionSort>(_onUpdateFusionSort);
    on<UpdateFusionSpriteVariant>(_onUpdateFusionSpriteVariant);
  }

  Future<void> _onGenerateFusionGrid(
    GenerateFusionGridEvent event,
    Emitter<FusionGridState> emit,
  ) async {
    emit(FusionGridLoading());

    try {
      // Generar grid completo en segundo plano (usando compute para no bloquear UI)
      final gridWithSprites = await generateFusionGrid.call(
        event.selectedPokemon,
      );

      // Emitir estado final cuando todo esté listo
      emit(
        FusionGridLoaded(
          baseFusionGrid: gridWithSprites,
          fusionGrid: gridWithSprites,
          selectedPokemon: event.selectedPokemon,
          sortKey: FusionSortKey.none,
          sortOrder: FusionSortOrder.descending,
        ),
      );
    } catch (e) {
      emit(FusionGridError('Failed to generate fusion grid: $e'));
    }
  }

  void _onUpdateFusionSpriteVariant(
    UpdateFusionSpriteVariant event,
    Emitter<FusionGridState> emit,
  ) {
    final currentState = state;
    if (currentState is! FusionGridLoaded) return;

    List<List<Fusion?>> mapGrid(List<List<Fusion?>> grid) {
      final newGrid = <List<Fusion?>>[];
      for (final row in grid) {
        final newRow = <Fusion?>[];
        for (final fusion in row) {
          if (fusion != null &&
              fusion.headPokemon.pokedexNumber == event.headId &&
              fusion.bodyPokemon.pokedexNumber == event.bodyId) {
            newRow.add(
              Fusion(
                headPokemon: fusion.headPokemon,
                bodyPokemon: fusion.bodyPokemon,
                availableSprites: fusion.availableSprites,
                types: fusion.types,
                primarySprite: event.sprite,
                stats: fusion.stats,
              ),
            );
          } else {
            newRow.add(fusion);
          }
        }
        newGrid.add(newRow);
      }
      return newGrid;
    }

    final updatedBase = mapGrid(currentState.baseFusionGrid);
    final updatedGrid = mapGrid(currentState.fusionGrid);

    emit(currentState.copyWith(
      baseFusionGrid: updatedBase,
      fusionGrid: updatedGrid,
    ));
  }

  void _onUpdateFusionSort(
    UpdateFusionSort event,
    Emitter<FusionGridState> emit,
  ) {
    final currentState = state;
    if (currentState is FusionGridLoaded) {
      // Restaurar orden base si se elige 'none'
      final sorted = event.sortKey == FusionSortKey.none
          ? currentState.baseFusionGrid
          : _sortGridByStat(
              currentState.baseFusionGrid,
              event.sortKey,
              event.sortOrder,
            );
      emit(currentState.copyWith(
        fusionGrid: sorted,
        sortKey: event.sortKey,
        sortOrder: event.sortOrder,
      ));
    }
  }

  List<List<Fusion?>> _sortGridByStat(
    List<List<Fusion?>> grid,
    FusionSortKey sortKey,
    FusionSortOrder sortOrder,
  ) {
    if (sortKey == FusionSortKey.none) return grid;

    // Ordenamos cada fila por la métrica para que quede de izquierda a derecha
    int valueOf(Fusion? fusion) {
      if (fusion?.stats == null) return -0x3fffffff; // muy bajo para nulos
      final s = fusion!.stats!;
      switch (sortKey) {
        case FusionSortKey.total:
          return s.hp + s.attack + s.defense + s.specialAttack + s.specialDefense + s.speed;
        case FusionSortKey.hp:
          return s.hp;
        case FusionSortKey.attack:
          return s.attack;
        case FusionSortKey.defense:
          return s.defense;
        case FusionSortKey.specialAttack:
          return s.specialAttack;
        case FusionSortKey.specialDefense:
          return s.specialDefense;
        case FusionSortKey.speed:
          return s.speed;
        case FusionSortKey.none:
          return 0;
      }
    }

    final sortedGrid = <List<Fusion?>>[];
    for (final row in grid) {
      final newRow = List<Fusion?>.from(row);
      newRow.sort((a, b) {
        final va = valueOf(a);
        final vb = valueOf(b);
        final cmp = va.compareTo(vb);
        return sortOrder == FusionSortOrder.ascending ? cmp : -cmp;
      });
      sortedGrid.add(newRow);
    }

    return sortedGrid;
  }

  void _onClearFusionGrid(
    ClearFusionGrid event,
    Emitter<FusionGridState> emit,
  ) {
    emit(FusionGridInitial());
  }

  void _onZoomIn(ZoomIn event, Emitter<FusionGridState> emit) {
    final currentState = state;
    if (currentState is FusionGridLoaded) {
      final newZoom = (currentState.zoomLevel + zoomStep).clamp(
        minZoom,
        maxZoom,
      );
      emit(currentState.copyWith(zoomLevel: newZoom));
    }
  }

  void _onZoomOut(ZoomOut event, Emitter<FusionGridState> emit) {
    final currentState = state;
    if (currentState is FusionGridLoaded) {
      final newZoom = (currentState.zoomLevel - zoomStep).clamp(
        minZoom,
        maxZoom,
      );
      emit(currentState.copyWith(zoomLevel: newZoom));
    }
  }

  void _onResetZoom(ResetZoom event, Emitter<FusionGridState> emit) {
    final currentState = state;
    if (currentState is FusionGridLoaded) {
      emit(currentState.copyWith(zoomLevel: 1.0));
    }
  }

  void _onToggleFusionSelection(
    ToggleFusionSelection event,
    Emitter<FusionGridState> emit,
  ) {
    final currentState = state;
    if (currentState is FusionGridLoaded) {
      final fusionId = event.fusion.fusionId;
      final newSelectedFusionIds = Set<String>.from(currentState.selectedFusionIds);
      
      if (newSelectedFusionIds.contains(fusionId)) {
        newSelectedFusionIds.remove(fusionId);
      } else {
        newSelectedFusionIds.add(fusionId);
      }
      
      emit(currentState.copyWith(selectedFusionIds: newSelectedFusionIds));
    }
  }

  void _onToggleComparisonMode(
    ToggleComparisonMode event,
    Emitter<FusionGridState> emit,
  ) {
    final currentState = state;
    if (currentState is FusionGridLoaded) {
      emit(currentState.copyWith(isComparisonMode: !currentState.isComparisonMode));
    }
  }

  void _onClearSelectedFusions(
    ClearSelectedFusions event,
    Emitter<FusionGridState> emit,
  ) {
    final currentState = state;
    if (currentState is FusionGridLoaded) {
      emit(currentState.copyWith(
        selectedFusionIds: const {},
        isComparisonMode: false,
      ));
    }
  }

  void _onSelectAllFusions(
    SelectAllFusions event,
    Emitter<FusionGridState> emit,
  ) {
    final currentState = state;
    if (currentState is FusionGridLoaded) {
      final allIds = <String>{};
      for (final row in currentState.fusionGrid) {
        for (final fusion in row) {
          if (fusion != null) {
            allIds.add(fusion.fusionId);
          }
        }
      }

      emit(currentState.copyWith(
        selectedFusionIds: allIds,
        isComparisonMode: true,
      ));
    }
  }
}
