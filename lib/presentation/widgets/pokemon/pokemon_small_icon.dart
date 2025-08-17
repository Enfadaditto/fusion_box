import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/core/services/small_icons_service.dart';

class PokemonSmallIcon extends StatelessWidget {
  final Pokemon pokemon;
  final double size;

  const PokemonSmallIcon({super.key, required this.pokemon, this.size = 40.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: FutureBuilder<String>(
          future: SmallIconsService().getPokemonIcon(pokemon.name),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: Colors.black87,
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              // Fallback to a colored circle with Pokemon number
              return Container(
                color: Colors.grey[400],
                child: Center(
                  child: Text(
                    pokemon.pokedexNumber.toString(),
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }

            return Image.network(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to a colored circle with Pokemon number
                return Container(
                  color: Colors.grey[400],
                  child: Center(
                    child: Text(
                      pokemon.pokedexNumber.toString(),
                      style: TextStyle(
                        fontSize: size * 0.3,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
