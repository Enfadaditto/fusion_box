import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/domain/usecases/generate_fusion_grid.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_event.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_state.dart';

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
          fusionGrid: gridWithSprites,
          selectedPokemon: event.selectedPokemon,
        ),
      );
    } catch (e) {
      emit(FusionGridError('Failed to generate fusion grid: $e'));
    }
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
}
