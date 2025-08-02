import 'package:equatable/equatable.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/entities/fusion.dart';

abstract class FusionGridEvent extends Equatable {
  const FusionGridEvent();

  @override
  List<Object> get props => [];
}

class GenerateFusionGridEvent extends FusionGridEvent {
  final List<Pokemon> selectedPokemon;

  const GenerateFusionGridEvent(this.selectedPokemon);

  @override
  List<Object> get props => [selectedPokemon];
}

class ClearFusionGrid extends FusionGridEvent {}

class ZoomIn extends FusionGridEvent {}

class ZoomOut extends FusionGridEvent {}

class ResetZoom extends FusionGridEvent {}

class ToggleFusionSelection extends FusionGridEvent {
  final Fusion fusion;

  const ToggleFusionSelection(this.fusion);

  @override
  List<Object> get props => [fusion];
}

class ToggleComparisonMode extends FusionGridEvent {}

class ClearSelectedFusions extends FusionGridEvent {}
