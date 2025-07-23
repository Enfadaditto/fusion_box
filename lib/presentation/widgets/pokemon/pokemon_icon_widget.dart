import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/core/constants/pokemon_type_colors.dart';

class PokemonIconWidget extends StatelessWidget {
  final Pokemon pokemon;
  final double size;

  const PokemonIconWidget({super.key, required this.pokemon, this.size = 64.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PokemonTypeColors.getTypeColor(
          pokemon.types.isNotEmpty ? pokemon.types.first : 'Normal',
        ),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pokemon.pokedexNumber.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.25,
              ),
            ),
            if (size > 40)
              Text(
                pokemon.name.length > 8
                    ? '${pokemon.name.substring(0, 6)}..'
                    : pokemon.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget más pequeño para uso en listas
class PokemonIconSmall extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonIconSmall({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return PokemonIconWidget(pokemon: pokemon, size: 40.0);
  }
}

/// Widget mediano para uso en grids
class PokemonIconMedium extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonIconMedium({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return PokemonIconWidget(pokemon: pokemon, size: 64.0);
  }
}

/// Widget grande para detalles
class PokemonIconLarge extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonIconLarge({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return PokemonIconWidget(pokemon: pokemon, size: 120.0);
  }
}
