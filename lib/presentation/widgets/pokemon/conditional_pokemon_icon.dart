import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/presentation/bloc/settings/settings_bloc.dart';
import 'package:fusion_box/presentation/bloc/settings/settings_state.dart';
import 'package:fusion_box/presentation/widgets/pokemon/cached_pokemon_icon.dart';
import 'package:fusion_box/presentation/widgets/pokemon/pokemon_small_icon.dart';

class ConditionalPokemonIcon extends StatelessWidget {
  final Pokemon pokemon;
  final double size;

  const ConditionalPokemonIcon({
    super.key,
    required this.pokemon,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) {
        // Rebuild only when useSimpleIcons changes
        if (previous is SettingsLoaded && current is SettingsLoaded) {
          return previous.useSimpleIcons != current.useSimpleIcons;
        }
        return true;
      },
      builder: (context, state) {
        if (state is SettingsLoaded) {
          // If useSimpleIcons is true, show the simple colored icons
          if (state.useSimpleIcons) {
            return CachedPokemonIcon(pokemon: pokemon, size: size);
          } else {
            // If useSimpleIcons is false, show the small Pokemon icons from API
            return PokemonSmallIcon(pokemon: pokemon, size: size);
          }
        }

        // Default to simple icons while loading settings
        return CachedPokemonIcon(pokemon: pokemon, size: size);
      },
    );
  }
}

// Convenience widgets for different sizes
class ConditionalPokemonIconSmall extends StatelessWidget {
  final Pokemon pokemon;

  const ConditionalPokemonIconSmall({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return ConditionalPokemonIcon(pokemon: pokemon, size: 40.0);
  }
}

class ConditionalPokemonIconMedium extends StatelessWidget {
  final Pokemon pokemon;

  const ConditionalPokemonIconMedium({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return ConditionalPokemonIcon(pokemon: pokemon, size: 64.0);
  }
}

class ConditionalPokemonIconLarge extends StatelessWidget {
  final Pokemon pokemon;

  const ConditionalPokemonIconLarge({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return ConditionalPokemonIcon(pokemon: pokemon, size: 120.0);
  }
}
