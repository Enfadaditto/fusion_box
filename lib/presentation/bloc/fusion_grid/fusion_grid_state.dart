import 'package:equatable/equatable.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';

abstract class FusionGridState extends Equatable {
  const FusionGridState();

  @override
  List<Object> get props => [];
}

class FusionGridInitial extends FusionGridState {}

class FusionGridLoading extends FusionGridState {}

class FusionGridLoaded extends FusionGridState {
  final List<List<Fusion?>> fusionGrid;
  final List<Pokemon> selectedPokemon;
  final double zoomLevel;

  const FusionGridLoaded({
    required this.fusionGrid,
    required this.selectedPokemon,
    this.zoomLevel = 1.0,
  });

  FusionGridLoaded copyWith({
    List<List<Fusion?>>? fusionGrid,
    List<Pokemon>? selectedPokemon,
    double? zoomLevel,
  }) {
    return FusionGridLoaded(
      fusionGrid: fusionGrid ?? this.fusionGrid,
      selectedPokemon: selectedPokemon ?? this.selectedPokemon,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }

  @override
  List<Object> get props => [fusionGrid, selectedPokemon, zoomLevel];
}

class FusionGridError extends FusionGridState {
  final String message;

  const FusionGridError(this.message);

  @override
  List<Object> get props => [message];
}
