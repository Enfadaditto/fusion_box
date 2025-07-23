import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/core/constants/pokemon_type_colors.dart';

/// Widget optimizado para iconos de Pokemon con división diagonal de tipos
class CachedPokemonIcon extends StatelessWidget {
  final Pokemon pokemon;
  final double size;

  const CachedPokemonIcon({super.key, required this.pokemon, this.size = 64.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: Colors.white, width: size >= 64.0 ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: PokemonTypePainter(
            primaryType:
                pokemon.types.isNotEmpty ? pokemon.types.first : 'Normal',
            secondaryType: pokemon.types.length > 1 ? pokemon.types[1] : null,
          ),
        ),
      ),
    );
  }
}

/// CustomPainter para dibujar la división diagonal de tipos
class PokemonTypePainter extends CustomPainter {
  final String primaryType;
  final String? secondaryType;

  PokemonTypePainter({required this.primaryType, this.secondaryType});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (secondaryType == null) {
      // Monotipo: solo pintar con el color del tipo principal
      final paint =
          Paint()
            ..color = PokemonTypeColors.getTypeColor(primaryType)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, paint);
    } else {
      // Dual-tipo: división diagonal
      final primaryColor = PokemonTypeColors.getTypeColor(primaryType);
      final secondaryColor = PokemonTypeColors.getTypeColor(secondaryType!);

      // Crear path para la mitad superior izquierda (tipo primario)
      final path1 = Path();
      path1.moveTo(0, 0);
      path1.lineTo(size.width, 0);
      path1.lineTo(0, size.height);
      path1.close();

      // Clipear con el círculo
      final circlePath =
          Path()..addOval(Rect.fromCircle(center: center, radius: radius));

      final clippedPath1 = Path.combine(
        PathOperation.intersect,
        path1,
        circlePath,
      );

      // Pintar la primera mitad
      final paint1 =
          Paint()
            ..color = primaryColor
            ..style = PaintingStyle.fill;
      canvas.drawPath(clippedPath1, paint1);

      // Crear path para la mitad inferior derecha (tipo secundario)
      final path2 = Path();
      path2.moveTo(size.width, 0);
      path2.lineTo(size.width, size.height);
      path2.lineTo(0, size.height);
      path2.close();

      final clippedPath2 = Path.combine(
        PathOperation.intersect,
        path2,
        circlePath,
      );

      // Pintar la segunda mitad
      final paint2 =
          Paint()
            ..color = secondaryColor
            ..style = PaintingStyle.fill;
      canvas.drawPath(clippedPath2, paint2);

      // Dibujar línea diagonal de separación
      final linePaint =
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), linePaint);
    }
  }

  @override
  bool shouldRepaint(PokemonTypePainter oldDelegate) {
    return oldDelegate.primaryType != primaryType ||
        oldDelegate.secondaryType != secondaryType;
  }
}

/// Widgets de tamaños específicos
class CachedPokemonIconSmall extends StatelessWidget {
  final Pokemon pokemon;

  const CachedPokemonIconSmall({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return CachedPokemonIcon(pokemon: pokemon, size: 40.0);
  }
}

class CachedPokemonIconMedium extends StatelessWidget {
  final Pokemon pokemon;

  const CachedPokemonIconMedium({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return CachedPokemonIcon(pokemon: pokemon, size: 64.0);
  }
}

class CachedPokemonIconLarge extends StatelessWidget {
  final Pokemon pokemon;

  const CachedPokemonIconLarge({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return CachedPokemonIcon(pokemon: pokemon, size: 120.0);
  }
}
