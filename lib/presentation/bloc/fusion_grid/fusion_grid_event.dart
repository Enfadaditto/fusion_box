import 'package:equatable/equatable.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';

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
