import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/usecases/get_fusion.dart';
import 'package:image/image.dart' as img;

// Función top-level para ejecutar en isolate
Future<List<List<Fusion?>>> generateFusionGridInIsolate(
  List<Pokemon> selectedPokemon,
) async {
  final grid = <List<Fusion?>>[];

  for (int i = 0; i < selectedPokemon.length; i++) {
    final row = <Fusion?>[];
    for (int j = 0; j < selectedPokemon.length; j++) {
      final headPokemon = selectedPokemon[i];
      final bodyPokemon = selectedPokemon[j];

      // Calcular tipos básicos
      final types = _calculateBasicFusionTypes(headPokemon, bodyPokemon);

      final fusion = Fusion(
        headPokemon: headPokemon,
        bodyPokemon: bodyPokemon,
        availableSprites: [],
        types: types,
        primarySprite: null, // Los sprites se cargarán en el hilo principal
      );

      row.add(fusion);
    }
    grid.add(row);
  }

  return grid;
}

// Función helper para calcular tipos
List<String> _calculateBasicFusionTypes(Pokemon head, Pokemon body) {
  final types = <String>[];
  if (head.types.isNotEmpty) types.add(head.types.first);

  final bool bodyIsDualType = body.types.length > 1;

  if (bodyIsDualType) {
    if (!types.contains(body.types[1])) {
      types.add(body.types[1]);
    } else {
      types.add(body.types[0]);
    }
  } else {
    if (!types.contains(body.types[0])) {
      types.add(body.types[0]);
    }
  }

  return types;
}

class GenerateFusionGrid {
  final GetFusion getFusion;

  GenerateFusionGrid({required this.getFusion});

  Future<List<List<Fusion?>>> call(List<Pokemon> selectedPokemon) async {
    try {
      // Generar estructura básica en isolate (no bloquea UI)
      final basicGrid = await compute(
        generateFusionGridInIsolate,
        selectedPokemon,
      );

      // Cargar sprites en el hilo principal (necesario para acceder a repositorios)
      final gridWithSprites = await _loadAllSprites(basicGrid);

      return gridWithSprites;
    } catch (e) {
      rethrow;
    }
  }

  // Cargar todos los sprites en el hilo principal
  Future<List<List<Fusion?>>> _loadAllSprites(
    List<List<Fusion?>> basicGrid,
  ) async {
    final gridWithSprites = <List<Fusion?>>[];

    for (int i = 0; i < basicGrid.length; i++) {
      final row = <Fusion?>[];

      final headPokemon = basicGrid[i][i];
      if (headPokemon != null) {
        final spritesheetPath = await getFusion.spriteRepository
            .getSpritesheetPath(headPokemon.headPokemon.pokedexNumber);

        if (spritesheetPath != null) {
          final spriteSheet = File(spritesheetPath);

          img.Image? image;
          if (await spriteSheet.exists()) {
            final bytes = await spriteSheet.readAsBytes();
            image = img.decodeImage(bytes);
          }

          for (int j = 0; j < basicGrid[i].length; j++) {
            final fusion = basicGrid[i][j];

            if (fusion != null) {
              final sprite =
                  image != null
                      ? await getFusion.spriteRepository
                          .getSpecificSpriteFromSpritesheet(
                            spritesheetPath,
                            image,
                            fusion.headPokemon.pokedexNumber,
                            fusion.bodyPokemon.pokedexNumber,
                          )
                      : await getFusion.spriteRepository.getSpecificSprite(
                        fusion.headPokemon.pokedexNumber,
                        fusion.bodyPokemon.pokedexNumber,
                      );

              // Si no hay sprite personalizado, intentar autogenerado
              final finalSprite =
                  sprite ??
                  await getFusion.spriteRepository.getAutogenSprite(
                    fusion.headPokemon.pokedexNumber,
                    fusion.bodyPokemon.pokedexNumber,
                  );

              final fusionWithSprite = Fusion(
                headPokemon: fusion.headPokemon,
                bodyPokemon: fusion.bodyPokemon,
                availableSprites: fusion.availableSprites,
                types: fusion.types,
                primarySprite: finalSprite,
              );

              row.add(fusionWithSprite);
            } else {
              row.add(null);
            }
          }
        }
      }
      gridWithSprites.add(row);
    }

    return gridWithSprites;
  }

  Future<List<Fusion>> getAllFusions(List<Pokemon> selectedPokemon) async {
    final fusions = <Fusion>[];

    for (int i = 0; i < selectedPokemon.length; i++) {
      for (int j = 0; j < selectedPokemon.length; j++) {
        final fusion = await getFusion.call(
          selectedPokemon[i].pokedexNumber,
          selectedPokemon[j].pokedexNumber,
        );
        if (fusion != null) {
          fusions.add(fusion);
        }
      }
    }

    return fusions;
  }
}
