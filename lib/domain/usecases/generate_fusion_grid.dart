import 'dart:io';
import 'dart:isolate';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/domain/entities/pokemon_stats.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:fusion_box/domain/usecases/get_fusion.dart';
import 'package:fusion_box/core/services/settings_service.dart';
import 'package:fusion_box/core/utils/fusion_stats_calculator.dart';
import 'package:fusion_box/core/services/preferred_sprite_service.dart';
import 'package:fusion_box/injection_container.dart';
import 'package:fusion_box/core/services/sprite_download_service.dart';
import 'package:fusion_box/core/services/variants_cache_service.dart';
import 'package:fusion_box/core/services/logger_service.dart';
import 'package:fusion_box/core/services/sprite_isolate.dart';
import 'package:fusion_box/data/parsers/sprite_parser.dart';

// Clase para pasar parámetros al isolate
class FusionGridParams {
  final List<Pokemon> selectedPokemon;
  final bool useAxAFusions;

  FusionGridParams({
    required this.selectedPokemon,
    required this.useAxAFusions,
  });
}

// Función top-level para ejecutar en isolate
Future<List<List<Fusion?>>> generateFusionGridInIsolate(
  FusionGridParams params,
) async {
  final grid = <List<Fusion?>>[];

  for (int i = 0; i < params.selectedPokemon.length; i++) {
    final row = <Fusion?>[];
    for (int j = 0; j < params.selectedPokemon.length; j++) {
      final headPokemon = params.selectedPokemon[i];
      final bodyPokemon = params.selectedPokemon[j];

      // Si las fusiones AxA están deshabilitadas y es la misma posición, saltar
      if (!params.useAxAFusions && i == j) {
        row.add(null);
        continue;
      }

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
      // Limpiar caché de variantes al inicio (forzar lectura desde spritesheet)
      try {
        await VariantsCacheService.clearAll();
      } catch (_) {}
      // Obtener configuración de fusiones AxA
      final useAxAFusions = await SettingsService.getUseAxAFusions();

      // Generar estructura básica en isolate (no bloquea UI)
      final basicGrid = await compute(
        generateFusionGridInIsolate,
        FusionGridParams(
          selectedPokemon: selectedPokemon,
          useAxAFusions: useAxAFusions,
        ),
      );

      // Cargar sprites en el hilo principal (necesario para acceder a repositorios)
      final gridWithSprites = await _loadAllSprites(basicGrid);

      return gridWithSprites;
    } catch (e, s) {
      try {
        instance.get<LoggerService>().logError(
          Exception('GenerateFusionGrid.call failed: $e'),
          s,
        );
      } catch (_) {}
      rethrow;
    }
  }

  // Cargar todos los sprites en el hilo principal
  Future<List<List<Fusion?>>> _loadAllSprites(
    List<List<Fusion?>> basicGrid,
  ) async {
    final gridWithSprites = <List<Fusion?>>[];
    final prefetchedHeadIds = <int>{};

    // Prefetch de todas las filas al inicio para dar tiempo a completar
    try {
      if (!kIsWeb) {
        final downloader = instance<SpriteDownloadService>();
        for (int i = 0; i < basicGrid.length; i++) {
          final rowHeadId = (i == 0
              ? basicGrid[i][1]!.headPokemon.pokedexNumber
              : basicGrid[i][0]!.headPokemon.pokedexNumber);
          if (!prefetchedHeadIds.contains(rowHeadId)) {
            final spritesheetPath = await getFusion.spriteRepository.getSpritesheetPath(rowHeadId);
            if (spritesheetPath != null) {
              prefetchedHeadIds.add(rowHeadId);
              unawaited(
                downloader.downloadAllVariants(
                  headId: rowHeadId,
                  baseLocalPath: spritesheetPath,
                  type: SpriteType.custom,
                ),
              );
            }
          }
        }
      }
    } catch (e, s) {
      try {
        instance.get<LoggerService>().logError(
          Exception('GenerateFusionGrid._loadAllSprites prefetch failed: $e'),
          s,
        );
      } catch (_) {}
    }

    for (int i = 0; i < basicGrid.length; i++) {
      final row = <Fusion?>[];
      // 1 / 0 para evitar null en el ajuste AxA de fusiones
      final spritesheetPath = !kIsWeb
          ? await getFusion.spriteRepository.getSpritesheetPath(
              i == 0
                  ? basicGrid[i][1]!.headPokemon.pokedexNumber
                  : basicGrid[i][0]!.headPokemon.pokedexNumber,
            )
          : null;

      // Pre-batch crop for all body indices in this row using an isolate
      final Map<int, SpriteData> rowIndexToSprite = {};
      // Lanzar prefetched variants en segundo plano por headId de la fila
      try {
        if (!kIsWeb) {
          final rowHeadId = (i == 0
                  ? basicGrid[i][1]!.headPokemon.pokedexNumber
                  : basicGrid[i][0]!.headPokemon.pokedexNumber);
          if (spritesheetPath != null && !prefetchedHeadIds.contains(rowHeadId)) {
            prefetchedHeadIds.add(rowHeadId);
            final downloader = instance<SpriteDownloadService>();
            unawaited(
              downloader.downloadAllVariants(
                headId: rowHeadId,
                baseLocalPath: spritesheetPath,
                type: SpriteType.custom,
              ),
            );
          }
        }
      } catch (e, s) {
        try {
          instance.get<LoggerService>().logError(
            Exception('GenerateFusionGrid._loadAllSprites row prefetch failed: $e'),
            s,
          );
        } catch (_) {}
      }
      if (!kIsWeb && spritesheetPath != null) {
        final spriteSheet = File(spritesheetPath);
        if (await spriteSheet.exists()) {
          // Collect all body indices needed for this row
          final Set<int> indices = <int>{};
          for (int j = 0; j < basicGrid[i].length; j++) {
            final fusion = basicGrid[i][j];
            if (fusion != null) {
              indices.add(fusion.bodyPokemon.pokedexNumber);
            }
          }
          if (indices.isNotEmpty) {
            try {
              final results = await compute(
                batchDecodeAndCrop,
                {
                  'path': spritesheetPath,
                  'indices': indices.toList(),
                  'spriteWidth': SpriteParser.SPRITE_WIDTH,
                  'spriteHeight': SpriteParser.SPRITE_HEIGHT,
                  'spritesPerRow': SpriteParser.SPRITES_PER_ROW,
                  'variant': '',
                  'isAutogenerated': false,
                },
              );

              for (final dynamic item in results) {
                final Map<String, dynamic> map = item as Map<String, dynamic>;
                final int index = map['index'] as int;
                final int x = map['x'] as int;
                final int y = map['y'] as int;
                final int width = map['width'] as int;
                final int height = map['height'] as int;
                final String variant = (map['variant'] as String?) ?? '';
                final bool isAutogenerated = (map['isAutogenerated'] as bool?) ?? false;
                final String path = map['path'] as String;
                final TransferableTypedData ttd = map['bytes'] as TransferableTypedData;
                final Uint8List pngBytes = ttd.materialize().asUint8List();

                rowIndexToSprite[index] = SpriteData(
                  spritePath: path,
                  spriteBytes: pngBytes,
                  x: x,
                  y: y,
                  width: width,
                  height: height,
                  variant: variant,
                  isAutogenerated: isAutogenerated,
                );
              }
            } catch (e, s) {
              try {
                instance.get<LoggerService>().logError(
                  Exception('GenerateFusionGrid._loadAllSprites isolate batch failed: $e'),
                  s,
                );
              } catch (_) {}
            }
          }
        }
      }

      // Consultar si se permiten sprites autogenerados
      final bool useAutogenSprites = await SettingsService.getUseAutogenSprites();

      // Procesar todas las columnas de esta fila
      for (int j = 0; j < basicGrid[i].length; j++) {
        final fusion = basicGrid[i][j];

        if (fusion != null) {
          SpriteData? finalSprite;

          // 1) Intentar respetar la variante preferida del usuario
          final preferredVariant = await PreferredSpriteService.getPreferredVariant(
            fusion.headPokemon.pokedexNumber,
            fusion.bodyPokemon.pokedexNumber,
          );
          if (preferredVariant != null) {
            if (preferredVariant.isEmpty && spritesheetPath != null) {
              // Use isolate-cropped sprite if available
              finalSprite = rowIndexToSprite[fusion.bodyPokemon.pokedexNumber];
            }
            // For non-empty preferred variants, read specific file
            finalSprite ??= await getFusion.spriteRepository.getSpecificSprite(
              fusion.headPokemon.pokedexNumber,
              fusion.bodyPokemon.pokedexNumber,
              variant: preferredVariant,
            );
          }

          // 2) Si no hay preferencia o falló, intentar sprite del spritesheet base
          if (finalSprite == null && !kIsWeb && spritesheetPath != null) {
            // Try isolate batch pre-crop result
            finalSprite = rowIndexToSprite[fusion.bodyPokemon.pokedexNumber];
          }

          // 3) Si no hay sprite del spritesheet, intentar obtener sprite específico
          finalSprite ??= await getFusion.spriteRepository.getSpecificSprite(
            fusion.headPokemon.pokedexNumber,
            fusion.bodyPokemon.pokedexNumber,
          );

          // Si no hay sprite personalizado, intentar autogenerado (en web devuelve placeholder)
          if (finalSprite == null && useAutogenSprites) {
            finalSprite = await getFusion.spriteRepository.getAutogenSprite(
              fusion.headPokemon.pokedexNumber,
              fusion.bodyPokemon.pokedexNumber,
            );
          }

          // Si sigue sin sprite y los autogenerados están deshabilitados, marcar celda como disabled
          if (finalSprite == null && !useAutogenSprites) {
            row.add(null);
            continue;
          }

          // Calcular estadísticas de la fusión
          PokemonStats? fusionStats;
          try {
            final calculator = FusionStatsCalculator();
            fusionStats = await calculator.getStatsFromFusion(
              fusion.headPokemon,
              fusion.bodyPokemon,
            );
          } catch (e, s) {
            try {
              instance.get<LoggerService>().logError(
                Exception('GenerateFusionGrid._loadAllSprites stats calc failed: $e'),
                s,
              );
            } catch (_) {}
          }

          final fusionWithSprite = Fusion(
            headPokemon: fusion.headPokemon,
            bodyPokemon: fusion.bodyPokemon,
            availableSprites: fusion.availableSprites,
            types: fusion.types,
            primarySprite: finalSprite,
            stats: fusionStats,
          );

          row.add(fusionWithSprite);
        } else {
          row.add(null);
        }
      }

      gridWithSprites.add(row);
    }

    return gridWithSprites;
  }

  Future<List<Fusion>> getAllFusions(List<Pokemon> selectedPokemon) async {
    final fusions = <Fusion>[];

    // Obtener configuración de fusiones AxA
    final useAxAFusions = await SettingsService.getUseAxAFusions();

    for (int i = 0; i < selectedPokemon.length; i++) {
      for (int j = 0; j < selectedPokemon.length; j++) {
        // Si las fusiones AxA están deshabilitadas y es la misma posición, saltar
        if (!useAxAFusions && i == j) {
          continue;
        }

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
