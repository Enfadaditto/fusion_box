import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_details.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_bloc.dart';

class FusionDetailsDialog extends StatefulWidget {
  final Fusion? fusion;
  final Pokemon? pokemon;
  final FusionGridBloc? fusionGridBloc;

  const FusionDetailsDialog({
    super.key,
    this.fusion,
    this.pokemon,
    this.fusionGridBloc,
  }) : assert(
          (fusion != null) ^ (pokemon != null),
          'Provide exactly one of fusion or pokemon',
        );

  static void show(BuildContext context, Fusion fusion) {
    // Capture bloc from the caller's context (within provider scope)
    final fusionGridBloc = context.read<FusionGridBloc>();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => FusionDetailsDialog(
        fusion: fusion,
        fusionGridBloc: fusionGridBloc,
      ),
    );
  }

  static void showForPokemon(BuildContext context, Pokemon pokemon) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FusionDetailsDialog(pokemon: pokemon),
    );
  }

  @override
  State<FusionDetailsDialog> createState() => _FusionDetailsDialogState();
}

class _FusionDetailsDialogState extends State<FusionDetailsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: null,
      contentPadding: const EdgeInsets.all(24),
      content: FusionDetailsContent(
        fusion: widget.fusion,
        pokemon: widget.pokemon,
        fusionGridBloc: widget.fusionGridBloc,
      ),
    );
  }
} 