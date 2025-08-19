import 'package:equatable/equatable.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';

/// Clave de ordenación disponible para el grid
enum FusionSortKey {
  none,
  total,
  hp,
  attack,
  defense,
  specialAttack,
  specialDefense,
  speed,
}

/// Dirección de ordenación
enum FusionSortOrder { descending, ascending }

abstract class FusionGridState extends Equatable {
  const FusionGridState();

  @override
  List<Object> get props => [];
}

class FusionGridInitial extends FusionGridState {}

class FusionGridLoading extends FusionGridState {}

class FusionGridLoaded extends FusionGridState {
  final List<List<Fusion?>> baseFusionGrid;
  final List<List<Fusion?>> fusionGrid;
  final List<Pokemon> selectedPokemon;
  final double zoomLevel;
  final Set<String> selectedFusionIds;
  final bool isComparisonMode;
  final FusionSortKey sortKey;
  final FusionSortOrder sortOrder;

  const FusionGridLoaded({
    required this.baseFusionGrid,
    required this.fusionGrid,
    required this.selectedPokemon,
    this.zoomLevel = 1.0,
    this.selectedFusionIds = const {},
    this.isComparisonMode = false,
    this.sortKey = FusionSortKey.none,
    this.sortOrder = FusionSortOrder.descending,
  });

  FusionGridLoaded copyWith({
    List<List<Fusion?>>? baseFusionGrid,
    List<List<Fusion?>>? fusionGrid,
    List<Pokemon>? selectedPokemon,
    double? zoomLevel,
    Set<String>? selectedFusionIds,
    bool? isComparisonMode,
    FusionSortKey? sortKey,
    FusionSortOrder? sortOrder,
  }) {
    return FusionGridLoaded(
      baseFusionGrid: baseFusionGrid ?? this.baseFusionGrid,
      fusionGrid: fusionGrid ?? this.fusionGrid,
      selectedPokemon: selectedPokemon ?? this.selectedPokemon,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      selectedFusionIds: selectedFusionIds ?? this.selectedFusionIds,
      isComparisonMode: isComparisonMode ?? this.isComparisonMode,
      sortKey: sortKey ?? this.sortKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object> get props => [
        baseFusionGrid,
        fusionGrid,
        selectedPokemon,
        zoomLevel,
        selectedFusionIds,
        isComparisonMode,
        sortKey,
        sortOrder,
      ];
}

class FusionGridError extends FusionGridState {
  final String message;

  const FusionGridError(this.message);

  @override
  List<Object> get props => [message];
}
