import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/core/services/settings_notification_service.dart';
import 'package:fusion_box/presentation/widgets/pokemon/cached_pokemon_icon.dart';
import 'package:fusion_box/presentation/widgets/pokemon/pokemon_small_icon.dart';

class StreamBasedPokemonIcon extends StatefulWidget {
  final Pokemon pokemon;
  final double size;

  const StreamBasedPokemonIcon({
    super.key,
    required this.pokemon,
    this.size = 40.0,
  });

  @override
  State<StreamBasedPokemonIcon> createState() => _StreamBasedPokemonIconState();
}

class _StreamBasedPokemonIconState extends State<StreamBasedPokemonIcon> {
  bool _useSimpleIcons = true;
  late StreamSubscription<bool> _subscription;

  @override
  void initState() {
    super.initState();
    // Initialize with current value
    _useSimpleIcons = SettingsNotificationService().currentValue;

    _subscription = SettingsNotificationService().simpleIconsStream.listen((
      useSimpleIcons,
    ) {
      if (mounted) {
        setState(() {
          _useSimpleIcons = useSimpleIcons;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useSimpleIcons) {
      return CachedPokemonIcon(pokemon: widget.pokemon, size: widget.size);
    } else {
      return PokemonSmallIcon(pokemon: widget.pokemon, size: widget.size);
    }
  }
}

// Convenience widgets for different sizes
class StreamBasedPokemonIconSmall extends StatelessWidget {
  final Pokemon pokemon;

  const StreamBasedPokemonIconSmall({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return StreamBasedPokemonIcon(pokemon: pokemon, size: 40.0);
  }
}

class StreamBasedPokemonIconMedium extends StatelessWidget {
  final Pokemon pokemon;

  const StreamBasedPokemonIconMedium({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return StreamBasedPokemonIcon(pokemon: pokemon, size: 64.0);
  }
}

class StreamBasedPokemonIconLarge extends StatelessWidget {
  final Pokemon pokemon;

  const StreamBasedPokemonIconLarge({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return StreamBasedPokemonIcon(pokemon: pokemon, size: 120.0);
  }
}
